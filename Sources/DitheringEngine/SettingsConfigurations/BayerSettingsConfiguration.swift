//
//  BayerSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class BayerSettingsConfiguration: SettingsConfiguration, OrderedDitheringThresholdConfiguration {
    
    /// Exponent for size of threshold map m=2^n. mxm. Value between 1 and 6. Default value is 5.
    public let thresholdMapSize: CurrentValueSubject<Int, Never>
    
    public var size: Int {
        let exponent = thresholdMapSize.value
        return 2 << (exponent - 1)
    }
    
    public init(thresholdMapSize: Int = 5) {
        self.thresholdMapSize = CurrentValueSubject(thresholdMapSize)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        
        return thresholdMapSize
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
    
}
