import CoreGraphics
import simd

public typealias ByteLUT = LUT<UInt8>
public typealias ByteLUTCollection = LUTCollection<UInt8>
public typealias BytePalette = LUTPalette<UInt8>

public class DitheringEngine {
    
    private var imageDescription: ImageDescription?
    private var floatingImageDescription: FloatingImageDescription?
    private var resultImageDescription: ImageDescription?
    
    public let palettes = Palettes()
    
    public init() {}
    
    public func set(image: CGImage) throws {
        if image.bitsPerComponent != SetImage.bitsPerCompinent {
            throw SetImage.Error.invalidBitsPerComponent(image.bitsPerComponent)
        }
        
        let components = image.bitsPerPixel / image.bitsPerComponent
        
        if !SetImage.allowedNumberOfComponents.contains(where: { $0 == components }) {
            throw SetImage.Error.invalidNumberOfComponents(components)
        }
        
        let newImageDescription = ImageDescription(width: image.width, height: image.height, components: components)
        if !newImageDescription.setBufferFrom(image: image) {
            throw SetImage.Error.couldNotSetBufferFromCGImage
        }
        
        self.imageDescription?.release()
        self.imageDescription = newImageDescription
        
        self.floatingImageDescription?.release()
        self.floatingImageDescription = newImageDescription.toFloatingImageDescription()
        
        self.resultImageDescription?.release()
        let newResultImageDescription = ImageDescription(width: image.width, height: image.height, components: 4)
        newResultImageDescription.buffer.update(repeating: 255, count: newResultImageDescription.count)
        self.resultImageDescription = newResultImageDescription
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
    
    public func dither(usingMethod method: DitherMethod, andPalette palette: Palette, withDitherMethodSettings ditherSettings: PaletteSettingsConfiguration, withPaletteSettings paletteSettings: PaletteSettingsConfiguration) throws -> CGImage {
        
        let lut = palette.lut(fromPalettes: palettes, settings: paletteSettings)
        method.run(withEngine: self, lut: lut, settings: ditherSettings)
        return try generateResultImage()
    }
    
    private func dither_None(palette: BytePalette) {
        guard
            let imageDescription,
            let resultImageDescription
        else {
            return
        }
        
        for i in 0..<imageDescription.size {
            let colorIn = imageDescription.getColorAt(index: i)
            resultImageDescription.setColorAt(index: i, color: colorIn)
        }
    }
    
    private func dither_CleanThreshold(palette: BytePalette) {
        guard
            let imageDescription,
            let resultImageDescription
        else {
            return
        }
        
        for i in 0..<imageDescription.size {
            let colorIn = imageDescription.getColorAt(index: i)
            
            let color = palette.pickColor(basedOn: colorIn)
            resultImageDescription.setColorAt(index: i, color: color)
        }
    }
    
    private func dither_FloydSteinberg(palette: BytePalette, matrix: [Int], direction: FloydSteinbergDitheringDirection) {
        guard
            let floatingImageDescription,
            let resultImageDescription
        else {
            return
        }
        
        let imageDescription = floatingImageDescription.makeCopy()
        
        let max_f = Float(UInt8.max)
        let max = SIMD3(x: max_f, y: max_f, z: max_f)
        
        let isYDirection = direction.isYDirection
        let width = imageDescription.width
        let height = imageDescription.height
        let offsets = direction.offsetsWith(matrix: matrix, andWidth: imageDescription.width)
        
        for y in 0..<(isYDirection ? width : height) {
            for x in 0..<(isYDirection ? height : width) {
                let i = direction.index(forX: x, y: y, width: width, andHeight: height)
                
                let colorIn = imageDescription.getColorAt(index: i)
                let color = palette.pickColor(basedOn: colorIn)
                let color_f = SIMD3<Float>(color)
                resultImageDescription.setColorAt(index: i, color: color)
                
                let error = colorIn - color_f
                
                if i != 0 && i % floatingImageDescription.width == 0 {
                    continue
                }

                for (offset, weight) in offsets {
                    let index = i + offset
                    let colorIn = imageDescription.getColorAt(index: index)
                    let newColor = colorIn + (SIMD3(repeating: weight) * error)
                    let clampedNewColor = clamp(newColor, min: .zero, max: max)
                    imageDescription.setColorAt(index: index, color: clampedNewColor)
                }
            }
        }
        
        imageDescription.release()
    }
    
    private func dither_Bayer(palette: BytePalette) {
        guard
            let imageDescription = floatingImageDescription,
            let resultImageDescription
        else {
            return
        }
        
        let thresholdMap: ThresholdMap<Float> = generateThresholdMap(n: 4)
//        let normalizationOffset: Float = 0.5//Float(thresholdMap.count / 2)
        let count_f: Float = 1//Float(thresholdMap.count)
        
//        let uniqueColors: Float = Float(palette.uniqueColors)
//        let N = log2(uniqueColors) / 3
//        let r: Float = 255 / N
        
//        let max_f = Float(UInt8.max)
//        let max = SIMD3(x: max_f, y: max_f, z: max_f)
        
        for y in 0..<imageDescription.height {
            for x in 0..<imageDescription.width {
                let i = y * imageDescription.width + x
                
                let colorIn = imageDescription.getColorAt(index: i)
                
                let threshold = (thresholdMap.thresholdAt(x: x % thresholdMap.num, y: y % thresholdMap.num) / count_f) //- normalizationOffset
                
                let newColor = 0.5 * (colorIn + SIMD3(repeating:  threshold))
                let clampedNewColor = floor(newColor)//clamp(newColor, min: .zero, max: max)
                let color = palette.pickColor(basedOn: clampedNewColor)
                
                resultImageDescription.setColorAt(index: i, color: color)
            }
        }
        
        thresholdMap.release()
    }
    
    public enum DitherMethod: String, CaseIterable, SettingsEnum, Identifiable {
        case none,
             threshold,
             floydSteinberg,
             bayer
        
        fileprivate func run(withEngine engine: DitheringEngine, lut: BytePalette, settings: PaletteSettingsConfiguration) {
            switch self {
            case .none:
                engine.dither_None(palette: lut)
            case .threshold:
                engine.dither_CleanThreshold(palette: lut)
            case .floydSteinberg:
                let settings = (settings as? FloydSteinbergSettingsConfiguration) ?? .init()
                let matrix = settings.matrix.value
                let direction = settings.direction.value
                engine.dither_FloydSteinberg(palette: lut, matrix: matrix, direction: direction)
            case .bayer:
                engine.dither_Bayer(palette: lut)
            }
        }
        
        public var title: String {
            switch self {
            case .none: return "None"
            case .threshold: return "Threshold"
            case .floydSteinberg: return "Floyd-Steinberg"
            case .bayer: return "Bayer"
            }
        }
        
        public func settings() -> PaletteSettingsConfiguration {
            switch self {
            case .none:
                return EmptyPaletteSettingsConfiguration()
            case .threshold:
                return EmptyPaletteSettingsConfiguration()
            case .floydSteinberg:
                return FloydSteinbergSettingsConfiguration()
            case .bayer:
                return EmptyPaletteSettingsConfiguration()
            }
        }
        
        public var id: RawValue { self.rawValue }
        
        public static var setting = DitherMethodSettingsConfiguration()
    }
    
}
