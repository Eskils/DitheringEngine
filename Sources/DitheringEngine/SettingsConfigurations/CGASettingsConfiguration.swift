//
//  CGASettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class CGASettingsConfiguration: SettingsConfiguration {
    public typealias Enum = Palette.CGAMode
    
    /// Specifies the graphics mode to use.
    /// Each graphics mode has a unique set of colors.
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

extension CGASettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case mode
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(mode.value, forKey: .mode)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mode = try container.decode(Enum.self, forKey: .mode)
        
        self.init(mode: mode)
    }
    
}
