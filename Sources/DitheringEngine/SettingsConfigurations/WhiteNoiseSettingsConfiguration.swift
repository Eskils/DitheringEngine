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
    
    /// The intensity value to multiply the threshold map by.
    public let intensity: CurrentValueSubject<Float, Never>
    
    /// Determines wether to perform the computation on the CPU. If false, the GPU is used for quicker performance.
    public let performOnCPU: CurrentValueSubject<Bool, Never>
    
    public var size: Int {
        let exponent = thresholdMapSize.value
        return 2 << (exponent - 1)
    }
    
    public init(thresholdMapSize: Int = 7, intensity: Float = 0.5, performOnCPU: Bool = false) {
        self.thresholdMapSize = CurrentValueSubject(thresholdMapSize)
        self.intensity = CurrentValueSubject(intensity)
        self.performOnCPU = CurrentValueSubject(performOnCPU)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        Publishers.CombineLatest3(thresholdMapSize, intensity, performOnCPU)
            .map { (size, intensity, onCPU) in
                [size, intensity, onCPU] as Any
            }
            .eraseToAnyPublisher()
    }
    
}

extension WhiteNoiseSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case thresholdMapSize, performOnCPU, intensity
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(thresholdMapSize.value, forKey: .thresholdMapSize)
        try container.encode(performOnCPU.value, forKey: .performOnCPU)
        try container.encode(intensity.value, forKey: .intensity)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let thresholdMapSize = try container.decode(Int.self, forKey: .thresholdMapSize)
        let performOnCPU = try container.decode(Bool.self, forKey: .performOnCPU)
        let intensity = try container.decode(Float.self, forKey: .intensity)
        
        self.init(thresholdMapSize: thresholdMapSize, intensity: intensity, performOnCPU: performOnCPU)
    }
    
}
