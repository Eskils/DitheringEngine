import CoreVideo.CVPixelBuffer
import CoreGraphics
import simd

public typealias ByteLUT = LUT<UInt8>
public typealias ByteLUTCollection = LUTCollection<UInt8>
public typealias BytePalette = LUTPalette<UInt8>

public class DitheringEngine {
    
    private var imageDescription: ImageDescription?
    private var floatingImageDescription: FloatingImageDescription?
    private var resultImageDescription: ImageDescription?
    
    let metalOrderedDithering = MetalOrderedDithering()
    
    public let palettes = Palettes()
    
    /// Whether to copy the alpha channel from the original image to the dithered image. Default is `true`
    public var preserveTransparency: Bool = true {
        didSet {
            if !preserveTransparency {
                // The alpha channel of the resultImage needs to be reset
                // when this changes to false
                invalidateResultImageDescription = true
            }
        }
    }
    
    private let seed = Int(arc4random())
    
    private var invalidateResultImageDescription = false
    
    public init() {}
    
    public func set(image: CGImage) throws {
        let width = image.width
        let height = image.height
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        guard let image = convertColorspaceOf(
            image: image,
            toColorSpace: CGColorSpaceCreateDeviceRGB(),
            withBitmapInfo: bitmapInfo.rawValue
        ) else {
            throw SetImage.Error.couldNotConvertColorspace
        }
        
        if image.bitsPerComponent != SetImage.bitsPerCompinent {
            throw SetImage.Error.invalidBitsPerComponent(image.bitsPerComponent)
        }
        
        let components = image.bitsPerPixel / image.bitsPerComponent
        
        if !SetImage.allowedNumberOfComponents.contains(where: { $0 == components }) {
            throw SetImage.Error.invalidNumberOfComponents(components)
        }
        
        
        var hasKeptOldImageDescription = false
                
        let newImageDescription: ImageDescription
        if let imageDescription, imageDescription.width == width, imageDescription.height == height, imageDescription.components == imageDescription.components {
            hasKeptOldImageDescription = true
            newImageDescription = imageDescription
        } else {
            newImageDescription = ImageDescription(width: width, height: height, components: components)
        }
        
        if !newImageDescription.setBufferFrom(image: image) {
            throw SetImage.Error.couldNotSetBufferFromCGImage
        }
        
        if !hasKeptOldImageDescription {
            self.imageDescription?.release()
            self.imageDescription = newImageDescription
        }
        
        if let floatingImageDescription, hasKeptOldImageDescription {
            newImageDescription.toFloatingImageDescription(writingTo: floatingImageDescription)
        } else {
            self.floatingImageDescription?.release()
            self.floatingImageDescription = newImageDescription.toFloatingImageDescription()
        }
        
        if !hasKeptOldImageDescription {
            self.resultImageDescription?.release()
            let newResultImageDescription = ImageDescription(width: image.width, height: image.height, components: 4)
            newResultImageDescription.buffer.update(repeating: 255, count: newResultImageDescription.count)
            self.resultImageDescription = newResultImageDescription
        } else {
            if !preserveTransparency, let resultImageDescription {
                resultImageDescription.buffer.update(repeating: 255, count: resultImageDescription.count)
            }
        }
    }
    
    public func set(pixelBuffer: CVPixelBuffer) throws {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let components = bytesPerRow / width
        var hasKeptOldImageDescription = false
        
        let newImageDescription: ImageDescription
        if let imageDescription, imageDescription.width == width, imageDescription.height == height, imageDescription.components == imageDescription.components, imageDescription.pixelOrdering == .bgra {
            hasKeptOldImageDescription = true
            newImageDescription = imageDescription
        } else {
            newImageDescription = ImageDescription(width: width, height: height, components: components, pixelOrdering: .bgra)
        }
        if !newImageDescription.setBufferFrom(pixelBuffer: pixelBuffer) {
            throw SetImage.Error.couldNotSetBufferFromPixelBuffer
        }
        
        if !hasKeptOldImageDescription {
            self.imageDescription?.release()
            self.imageDescription = newImageDescription
        }
        
        if let floatingImageDescription, hasKeptOldImageDescription {
            newImageDescription.toFloatingImageDescription(writingTo: floatingImageDescription)
        } else {
            self.floatingImageDescription?.release()
            self.floatingImageDescription = newImageDescription.toFloatingImageDescription()
        }
        
        if !hasKeptOldImageDescription {
            self.resultImageDescription?.release()
            let newResultImageDescription = ImageDescription(width: width, height: height, components: 4)
            newResultImageDescription.buffer.update(repeating: 255, count: newResultImageDescription.count)
            self.resultImageDescription = newResultImageDescription
        }
    }
    
