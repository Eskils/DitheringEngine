//
//  VideoAssembler.swift
//
//
//  Created by Eskil Gjerde Sviggum on 08/11/2023.
//

import AVFoundation

class VideoAssembler {
    
    let width: Int
    let height: Int
    let framerate: Int
    
    private let assetWriter: AVAssetWriter
    private let assetWriterInput: AVAssetWriterInput
    private let assetWriterAdaptor: AVAssetWriterInputPixelBufferAdaptor
    
    private var framecount: Int = 0
    
    init(outputURL: URL, width: Int, height: Int, framerate: Int) throws {
        self.width = width
        self.height = height
        self.framerate = framerate
        
        self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let assetWriterSettings = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey : width, AVVideoHeightKey: height] as [String : Any]
        
        self.assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: assetWriterSettings)
        self.assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
        
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
        let frametime = CMTimeMake(value: Int64(framecount), timescale: Int32(framerate))
        framecount += 1
        
        while !assetWriterInput.isReadyForMoreMediaData {}
        self.assetWriterAdaptor.append(pixelBuffer, withPresentationTime: frametime)
        
        print("Finished processing frame \(framecount)")
    }
    
    func generateVideo() async {
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
