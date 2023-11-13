//
//  PaletteSelectionSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class PaletteSelectionSettingsConfiguration: SettingsConfiguration {
    public typealias Enum = Palette
    
    /// Specifies the palette to use for dithering.
    public let palette: CurrentValueSubject<Enum, Never>
    
    public init(mode: Enum = .bw) {
        self.palette = CurrentValueSubject(mode)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        palette
            .map { $0 as Any }
            .eraseToAnyPublisher()
            
    }
}

extension PaletteSelectionSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case palette
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(palette.value, forKey: .palette)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mode = try container.decode(Enum.self, forKey: .palette)
        
        self.init(mode: mode)
    }
    
}
