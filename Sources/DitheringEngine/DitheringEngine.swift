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
    
    private let seed = Int(arc4random())
    
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
        }
    }
    
    public func generateOriginalImage() throws -> CGImage {
        guard let imageDescription else {
            throw Error.noImageDescription
        }
        
        return try imageDescription.makeCGImage()
    }
    
    public func generateResultImage() throws -> CGImage {
        guard let resultImageDescription else {
            throw Error.noImageDescription
        }
        
        return try resultImageDescription.makeCGImage()
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
            case couldNotConvertColorspace
        }
    }
    
    enum Error: Swift.Error {
        case noImageDescription
    }
    
}

extension DitheringEngine {
    
    public func dither(usingMethod method: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherSettings: SettingsConfiguration, withPaletteSettings paletteSettings: SettingsConfiguration) throws -> CGImage {
        guard
            let imageDescription,
            let floatingImageDescription,
            let resultImageDescription
        else {
            return try generateResultImage()
        }
        
        let lut = palette.lut(fromPalettes: palettes, settings: paletteSettings)
        let ditherMethods = DitherMethods(imageDescription: imageDescription, resultImageDescription: resultImageDescription, floatingImageDescription: floatingImageDescription, seed: seed, orderedDitheringMetal: metalOrderedDithering)
        method.run(withDitherMethods: ditherMethods, lut: lut, settings: ditherSettings)
        
        return try generateResultImage()
    }
    
}
