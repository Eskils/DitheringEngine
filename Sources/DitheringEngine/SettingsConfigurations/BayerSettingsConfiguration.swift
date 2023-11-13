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
    
    /// Determines wether to perform the computation on the CPU. If false, the GPU is used for quicker performance.
    public let performOnCPU: CurrentValueSubject<Bool, Never>
    
    public var size: Int {
        let exponent = thresholdMapSize.value
        return 2 << (exponent - 1)
    }
    
    public init(thresholdMapSize: Int = 5, performOnCPU: Bool = false) {
        self.thresholdMapSize = CurrentValueSubject(thresholdMapSize)
        self.performOnCPU = CurrentValueSubject(performOnCPU)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        
        return thresholdMapSize.combineLatest(performOnCPU, { thresholdMapSize, onCPU in
            [thresholdMapSize, onCPU] as Any
        })
            .eraseToAnyPublisher()
    }
    
}

extension BayerSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case thresholdMapSize, performOnCPU
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(thresholdMapSize.value, forKey: .thresholdMapSize)
        try container.encode(performOnCPU.value, forKey: .performOnCPU)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let thresholdMapSize = try container.decode(Int.self, forKey: .thresholdMapSize)
        let performOnCPU = try container.decode(Bool.self, forKey: .performOnCPU)
        
        self.init(thresholdMapSize: thresholdMapSize, performOnCPU: performOnCPU)
    }
    
}
