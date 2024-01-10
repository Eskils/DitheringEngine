//
//  VideoDitheringEngine.swift
//
//
//  Created by Eskil Gjerde Sviggum on 08/11/2023.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

public struct VideoDitheringEngine {
    
    /// The frame rate for your resulting video.
    public private(set) var frameRate: Float = 30
    
    private let queue = DispatchQueue(label: "com.skillbreak.DitheringEngine", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    /// Number of frames to process concurrently (per batch). Default is 5. A greater number might be faster, but will use more memory.
    public var numberOfConcurrentFrames = 5
    
    private var workItems: Int {
        numberOfConcurrentFrames
    }
    
    public init(numberOfConcurrentFrames: Int = 5) {
        self.numberOfConcurrentFrames = numberOfConcurrentFrames
    }
    
    /// Provide the frame rate for your resulting video. 
    /// The final frame rate is less than or equal to the specified value.
    /// If you specify 30, and the imported video has a framerate of 24 frames per second,
    /// The resulting video will have a framerate of 24 fps.
    public init(frameRate: Int) {
        self.frameRate = Float(frameRate)
    }
    
    /// Dither video from url using method and palette. Set options and outputURL. ProgressHandler needs a return of `true` to continue, returning false will cancell the dithering and yield an `VideoDitheringError.cancelled` failure in the completion callback.
    public func dither(video url: URL, resizingTo size: CGSize?, usingMethod ditherMethod: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, options: VideoDitherOptions = .none, outputURL: URL, progressHandler: ((Float) -> Bool)? = nil, completionHandler: @escaping (Error?) -> Void) {
        var videoDescription = VideoDescription(url: url)
        
        if let size {
            videoDescription.renderSize = size
        }
        
        dither(
            videoDescription: videoDescription,
            usingMethod: ditherMethod,
            andPalette: palette,
            withDitherMethodSettings: ditherMethodSettings,
            andPaletteSettings: paletteSettings,
            options: options,
            outputURL: outputURL,
            progressHandler: progressHandler,
            completionHandler: completionHandler
        )
    }
    
    /// Dither video using method and palette. Set options and outputURL. ProgressHandler needs a return of `true` to continue, returning false will cancell the dithering and yield an `VideoDitheringError.cancelled` failure in the completion callback.
    public func dither(videoDescription: VideoDescription, usingMethod ditherMethod: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, options: VideoDitherOptions = .none, outputURL: URL, progressHandler: ((Float) -> Bool)? = nil, completionHandler: @escaping (Error?) -> Void) {
        
        guard 
            let originalSize = videoDescription.size
        else {
            completionHandler(VideoDescription.VideoDescriptionError.assetContainsNoTrackForVideo)
            return
        }
        
        let frameRate = videoDescription.expectedFrameRate(frameRateCap: self.frameRate)
        let sampleRate = videoDescription.sampleRate ?? 44100
        
        let size: CGSize
        if let renderSize = videoDescription.renderSize {
            let width = renderSize.width
            let height = width * (originalSize.height / originalSize.width)
            size = CGSize(width: width, height: height)
        } else {
            size = originalSize
        }
        
        let width = Int(originalSize.width)
        let height = Int(originalSize.height)
        
        let videoAssembler: VideoAssembler
        do {
            videoAssembler = try VideoAssembler(outputURL: outputURL, width: Int(size.width.rounded()), height: Int(size.height.rounded()), framerate: Int(frameRate), sampleRate: sampleRate, transform: videoDescription.transform, emitFrames: false)
        } catch {
            completionHandler(error)
            return
        }
        
        let numberOfFrames = videoDescription.numberOfFrames(overrideFramerate: frameRate) ?? 0
        let numberOfBatches = numberOfFrames / workItems
        
        let lutPalette = palette.lut(fromPalettes: Palettes(), settings: paletteSettings)
        let byteColorCache: ByteByteColorCache?
        let floatingColorCache: FloatByteColorCache?
        if case .lutCollection(let collection) = lutPalette.type, options.contains(.precalculateDitheredColorForAllColors) {
            byteColorCache = .populateWitColors(fromLUT: collection)
            floatingColorCache = byteColorCache?.toFloatingWithoutCopy()
        } else {
            byteColorCache = nil
            floatingColorCache = nil
        }
        
        let workItemContexts = (0..<workItems).compactMap { _ -> WorkItemContext? in
            return WorkItemContext(
                ditheringEngine: DitheringEngine(),
                context: CIContext(),
                renderSize: videoDescription.renderSize,
                ditherMethod: ditherMethod,
                palette: palette,
                ditherMethodSettings: ditherMethodSettings,
                paletteSettings: paletteSettings,
                byteColorCache: byteColorCache,
                floatingColorCache: floatingColorCache
            )
        }
        
        if progressHandler?(0) == false {
            videoAssembler.cancelVideoGeneration()
            completionHandler(VideoDitheringError.cancelled)
            return
        }
        
        do {
            let assetReader = try videoDescription.makeReader()
            let frames = try videoDescription.getFrames(assetReader: assetReader, frameRateCap: frameRate)
            
            #if DEBUG
            print("Opening audio track")
            #endif
            
            let audioSamples: VideoDescription.GetAudioHandler?
            do {
                audioSamples = try videoDescription.getAudio(assetReader: assetReader)
            } catch {
                if let error = error as? VideoDescription.VideoDescriptionError,
                   case .assetContainsNoTrackForAudio = error {
                    print("Media has no audio track")
                    audioSamples = nil
                } else {
                    throw error
                }
            }
            
            #if DEBUG
            print("Finished opening audio track, starting to open frames")
            #endif
            
            videoDescription.startReading(reader: assetReader)
            
            DispatchQueue.main.async {
                dispatchUntilEmpty(queue: queue, contexts: workItemContexts, frames: frames, videoAssembler: videoAssembler) { batchNumber in
                    if let progressHandler {
                        let progress = min(1, Float(batchNumber) / Float(numberOfBatches))
                        return progressHandler(progress)
                    }
                    
                    return true
                } completion: { wasCanceled in
                    if wasCanceled {
                        frames.cancel()
                        audioSamples?.cancel()
                        videoAssembler.cancelVideoGeneration()
                        completionHandler(VideoDitheringError.cancelled)
                        return
                    }
                    
                    print("Finished adding all frames")
                    if let audioSamples, !options.contains(.removeAudio) {
                        transferAudio(audioSamples: audioSamples, videoAssembler: videoAssembler)
                        print("Finished adding audio")
                    }
                    DispatchQueue.main.async {
                        Task {
                            await videoAssembler.generateVideo()
                            completionHandler(nil)
                        }
                    }
                }
            }
        } catch {
            videoAssembler.cancelVideoGeneration()
            completionHandler(error)
            return
        }
    }
    
    private func transferAudio(audioSamples: VideoDescription.GetAudioHandler, videoAssembler: VideoAssembler) {
        while let sample = audioSamples.next() {
            videoAssembler.addAudio(sample: sample)
        }
    }
    
    @MainActor
    private func dispatchUntilEmpty(queue: DispatchQueue, contexts: [WorkItemContext], frames: VideoDescription.GetFramesHandler, videoAssembler: VideoAssembler, count: Int = 0, progressHandler: @escaping (Int) -> Bool, completion: @escaping (_ wasCanceled: Bool) -> Void) {
        let numThreads = contexts.count
        let buffers = (0..<numThreads).compactMap { _ in frames.next() }
        let isLastRun = buffers.count != numThreads
        var idempotency = 0
        dispatch(queue: queue, contexts: contexts, buffers: buffers, idempotency: idempotency) { receivedIdempotency, results in
            
            let shouldContinue = progressHandler(count)
            
            if !shouldContinue {
                completion(true)
                return
            }
            
            if receivedIdempotency != idempotency {
                return
            }
            
            idempotency += 1
            
            for result in results {
                if let result {
                    videoAssembler.addFrame(pixelBuffer: result)
                }
            }
            
            if isLastRun {
                completion(false)
            }
            
            if isLastRun {
                return
            }
            
            dispatchUntilEmpty(queue: queue, contexts: contexts, frames: frames, videoAssembler: videoAssembler, count: count + 1, progressHandler: progressHandler, completion: completion)
        }
    }
    
    private func dispatch(queue: DispatchQueue, contexts: [WorkItemContext], buffers: [CVPixelBuffer], idempotency: Int, completion: @escaping (Int, [CVPixelBuffer?]) -> Void) {
        let numThreads = min(buffers.count, contexts.count)
        var results = [CVPixelBuffer?](repeating: nil, count: numThreads)
        var responses: Int = 0
        
        if numThreads == 0 {
            completion(idempotency, results)
            return
        }
        
        for i in 0..<numThreads {
            let context = contexts[i]
            let pixelBuffer = buffers[i]
            queue.async {
                defer {
                    DispatchQueue.main.async {
                        responses += 1
                        if responses == numThreads {
                            responses += 1
                            completion(idempotency, results)
                        }
                    }
                }
                
                do {
                    let result = try context.scaleAndDither(pixelBuffer: pixelBuffer)
                    results[i] = result
                } catch {
                    print("Failed to scale and dither frame: \(error)")
                }
            }
        }
        
    }
}

extension VideoDitheringEngine {
    struct WorkItemContext {
        private let ditheringEngine: DitheringEngine
        private let context: CIContext
        private let renderSize: CGSize?,
            ditherMethod: DitherMethod,
            palette: Palette,
            ditherMethodSettings: SettingsConfiguration,
            paletteSettings: SettingsConfiguration,
            byteColorCache: ByteByteColorCache?,
            floatingColorCache: FloatByteColorCache?
        
