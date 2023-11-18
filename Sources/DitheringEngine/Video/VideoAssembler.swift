//
//  VideoAssembler.swift
//
//
//  Created by Eskil Gjerde Sviggum on 08/11/2023.
//

import AVFoundation
import UIKit

class VideoAssembler {
    
    let width: Int
    let height: Int
    let framerate: Int
    
    private let assetWriter: AVAssetWriter
    private let assetWriterInput: AVAssetWriterInput
    private let assetWriterAdaptor: AVAssetWriterInputPixelBufferAdaptor
    
    private let emitFrames: Bool
    private let framesURL: URL
    
    private var framecount: Int = 0
    
    init(outputURL: URL, width: Int, height: Int, framerate: Int, emitFrames: Bool = false) throws {
        self.width = width
        self.height = height
        self.framerate = framerate
        self.emitFrames = emitFrames
        
        self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let assetWriterSettings = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey : width, AVVideoHeightKey: height] as [String : Any]
        
        self.assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: assetWriterSettings)
        self.assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
        
        assetWriterInput.expectsMediaDataInRealTime = true
        
        self.framesURL = outputURL.deletingLastPathComponent().appendingPathComponent("Frames")
        
        if emitFrames {
            if FileManager.default.fileExists(atPath: framesURL.path) {
                try? FileManager.default.removeItem(at: framesURL)
            }
            
            try? FileManager.default.createDirectory(at: framesURL, withIntermediateDirectories: true)
        }
        
        try startVideoAssetWriter()
    }
    
    private func startVideoAssetWriter() throws {
        guard assetWriter.canAdd(assetWriterInput) else {
            throw VideoAssemblerError.cannotAddAssetWriterInput
        }
        
        assetWriter.add(assetWriterInput)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
    }
    
    func addFrame(pixelBuffer: CVPixelBuffer) {
        if emitFrames {
            storeImageFrame(pixelBuffer: pixelBuffer)
        }
        
        let frametime = CMTimeMake(value: Int64(framecount), timescale: Int32(framerate))
        framecount += 1
        
        while !assetWriterInput.isReadyForMoreMediaData {}
        self.assetWriterAdaptor.append(pixelBuffer, withPresentationTime: frametime)
    }
    
    let context = CIContext()
    
    private func storeImageFrame(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent),
           let data = UIImage(cgImage: cgImage).pngData() {
            let url = framesURL.appendingPathComponent("DitheredVideoFrame_\(framecount).png")
            try? data.write(to: url)
        }
    }
    
    func generateVideo() async {
        while !assetWriterInput.isReadyForMoreMediaData {}
        assetWriterInput.markAsFinished()
        await assetWriter.finishWriting()
    }
    
    func cancelVideoGeneration() {
        assetWriter.cancelWriting()
    }
    
    enum VideoAssemblerError: Error {
        case cannotAddAssetWriterInput
    }
    
}
