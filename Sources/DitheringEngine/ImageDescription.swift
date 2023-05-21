//
//  ImageDescription.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 29/11/2022.
//

import CoreGraphics
import simd

public protocol ImageColor: SIMDScalar, Decodable, Encodable, Hashable {
    static var zero: Self { get }
    
    func toFloat() -> Float
    func toUInt8() -> UInt8
}

extension UInt8: ImageColor {
    public func toFloat() -> Float { Float(self) }
    public func toUInt8() -> UInt8 { self }
}
extension Float: ImageColor {
    public func toFloat() -> Float { self }
    public func toUInt8() -> UInt8 { UInt8(self) }
}

extension SIMD3 where Scalar: ImageColor {
    
    static var zero: SIMD3<Scalar> { SIMD3(.zero, .zero, .zero) }
    
    func toFloatSIMD3() -> SIMD3<Float> {
        SIMD3<Float>(x: x.toFloat(), y: y.toFloat(), z: z.toFloat())
    }
    
    func toCbCr() -> SIMD2<Float> {
        let f = self.toFloatSIMD3()
        let cb = 128 - (0.168736 * f.x) - (0.331264 * f.y) + (0.5 * f.z)
        let cr = 128 + (0.5 * f.x) - (0.418688 * f.y) - (0.081312 * f.z)
        return SIMD2(x: cb, y: cr)
    }
    
    func toUInt8SIMD3() -> SIMD3<UInt8> {
        SIMD3<UInt8>(x: x.toUInt8(), y: y.toUInt8(), z: z.toUInt8())
    }
}

//FIXME: Test performance of class vs struct -> Class is safer
class GenericImageDescription<Color: ImageColor> {
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
    
    /// Initializes an empty image with the specified size and channels.
    init(width: Int, height: Int, components: Int) {
        self.width = width
        self.height = height
        self.components = components
        self.size = width * height
        self.count = components * width * height
        self.bytesPerRow = components * width
        self.buffer = UnsafeMutablePointer<Color>.allocate(capacity: count)
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

        return color
    }
    
    func setColorAt(index i: Int, color: SIMD3<Color>) {
        if components * i + 2 > count {
            return
        }
        
        var color = color
        withUnsafeBytes(of: &color) { bufferPointer in
            let pointer = bufferPointer.baseAddress!.assumingMemoryBound(to: Color.self)
            buffer.advanced(by: components * i).update(from: pointer, count: 3)
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
    
    /// Converts to FloatingImageDescription
    func toFloatingImageDescription() -> FloatingImageDescription {
        let imageDescription = FloatingImageDescription(width: width, height: height, components: components)
        
        for i in 0..<size {
            let color = getColorAt(index: i)
            let floatingColor = SIMD3<Float>(color)
            imageDescription.setColorAt(index: i, color: floatingColor)
        }
        
        return imageDescription
    }
    
    /// Generates a CGImage from the image buffer data.
    func makeCGImage() throws -> CGImage {
        guard let component = Component(rawValue: components) else {
            throw MakeCGImage.Error.invalidNumberOfComponents
        }
        
        guard
            let context = CGContext(
                data: buffer,
                width: width,
                height: height,
                bitsPerComponent: MakeCGImage.bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: component.colorSpace,
                bitmapInfo: component.bitmapInfo
            )
        else {
            throw MakeCGImage.Error.failedToCreateCGContext
        }
        
        guard let image = context.makeImage() else {
            throw MakeCGImage.Error.failedToCreateImage
        }
        
        return image
    }
    
    struct MakeCGImage {
        private init() {}
        
        static let bitsPerComponent = UInt8.bitWidth
        
        enum Error: Swift.Error {
            case invalidNumberOfComponents
            case failedToCreateCGContext
            case failedToCreateImage
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