        init(ditheringEngine: DitheringEngine, context: CIContext, renderSize: CGSize? = nil, ditherMethod: DitherMethod, palette: Palette, ditherMethodSettings: SettingsConfiguration, paletteSettings: SettingsConfiguration, byteColorCache: ByteByteColorCache?, floatingColorCache: FloatByteColorCache?) {
            self.ditheringEngine = ditheringEngine
            self.context = context
            self.renderSize = renderSize
            self.ditherMethod = ditherMethod
            self.palette = palette
            self.ditherMethodSettings = ditherMethodSettings
            self.paletteSettings = paletteSettings
            self.byteColorCache = byteColorCache
            self.floatingColorCache = floatingColorCache
        }
        
        func scaleAndDither(pixelBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let scaleFilter = CIFilter.lanczosScaleTransform()
            scaleFilter.inputImage = ciImage
            if let renderSize {
                let scale = renderSize.width / ciImage.extent.width
                scaleFilter.scale = Float(scale)
            } else {
                scaleFilter.scale = 1
            }
            
            if let scaledImage = scaleFilter.outputImage,
               let renderedImage = ciImageToCVPixelBuffer(image: scaledImage, context: context) {
                try ditheringEngine.set(pixelBuffer: renderedImage)
            } else {
                print("Failed to resize image")
                try ditheringEngine.set(pixelBuffer: pixelBuffer)
            }

            let pixelBuffer = try ditheringEngine.ditherIntoPixelBuffer(
                usingMethod: ditherMethod,
                andPalette: palette,
                withDitherMethodSettings: ditherMethodSettings,
                withPaletteSettings: paletteSettings,
                byteColorCache: byteColorCache,
                floatingColorCache: floatingColorCache
            )
            
            return pixelBuffer
        }
    
