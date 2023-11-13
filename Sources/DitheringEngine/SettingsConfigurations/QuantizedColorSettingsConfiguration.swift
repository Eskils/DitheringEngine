//
//  QuantizedColorSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class QuantizedColorSettingsConfiguration: SettingsConfiguration {
    
    /// Specifies the number of bits to quantize to.
    /// The number of bits can be between 0 and 8.
    public let bits: CurrentValueSubject<Double, Never>
    
    /// Bits can be anything from 0 to 8.
    public init(bits: Int) {
        self.bits = CurrentValueSubject(Double(bits))
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        bits
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

extension QuantizedColorSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case bits
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(Int(bits.value), forKey: .bits)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mode = try container.decode(Int.self, forKey: .bits)
        
        self.init(bits: mode)
    }
    
}
