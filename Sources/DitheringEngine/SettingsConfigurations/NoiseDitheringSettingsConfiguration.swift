//
//  NoiseDitheringSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine
import CoreGraphics

public final class NoiseDitheringSettingsConfiguration: SettingsConfiguration {
    
    public let noisePattern: CurrentValueSubject<CGImage?, Never>
    
    public init(noisePattern: CGImage? = nil) {
        self.noisePattern = CurrentValueSubject(noisePattern)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        
        return noisePattern
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
    
    
}
