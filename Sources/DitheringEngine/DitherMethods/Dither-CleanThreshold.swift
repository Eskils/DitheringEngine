//
//  Dither-CleanThreshold.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func cleanThreshold(palette: BytePalette) {
        for i in 0..<imageDescription.size {
            let colorIn = imageDescription.getColorAt(index: i)
            
            let color = palette.pickColor(basedOn: colorIn)
            resultImageDescription.setColorAt(index: i, color: color)
        }
    }
}
