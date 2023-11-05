//
//  Dither-ErrorDiffusion.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import simd

extension DitherMethods {
    func errorDiffusion(palette: BytePalette, matrix: [Int], customization: ErrorDiffusionDitheringCustomization) {
        let imageDescription = floatingImageDescription.makeCopy()
        
        let max_f = Float(UInt8.max)
        let max = SIMD3(x: max_f, y: max_f, z: max_f)
        
        let isYDirection = customization.isYDirection
        let width = imageDescription.width
        let height = imageDescription.height
        let offsets = customization.offsetsWith(matrix: matrix, andWidth: imageDescription.width)
        
        for y in 0..<(isYDirection ? width : height) {
            for x in 0..<(isYDirection ? height : width) {
                let i = customization.index(forX: x, y: y, width: width, andHeight: height)
                
                let colorIn = imageDescription.getColorAt(index: i)
                let color = palette.pickColor(basedOn: colorIn)
                let color_f = SIMD3<Float>(color)
                resultImageDescription.setColorAt(index: i, color: color)
                
                let error = colorIn - color_f
                
                if i != 0 && i % floatingImageDescription.width == 0 {
                    continue
                }

                for (offset, weight) in offsets {
                    let index = i + offset
                    let colorIn = imageDescription.getColorAt(index: index)
                    let newColor = colorIn + (SIMD3(repeating: weight) * error)
                    let clampedNewColor = clamp(newColor, min: .zero, max: max)
                    imageDescription.setColorAt(index: index, color: clampedNewColor)
                }
            }
        }
        
        imageDescription.release()
    }
}
