//
//  WhiteNoiseSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class WhiteNoiseSettingsConfiguration: SettingsConfiguration, OrderedDitheringThresholdConfiguration {
    
    /// Exponent for size of threshold map m=2^n. mxm. Value between 7 and 10. Default value is 7.
    public let thresholdMapSize: CurrentValueSubject<Int, Never>
    
    public var size: Int {
        let exponent = thresholdMapSize.value
        return 2 << (exponent - 1)
    }
    
    public init(thresholdMapSize: Int = 7) {
        self.thresholdMapSize = CurrentValueSubject(thresholdMapSize)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        
        return thresholdMapSize
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
    
}
