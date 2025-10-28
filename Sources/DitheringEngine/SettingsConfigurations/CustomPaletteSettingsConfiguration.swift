//
//  CustomPaletteSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class CustomPaletteSettingsConfiguration: CustomPaletteSettings {
    public let palette: CurrentValueSubject<BytePalette, Never>
    
    public init(palette: BytePalette = .from(lutCollection: LUTCollection<UInt8>(entries: [SIMD3<UInt8>(0,0,0), SIMD3<UInt8>(255, 255, 255)]))) {
        self.palette = CurrentValueSubject(palette)
    }
    
    public func palette(imageDescription: ImageDescription?, preferNoGray: Bool) -> BytePalette {
        palette.value
    }
    
    public convenience init(entries: [SIMD3<UInt8>]) {
        let lutCollection = LUTCollection(entries: entries)
        let palette = BytePalette.from(lutCollection: lutCollection)
        
        self.init(palette: palette)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        palette
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}

extension CustomPaletteSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case entries
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        let entries = palette.value.colors()
        try container.encode(entries, forKey: .entries)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let entries = try container.decode([SIMD3<UInt8>].self, forKey: .entries)
        let lutCollection = LUTCollection(entries: entries)
        let palette = BytePalette.from(lutCollection: lutCollection)
        
        self.init(palette: palette)
    }
    
}
