//
//  CGImageDataTransformer.swift
//  DitheringEngine
//
//  Created by Eskil Gjerde Sviggum on 10/03/2025.
//

import Foundation
import CoreGraphics
import ImageIO

struct CGImageDataTransformer {
    /// Convert image data to a Core Graphics image
    static func image(from data: Data) throws(CGImageDataTransformerError) -> CGImage {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw .cannotMakeImageSource
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw .cannotMakeImageFromData
        }
        
        return cgImage
    }

    /// Convert a Core Graphics image to PNG data
    static func data(from image: CGImage) throws(CGImageDataTransformerError) -> Data {
        let data = NSMutableData()
        guard
            let imageDestination = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil)
        else {
            throw .cannotMakeImageDestination
        }
        
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        
        return data as Data
    }
}

enum CGImageDataTransformerError: Error {
    case cannotMakeImageSource
    case cannotMakeImageFromData
    case cannotMakeImageDestination
}
