//
//  renderImageInPlace.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import CoreGraphics
import CoreImage

func renderImageInPlace(_ image: CGImage?, renderSize: CGSize, imageFrame: CGRect, isRunning: Bool) -> CGImage? {
    var image = image
    
    if isRunning {
        image = image?.blur(radius: 5) ?? image
    }
    
    let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
    
    let width = Int(renderSize.width)
    let height = Int(renderSize.height)
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo.rawValue
    )
    assert(context != nil)
    
    let frame = CGRect(x: imageFrame.minX - imageFrame.width / 2, y: imageFrame.minY - imageFrame.height / 2, width: imageFrame.width, height: imageFrame.height)
    let scale = imageFrame.width / renderSize.width
    
    context?.interpolationQuality = interpolationQuality(forScale: scale)
    if let image {
        context?.draw(image, in: frame)
    }
    
    let resultImage = context?.makeImage()
    assert(resultImage != nil)
    
    return resultImage
}

private func interpolationQuality(forScale scale: Double) -> CGInterpolationQuality {
    if scale > 3 {
        return .none
    }
    
    if scale > 2 {
        return .low
    }
    
    if scale > 1 {
        return .medium
    }
    
    if scale <= 1 {
        return .high
    }
    
    return .default
}
