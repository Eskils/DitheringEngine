//
//  Dither-FloydSteinberg.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension DitherMethods {
    func floydSteinberg(palette: BytePalette, matrix: [Int], direction: FloydSteinbergDitheringDescription) {
        errorDiffusion(
            palette: palette,
            matrix: matrix,
            customization: direction
        )
    }
}

// MARK: - Dithering Description

public enum FloydSteinbergDitheringDescription: String, Nameable, Identifiable, ErrorDiffusionDitheringCustomization, Codable {
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
