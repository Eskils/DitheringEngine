//
//  SIMD3+Extension.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import simd

extension SIMD3 {
    
    var r: Scalar {
        get { self.x }
        set(value) { self.x = value }
    }
    
    var g: Scalar {
        get { self.y }
        set(value) { self.y = value }
    }
    
    var b: Scalar {
        get { self.z }
        set(value) { self.z = value }
    }
    
}

extension SIMD3 where Scalar == UInt8 {
    
    static func from32Bits(_ uint32: UInt32) -> Self {
        var uint32 = (uint32.byteSwapped >> 8)
        let simd = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
        
        withUnsafeBytes(of: &uint32) { bufferPointer in
            let pointer = bufferPointer.baseAddress!
                .assumingMemoryBound(to: UInt8.self)
            simd.update(from: pointer, count: 3)
        }
        
        let simd3 = UnsafeRawPointer(simd).assumingMemoryBound(to: SIMD3<Scalar>.self).pointee
        return simd3
    }
    
}
