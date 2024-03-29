//
//  FloydSteinbergSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class FloydSteinbergSettingsConfiguration: SettingsConfiguration {
    
    /// A matrix (array of four numbers) which specifies what weighting of the error to give the neighbouring pixels.
    /// The weighing is a fraction of the number and the sum of all numbers in the matrix.
    /// For instance: in the default matrix, [7, 3, 5, 1], the first is given the weight 7/16.
    public let matrix: CurrentValueSubject<[Int], Never>
    
    /// Specifies in what order to go through the pixels of the image.
    /// This has an effect on where the error is distributed.
    public let direction: CurrentValueSubject<FloydSteinbergDitheringDescription, Never>
    
    public init(direction: FloydSteinbergDitheringDescription = .leftToRight, matrix: [Int] = [7, 3, 5, 1]) {
        self.matrix = CurrentValueSubject(matrix)
        self.direction = CurrentValueSubject(direction)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        
        return matrix.combineLatest(direction, { matrix, direction in
            return [matrix, direction] as Any
        })
            .dropFirst()
            .eraseToAnyPublisher()
    }
    
}

extension FloydSteinbergSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case direction, matrix
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(direction.value, forKey: .direction)
        try container.encode(matrix.value, forKey: .matrix)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let direction = try container.decode(FloydSteinbergDitheringDescription.self, forKey: .direction)
        let matrix = try container.decode([Int].self, forKey: .matrix)
        
        self.init(direction: direction, matrix: matrix)
    }
    
}
