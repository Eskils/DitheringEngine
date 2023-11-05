//
//  Palette.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

public enum Palette: String, CaseIterable {
    case bw
    case grayscale
    case quantizedColor
    case cga
    case apple2
    case gameBoy
    case custom
}

extension Palette {
    func lut(fromPalettes palettes: Palettes, settings: SettingsConfiguration) -> BytePalette {
        switch self {
        case .bw:
            return palettes.bwLut()
        case .grayscale:
            let settings = (settings as? QuantizedColorSettingsConfiguration) ?? .init(bits: 1)
            let bits = Int(settings.bits.value)
            return palettes.grayscaleLut(withBits: bits)
        case .quantizedColor:
            let settings = (settings as? QuantizedColorSettingsConfiguration) ?? .init(bits: 1)
            let bits = Int(settings.bits.value)
            return palettes.quantizedColorLut(withBits: bits)
        case .cga:
            let settings = (settings as? CGASettingsConfiguration) ?? .init()
            return settings.mode.value.palette(fromPalettes: palettes)
        case .apple2:
            let settings = (settings as? Apple2SettingsConfiguration) ?? .init()
            return settings.mode.value.palette(fromPalettes: palettes)
        case .gameBoy:
            return palettes.gameBoy()
        case .custom:
            let settings = (settings as? CustomPaletteSettingsConfiguration) ?? .init()
            return settings.palette.value
        }
    }
    
    public func settings() -> SettingsConfiguration {
        switch self {
        case .bw:
            return EmptyPaletteSettingsConfiguration()
        case .grayscale:
            return QuantizedColorSettingsConfiguration(bits: 1)
        case .quantizedColor:
            return QuantizedColorSettingsConfiguration(bits: 1)
        case .cga:
            return CGASettingsConfiguration()
        case .apple2:
            return Apple2SettingsConfiguration()
        case .gameBoy:
            return EmptyPaletteSettingsConfiguration()
        case .custom:
            return CustomPaletteSettingsConfiguration()
        }
    }
    
    public func colors(settings: SettingsConfiguration) -> [SIMD3<UInt8>] {
        let palette = lut(fromPalettes: Palettes(), settings: settings)
        return palette.colors()
    }
}

extension Palette: Identifiable {
    public var id: RawValue { self.rawValue }
}

extension Palette: Nameable {
    public var title: String {
        switch self {
        case .bw:
            return "Black & white"
        case .grayscale:
            return "Grayscale"
        case .quantizedColor:
            return "Quantized color"
        case .cga:
            return "CGA"
        case .apple2:
            return "Apple ]["
        case .gameBoy:
            return "Game Boy"
        case .custom:
            return "Custom"
        }
    }
}
