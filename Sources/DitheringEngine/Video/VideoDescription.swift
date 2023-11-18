//
//  VideoDescription.swift
//
//
//  Created by Eskil Gjerde Sviggum on 08/11/2023.
//

import Foundation
import AVFoundation
import CoreImage

public struct VideoDescription {
    
    public let asset: AVAsset
    public var renderSize: CGSize?
    
    public init(url: URL) {
        self.asset = AVURLAsset(url: url)
    }
    
    public init(asset: AVAsset) {
        self.asset = asset
    }
    
    var framerate: Float? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        return videoTrack.nominalFrameRate
    }
    
    var duration: TimeInterval {
        asset.duration.seconds
    }
    
    func numberOfFrames(overrideFramerate: Float? = nil) -> Int? {
        guard let framerate = overrideFramerate ?? self.framerate else {
            return nil
        }
        
        return Int(framerate * Float(duration))
    }
    
    var size: CGSize? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        return videoTrack.naturalSize
    }
    
    /// Reads the first frame in the video as an image.
    public func getPreviewImage() async throws -> CGImage {
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        let time = CMTime.zero
        
        if #available(iOS 16, macCatalyst 16, *) {
            let (image, _) = try await assetImageGenerator.image(at: time)
            return image
        } else {
            let image = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            return image
        }
    }
    
    func getFrames(frameRateCap: Float? = nil) throws -> GetFramesHandler {
        let assetReader: AVAssetReader
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            throw VideoDescriptionError.cannotMakeAssetReader(error)
        }
        
        let outputSettings = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw VideoDescriptionError.assetContainsNoTrackForVideo
        }
        
        let frameRate = videoTrack.nominalFrameRate.rounded()
        let expectedFrameRate: Float = frameRateCap ?? frameRate
        let framesToInclude = Int(frameRate / expectedFrameRate)
        
        print(frameRate, expectedFrameRate, framesToInclude)
        
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        
        if !assetReader.canAdd(trackReaderOutput) {
            throw VideoDescriptionError.cannotAddTrackReaderOutput
        }
        
        assetReader.add(trackReaderOutput)
        assetReader.startReading()
        
        return GetFramesHandler(assetReader: assetReader, trackReaderOutput: trackReaderOutput, framesToInclude: framesToInclude)
    }
    
    enum VideoDescriptionError: Error {
        case cannotMakeAssetReader(Error)
        case assetContainsNoTrackForVideo
        case cannotAddTrackReaderOutput
        case failedToReadAllFramesInVideo(status: Int)
        case cannotMakeExporter
    }
    
    class GetFramesHandler {
        
        private let assetReader: AVAssetReader
        private let trackReaderOutput: AVAssetReaderTrackOutput
        private let framesToInclude: Int
        var sampleIndex = 0
        
        init(assetReader: AVAssetReader, trackReaderOutput: AVAssetReaderTrackOutput, framesToInclude: Int) {
            self.assetReader = assetReader
            self.trackReaderOutput = trackReaderOutput
            self.framesToInclude = framesToInclude
        }
        
        func next() -> CVPixelBuffer? {
            while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                if sampleIndex % framesToInclude != 0 {
                    sampleIndex += 1
                    continue
                }
                
                if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    sampleIndex += 1
                    return imageBuffer
                }
            }
            
            return nil
        }
        
        func cancel() {
            assetReader.cancelReading()
        }
    }
}

