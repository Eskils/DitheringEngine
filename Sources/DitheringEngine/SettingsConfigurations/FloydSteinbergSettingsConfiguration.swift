//
//  FloydSteinbergSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class FloydSteinbergSettingsConfiguration: SettingsConfiguration {
    
    public let matrix: CurrentValueSubject<[Int], Never>
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
