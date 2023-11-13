//
//  Palette-CGA.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Palette {
    public enum CGAMode: String, CaseIterable, Codable {
        /// Black, green, red, brown
        case palette0Low
        
        /// Black, light green, light red, yellow
        case palette0High
        
        /// Black, cyan, magenta, light gray
        case palette1Low
        
        /// Black, light cyan, light magenta, white
        case palette1High
        
        /// Black, cyan, red, light gray
        case mode5Low
        
        /// Black, light cyan, light red, white
        case mode5High
        
        /// All 16 colors
        case textMode
    }
}

extension Palette.CGAMode {
    func palette(fromPalettes palettes: Palettes) -> BytePalette {
        switch self {
        case .palette0Low:
            return palettes.cgaColorMode4Palette0LowLut()
        case .palette0High:
            return palettes.cgaColorMode4Palette0HighLut()
        case .palette1Low:
            return palettes.cgaColorMode4Palette1LowLut()
        case .palette1High:
            return palettes.cgaColorMode4Palette1HighLut()
        case .textMode:
            return palettes.cgaColorLut()
        case .mode5Low:
            return palettes.cgaColorMode5LowLut()
        case .mode5High:
            return palettes.cgaColorMode5HighLut()
        }
    }
}

extension Palette.CGAMode: Nameable {
    public var title: String {
        switch self {
        case .palette0Low:
            return "Mode 4 | Pallete 0 | Low"
        case .palette0High:
            return "Mode 4 | Pallete 0 | High"
        case .palette1Low:
            return "Mode 4 | Pallete 1 | Low"
        case .palette1High:
            return "Mode 4 | Pallete 1 | High"
        case .mode5Low:
            return "Mode 5 | Low"
        case .mode5High:
            return "Mode 5 | High"
        case .textMode:
            return "Text mode"
        }
    }
}

extension Palette.CGAMode: Identifiable {
    public var id: RawValue { self.rawValue }
}

// MARK: - Palette definitions

extension Palettes {
    private func cgaColors() -> [SIMD3<UInt8>] {
        [
            .from32Bits(0x00_00_00),    //  0, Black
            .from32Bits(0x00_00_AA),    //  1, Blue
            .from32Bits(0xAA_AA_00),    //  2, Green
            .from32Bits(0x00_AA_AA),    //  3, Cyan
            .from32Bits(0xAA_00_00),    //  4, Red
            .from32Bits(0xAA_00_AA),    //  5, Magenta
            .from32Bits(0xAA_55_00),    //  6, Brown
            .from32Bits(0xAA_AA_AA),    //  7, Light gray
            
            .from32Bits(0x55_55_55),    //  8, Dark gray
            .from32Bits(0x55_55_FF),    //  9, Light blue
            .from32Bits(0x55_FF_55),    // 10, Light green
            .from32Bits(0x55_FF_FF),    // 11, Light cyan
            .from32Bits(0xFF_55_55),    // 12, Light red
            .from32Bits(0xFF_55_FF),    // 13, Light magenta
            .from32Bits(0xFF_FF_55),    // 14, Yellow
            .from32Bits(0xFF_FF_FF),    // 15, White
        ]
    }
    
    public func cgaColorLut() -> BytePalette {
        let entries = cgaColors()
        return .from(lutCollection: ByteLUTCollection(entries: entries))
    }
    
    public func cgaColorMode4Palette1HighLut() -> BytePalette {
        let entries = cgaColors()
        return .from(lutCollection: ByteLUTCollection(entries: [
            entries[ 0],    // Black
            entries[11],    // Light cyan
            entries[13],    // Light magenta
            entries[15],    // White
        ]))
    }
    
    public func cgaColorMode4Palette1LowLut() -> BytePalette {
        let entries = cgaColors()
        return .from(lutCollection: ByteLUTCollection(entries: [
            entries[ 0],    // Black
            entries[ 3],    // Cyan
            entries[ 5],    // Magenta
            entries[ 7],    // Light gray
        ]))
    }
    
    public func cgaColorMode4Palette0HighLut() -> BytePalette {
        let entries = cgaColors()
        return .from(lutCollection: ByteLUTCollection(entries: [
            entries[ 0],    // Black
            entries[10],    // Light green
            entries[12],    // Light red
            entries[14],    // Yellow
        ]))
    }
    
    public func cgaColorMode4Palette0LowLut() -> BytePalette {
        let entries = cgaColors()
        return .from(lutCollection: ByteLUTCollection(entries: [
            entries[ 0],    // Black
            entries[ 2],    // Green
            entries[ 4],    // Red
            entries[ 6],    // Brown
        ]))
    }
    
    public func cgaColorMode5LowLut() -> BytePalette {
        let entries = cgaColors()
        return .from(lutCollection: ByteLUTCollection(entries: [
            entries[ 0],    // Black
            entries[ 3],    // Cyan
            entries[ 4],    // Red
            entries[ 7],    // Light gray
        ]))
    }
    
    public func cgaColorMode5HighLut() -> BytePalette {
        let entries = cgaColors()
        return .from(lutCollection: ByteLUTCollection(entries: [
            entries[ 0],    // Black
            entries[11],    // Light cyan
            entries[12],    // Light red
            entries[15],    // White
        ]))
    }
}
