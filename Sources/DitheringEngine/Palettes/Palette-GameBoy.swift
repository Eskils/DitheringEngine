//
//  Palette-GameBoy.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Palettes {
    public func gameBoy() -> BytePalette {
        .from(lutCollection: ByteLUTCollection(entries: [
            .from32Bits(0x9BBC0F),
            .from32Bits(0x8BAC0F),
            .from32Bits(0x306230),
            .from32Bits(0x0F380F),
        ]))
    }
}
