//
//  OrderedDitheringThresholdConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public protocol OrderedDitheringThresholdConfiguration: SettingsConfiguration {
    var thresholdMapSize: CurrentValueSubject<Int, Never> { get }
    var size: Int { get }
}
