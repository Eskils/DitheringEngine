//
//  SettingsConfiguration.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 05/12/2022.
//

import Foundation

public struct ThresholdSettingsConfiguration: DitherSettingsConfiguration {
    
    public init() {}
}

public struct BayerSettingsConfiguration: DitherSettingsConfiguration {
    
    public init() {}
}

public protocol DitherSettingsConfiguration {
    
}


