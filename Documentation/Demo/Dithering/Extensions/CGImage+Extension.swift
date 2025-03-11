//
//  CGImage+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import UIKit

extension CGImage {
    func toUIImage() -> UIImage {
        UIImage(cgImage: self)
    }
    
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}
