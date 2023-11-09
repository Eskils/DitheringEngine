//
//  VideoDescription.swift
//
//
//  Created by Eskil Gjerde Sviggum on 08/11/2023.
//

import Foundation
import AVFoundation

public struct VideoDescription {
    
    public let asset: AVAsset
    
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
    
    func getFrames(handler: (CVPixelBuffer) throws -> Void) throws {
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
        
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        
        if !assetReader.canAdd(trackReaderOutput) {
            throw VideoDescriptionError.cannotAddTrackReaderOutput
        }
        
        assetReader.add(trackReaderOutput)
        assetReader.startReading()
        
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                do {
                    try handler(imageBuffer)
                } catch {
                    assetReader.cancelReading()
                    throw error
                }
            }
        }
        
        if assetReader.status != .completed {
            throw VideoDescriptionError.failedToReadAllFramesInVideo(status: assetReader.status.rawValue)
        }
    }
    
    enum VideoDescriptionError: Error {
        case cannotMakeAssetReader(Error)
        case assetContainsNoTrackForVideo
        case cannotAddTrackReaderOutput
        case failedToReadAllFramesInVideo(status: Int)
    }
}

