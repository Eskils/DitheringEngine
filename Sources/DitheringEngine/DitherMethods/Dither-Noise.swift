//
//  Dither-Noise.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func noise(palette: BytePalette, noisePattern: ImageDescription) {
        let thresholdMap = FloatingThresholdMap.generateImageThresholdMap(image: noisePattern)
        let normalizationOffset: Float = 128
        let thresholdMultiplier: Float = 1
        
        ordered(
            palette: palette,
            thresholdMap: thresholdMap,
            normalizationOffset: normalizationOffset,
            thresholdMultiplier: thresholdMultiplier
        )
        
        thresholdMap.release()
    }
}
