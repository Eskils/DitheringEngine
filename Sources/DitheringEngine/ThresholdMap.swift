//
//  ThresholdMap.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 02/12/2022.
//

struct ThresholdMap<T: Numeric & ImageColor>: CustomStringConvertible {
    let count: Int
    let num: Int
    let buffer: UnsafeMutablePointer<T>
    
    init(num: Int, buffer: UnsafeMutablePointer<T>) {
        self.count = num * num
        self.num = num
        self.buffer = buffer
    }
    
    init<U: Collection>(entries: U, num: Int) where U.Element == T {
        let buffer = UnsafeMutablePointer<T>.allocate(capacity: entries.count)
        entries.withContiguousStorageIfAvailable { bufferPointer in
            let pointer = bufferPointer.baseAddress!
            buffer.update(from: pointer, count: entries.count)
        }
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

extension ThresholdMap {
    static func thresholdMap2x2() -> ThresholdMap<T> {
        return ThresholdMap(entries: [0, 2,
                                      3, 1], num: 2)
    }

    static func thresholdMap4x4() -> ThresholdMap<T> {
        return ThresholdMap(entries: [15, 135,  45, 165,
                                      195,  75, 225, 105,
                                      60, 180,  30, 150,
                                      240, 120, 210,  90 ], num: 4)
    }

    /// Generates threshold map for Bayer dithering. N must be a multiple of 2.
    static func generateBayerThresholdMap(n num: Int) -> FloatingThresholdMap {
        if num <= 2 { return FloatingThresholdMap.thresholdMap2x2() }
        
        let previousNum = num >> 1
        let thresholdMap: FloatingThresholdMap = generateBayerThresholdMap(n: previousNum)
        let count = num * num
        
        let buffer = UnsafeMutablePointer<Float>.allocate(capacity: count)
        for y in 0..<num {
            for x in 0..<num {
                let term = Int(thresholdMap.thresholdAt(x: x % previousNum, y: y % previousNum))
                
                let quadrantX = (x / previousNum)
                let quadrantY = (y / previousNum)
                let offset = 2 * quadrantX + (3 - 4 * quadrantX) * quadrantY
                
                let i = y * num + x
                
                buffer[i] = Float(4 * term + offset)
            }
        }
        
        thresholdMap.release()
        return FloatingThresholdMap(num: num, buffer: buffer)
    }

    /// Generates white noise threshold map.
    static func generateWhiteNoiseThresholdMap(n num: Int, max: Float, seed: Int) -> FloatingThresholdMap {
        let buffer = UnsafeMutablePointer<Float>.allocate(capacity: num * num)
        var numberGenerator = WhiteNoiseGenerator(seed: seed)
        for i in 0..<num * num {
            buffer[i] = Float.random(in: 0...max, using: &numberGenerator)
        }
        
        return FloatingThresholdMap(num: num, buffer: buffer)
    }

    /// Generates threshold map from image.
    static func generateImageThresholdMap(image: ImageDescription) -> FloatingThresholdMap {
        let buffer = UnsafeMutablePointer<Float>.allocate(capacity: image.width * image.width)
        
        for i in 0..<image.width*image.width {
            let value = image.getColorAt(index: i).x
            buffer[i] = Float(value)
        }
        
        return FloatingThresholdMap(num: image.width, buffer: buffer)
    }
}
