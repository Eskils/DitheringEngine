//
//  Dither-Ordered.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func orderedCPU(palette: BytePalette, thresholdMap: FloatingThresholdMap, normalizationOffset: Float, thresholdMultiplier: Float) {
        for y in 0..<floatingImageDescription.height {
            for x in 0..<floatingImageDescription.width {
                let i = y * floatingImageDescription.width + x
                
                let colorIn = floatingImageDescription.getColorAt(index: i)
                
                let threshold = thresholdMap.thresholdAt(x: x % thresholdMap.num, y: y % thresholdMap.num) - normalizationOffset
                
                let newColor = (colorIn + thresholdMultiplier * SIMD3(repeating:  threshold))
                let clampedNewColor = newColor.rounded(.toNearestOrAwayFromZero)
                let color = palette.pickColor(basedOn: clampedNewColor, cache: floatingColorMatchCache)
                
                resultImageDescription.setColorAt(index: i, color: color)
            }
        }
    }
    
    func ordered(palette: BytePalette, thresholdMap: FloatingThresholdMap, normalizationOffset: Float, thresholdMultiplier: Float, performOnCPU: Bool = false) {
        if performOnCPU {
            orderedCPU(palette: palette, thresholdMap: thresholdMap, normalizationOffset: normalizationOffset, thresholdMultiplier: thresholdMultiplier)
            return
        }
        
        do {
            orderedDitheringMetal.imageDescription = imageDescription
            orderedDitheringMetal.resultImageDescription = resultImageDescription
            try orderedDitheringMetal.orderedDitheringMetal(palette: palette, thresholdMap: thresholdMap, normalizationOffset: normalizationOffset, thresholdMultiplier: thresholdMultiplier)
        } catch {
            #if DEBUG
            print("Cannot run ordered dithering on GPU with error: \(error)")
            #endif
            orderedCPU(palette: palette, thresholdMap: thresholdMap, normalizationOffset: normalizationOffset, thresholdMultiplier: thresholdMultiplier)
        }
    }
}
