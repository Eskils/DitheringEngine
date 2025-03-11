//
//  renderImageInPlace.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import UIKit

func renderImageInPlace(_ image: UIImage, renderSize: CGSize, imageFrame: CGRect, isRunning: Bool) -> UIImage {
    var image = image
    
    if isRunning {
        image = image.blur(radius: 5) ?? image
    }
    
    let renderer = UIGraphicsImageRenderer(size: renderSize)
    
    let frame = CGRect(x: imageFrame.minX - imageFrame.width / 2, y: imageFrame.minY - imageFrame.height / 2, width: imageFrame.width, height: imageFrame.height)
    let scale = imageFrame.width / renderSize.width
    
    let result = renderer.image { context in
        context.cgContext.interpolationQuality = interpolationQuality(forScale: scale)
        image.draw(in: frame)
    }
    
    return result
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
