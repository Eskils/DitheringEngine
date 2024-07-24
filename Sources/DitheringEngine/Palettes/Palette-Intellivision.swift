//
//  Palette-Intellivision.swift
//
//
//  Created by Eskil Gjerde Sviggum on 16/01/2024.
//

import Foundation

extension Palettes {
    public func intellivision() -> BytePalette {
        .from(lutCollection: ByteLUTCollection(entries: [
            .from32Bits(0x000000),
            .from32Bits(0xFFFCFF),
            .from32Bits(0x002DFF),
            
            .from32Bits(0xFF3E00),
            .from32Bits(0xC9D464),
            .from32Bits(0x00780F),
            .from32Bits(0x00A720),
            
            .from32Bits(0xFAEA27),
            .from32Bits(0x5ACBFF),
            .from32Bits(0xFFA600),
            .from32Bits(0x3C5800),
        
            .from32Bits(0xFF3276),
            .from32Bits(0xBD95FF),
            .from32Bits(0x6CCD30),
            .from32Bits(0xC81A7D),
        ]))
    }
}
