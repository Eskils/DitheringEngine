//
//  Palette-Apple2.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Palette {
    public enum Apple2Mode: String, CaseIterable {
        case loRes
        case hiRes
    }
}

extension Palette.Apple2Mode {
    func palette(fromPalettes palettes: Palettes) -> BytePalette {
        switch self {
        case .loRes:
            return palettes.apple2LoRes()
        case .hiRes:
            return palettes.apple2HiRes()
        }
    }
}

extension Palette.Apple2Mode: Nameable {
    public var title: String {
        switch self {
        case .loRes:
            return "Lo-Res"
        case .hiRes:
            return "Hi-Res"
        }
    }
}

extension Palette.Apple2Mode: Identifiable {
    public var id: RawValue { self.rawValue }
}

// MARK: - Palette definitions

extension Palettes {
    public func apple2LoRes() -> BytePalette {
        .from(lutCollection: ByteLUTCollection(entries: [
            .from32Bits(0x000000),
            .from32Bits(0x99035F),
            .from32Bits(0x4204E1),
            .from32Bits(0xCA13FE),
            
            .from32Bits(0x007310),
            .from32Bits(0x7F7F7F),
            .from32Bits(0x2497FF),
            .from32Bits(0xAAA2FF),
            
            .from32Bits(0x4F5101),
            .from32Bits(0xF05C00),
            .from32Bits(0xBEBEBE),
            .from32Bits(0xFF85E1),
            
            .from32Bits(0x12CA07),
            .from32Bits(0xCED413),
            .from32Bits(0x51F595),
            .from32Bits(0xFFFFFF),
        ]))
    }
    
    public func apple2HiRes() -> BytePalette {
        .from(lutCollection: ByteLUTCollection(entries: [
            .from32Bits(0x000000),
            .from32Bits(0xFFFFFF),
            .from32Bits(0x20C000),
            .from32Bits(0xA000FF),
            .from32Bits(0x0080FF),
            .from32Bits(0xF05000),
        ]))
    }
}
