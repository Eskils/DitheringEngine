//
//  SIMD3+Extension.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import simd

extension SIMD3 where Scalar == UInt8 {
    
    static func from32Bits(_ uint32: UInt32) -> Self {
        var uint32 = (uint32.byteSwapped >> 8)
        let capacity = MemoryLayout<SIMD3>.size
        let simd = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        
        withUnsafeBytes(of: &uint32) { bufferPointer in
            let pointer = bufferPointer.baseAddress!
                .assumingMemoryBound(to: UInt8.self)
            simd.update(from: pointer, count: capacity)
        }
        
        let simd3 = UnsafeRawPointer(simd).assumingMemoryBound(to: SIMD3<Scalar>.self).pointee
        return simd3
    }
    
}
