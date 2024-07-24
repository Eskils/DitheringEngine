//
//  Palette-Apple2.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Palette {
    public enum Apple2Mode: String, CaseIterable, Codable {
        case loRes
        case hiRes
    }
}

extension Palette.Apple2Mode {
    func palette(fromPalettes palettes: Palettes, preferNoGray: Bool) -> BytePalette {
        switch self {
        case .loRes:
            if (preferNoGray) {
                return palettes.apple2LoResWithoutGray()
            } else {
                return palettes.apple2LoRes()
            }
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
            .from32Bits(0x000000),  // 0
            .from32Bits(0x99035F),  // 1
            .from32Bits(0x4204E1),  // 2
            .from32Bits(0xCA13FE),  // 3
            
            .from32Bits(0x007310),  // 4
            .from32Bits(0x7F7F7F),  // 5
            .from32Bits(0xBEBEBE),  // 6
            .from32Bits(0xAAA2FF),  // 7
            
            .from32Bits(0x4F5101),  // 8
            .from32Bits(0xF05C00),  // 9
            .from32Bits(0x2497FF),  // 10
            .from32Bits(0xFF85E1),  // 11
            
            .from32Bits(0x12CA07),  // 12
            .from32Bits(0xCED413),  // 13
            .from32Bits(0x51F595),  // 14
            .from32Bits(0xFFFFFF),  // 15
        ]))
    }
    
    public func apple2LoResWithoutGray() -> BytePalette {
        let entries = apple2LoRes().colors()
        return .from(lutCollection: ByteLUTCollection(entries: Array(entries[0..<5]) + Array(entries[7..<16])))
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
