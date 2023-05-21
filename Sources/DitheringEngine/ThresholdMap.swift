//
//  ThresholdMap.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 02/12/2022.
//

import Foundation

struct ThresholdMap<T>: CustomStringConvertible {
    let count: Int
    let num: Int
    let buffer: UnsafeMutablePointer<T>
    
    init(num: Int, buffer: UnsafeMutablePointer<T>) {
        self.count = num * num
        self.num = num
        self.buffer = buffer
    }
    
    init<U: Collection>(entries: U) where U.Element == T {
        let buffer = UnsafeMutablePointer<T>.allocate(capacity: entries.count)
        entries.withContiguousStorageIfAvailable { bufferPointer in
            let pointer = bufferPointer.baseAddress!
            buffer.update(from: pointer, count: entries.count)
        }
        let num = Int(sqrt(Float(entries.count)))
        self.init(num: num, buffer: buffer)
    }
    
    func thresholdAt(x: Int, y: Int) -> T {
        let index = y * num + x
        
        if index >= count {
            return buffer[0]
        }
        
        return buffer[index]
    }
    
    var description: String {
        var result = ""
        
        for y in 0..<num {
            for x in 0..<num {
                let value = thresholdAt(x: x, y: y)
                result += "\(value) "
            }
            result.append("\n")
        }
        
        return result
    }
    
    func release() {
        buffer.deallocate()
    }
}

typealias ByteThresholdMap = ThresholdMap<UInt8>
typealias FloatingThresholdMap = ThresholdMap<Float>

func thresholdMap2x2<T: Numeric & ImageColor>() -> ThresholdMap<T> {
    return ThresholdMap(entries: [0, 2,
                                  3, 1])
}

func thresholdMap4x4<T: Numeric & ImageColor>() -> ThresholdMap<T> {
    return ThresholdMap(entries: [15, 135,  45, 165,
                                  195,  75, 225, 105,
                                  60, 180,  30, 150,
                                  240, 120, 210,  90 ])
}

func generateThresholdMap(n: Int) -> FloatingThresholdMap {
    if n <= 1 { return thresholdMap2x2() }
    
    let thresholdMap: ThresholdMap<Float> = generateThresholdMap(n: n - 1)
    let num = Int(pow(2, Float(n)))
    let count = num * num
    
    let buffer = UnsafeMutablePointer<Float>.allocate(capacity: count)
    for y in 0..<num {
        for x in 0..<num {
            let term1 = thresholdMap.thresholdAt(x: x / 2, y: y / 2)
            let term2 = 4 * thresholdMap.thresholdAt(x: x % 2, y: y % 2)
            let i = y * num + x
            buffer[i] = Float(term1 + term2)
        }
    }
    
    thresholdMap.release()
    return FloatingThresholdMap(num: num, buffer: buffer)
}
