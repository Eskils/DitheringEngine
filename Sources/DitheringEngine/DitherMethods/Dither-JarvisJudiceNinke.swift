//
//  Dither-JarvisJudiceNinke.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func jarvisJudiceNinke(palette: BytePalette) {
        let matrix = [Int]()
        let customization = JarvisJudiceNinkeDitheringDescription()
        
        errorDiffusion(
            palette: palette,
            matrix: matrix,
            customization: customization
        )
    }
}

// MARK: - Dithering Description

struct JarvisJudiceNinkeDitheringDescription: ErrorDiffusionDitheringCustomization {
    
    private func offsetsFor(width w: Int) -> [Int] {
        [                                 0 * w + 1, 0 * w + 2,
         1 * w - 2, 1 * w - 1, 1 * w + 0, 1 * w + 1, 1 * w + 2,
         2 * w - 2, 2 * w - 1, 2 * w + 0, 2 * w + 1, 2 * w + 2
        ]
    }
    
    func offsetsWith(matrix: [Int], andWidth w: Int) -> [(offset: Int, weight: Float)] {
        let matrix: [Float] = [
                        7, 5,
               3, 5, 7, 5, 3,
               1, 3, 5, 3, 1
        ]
        
        let weights = matrix.map { $0 / 48 }
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
