//
//  File.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import CoreGraphics

/// Creates a new image by converting colorspace of the image to the one specified.
func convertColorspaceOf(
    image: CGImage,
    toColorSpace colorSpace: CGColorSpace,
    withBitmapInfo bitmapInfo: UInt32
) -> CGImage? {
    let rect = CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height))
    
    let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )
    
    context?.draw(image, in: rect)
    
    return context?.makeImage()
}
