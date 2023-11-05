//
//  CGASettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class CGASettingsConfiguration: SettingsConfiguration {
    public typealias Enum = Palette.CGAMode
    
    public let mode: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .palette1High) {
        self.mode = CurrentValueSubject(mode)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        mode
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}
