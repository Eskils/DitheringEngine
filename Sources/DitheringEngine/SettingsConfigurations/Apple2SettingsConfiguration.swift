//
//  Apple2SettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class Apple2SettingsConfiguration: SettingsConfiguration {
    public typealias Enum = Palette.Apple2Mode
    
    public let mode: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .hiRes) {
        self.mode = CurrentValueSubject(mode)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        mode
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}
