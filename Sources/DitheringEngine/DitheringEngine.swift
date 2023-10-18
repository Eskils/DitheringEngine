import Foundation
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
    
    private let seed = Int(arc4random())
    
    public init() {}
    
    public func set(image: CGImage) throws {
        
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
    
    private func dither_FloydSteinberg(palette: BytePalette, matrix: [Int], customization: FloydSteinbergDitheringCustomization) {
        guard
            let floatingImageDescription,
            let resultImageDescription
        else {
            return
        }
        
        let imageDescription = floatingImageDescription.makeCopy()
        
        let max_f = Float(UInt8.max)
        let max = SIMD3(x: max_f, y: max_f, z: max_f)
        
        let isYDirection = customization.isYDirection
        let width = imageDescription.width
        let height = imageDescription.height
        let offsets = customization.offsetsWith(matrix: matrix, andWidth: imageDescription.width)
        
        for y in 0..<(isYDirection ? width : height) {
            for x in 0..<(isYDirection ? height : width) {
                let i = customization.index(forX: x, y: y, width: width, andHeight: height)
                
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
    
    private func dither_FloydSteinberg(palette: BytePalette, matrix: [Int], direction: FloydSteinbergDitheringDirection) {
        dither_FloydSteinberg(
            palette: palette,
            matrix: matrix,
            customization: direction
        )
    }
    
    private func dither_Atkinson(palette: BytePalette) {
        let matrix = [Int]()
        let customization = FloydSteinbergAtkinsonDitheringDescription()
        
        dither_FloydSteinberg(
            palette: palette,
            matrix: matrix,
            customization: customization
        )
    }
    
    private func dither_JarvisJudiceNinke(palette: BytePalette) {
        let matrix = [Int]()
        let customization = FloydSteinbergJarvisJudiceNinkeDitheringDescription()
        
        dither_FloydSteinberg(
            palette: palette,
            matrix: matrix,
            customization: customization
        )
    }
    
    private func dither_Ordered(palette: BytePalette, thresholdMap: FloatingThresholdMap, normalizationOffset: Float, thresholdMultiplier: Float) {
        guard
            let imageDescription = floatingImageDescription,
            let resultImageDescription
        else {
            return
        }
        
        for y in 0..<imageDescription.height {
            for x in 0..<imageDescription.width {
                let i = y * imageDescription.width + x
                
                let colorIn = imageDescription.getColorAt(index: i)
                
                let threshold = thresholdMap.thresholdAt(x: x % thresholdMap.num, y: y % thresholdMap.num) - normalizationOffset
                
                let newColor = (colorIn + thresholdMultiplier * SIMD3(repeating:  threshold))
                let clampedNewColor = newColor.rounded(.toNearestOrAwayFromZero)
                let color = palette.pickColor(basedOn: clampedNewColor)
                
                resultImageDescription.setColorAt(index: i, color: color)
            }
        }
    }
    
    private func dither_Bayer(palette: BytePalette, thresholdMapSize: Int) {
        let thresholdMapSize = clamp(thresholdMapSize, min: 2, max: 256)
        let thresholdMap = generateBayerThresholdMap(n: thresholdMapSize)
        let normalizationOffset = Float(thresholdMap.count) / 2
        let thresholdMultiplier = 8 / Float(thresholdMapSize)
        
        dither_Ordered(
            palette: palette,
            thresholdMap: thresholdMap,
            normalizationOffset: normalizationOffset,
            thresholdMultiplier: thresholdMultiplier
        )
        
        thresholdMap.release()
    }
    
    private func dither_WhiteNoise(palette: BytePalette, thresholdMapSize: Int) {
        let thresholdMapSize = clamp(thresholdMapSize, min: 2, max: 256)
        let thresholdMap = generateWhiteNoiseThresholdMap(n: thresholdMapSize, max: 255, seed: seed)
        let normalizationOffset: Float = 128
        let thresholdMultiplier: Float = 1.0
        
        dither_Ordered(
            palette: palette,
            thresholdMap: thresholdMap,
            normalizationOffset: normalizationOffset,
            thresholdMultiplier: thresholdMultiplier
        )
        
        thresholdMap.release()
    }
    
    private func dither_Noise(palette: BytePalette, noisePattern: ImageDescription) {
        let thresholdMap = generateImageThresholdMap(image: noisePattern)
        let normalizationOffset: Float = 128
        let thresholdMultiplier: Float = 1
        
        dither_Ordered(
            palette: palette,
            thresholdMap: thresholdMap,
            normalizationOffset: normalizationOffset,
            thresholdMultiplier: thresholdMultiplier
        )
        
        thresholdMap.release()
    }
    
    public enum DitherMethod: String, CaseIterable, SettingsEnum, Identifiable {
        case none,
             threshold,
             floydSteinberg,
             atkinson,
             jarvisJudiceNinke,
             bayer,
             whiteNoise,
             noise
        
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
            case .atkinson:
                engine.dither_Atkinson(palette: lut)
            case .jarvisJudiceNinke:
                engine.dither_JarvisJudiceNinke(palette: lut)
            case .bayer:
                let settings = (settings as? BayerSettingsConfiguration) ?? .init()
                let thresholdMapSize = settings.size
                engine.dither_Bayer(palette: lut, thresholdMapSize: thresholdMapSize)
            case .whiteNoise:
                let settings = (settings as? BayerSettingsConfiguration) ?? .init()
                let thresholdMapSize = settings.size
                engine.dither_WhiteNoise(palette: lut, thresholdMapSize: thresholdMapSize)
            case .noise:
                let settings = (settings as? NoiseDitheringSettingsConfiguration) ?? .init()
                guard let noisePattern = settings.noisePattern.value else {
                    engine.dither_None(palette: lut)
                    return
                }
                let noisePatternBuffered = ImageDescription(width: noisePattern.width, height: noisePattern.height, components: noisePattern.bytesPerRow / noisePattern.width)
                if noisePatternBuffered.setBufferFrom(image: noisePattern) {
                    engine.dither_Noise(palette: lut, noisePattern: noisePatternBuffered)
                } else {
                    print("Could not load noise pattern.")
                    engine.dither_None(palette: lut)
                }
                noisePatternBuffered.release()
            }
        }
        
        public var title: String {
            switch self {
            case .none:                 return "None"
            case .threshold:            return "Threshold"
            case .floydSteinberg:       return "Floyd-Steinberg"
            case .atkinson:             return "Atkinson"
            case .jarvisJudiceNinke:    return "Jarvis-Judice-Ninke"
            case .bayer:                return "Bayer"
            case .whiteNoise:           return "White Noise"
            case .noise:                return "Noise"
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
            case .atkinson:
                return EmptyPaletteSettingsConfiguration()
            case .jarvisJudiceNinke:
                return EmptyPaletteSettingsConfiguration()
            case .bayer:
                return BayerSettingsConfiguration()
            case .whiteNoise:
                return BayerSettingsConfiguration()
            case .noise:
                return NoiseDitheringSettingsConfiguration()
            }
        }
        
        public var id: RawValue { self.rawValue }
        
        public static var setting = DitherMethodSettingsConfiguration()
    }
    
}
