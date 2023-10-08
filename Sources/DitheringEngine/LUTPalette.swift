//
//  LUTPalette.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 02/12/2022.
//

import Foundation

public struct LUTPalette<Color: ImageColor> {
    
    private let type: PaletteType
    
    public static func from(lut: LUT<Color>) -> LUTPalette<Color> {
        LUTPalette(type: .lut(lut))
    }
    
    public static func from(lutCollection: LUTCollection<Color>) -> LUTPalette<Color> {
        LUTPalette(type: .lutCollection(lutCollection))
    }
    
    private func lightnessOf<T: ImageColor>(color: SIMD3<T>) -> Float {
        let color = color.toFloatSIMD3()
        let max = 3 * Float(UInt8.max)
        return color.sum() / max
    }
    
    private func lightnessOfComponentsIn<T: ImageColor>(color: SIMD3<T>) -> SIMD3<Float> {
        let color = color.toFloatSIMD3()
        let max = Float(UInt8.max)
        let maxVec = SIMD3(repeating: max)
        return color / maxVec
    }
    
    private func pickColorFrom<T: ImageColor>(lut: LUT<Color>, basedOn color: SIMD3<T>) -> SIMD3<Color> {
        if lut.isColor {
            let lightness = lightnessOfComponentsIn(color: color)
            let newColor = lut.getEntryWithThresholds(r: lightness.r, g: lightness.g, b: lightness.b)
            return newColor
        } else {
            let lightness = lightnessOf(color: color)
            let newColor = lut.getEntryWith(threshold: lightness)
            return SIMD3(repeating: newColor)
        }
    }
    
    private func pickColorFrom<T: ImageColor>(lutCollection: LUTCollection<Color>, basedOn color: SIMD3<T>) -> SIMD3<Color> {
        lutCollection.closestColor(to: color)
    }
    
    public func pickColor<T: ImageColor>(basedOn color: SIMD3<T>) -> SIMD3<Color> {
        switch type {
        case .lut(let lut):
            return pickColorFrom(lut: lut, basedOn: color)
        case .lutCollection(let lutCollection):
            return pickColorFrom(lutCollection: lutCollection, basedOn: color)
        }
    }
    
    public var uniqueColors: Int {
        switch type {
        case .lut(let lut):
            if lut.isColor {
                return 3 * lut.count
            } else {
                return lut.count
            }
        case .lutCollection(let lutCollection):
            return lutCollection.count
        }
    }
    
    public func colors() -> [SIMD3<UInt8>] {
        switch type {
        case .lut(let lut):
            let colors = (0..<lut.count).map {
                lut.getEntryAt(index: $0).toUInt8()
            }
            if lut.isColor {
                #if DEBUG
                let count = min(4, colors.count)
                #else
                let count = min(8, colors.count)
                #endif
                let stride = colors.count / count
                return (0..<count).flatMap { r in
                    (0..<count).flatMap { g in
                        (0..<count).map { b in
                            let red     = colors[r * stride]
                            let green   = colors[g * stride]
                            let blue    = colors[b * stride]
                            
                            return SIMD3(x: red, y: green, z: blue)
                        }
                    }
                }
            } else {
                return colors.map { color in
                    SIMD3(x: color, y: color, z: color)
                }
            }
        case .lutCollection(let collection):
            return collection.entries.map { $0.toUInt8SIMD3() }
        }
    }
    
    public enum PaletteType {
        case lut(LUT<Color>)
        case lutCollection(LUTCollection<Color>)
    }
}
