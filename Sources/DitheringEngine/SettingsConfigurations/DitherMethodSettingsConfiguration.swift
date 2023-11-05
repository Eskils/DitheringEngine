//
//  DitherMethodSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class DitherMethodSettingsConfiguration: SettingsConfiguration {
    public typealias Enum = DitherMethod
    
    public let ditherMethod: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .none) {
        self.ditherMethod = CurrentValueSubject(mode)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        ditherMethod
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}
