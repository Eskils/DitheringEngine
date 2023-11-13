//
//  DitherMehtod.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

public enum DitherMethod: String, CaseIterable, Codable {
    case none
    case threshold
    case floydSteinberg
    case atkinson
    case jarvisJudiceNinke
    case bayer
    case whiteNoise
    case noise
}

extension DitherMethod {
    func run(withDitherMethods ditherMethods: DitherMethods, lut: BytePalette, settings: SettingsConfiguration) {
        switch self {
        case .none:
            ditherMethods.none(palette: lut)
        case .threshold:
            ditherMethods.cleanThreshold(palette: lut)
        case .floydSteinberg:
            let settings = (settings as? FloydSteinbergSettingsConfiguration) ?? .init()
            let matrix = settings.matrix.value
            let direction = settings.direction.value
            ditherMethods.floydSteinberg(palette: lut, matrix: matrix, direction: direction)
        case .atkinson:
            ditherMethods.atkinson(palette: lut)
        case .jarvisJudiceNinke:
            ditherMethods.jarvisJudiceNinke(palette: lut)
        case .bayer:
            let settings = (settings as? BayerSettingsConfiguration) ?? .init()
            let thresholdMapSize = settings.size
            let performOnCPU = settings.performOnCPU.value
            ditherMethods.bayer(palette: lut, thresholdMapSize: thresholdMapSize, performOnCPU: performOnCPU)
        case .whiteNoise:
            let settings = (settings as? WhiteNoiseSettingsConfiguration) ?? .init()
            let thresholdMapSize = settings.size
            let performOnCPU = settings.performOnCPU.value
            ditherMethods.whiteNoise(palette: lut, thresholdMapSize: thresholdMapSize, performOnCPU: performOnCPU)
        case .noise:
            let settings = (settings as? NoiseDitheringSettingsConfiguration) ?? .init()
            guard let noisePattern = settings.noisePattern.value else {
                ditherMethods.none(palette: lut)
                return
            }
            let noisePatternBuffered = ImageDescription(width: noisePattern.width, height: noisePattern.height, components: noisePattern.bytesPerRow / noisePattern.width)
            let performOnCPU = settings.performOnCPU.value
            if noisePatternBuffered.setBufferFrom(image: noisePattern) {
                ditherMethods.noise(palette: lut, noisePattern: noisePatternBuffered, performOnCPU: performOnCPU)
            } else {
                print("Could not load noise pattern.")
                ditherMethods.none(palette: lut)
            }
            noisePatternBuffered.release()
        }
    }
    
    public func settings() -> SettingsConfiguration {
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
            return WhiteNoiseSettingsConfiguration()
        case .noise:
            return NoiseDitheringSettingsConfiguration()
        }
    }
    
    public static var setting = DitherMethodSettingsConfiguration()
}

extension DitherMethod: Nameable {
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
}

extension DitherMethod: Identifiable {
    public var id: RawValue { self.rawValue }
}
