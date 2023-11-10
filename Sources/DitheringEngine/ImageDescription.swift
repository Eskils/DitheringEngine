//
//  ImageDescription.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 29/11/2022.
//

import CoreVideo.CVPixelBuffer
import CoreGraphics
import simd

enum PixelOrdering {
    case bgra
    case rgba
}

final class GenericImageDescription<Color: ImageColor> {
    /// The width of the image.
    let width: Int
    
    /// The width of the image.
    let height: Int
    
    /// The number of color channels in the image
    let components: Int
    
    /// components • width • height
    let count: Int
    
    /// width • height
    let size: Int
    
    /// components • width
    let bytesPerRow: Int
    
    /// Pointer to the image bytes
    let buffer: UnsafeMutablePointer<Color>
    
    private let getterBuffer = UnsafeMutablePointer<Color>.allocate(capacity: 3)
    
    private var isReleased: Bool = false
    
    let pixelOrdering: PixelOrdering
    
    /// Initializes an empty image with the specified size and channels.
    init(width: Int, height: Int, components: Int, pixelOrdering: PixelOrdering = .rgba) {
        self.width = width
        self.height = height
        self.components = components
        self.size = width * height
        self.count = components * width * height
        self.bytesPerRow = components * width
        self.buffer = UnsafeMutablePointer<Color>.allocate(capacity: count)
        self.pixelOrdering = pixelOrdering
    }
    
    /// Returns a new image description with the same image data copied over.
    func makeCopy() -> GenericImageDescription<Color> {
        let imageDescription = GenericImageDescription(width: width, height: height, components: components)
        imageDescription.buffer.update(from: self.buffer, count: count)
        return imageDescription
    }
    
    /// Releases the image buffer. This description must not be used after release.
    func release() {
        if isReleased {
            return
        }
        
        buffer.deallocate()
        getterBuffer.deallocate()
        isReleased = true
    }
    
    deinit {
        release()
    }
}

typealias ImageDescription = GenericImageDescription<UInt8>
typealias FloatingImageDescription = GenericImageDescription<Float>

extension GenericImageDescription {
    
    enum Component: Int, CaseIterable {
        case grayscale = 1
        case rgb = 3
        case rgba = 4
        
        var colorSpace: CGColorSpace {
            switch self {
            case .grayscale:
                return CGColorSpaceCreateDeviceGray()
            case .rgb:
                return CGColorSpaceCreateDeviceRGB()
            case .rgba:
                return CGColorSpaceCreateDeviceRGB()
            }
        }
        
        var bitmapInfo: UInt32 {
            switch self {
            case .grayscale:
                return CGImageAlphaInfo.none.rawValue
            case .rgb:
                return CGImageAlphaInfo.none.rawValue
            case .rgba:
                return CGImageAlphaInfo.premultipliedLast.rawValue
            }
        }
    }
    
    func getColorAt(index i: Int) -> SIMD3<Color> {
        if i < 0 || components * i + 2 > count {
            return .zero
        }
        
        
        getterBuffer.update(from: buffer.advanced(by: components * i), count: 3)
        let color = UnsafeRawPointer(getterBuffer)
            .assumingMemoryBound(to: SIMD3<Color>.self)
            .pointee
        
        let correctFormatColor = color//handlePixelOrderingTransform(forColor: color)

        return correctFormatColor
    }
    
    func setColorAt(index i: Int, color: SIMD3<Color>) {
        if components * i + 2 > count {
            return
        }
        
        var correctFormatColor = color//handlePixelOrderingTransform(forColor: color)
        withUnsafeBytes(of: &correctFormatColor) { bufferPointer in
            let pointer = bufferPointer.baseAddress!.assumingMemoryBound(to: Color.self)
            buffer.advanced(by: components * i).update(from: pointer, count: 3)
        }
        
    }
    
    private func handlePixelOrderingTransform(forColor color: SIMD3<Color>) -> SIMD3<Color> {
        switch pixelOrdering {
        case .rgba:
            return color
        case .bgra:
            return SIMD3<Color>(x: color.z, y: color.y, z: color.x)
        }
    }
    
}

extension GenericImageDescription where Color == UInt8 {
    
