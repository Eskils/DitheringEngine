//
//  PaletteSettingsConfiguration.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 05/12/2022.
//

import Foundation
import SwiftUI
import Combine

public protocol PaletteSettingsConfiguration: AnyObject {
    func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never>
}

public protocol SettingsEnum: CaseIterable, Hashable, Identifiable {
    var title: String { get }
}

public class EmptyPaletteSettingsConfiguration: PaletteSettingsConfiguration {
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        return CurrentValueSubject(0)
            .eraseToAnyPublisher()
    }
    
    public init() {}
}

public class QuantizedColorSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public let bits: CurrentValueSubject<Double, Never>
    
    /// Bytes can be anything from 0 to 8.
    public init(bits: Int) {
        self.bits = CurrentValueSubject(Double(bits))
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        bits
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

public class CGASettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public typealias Enum = Palette.CGAMode
    
    public let mode: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .palette1High) {
        self.mode = CurrentValueSubject(mode)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        mode
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

public class Apple2SettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public typealias Enum = Palette.Apple2Mode
    
    public let mode: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .hiRes) {
        self.mode = CurrentValueSubject(mode)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        mode
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

public class CustomPaletteSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public let palette: CurrentValueSubject<BytePalette, Never>
    
    public init(palette: BytePalette = .from(lutCollection: LUTCollection<UInt8>(entries: [SIMD3<UInt8>(0,0,0), SIMD3<UInt8>(255, 255, 255)]))) {
        self.palette = CurrentValueSubject(palette)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        palette
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

public class DitherMethodSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public typealias Enum = DitheringEngine.DitherMethod
    
    public let ditherMethod: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .none) {
        self.ditherMethod = CurrentValueSubject(mode)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        ditherMethod
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

public class PaletteSelectionSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public typealias Enum = Palette
    
    public let palette: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .bw) {
        self.palette = CurrentValueSubject(mode)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        palette
            .map { $0 as Any }
            .eraseToAnyPublisher()
            
    }
}

public enum FloydSteinbergDitheringDirection: String, SettingsEnum, Identifiable, FloydSteinbergDitheringCustomization {
    case leftToRight,
         rightToLeft,
         topToBottom,
         bottomToTop
    
    public var id: String { self.rawValue }
    
    public var title: String {
        switch self {
        case .leftToRight:
            return "Left to Right"
        case .rightToLeft:
            return "Right to Left"
        case .topToBottom:
            return "Top to Bottom"
        case .bottomToTop:
            return "Bottom to Top"
        }
    }
    
    var isNegativeXDirection: Bool {
        self == .rightToLeft
    }
    
    var isNegativeYDirection: Bool {
        self == .bottomToTop
    }
    
    var isYDirection: Bool {
        self == .topToBottom
        || self == .bottomToTop
    }
    
    func index(forX x: Int, y: Int, width: Int, andHeight height: Int) -> Int {
        switch self {
        case .leftToRight:
            return y * width + x
        case .rightToLeft:
            return y * width + (width - x)
        case .topToBottom:
            return x * width + y
        case .bottomToTop:
            return (height - x) * width + y
        }
    }
    
    private func offsetsFor(width w: Int) -> [Int] {
        switch self {
        case .leftToRight:
            return [1, w - 1, w, w + 1]
        case .rightToLeft:
            return [-1, w + 1, w, w - 1]
        case .topToBottom:
            return [1, w - 1, w, w + 1]
        case .bottomToTop:
            return [1, -w - 1, -w, -w + 1]
        }
    }
    
    func offsetsWith(matrix: [Int], andWidth w: Int) -> [(offset: Int, weight: Float)] {
        let matrix = matrix.map { Float($0) }
        let matrixSum = matrix.sum().add1IfZero()
        
        let weights = matrix.map { $0 / matrixSum }
        let offsets = offsetsFor(width: w)
        
        return (0..<min(offsets.count, matrix.count)).map { i in
            (offset: offsets[i], weight: weights[i])
        }
    }
}

struct FloydSteinbergAtkinsonDitheringDescription: FloydSteinbergDitheringCustomization {
    
    private func offsetsFor(width w: Int) -> [Int] {
        [           0 * w + 1, 0 * w + 2,
         1 * w - 1, 1 * w + 0, 1 * w + 1,
                    2 * w + 0,
        ]
    }
    
    func offsetsWith(matrix: [Int], andWidth w: Int) -> [(offset: Int, weight: Float)] {
        let matrix: [Float] = [1, 1, 1, 1, 1, 1]
        
        let weights = matrix.map { $0 / 8 }
        let offsets = offsetsFor(width: w)
        
        return (0..<min(offsets.count, matrix.count)).map { i in
            (offset: offsets[i], weight: weights[i])
        }
    }
    
