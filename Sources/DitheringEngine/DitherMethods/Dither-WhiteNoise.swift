//
//  Dither-WhiteNoise.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func whiteNoise(palette: BytePalette, thresholdMapSize: Int, intensity: Float, performOnCPU: Bool) {
        let thresholdMapSize = clamp(thresholdMapSize, min: 2, max: 256)
        let thresholdMap = FloatingThresholdMap.generateWhiteNoiseThresholdMap(n: thresholdMapSize, max: 255, seed: seed)
        let normalizationOffset: Float = 128
        let thresholdMultiplier: Float = intensity
        
        ordered(
            palette: palette,
            thresholdMap: thresholdMap,
            normalizationOffset: normalizationOffset,
            thresholdMultiplier: thresholdMultiplier,
            performOnCPU: performOnCPU
        )
        
        thresholdMap.release()
    }
}
