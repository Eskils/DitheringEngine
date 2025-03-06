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
    
    private let getterBuffer = UnsafeMutablePointer<Color>.allocate(capacity: 4)
    
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
        
        
        let index = components * i
        
        return SIMD3(buffer[index + 0],
                     buffer[index + 1],
                     buffer[index + 2])
    }
    
    func getColorWithAlphaAt(index i: Int) -> SIMD4<Color> {
        let hasAlpha = components == 4
        
        if i < 0 || components * i + 3 > count {
            return .zero
        }
        
        let index = components * i
        
        return SIMD4(buffer[index + 0],
                     buffer[index + 1],
                     buffer[index + 2],
                     hasAlpha ? buffer[index + 3] : .one)
    }
    
    func getColor(component: ColorComponent, at i: Int) -> Color {
        let componentOffset = component.offset
        
        if i < 0 || components * i + componentOffset > count {
            return .zero
        }
        
        let index = components * i
        return buffer[index + componentOffset]
    }
    
    func setColorAt(index i: Int, color: SIMD3<Color>) {
        if components * i + 2 > count {
            return
        }
        
        let index = components * i
        
        buffer[index + 0] = color.x
        buffer[index + 1] = color.y
        buffer[index + 2] = color.z
    }
    
    func setColorWithAlphaAt(index i: Int, color: SIMD4<Color>) {
        if components * i + 3 > count {
            return
        }
        
        let index = components * i
        
        buffer[index + 0] = color.x
        buffer[index + 1] = color.y
        buffer[index + 2] = color.z
        buffer[index + 3] = color.w
    }
    
    func setColor(component: ColorComponent, at i: Int, color: Color) {
        let componentOffset = component.offset
        
        if i < 0 || components * i + componentOffset > count {
            return
        }
        
        let index = components * i
        buffer[index + componentOffset] = color
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
            let data = dataProvider.data,
            let pointer = CFDataGetBytePtr(data)
        else {
            return false
        }
        
        let expectedBytesPerRow = self.bytesPerRow
        
        for row in 0..<image.height {
            self.buffer.advanced(by: expectedBytesPerRow * row).update(from: pointer.advanced(by: image.bytesPerRow * row), count: expectedBytesPerRow)
        }
        
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
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        for row in 0..<height {
            for col in 0..<width {
                let inputOffset = row * bytesPerRow
                let outputOffset = self.bytesPerRow * row
                
                let inputPointer = baseAddress.advanced(by: inputOffset)
                let outputPointer = buffer.advanced(by: outputOffset)
                
                let b = inputPointer[4 * col + 0]
                let g = inputPointer[4 * col + 1]
                let r = inputPointer[4 * col + 2]
                let a = inputPointer[4 * col + 3]
                
                outputPointer[4 * col + 0] = r
                outputPointer[4 * col + 1] = g
                outputPointer[4 * col + 2] = b
                outputPointer[4 * col + 3] = a
            }
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
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: MakeImage.bitsPerComponent,
                bytesPerRow: 0,
                space: component.colorSpace,
                bitmapInfo: component.bitmapInfo
            )
        else {
            throw MakeImage.Error.failedToCreateCGContext
        }
        
        guard let data = context.data?.assumingMemoryBound(to: UInt8.self) else {
            throw MakeImage.Error.failedToCreateDataFromCGContext
        }
        
        for row in 0..<height {
            data.advanced(by: context.bytesPerRow * row).update(from: buffer.advanced(by: bytesPerRow * row), count: bytesPerRow)
        }
        
        guard let image = context.makeImage() else {
            throw MakeImage.Error.failedToCreateImage
        }
        
        return image
    }
    
    /// Generates a CVPixelBuffer from the image buffer data.
    func makePixelBuffer() throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )
        
        guard
            let pixelBuffer,
            status == kCVReturnSuccess
        else {
            throw MakeImage.Error.failedToCreateCVPixelBuffer(status: status)
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self) else {
            throw MakeImage.Error.failedToGetCVPixelBufferBaseAddress
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        for row in 0..<height {
            for col in 0..<width {
                let bufferOffset = self.bytesPerRow * row
                let cvPixelBufferOffset = bytesPerRow * row
                
                let bufferPointer = buffer.advanced(by: bufferOffset)
                let cvPixelBufferPointer = baseAddress.advanced(by: cvPixelBufferOffset)
                
                let r = bufferPointer[4 * col + 0]
                let g = bufferPointer[4 * col + 1]
                let b = bufferPointer[4 * col + 2]
                let a = bufferPointer[4 * col + 3]
                
                cvPixelBufferPointer[4 * col + 0] = b
                cvPixelBufferPointer[4 * col + 1] = g
                cvPixelBufferPointer[4 * col + 2] = r
                cvPixelBufferPointer[4 * col + 3] = a
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        return pixelBuffer
    }
    
    struct MakeImage {
        private init() {}
        
        static let bitsPerComponent = UInt8.bitWidth
        
        enum Error: Swift.Error {
            case invalidNumberOfComponents
            case failedToCreateCGContext
            case failedToCreateDataFromCGContext
            case failedToCreateImage
            case failedToCreateCVPixelBuffer(status: CVReturn)
            case failedToGetCVPixelBufferBaseAddress
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

extension GenericImageDescription {
    
    enum ColorComponent {
        /// The red channel of the image
        case red
        /// The green channel of the image
        case green
        /// The blue channel of the image
        case blue
        /// The alpha channel of the image
        case alpha
    }
    
}

extension GenericImageDescription.ColorComponent {
    var offset: Int {
        switch self {
        case .red:
            0
        case .green:
            1
        case .blue:
            2
        case .alpha:
            3
        }
    }
}
