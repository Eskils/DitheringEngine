//
//  DitherMethodSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class DitherMethodSettingsConfiguration: SettingsConfiguration {
    public typealias Enum = DitherMethod
    
    public let ditherMethod: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .none) {
        self.ditherMethod = CurrentValueSubject(mode)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        ditherMethod
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

extension DitherMethodSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case ditherMethod
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(ditherMethod.value, forKey: .ditherMethod)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mode = try container.decode(Enum.self, forKey: .ditherMethod)
        
        self.init(mode: mode)
    }
    
}
