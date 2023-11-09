//
//  VideoDitheringEngine.swift
//
//
//  Created by Eskil Gjerde Sviggum on 08/11/2023.
//

import Foundation

public struct VideoDitheringEngine {
    
    let ditheringEngine: DitheringEngine
    
    public init(ditheringEngine: DitheringEngine? = nil) {
        self.ditheringEngine = ditheringEngine ?? DitheringEngine()
    }
    
    public func dither(video url: URL, toPalette palette: Palette, usingDitherMethod ditherMethod: DitherMethod, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, outputURL: URL) async throws {
        try await dither(
            videoDescription: VideoDescription(url: url),
            toPalette: palette,
            usingDitherMethod: ditherMethod,
            withDitherMethodSettings: ditherMethodSettings,
            andPaletteSettings: paletteSettings,
            outputURL: outputURL
        )
    }
    
    public func dither(videoDescription: VideoDescription, toPalette palette: Palette, usingDitherMethod ditherMethod: DitherMethod, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, outputURL: URL) async throws {
        
        guard 
            let framerate = videoDescription.framerate.map({ Int($0) }),
            let size = videoDescription.size
        else {
            throw VideoDescription.VideoDescriptionError.assetContainsNoTrackForVideo
        }
        
        let videoAssembler = try VideoAssembler(outputURL: outputURL, width: Int(size.width), height: Int(size.height), framerate: framerate)
        
        do {
            try videoDescription.getFrames { pixelBuffer in
                try ditheringEngine.set(pixelBuffer: pixelBuffer)
                let pixelBuffer = try ditheringEngine.ditherIntoPixelBuffer(
                    usingMethod: ditherMethod,
                    andPalette: palette,
                    withDitherMethodSettings: ditherMethodSettings,
                    withPaletteSettings: paletteSettings
                )
                videoAssembler.addFrame(pixelBuffer: pixelBuffer)
            }
        } catch {
            videoAssembler.cancelVideoGeneration()
            throw error
        }
        
        await videoAssembler.generateVideo()
    }
    
}
