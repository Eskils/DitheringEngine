//
//  SettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

public protocol SettingsConfiguration: AnyObject {
    func didChange() -> AnyPublisher<Any, Never>
}