    /// Sets the image data of the image
    func setBufferFrom(image: CGImage) -> Bool {
        if isReleased {
            return false
        }
        
        guard
            let dataProvider = image.dataProvider,
            let data = dataProvider.data
        else {
            return false
        }
        
        CFDataGetBytes(data, CFRange(location: 0, length: count), buffer)
        
        return true
    }
    
    /// Sets the image data of the image
    func setBufferFrom(pixelBuffer: CVPixelBuffer) -> Bool {
        if isReleased {
            return false
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self) else {
            return false
        }
        
        for i in 0..<count {
            let b = baseAddress[4 * i + 0]
            let g = baseAddress[4 * i + 1]
            let r = baseAddress[4 * i + 2]
            let a = baseAddress[4 * i + 3]
            
            buffer[4 * i + 0] = r
            buffer[4 * i + 1] = g
            buffer[4 * i + 2] = b
            buffer[4 * i + 3] = a
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        return true
    }
    
    /// Converts to FloatingImageDescription
    func toFloatingImageDescription() -> FloatingImageDescription {
        let imageDescription = FloatingImageDescription(width: width, height: height, components: components, pixelOrdering: pixelOrdering)
        
        for i in 0..<size {
            let color = getColorAt(index: i)
            let floatingColor = SIMD3<Float>(color)
            imageDescription.setColorAt(index: i, color: floatingColor)
        }
        
        return imageDescription
    }
    
    /// Converts to FloatingImageDescription and writes to buffer
    func toFloatingImageDescription(writingTo imageDescription: FloatingImageDescription) {
        for i in 0..<size {
            let color = getColorAt(index: i)
            let floatingColor = SIMD3<Float>(color)
            imageDescription.setColorAt(index: i, color: floatingColor)
        }

    }
    
    /// Generates a CGImage from the image buffer data.
    func makeCGImage() throws -> CGImage {
        guard let component = Component(rawValue: components) else {
            throw MakeImage.Error.invalidNumberOfComponents
        }
        
        guard
            let context = CGContext(
                data: buffer,
                width: width,
                height: height,
                bitsPerComponent: MakeImage.bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: component.colorSpace,
                bitmapInfo: component.bitmapInfo
            )
        else {
            throw MakeImage.Error.failedToCreateCGContext
        }
        
        guard let image = context.makeImage() else {
            throw MakeImage.Error.failedToCreateImage
        }
        
        return image
    }
    
    /// Generates a CVPixelBuffer from the image buffer data.
    func makePixelBuffer(invertedColorBuffer: UnsafeMutablePointer<Color>) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        for i in 0..<count {
            let r = buffer[4 * i + 0]
            let g = buffer[4 * i + 1]
            let b = buffer[4 * i + 2]
            let a = buffer[4 * i + 3]
            
            invertedColorBuffer[4 * i + 0] = b
            invertedColorBuffer[4 * i + 1] = g
            invertedColorBuffer[4 * i + 2] = r
            invertedColorBuffer[4 * i + 3] = a
        }
        
        let status = CVPixelBufferCreateWithBytes(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            invertedColorBuffer,
            bytesPerRow,
            nil,
            nil,
            attrs,
            &pixelBuffer
        )
        
        guard let pixelBuffer, status == kCVReturnSuccess else {
            throw MakeImage.Error.failedToCreateCVPixelBuffer(status: status)
        }
        
        return pixelBuffer
    }
    
    struct MakeImage {
        private init() {}
        
        static let bitsPerComponent = UInt8.bitWidth
        
        enum Error: Swift.Error {
            case invalidNumberOfComponents
            case failedToCreateCGContext
            case failedToCreateImage
            case failedToCreateCVPixelBuffer(status: CVReturn)
        }
    }
    
}

extension GenericImageDescription where Color == Float {
    
    /// Converts to ImageDescription
    func toImageDescription() -> ImageDescription {
        let imageDescription = ImageDescription(width: width, height: height, components: components)
        
        for i in 0..<size {
            let floatingColor = getColorAt(index: i)
            let color = SIMD3<UInt8>(floatingColor)
            imageDescription.setColorAt(index: i, color: color)
        }
        
        return imageDescription
    }
    
    /// Generates a CGImage from the image buffer data.
    func makeCGImage() throws -> CGImage {
        let imageDescription = self.toImageDescription()
        do {
            let image = try imageDescription.makeCGImage()
            imageDescription.release()
            return image
        } catch {
            imageDescription.release()
            throw error
        }
    }
    
}
