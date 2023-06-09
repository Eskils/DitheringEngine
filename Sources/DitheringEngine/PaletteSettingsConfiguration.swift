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
}

public protocol SettingsEnum: CaseIterable, Hashable, Identifiable {
    var title: String { get }
}

public class EmptyPaletteSettingsConfiguration: PaletteSettingsConfiguration {
    public init() {}
}

public class QuantizedColorSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    let bits: CurrentValueSubject<Double, Never>
    
    /// Bytes can be anything from 0 to 8.
    public init(bits: Int) {
        self.bits = CurrentValueSubject(Double(bits))
    }
}

public class CGASettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public typealias Enum = Palette.CGAMode
    
    let mode: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .palette1High) {
        self.mode = CurrentValueSubject(mode)
    }
}

public class DitherMethodSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public typealias Enum = DitheringEngine.DitherMethod
    
    let ditherMethod: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .none) {
        self.ditherMethod = CurrentValueSubject(mode)
    }
}

public class PaletteSelectionSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    public typealias Enum = Palette
    
    let palette: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .bw) {
        self.palette = CurrentValueSubject(mode)
    }
}

public enum FloydSteinbergDitheringDirection: String, SettingsEnum, Identifiable {
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

public class FloydSteinbergSettingsConfiguration: PaletteSettingsConfiguration, ObservableObject {
    
    let matrix: CurrentValueSubject<[Int], Never>
    let direction: CurrentValueSubject<FloydSteinbergDitheringDirection, Never>
    
    public init(direction: FloydSteinbergDitheringDirection = .leftToRight, matrix: [Int] = [7, 3, 5, 1]) {
        self.matrix = CurrentValueSubject(matrix)
        self.direction = CurrentValueSubject(direction)
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
