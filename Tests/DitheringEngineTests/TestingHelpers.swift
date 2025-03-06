//
//  TestingHelpers.swift
//  DitheringEngine
//
//  Created by Eskil Gjerde Sviggum on 06/03/2025.
//

import Foundation
import CoreGraphics
import ImageIO

func convertColorspace(ofImage image: CGImage, toColorSpace colorSpace: CGColorSpace) -> CGImage? {
    let rect = CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height))
    let context = CGContext(data: nil, width: Int(rect.width), height: Int(rect.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(image, in: rect)
    let image = context.makeImage()
    return image
}

func image(atPath path: String) throws -> CGImage {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
        throw TestsError.cannotMakeImageSource
    }
    guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        throw TestsError.cannotMakeCGImageFromData
    }
    
    return cgImage
}

func write(image: CGImage, toPath path: String) throws {
    let data = NSMutableData()
    guard
        let imageDestination = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil)
    else {
        throw TestsError.cannotMakeImageDestination
    }
    
    CGImageDestinationAddImage(imageDestination, image, nil)
    
    CGImageDestinationFinalize(imageDestination)
    
    data.write(toFile: path, atomically: true)
}

func imageIsEqual(inputImagePath: String, expectedImagePath: String, producedOutputsPath: String, afterPerformingImageOperations block: (CGImage) throws -> CGImage) throws -> Bool {
    let inputImage = try image(atPath: inputImagePath)
    let transformedImage = try block(inputImage)
    
    try write(image: transformedImage, toPath: producedOutputsPath)
    let producedOutputImage = try image(atPath: producedOutputsPath)
    
    let expectedImage = try image(atPath: expectedImagePath)
    
    let colorspace = CGColorSpaceCreateDeviceRGB()
    let convertedTransformed = convertColorspace(ofImage: producedOutputImage, toColorSpace: colorspace)
    let convertedExpected = convertColorspace(ofImage: expectedImage, toColorSpace: colorspace)
    
    let isEqual = convertedTransformed?.dataProvider?.data == convertedExpected?.dataProvider?.data
    
    return isEqual
}
