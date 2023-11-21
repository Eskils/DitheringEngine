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
    
    public private(set) var frameRate: Float = 30
    
    private let queue = DispatchQueue(label: "com.skillbreak.DitheringEngine", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    /// Number of frames to process concurrently (per batch)
    private let workItems = 5
    
    public init() {}
    
    /// Provide the frame rate for your resulting video. 
    /// The final frame rate is less than or equal to the specified value.
    /// If you specify 30, and the imported video has a framerate of 24 frames per second,
    /// The resulting video will have a framerate of 24 fps.
    public init(frameRate: Int) {
        self.frameRate = Float(frameRate)
    }
    
    public func dither(video url: URL, resizingTo size: CGSize?, usingMethod ditherMethod: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, outputURL: URL, progressHandler: ((Float) -> Void)? = nil, completionHandler: @escaping (Error?) -> Void) {
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
            outputURL: outputURL,
            progressHandler: progressHandler,
            completionHandler: completionHandler
        )
    }
    
    public func dither(videoDescription: VideoDescription, usingMethod ditherMethod: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, outputURL: URL, progressHandler: ((Float) -> Void)? = nil, completionHandler: @escaping (Error?) -> Void) {
        
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
            videoAssembler = try VideoAssembler(outputURL: outputURL, width: Int(size.width.rounded()), height: Int(size.height.rounded()), framerate: Int(frameRate), sampleRate: sampleRate, emitFrames: true)
        } catch {
            completionHandler(error)
            return
        }
        
        let numberOfFrames = videoDescription.numberOfFrames(overrideFramerate: frameRate) ?? 0
        let numberOfBatches = numberOfFrames / workItems
        
        let lutPalette = palette.lut(fromPalettes: Palettes(), settings: paletteSettings)
        let byteColorCache: ByteByteColorCache?
        let floatingColorCache: FloatByteColorCache?
        if case .lutCollection(let collection) = lutPalette.type {
            byteColorCache = .populateWitColors(fromLUT: collection)
            floatingColorCache = byteColorCache?.toFloatingWithoutCopy()
        } else {
            byteColorCache = nil
            floatingColorCache = nil
        }
        
        let workItemContexts = (0..<workItems).compactMap { _ -> WorkItemContext? in
            return WorkItemContext(
                ditheringEngine: DitheringEngine(),
                invertBuffer: UnsafeMutablePointer<UInt8>.allocate(capacity: 4 * width * height),
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
        
        do {
            let assetReader = try videoDescription.makeReader()
            let frames = try videoDescription.getFrames(assetReader: assetReader, frameRateCap: frameRate)
            
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
            
            videoDescription.startReading(reader: assetReader)
            
            DispatchQueue.main.async {
                dispatchUntilEmpty(queue: queue, contexts: workItemContexts, frames: frames, videoAssembler: videoAssembler) { batchNumber in
                    if let progressHandler {
                        let progress = min(1, Float(batchNumber) / Float(numberOfBatches))
                        progressHandler(progress)
                    }
                } completion: {
                    print("Finished adding all frames")
                    if let audioSamples {
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
    
    func transferAudio(audioSamples: VideoDescription.GetAudioHandler, videoAssembler: VideoAssembler) {
        while let sample = audioSamples.next() {
            videoAssembler.addAudio(sample: sample)
        }
    }
    
    @MainActor
    func dispatchUntilEmpty(queue: DispatchQueue, contexts: [WorkItemContext], frames: VideoDescription.GetFramesHandler, videoAssembler: VideoAssembler, count: Int = 0, progressHandler: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        let numThreads = contexts.count
        let buffers = (0..<numThreads).compactMap { _ in frames.next() }
        let isLastRun = buffers.count != numThreads
        var idempotency = 0
        dispatch(queue: queue, contexts: contexts, buffers: buffers, idempotency: idempotency) { receivedIdempotency, results in
            
            progressHandler(count)
            
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
                completion()
            }
            
            if isLastRun {
                return
            }
            
            dispatchUntilEmpty(queue: queue, contexts: contexts, frames: frames, videoAssembler: videoAssembler, count: count + 1, progressHandler: progressHandler, completion: completion)
        }
    }
    
    func dispatch(queue: DispatchQueue, contexts: [WorkItemContext], buffers: [CVPixelBuffer], idempotency: Int, completion: @escaping (Int, [CVPixelBuffer?]) -> Void) {
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
                
                guard
                    let result = try? context.scaleAndDither(pixelBuffer: pixelBuffer)
                else {
                    return
                }
                
                results[i] = result
            }
        }
        
    }
 
    
    struct RenderItem {
        let pixelBuffer: CVPixelBuffer
        let frame: Int
    }
    
    struct WorkItemContext {
        private let ditheringEngine: DitheringEngine
        private let invertBuffer: UnsafeMutablePointer<UInt8>
        private let context: CIContext
        private let renderSize: CGSize?,
            ditherMethod: DitherMethod,
            palette: Palette,
            ditherMethodSettings: SettingsConfiguration,
            paletteSettings: SettingsConfiguration,
            byteColorCache: ByteByteColorCache?,
            floatingColorCache: FloatByteColorCache?
        
        init(ditheringEngine: DitheringEngine, invertBuffer: UnsafeMutablePointer<UInt8>, context: CIContext, renderSize: CGSize? = nil, ditherMethod: DitherMethod, palette: Palette, ditherMethodSettings: SettingsConfiguration, paletteSettings: SettingsConfiguration, byteColorCache: ByteByteColorCache?, floatingColorCache: FloatByteColorCache?) {
            self.ditheringEngine = ditheringEngine
            self.invertBuffer = invertBuffer
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
               let renderedImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                try ditheringEngine.set(image: renderedImage)
            } else {
                print("Failed to resize image")
                try ditheringEngine.set(pixelBuffer: pixelBuffer)
            }

            let pixelBuffer = try ditheringEngine.ditherIntoPixelBuffer(
                usingMethod: ditherMethod,
                andPalette: palette,
                withDitherMethodSettings: ditherMethodSettings,
                withPaletteSettings: paletteSettings,
                invertedColorBuffer: invertBuffer,
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
              kCVPixelBufferCGBitmapContextCompatibilityKey: false,
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