    func index(forX x: Int, y: Int, width: Int, andHeight height: Int) -> Int {
        return y * width + x
    }
    
    let isYDirection: Bool = false
}

struct FloydSteinbergJarvisJudiceNinkeDitheringDescription: FloydSteinbergDitheringCustomization {
    
    private func offsetsFor(width w: Int) -> [Int] {
        [                                 0 * w + 1, 0 * w + 2,
         1 * w - 2, 1 * w - 1, 1 * w + 0, 1 * w + 1, 1 * w + 2,
         2 * w - 2, 2 * w - 1, 2 * w + 0, 2 * w + 1, 2 * w + 2
        ]
    }
    
    func offsetsWith(matrix: [Int], andWidth w: Int) -> [(offset: Int, weight: Float)] {
        let matrix: [Float] = [
                        7, 5,
               3, 5, 7, 5, 3,
               1, 3, 5, 3, 1
        ]
        
        let weights = matrix.map { $0 / 48 }
        let offsets = offsetsFor(width: w)
        
        return (0..<min(offsets.count, matrix.count)).map { i in
            (offset: offsets[i], weight: weights[i])
        }
    }
    
    func index(forX x: Int, y: Int, width: Int, andHeight height: Int) -> Int {
        return y * width + x
    }
    
    let isYDirection: Bool = false
}

protocol FloydSteinbergDitheringCustomization {
    var isYDirection: Bool { get }
    func index(forX x: Int, y: Int, width: Int, andHeight height: Int) -> Int
    func offsetsWith(matrix: [Int], andWidth w: Int) -> [(offset: Int, weight: Float)]
}

public class FloydSteinbergSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    
    public let matrix: CurrentValueSubject<[Int], Never>
    public let direction: CurrentValueSubject<FloydSteinbergDitheringDirection, Never>
    
    public init(direction: FloydSteinbergDitheringDirection = .leftToRight, matrix: [Int] = [7, 3, 5, 1]) {
        self.matrix = CurrentValueSubject(matrix)
        self.direction = CurrentValueSubject(direction)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        
        return matrix.combineLatest(direction, { matrix, direction in
            return [matrix, direction] as Any
        })
            .dropFirst()
            .eraseToAnyPublisher()
    }
    
}

public class BayerSettingsConfiguration: PaletteSettingsConfiguration {
    
    /// Exponent for size of threshold map m=2^n. mxm. Value between 1 and 6. Default value is 5.
    public let thresholdMapSize: CurrentValueSubject<Int, Never>
    
    var size: Int {
        let exponent = thresholdMapSize.value
        return 2 << (exponent - 1)
    }
    
    public init(thresholdMapSize: Int = 5) {
        self.thresholdMapSize = CurrentValueSubject(thresholdMapSize)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        
        return thresholdMapSize
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
    
    
}

public class NoiseDitheringSettingsConfiguration: PaletteSettingsConfiguration {
    
    public let noisePattern: CurrentValueSubject<CGImage?, Never>
    
    public init(noisePattern: CGImage? = nil) {
        self.noisePattern = CurrentValueSubject(noisePattern)
    }
    
    public func didChange(storingIn cancellables: inout Set<AnyCancellable>) -> AnyPublisher<Any, Never> {
        
        return noisePattern
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
    
    
}

//FIXME: This might not work…
func pipingCVSToAny<T>(_ cvs: CurrentValueSubject<T, Never>, storingIn cancellables: inout Set<AnyCancellable>) -> CurrentValueSubject<Any, Never> {
    
    let erasedCvs = CurrentValueSubject<Any, Never>(cvs.value)
    
    erasedCvs.sink { val in
        if let val = val as? T {
            cvs.send(val)
        }
    }
    .store(in: &cancellables)
    
    return erasedCvs
}

func pipingCVSToAnyForward<T>(_ cvs: CurrentValueSubject<T, Never>, storingIn cancellables: inout Set<AnyCancellable>) -> CurrentValueSubject<Any, Never> {
    
    let erasedCvs = CurrentValueSubject<Any, Never>(cvs.value)
    
    cvs.sink { val in
        erasedCvs.send(val)
    }
    .store(in: &cancellables)
    
    return erasedCvs
}


extension AnyPublisher {
    
    static func empty() -> AnyPublisher<Any, Never> {
        CurrentValueSubject<Any, Never>(0).eraseToAnyPublisher()
    }
    
}
