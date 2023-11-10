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
    
    var size: CGSize? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        return videoTrack.naturalSize
    }
    
    func getFrames(frameRateCap: Float? = nil, handler: (CVPixelBuffer) throws -> Void) throws {
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
        
        let frameRate = videoTrack.nominalFrameRate
        let expectedFrameRate: Float = frameRateCap ?? frameRate
        let framesToInclude = Int(frameRate / expectedFrameRate)
        
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        
        if !assetReader.canAdd(trackReaderOutput) {
            throw VideoDescriptionError.cannotAddTrackReaderOutput
        }
        
        assetReader.add(trackReaderOutput)
        assetReader.startReading()
        
        var sampleIndex = 0
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            if sampleIndex % framesToInclude != 0 {
                sampleIndex += 1
                continue
            }
            
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                do {
                    try handler(imageBuffer)
                } catch {
                    assetReader.cancelReading()
                    throw error
                }
                
                sampleIndex += 1
            }
        }
        
        if assetReader.status != .completed {
            throw VideoDescriptionError.failedToReadAllFramesInVideo(status: assetReader.status.rawValue)
        }
    }
    
    public func resizingVideo(toSize scaledSize: CGSize, outputURL: URL) async throws {
        guard let size else {
            throw VideoDescriptionError.assetContainsNoTrackForVideo
        }
        
        let scale = scaledSize.width / size.width
        
        let scaleComposition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: {request in
          
            guard let cropFilter = CIFilter(name: "CILanczosScaleTransform") else {
                assertionFailure()
                request.finish(with: request.sourceImage, context: nil)
                return
            }
            
            cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey)
            cropFilter.setValue(scale, forKey: kCIInputScaleKey)
              
              
            guard let outputImage = cropFilter.outputImage else {
                assertionFailure()
                request.finish(with: request.sourceImage, context: nil)
                return
            }

            request.finish(with: outputImage, context: nil)
        })
        
        scaleComposition.renderSize = CGSize(width: scaledSize.width, height: scale * size.height);
        scaleComposition.frameDuration = CMTimeMake(value: 1, timescale: 30);
        scaleComposition.renderScale = 1.0;

        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoDescriptionError.cannotMakeExporter
        }
        exporter.videoComposition = scaleComposition
        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4
        
        await exporter.export()
    }
    
    enum VideoDescriptionError: Error {
        case cannotMakeAssetReader(Error)
        case assetContainsNoTrackForVideo
        case cannotAddTrackReaderOutput
        case failedToReadAllFramesInVideo(status: Int)
        case cannotMakeExporter
    }
}

