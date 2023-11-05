//
//  Dither-None.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func none(palette: BytePalette) {
        for i in 0..<imageDescription.size {
            let colorIn = imageDescription.getColorAt(index: i)
            resultImageDescription.setColorAt(index: i, color: colorIn)
        }
    }
}
