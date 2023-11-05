//
//  Dither-Atkinson.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func atkinson(palette: BytePalette) {
        let matrix = [Int]()
        let customization = AtkinsonDitheringDescription()
        
        errorDiffusion(
            palette: palette,
            matrix: matrix,
            customization: customization
        )
    }
}

//MARK: - Dithering Description

struct AtkinsonDitheringDescription: ErrorDiffusionDitheringCustomization {
    
    private func offsetsFor(width w: Int) -> [Int] {
        [           0 * w + 1, 0 * w + 2,
         1 * w - 1, 1 * w + 0, 1 * w + 1,
                    2 * w + 0,
        ]
    }
    
    func offsetsWith(matrix: [Int], andWidth w: Int) -> [(offset: Int, weight: Float)] {
        let matrix: [Float] = [1, 1, 1, 1, 1, 1]
        
        let weights = matrix.map { $0 / 8 }
        let offsets = offsetsFor(width: w)
        
        return (0..<min(offsets.count, matrix.count)).map { i in
            (offset: offsets[i], weight: weights[i])
        }
    }
    
    func index(forX x: Int, y: Int, width: Int, andHeight height: Int) -> Int {
        return y * width + x
    }
    
    let isYDirection: Bool = false
}
