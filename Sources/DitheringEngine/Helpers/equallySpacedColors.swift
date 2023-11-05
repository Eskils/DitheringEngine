//
//  equallySpacedColors.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Foundation

func equallySpacedColors(withBits bits: Int) -> (entries: UnsafePointer<UInt8>, count: Int) {
    let bits = clamp(bits, min: 1, max: 8)
    
    let max = Int(UInt8.max)
    let count = (0..<bits).reduce(into: 1, { value, _ in value *= 2 })
    
    let entries = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
    for i in 0..<count {
        let color = (i * max) / (count - 1)
        entries[i] = UInt8(clamping: color)
    }
    
    return (UnsafePointer(entries), count)
}