        private func ciImageToCVPixelBuffer(image: CIImage, context: CIContext) -> CVPixelBuffer? {
            var pixelBuffer: CVPixelBuffer?
            let width = Int(image.extent.width)
            let height = Int(image.extent.height)
            let attrs = [
                  kCVPixelBufferCGImageCompatibilityKey: true,
                  kCVPixelBufferCGBitmapContextCompatibilityKey: true,
                  kCVPixelBufferWidthKey: Int(image.extent.width),
                  kCVPixelBufferHeightKey: Int(image.extent.height)
                ] as CFDictionary
            CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
            
            guard let pixelBuffer else {
                return nil
            }
            
            context.render(image, to: pixelBuffer)
            
            return pixelBuffer
        }
        
        
    }
}

public enum VideoDitheringError: Error {
    case cancelled
}

public struct VideoDitherOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Default video dithering.
    public static let none = Self(rawValue: 0)
    
    /// Makes an indexed map of all colors to dithered color.
    /// Adds an increased wait time in the begining.
    /// Might be faster with large LUTCollections. Do not use with LUT which is already index based.
    public static let precalculateDitheredColorForAllColors = Self(rawValue: 1 << 0)
    
    /// Does not transfer audio from the original video file.
    public static let removeAudio = Self(rawValue: 1 << 1)
    
    
}
