//
//  LUTPalette.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 02/12/2022.
//

import Foundation

public struct LUTPalette<Color: ImageColor> {
    
    let type: PaletteType
    
    private func lightnessOf<T: ImageColor>(color: SIMD3<T>) -> Float {
        let color = color.toFloatSIMD3()
        let max: Float = 3 * 255
        return color.sum() / max
    }
    
    private func lightnessOfComponentsIn<T: ImageColor>(color: SIMD3<T>) -> SIMD3<Float> {
        let color = color.toFloatSIMD3()
        let max: Float = 255
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
    
    private func pickColorFrom<T: ImageColor>(lutCollection: LUTCollection<Color>, basedOn color: SIMD3<T>, cache: ClosestColorCache<T, Color>?) -> SIMD3<Color> {
        if let cache, let colorMatch = cache.getPaletteColor(for: color) {
            return colorMatch
        }
        
        let colorMatch = lutCollection.closestColor(to: color)
        
        cache?.register(paletteColor: colorMatch, asAMatchTo: color)
        
        return colorMatch
    }
    
    public func pickColor<T: ImageColor>(basedOn color: SIMD3<T>, cache: ClosestColorCache<T, Color>? = nil) -> SIMD3<Color> {
        switch type {
        case .lut(let lut):
            return pickColorFrom(lut: lut, basedOn: color)
        case .lutCollection(let lutCollection):
            return pickColorFrom(lutCollection: lutCollection, basedOn: color, cache: cache)
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
    
    var numberOfEntries: Int {
        switch type {
        case .lut(let lut):
            return lut.count
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
}

extension LUTPalette {
    public static func from(lut: LUT<Color>) -> LUTPalette<Color> {
        LUTPalette(type: .lut(lut))
    }
    
    public static func from(lutCollection: LUTCollection<Color>) -> LUTPalette<Color> {
        LUTPalette(type: .lutCollection(lutCollection))
    }
}

extension LUTPalette {
    public enum PaletteType {
        case lut(LUT<Color>)
        case lutCollection(LUTCollection<Color>)
    }
}

public typealias ByteByteColorCache = ClosestColorCache<UInt8, UInt8>
public typealias FloatByteColorCache = ClosestColorCache<Float, UInt8>
public class ClosestColorCache<InputColor: ImageColor, PaletteColor: ImageColor> {
    
    private let size = 256
    private let sideSize = 256 * 256
    
    private let colorMap: UnsafeMutablePointer<Optional<SIMD3<PaletteColor>>>
    
    /// Specifies if the colorMap is a reference. In which case, should not be deallocated
    private let isReference: Bool
    
    public init() {
        let count = 256 * 256 * 256
        let pointer = UnsafeMutablePointer<Optional<SIMD3<PaletteColor>>>.allocate(capacity: count)
        pointer.update(repeating: nil, count: count)
        
        self.colorMap = pointer
        self.isReference = false
    }
    
    private init(colorMap: UnsafeMutablePointer<Optional<SIMD3<PaletteColor>>>, isReference: Bool) {
        self.colorMap = colorMap
        self.isReference = isReference
    }
    
    public static func populateWitColors(fromLUT collection: LUTCollection<PaletteColor>) -> ClosestColorCache<InputColor, PaletteColor> {
        let size = 256
        let sideSize = size * size
        let count = size * sideSize
        
        let colorMap = UnsafeMutablePointer<Optional<SIMD3<PaletteColor>>>.allocate(capacity: count)
        
        for r in 0..<size {
            for g in 0..<size {
                for b in 0..<size {
                    let index = sideSize * r + size * g + b
                    let paletteColor = collection.closestColor(to: SIMD3<UInt8>(x: UInt8(r), y: UInt8(g), z: UInt8(b)))
                    colorMap[index] = paletteColor
                }
            }
        }
        
        return ClosestColorCache(colorMap: colorMap, isReference: false)
    }
    
    public func register(paletteColor: SIMD3<PaletteColor>, asAMatchTo color: SIMD3<InputColor>) {
        let index = index(forColor: color)
        colorMap[index] = paletteColor
    }
    
    public func getPaletteColor(for color: SIMD3<InputColor>) -> SIMD3<PaletteColor>? {
        let index = index(forColor: color)
        return colorMap[index]
    }
    
    private func index(forColor color: SIMD3<InputColor>) -> Int {
        return sideSize * color.x.toInt() + size * color.y.toInt() + color.z.toInt()
    }
    
    public func toFloatingWithoutCopy() -> ClosestColorCache<Float, PaletteColor> where InputColor == UInt8 {
        ClosestColorCache<Float, PaletteColor>(colorMap: self.colorMap, isReference: true)
    }
    
    deinit {
        if !isReference {
            colorMap.deallocate()
        }
    }
    
}
