//
//  Helpers.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 29/11/2022.
//

import Foundation
import CoreGraphics
import simd
import UIKit
import Combine

/// Creates a new image by converting colorspace of the image to the one specified.
func convertColorspaceOf(image: CGImage, toColorSpace colorSpace: CGColorSpace, withBitmapInfo bitmapInfo: UInt32) -> CGImage? {
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

/// Clamps the value between `min` and `max`.
func clamp<T: Numeric>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable {
    return min(maxValue, max(value, minValue))
}

/// Clamps the value between `0` and `1`.
func clampDecimal<T: BinaryFloatingPoint>(_ value: T) -> T {
    return min(1, max(value, 0))
}

typealias RGB = SIMD3<UInt8>

extension SIMD3 {
    
    var r: Scalar {
        get { self.x }
        set(value) { self.x = value }
    }
    
    var g: Scalar {
        get { self.y }
        set(value) { self.y = value }
    }
    
    var b: Scalar {
        get { self.z }
        set(value) { self.z = value }
    }
    
}

func documentUrlForFile(withName name: String, storing data: Data) throws -> URL {
    let fs = FileManager.default
    let documentDirectoryUrl = try fs.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileUrl = documentDirectoryUrl.appendingPathComponent(name)
    
    try data.write(to: fileUrl)
    
    return fileUrl
}

extension SIMD3 where Scalar == UInt8 {
    
    static func from32Bits(_ uint32: UInt32) -> Self {
        var uint32 = (uint32.byteSwapped >> 8)
        let simd = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
        
        withUnsafeBytes(of: &uint32) { bufferPointer in
            let pointer = bufferPointer.baseAddress!
                .assumingMemoryBound(to: UInt8.self)
            simd.update(from: pointer, count: 3)
        }
        
        let simd3 = UnsafeRawPointer(simd).assumingMemoryBound(to: SIMD3<Scalar>.self).pointee
        return simd3
    }
    
}

extension CGImage {
    func toUIImage() -> UIImage {
        UIImage(cgImage: self)
    }
    
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

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

func renderImageInPlace(_ image: UIImage, renderSize: CGSize, imageFrame: CGRect, isRunning: Bool) -> UIImage {
    var image = image
    
    if isRunning {
        image = image.blur(radius: 5) ?? image
    }
    
    let renderer = UIGraphicsImageRenderer(size: renderSize)
    
    let frame = CGRect(x: imageFrame.minX - imageFrame.width / 2, y: imageFrame.minY - imageFrame.height / 2, width: imageFrame.width, height: imageFrame.height)
    
    let result = renderer.image { _ in
        image.draw(in: frame)
    }
    
    return result
}

extension Array where Element: Numeric {
    
    func sum() -> Element {
        self.reduce(.zero) { partialResult, value in
            partialResult + value
        }
    }
    
}

extension Numeric {
    
    func add1IfZero() -> Self {
        if self == .zero {
            return 1
        }
        
        return self
    }
    
}
