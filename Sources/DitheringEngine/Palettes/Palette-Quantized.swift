//
//  Palette-Quantized.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Palettes {
    public func quantizedColorLut(withBits bits: Int) -> BytePalette {
        let (entries, count) = equallySpacedColors(withBits: bits)
        
        return .from(lut: ByteLUT(buffer: entries, count: count, isColor: true))
    }
}
