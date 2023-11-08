//
//  LUTCollection.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import simd

public struct LUTCollection<Color: ImageColor> {
    let lut: UnsafePointer<SIMD3<Color>>
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
    
    var entries: [SIMD3<Color>] {
        var entries = [SIMD3<Color>](repeating: .zero, count: count)
        entries.withUnsafeMutableBytes { mutableBuffer in
            let pointer = mutableBuffer.baseAddress!.assumingMemoryBound(to: SIMD3<Color>.self)
            pointer.update(from: lut, count: count)
        }
        return entries
    }
    
    public func closestColor<T: ImageColor>(to color: SIMD3<T>) -> SIMD3<Color> {
        let color = color.toFloatSIMD3()
        var result: SIMD3<Color> = .zero
        var distanceRecord = Float.infinity
        
        for i in 0..<count {
            let lutColor = lut[i]
            let lutColor_f = lutColor.toFloatSIMD3()
            let redmean = (lutColor_f.x + color.x) / 2
            let coeffs = redmean < 128 ? SIMD3<Float>(x: 2, y: 4, z: 3) : SIMD3<Float>(x: 3, y: 4, z: 2)
            let distance = simd_distance_squared(coeffs * lutColor_f, coeffs * color)
            
            if distance < distanceRecord {
                distanceRecord = distance
                result = lutColor
            }
        }
        
        return result
    }
}
