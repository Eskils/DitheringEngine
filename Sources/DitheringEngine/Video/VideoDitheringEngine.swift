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
    
    let ditheringEngine: DitheringEngine
    
    private let frameRate: Float = 30
    
    public init(ditheringEngine: DitheringEngine? = nil) {
        self.ditheringEngine = ditheringEngine ?? DitheringEngine()
    }
    
    public func dither(video url: URL, toPalette palette: Palette, usingDitherMethod ditherMethod: DitherMethod, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, outputURL: URL, completionHandler: @escaping (Error?) -> Void) {
        let task = Task.detached(priority: .high) {
            do {
                try await dither(
                    video: url,
                    toPalette: palette,
                    usingDitherMethod: ditherMethod,
                    withDitherMethodSettings: ditherMethodSettings,
                    andPaletteSettings: paletteSettings,
                    outputURL: outputURL
                )
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }
    
    public func dither(videoDescription: VideoDescription, toPalette palette: Palette, usingDitherMethod ditherMethod: DitherMethod, withDitherMethodSettings ditherMethodSettings: SettingsConfiguration, andPaletteSettings paletteSettings: SettingsConfiguration, outputURL: URL, completionHandler: @escaping (Error?) -> Void) {
        let task = Task.detached(priority: .high) {
            do {
                try await dither(
                    videoDescription: videoDescription,
                    toPalette: palette,
                    usingDitherMethod: ditherMethod,
                    withDitherMethodSettings: ditherMethodSettings,
                    andPaletteSettings: paletteSettings,
                    outputURL: outputURL
                )
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
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
            let size = videoDescription.size
        else {
            throw VideoDescription.VideoDescriptionError.assetContainsNoTrackForVideo
        }
        
        let width = Int(size.width)
        let height = Int(size.height)
        
        let videoAssembler = try VideoAssembler(outputURL: outputURL, width: width, height: height, framerate: Int(frameRate))
        
        let invertedColorBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4 * width * height)
        
        let context = CIContext()
        do {
            try videoDescription.getFrames(frameRateCap: frameRate) { pixelBuffer in
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let scaleFilter = CIFilter.lanczosScaleTransform()
                scaleFilter.inputImage = ciImage
                if let renderSize = videoDescription.renderSize {
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
                    invertedColorBuffer: invertedColorBuffer
                )
                videoAssembler.addFrame(pixelBuffer: pixelBuffer)
            }
        } catch {
            invertedColorBuffer.deallocate()
            videoAssembler.cancelVideoGeneration()
            throw error
        }
        
        invertedColorBuffer.deallocate()
        await videoAssembler.generateVideo()
    }
    
    private func ciImageToCVPixelBuffer(image: CIImage, context: CIContext) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let width = Int(image.extent.width)
        let height = Int(image.extent.height)
        let attrs = [
              kCVPixelBufferCGImageCompatibilityKey: false,
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
