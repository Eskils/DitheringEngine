//
//  Dither-Bayer.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func bayer(palette: BytePalette, thresholdMapSize: Int, intensity: Float?, performOnCPU: Bool) {
        let thresholdMapSize = clamp(thresholdMapSize, min: 2, max: 256)
        let thresholdMap = FloatingThresholdMap.generateBayerThresholdMap(n: thresholdMapSize)
        let normalizationOffset = Float(thresholdMap.count) / 2
        let intensityFromSize = 8 / Float(thresholdMapSize)
        let thresholdMultiplier = intensity ?? intensityFromSize
        
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
