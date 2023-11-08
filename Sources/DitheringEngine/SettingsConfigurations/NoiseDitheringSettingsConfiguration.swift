//
//  NoiseDitheringSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine
import CoreGraphics

public final class NoiseDitheringSettingsConfiguration: SettingsConfiguration {
    
    /// Specifies the noise pattern to use for ordered dithering.
    public let noisePattern: CurrentValueSubject<CGImage?, Never>
    
    /// Determines wether to perform the computation on the CPU. If false, the GPU is used for quicker performance.
    public let performOnCPU: CurrentValueSubject<Bool, Never>
    
    public init(noisePattern: CGImage? = nil, performOnCPU: Bool = false) {
        self.noisePattern = CurrentValueSubject(noisePattern)
        self.performOnCPU = CurrentValueSubject(performOnCPU)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        
        return noisePattern.combineLatest(performOnCPU, { image, onCpu in
            [image as Any, onCpu] as Any
        })
            .eraseToAnyPublisher()
    }
    
    
}
