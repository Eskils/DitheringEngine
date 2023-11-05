//
//  CustomPaletteSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public final class CustomPaletteSettingsConfiguration: SettingsConfiguration {
    public let palette: CurrentValueSubject<BytePalette, Never>
    
    public init(palette: BytePalette = .from(lutCollection: LUTCollection<UInt8>(entries: [SIMD3<UInt8>(0,0,0), SIMD3<UInt8>(255, 255, 255)]))) {
        self.palette = CurrentValueSubject(palette)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        palette
            .map { $0 as Any }
            .eraseToAnyPublisher()
    }
}
