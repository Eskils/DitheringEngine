//
//  LUT.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 02/12/2022.
//

import Foundation
import simd

public class LUT<Color: ImageColor> {
    
    public let count: Int
    private let count_f: Float
    public let buffer: UnsafeMutablePointer<Color>
    public let isColor: Bool
    
    public convenience init<T: Collection>(entries: T, isColor: Bool) where T.Element == Color, T.Index == Int {
        let buffer = UnsafeMutablePointer<Color>.allocate(capacity: entries.count)
        for i in 0..<entries.count {
            buffer[i] = entries[i]
        }
        
        self.init(buffer: buffer, count: entries.count, isColor: isColor)
    }
    
    public init(buffer: UnsafeMutablePointer<Color>, count: Int, isColor: Bool) {
        self.count = count
        self.count_f = Float(count - 1)
        self.buffer = buffer
        self.isColor = isColor
    }
    
    public func getEntryAt(index i: Int) -> Color {
        if i >= count {
            fatalError("Index out of bounds")
        }
        
        return buffer[i]
    }
    
    /// Returns the entry corresponding to the given threshold. Preferable for grayscale.
    public func getEntryWith(threshold: Float) -> Color {
        let index = Int(clampDecimal(threshold) * count_f)
        return buffer[index]
    }
    
    /// Returns a color corresponding to the given thresholds. Preferable for color.
    public func getEntryWithThresholds(r: Float, g: Float, b: Float) -> SIMD3<Color> {
        let r = self.getEntryWith(threshold: r)
        let g = self.getEntryWith(threshold: g)
        let b = self.getEntryWith(threshold: b)
        
        return SIMD3(x: r, y: g, z: b)
    }
    
    deinit {
        buffer.deallocate()
    }
    
}

public struct LUTCollection<Color: ImageColor> {
    private let lut: UnsafePointer<SIMD3<Color>>
    public let count: Int
    
    public init(entries: [SIMD3<Color>]) {
        let buffer = UnsafeMutablePointer<SIMD3<Color>>.allocate(capacity: entries.count)
        
        entries.withUnsafeBytes { bufferPointer in
            let pointer = bufferPointer.baseAddress!.assumingMemoryBound(to: SIMD3<Color>.self)
            buffer.update(from: pointer, count: entries.count)
        }

        self.lut = UnsafePointer(buffer)
        
        self.count = entries.count
    }
    
    public func closestColor<T: ImageColor>(to color: SIMD3<T>) -> SIMD3<Color> {
        let color = color.toFloatSIMD3()
        var result: SIMD3<Color> = .zero
        var distanceRecord = Float.infinity
        
        for i in 0..<count {
            let lutColor = lut[i]
            let lutColor_f = lutColor.toFloatSIMD3()
            // Find distance between the error and the base color. We want to minimize this
            let distance = simd_distance_squared(lutColor_f, color)
//            let distance = simd_distance_squared(lutColor_f, color)
            
            if distance < distanceRecord {
                distanceRecord = distance
                result = lutColor
            }
        }
        
        return result
    }
}