    public func generateOriginalImage() throws -> CGImage {
        guard let imageDescription else {
            throw Error.noImageDescription
        }
        
        return try imageDescription.makeCGImage()
    }
    
    public func generateResultImage() throws -> CGImage {
        guard let resultImageDescription, let imageDescription else {
            throw Error.noImageDescription
        }
        
        if preserveTransparency && imageDescription.components == 4 {
            resultImageDescription.update(component: .alpha, from: imageDescription)
        } else if invalidateResultImageDescription {
            if !preserveTransparency && imageDescription.components == 4 {
                resultImageDescription.set(component: .alpha, to: 255)
            }
            invalidateResultImageDescription = false
        }
        
        return try resultImageDescription.makeCGImage()
    }
    
    func generateResultPixelBuffer() throws -> CVPixelBuffer {
        guard let resultImageDescription, let imageDescription else {
            throw Error.noImageDescription
        }
        
        if preserveTransparency && imageDescription.components == 4 {
            resultImageDescription.update(component: .alpha, from: imageDescription)
        } else if invalidateResultImageDescription {
            if !preserveTransparency && imageDescription.components == 4 {
                resultImageDescription.set(component: .alpha, to: 255)
            }
            invalidateResultImageDescription = false
        }
        
        return try resultImageDescription.makePixelBuffer()
    }
    
    func generateOriginalImagePixelBuffer() throws -> CVPixelBuffer {
        guard let imageDescription else {
            throw Error.noImageDescription
        }
        
        return try imageDescription.makePixelBuffer()
    }
    
}

extension DitheringEngine {
    
    struct SetImage {
        private init() {}
        
        static let bitsPerCompinent = UInt8.bitWidth
        static let allowedNumberOfComponents = ImageDescription.Component.allCases.map { $0.rawValue }
        
        enum Error: Swift.Error {
            case invalidBitsPerComponent(Int)
            case invalidNumberOfComponents(Int)
            case couldNotSetBufferFromCGImage
            case couldNotSetBufferFromPixelBuffer
            case couldNotConvertColorspace
        }
    }
    
    enum Error: Swift.Error {
        case noImageDescription
    }
    
}

extension DitheringEngine {
    
    private func performDithering(usingMethod method: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherSettings: SettingsConfiguration, withPaletteSettings paletteSettings: SettingsConfiguration, imageDescription: ImageDescription, floatingImageDescription: FloatingImageDescription, resultImageDescription: ImageDescription, byteColorCache: ByteByteColorCache?, floatingColorCache: FloatByteColorCache?) {
        let lut = palette.lut(fromPalettes: palettes, settings: paletteSettings, preferNoGray: method.preferNoGray)
        let ditherMethods = DitherMethods(imageDescription: imageDescription, resultImageDescription: resultImageDescription, floatingImageDescription: floatingImageDescription, seed: seed, orderedDitheringMetal: metalOrderedDithering, colorMatchCache: byteColorCache, floatingColorMatchCache: floatingColorCache)
        method.run(withDitherMethods: ditherMethods, lut: lut, settings: ditherSettings)
    }
    
    public func dither(usingMethod method: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherSettings: SettingsConfiguration, withPaletteSettings paletteSettings: SettingsConfiguration) throws -> CGImage {
        guard
            let imageDescription,
            let floatingImageDescription,
            let resultImageDescription
        else {
            return try generateResultImage()
        }
        
        performDithering(
            usingMethod: method,
            andPalette: palette,
            withDitherMethodSettings: ditherSettings,
            withPaletteSettings: paletteSettings,
            imageDescription: imageDescription,
            floatingImageDescription: floatingImageDescription,
            resultImageDescription: resultImageDescription,
            byteColorCache: nil,
            floatingColorCache: nil
        )
        
        return try generateResultImage()
    }
    
    func ditherIntoPixelBuffer(usingMethod method: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherSettings: SettingsConfiguration, withPaletteSettings paletteSettings: SettingsConfiguration, byteColorCache: ByteByteColorCache?, floatingColorCache: FloatByteColorCache?) throws -> CVPixelBuffer {
        guard
            let imageDescription,
            let floatingImageDescription,
            let resultImageDescription
        else {
            return try generateResultPixelBuffer()
        }
        
        resultImageDescription.buffer.update(repeating: 255, count: resultImageDescription.count)
        
        performDithering(
            usingMethod: method,
            andPalette: palette,
            withDitherMethodSettings: ditherSettings,
            withPaletteSettings: paletteSettings,
            imageDescription: imageDescription,
            floatingImageDescription: floatingImageDescription,
            resultImageDescription: resultImageDescription,
            byteColorCache: byteColorCache,
            floatingColorCache: floatingColorCache
        )
        
        return try generateResultPixelBuffer()
    }
    
}
