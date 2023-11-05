//
//  EmptySettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class EmptyPaletteSettingsConfiguration: SettingsConfiguration {
    public func didChange() -> AnyPublisher<Any, Never> {
        return CurrentValueSubject(0)
            .eraseToAnyPublisher()
    }
    
    public init() {}
}
