//
//  Palette-BlackAndWhite.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Palettes {
    public func bwLut() -> BytePalette {
        .from(lutCollection:
                LUT(entries: [0, 255], isColor: false)
                    .toLUTCollection()
        )
    }
}
