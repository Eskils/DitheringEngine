//
//  CGImage+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import CoreGraphics
import CoreImage
#if canImport(UIKit)
import UIKit
#endif

extension CGImage {
    #if canImport(UIKit)
    func toUIImage() -> UIImage {
        UIImage(cgImage: self)
    }
    #endif
    
    var size: CGSize {
        CGSize(width: width, height: height)
    }
    
    func blur(radius: CGFloat) -> CGImage? {
        let context = CIContext()
        let input = CIImage(cgImage: self)
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: "inputRadius")
        guard let result = filter.value(forKey: kCIOutputImageKey) as? CIImage,
              let resCG = context.createCGImage(result, from: input.extent)
        else { return nil }
        return resCG
    }
}
