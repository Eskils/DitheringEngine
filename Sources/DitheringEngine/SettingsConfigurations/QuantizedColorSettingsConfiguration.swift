//
//  QuantizedColorSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class QuantizedColorSettingsConfiguration: SettingsConfiguration {
    public let bits: CurrentValueSubject<Double, Never>
    
    /// Bytes can be anything from 0 to 8.
    public init(bits: Int) {
        self.bits = CurrentValueSubject(Double(bits))
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        bits
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}
