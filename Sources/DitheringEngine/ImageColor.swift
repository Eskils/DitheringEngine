//
//  ImageColor.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import simd

public protocol ImageColor: SIMDScalar, Decodable, Encodable, Hashable {
    static var zero: Self { get }
    
    func toFloat() -> Float
    func toUInt8() -> UInt8
    func toInt() -> Int
}

extension UInt8: ImageColor {
    public func toFloat() -> Float { Float(self) }
    public func toUInt8() -> UInt8 { self }
    public func toInt() -> Int { Int(self) }
}

extension Float: ImageColor {
    public func toFloat() -> Float { self }
    public func toUInt8() -> UInt8 { UInt8(self) }
    public func toInt() -> Int { Int(self) }
}

extension SIMD3 where Scalar: ImageColor {
    
    static var zero: SIMD3<Scalar> { SIMD3(.zero, .zero, .zero) }
    
    func toFloatSIMD3() -> SIMD3<Float> {
        SIMD3<Float>(x: x.toFloat(), y: y.toFloat(), z: z.toFloat())
    }
    
    func toUInt8SIMD3() -> SIMD3<UInt8> {
        SIMD3<UInt8>(x: x.toUInt8(), y: y.toUInt8(), z: z.toUInt8())
    }
}
