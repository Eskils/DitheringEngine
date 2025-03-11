//
//  UIImage+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import UIKit

extension UIImage {
    func blur(radius: CGFloat) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let context = CIContext()
        let input = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: "inputRadius")
        guard let result = filter.value(forKey: kCIOutputImageKey) as? CIImage,
              let resCG = context.createCGImage(result, from: input.extent)
        else { return nil }
        return UIImage(cgImage: resCG)
    }
}
