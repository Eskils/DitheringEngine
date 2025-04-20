//
//  NoiseDitheringSettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public final class NoiseDitheringSettingsConfiguration: SettingsConfiguration {
    
    /// Specifies the noise pattern to use for ordered dithering.
    public let noisePattern: CurrentValueSubject<CGImage?, Never>
    
    public let intensity: CurrentValueSubject<Float, Never>
    
    /// Determines wether to perform the computation on the CPU. If false, the GPU is used for quicker performance.
    public let performOnCPU: CurrentValueSubject<Bool, Never>
    
    public init(noisePattern: CGImage? = nil, intensity: Float = 0.5, performOnCPU: Bool = false) {
        self.noisePattern = CurrentValueSubject(noisePattern)
        self.intensity = CurrentValueSubject(intensity)
        self.performOnCPU = CurrentValueSubject(performOnCPU)
    }
    
    public func didChange() -> AnyPublisher<Any, Never> {
        Publishers.CombineLatest3(noisePattern, intensity, performOnCPU)
            .map { (image, intensity, onCpu) in
                [image as Any, intensity, onCpu] as Any
            }
            .eraseToAnyPublisher()
    }
    
    
}

extension NoiseDitheringSettingsConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case noisePattern, performOnCPU, intensity
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        
        let data = try noisePattern.value.map { try CGImageDataTransformer.data(from: $0) }
        
        try container.encodeIfPresent(data, forKey: .noisePattern)
        try container.encode(performOnCPU.value, forKey: .performOnCPU)
        try container.encode(intensity.value, forKey: .intensity)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let noisePatternData = try container.decode(Data.self, forKey: .noisePattern)
        
        let noisePattern = try CGImageDataTransformer.image(from: noisePatternData)
        let performOnCPU = try container.decode(Bool.self, forKey: .performOnCPU)
        let intensity = try container.decode(Float.self, forKey: .intensity)
        
        self.init(noisePattern: noisePattern, intensity: intensity, performOnCPU: performOnCPU)
    }
    
}

