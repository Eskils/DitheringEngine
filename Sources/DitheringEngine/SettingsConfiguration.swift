//
//  SettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Foundation
import Combine

public protocol SettingsConfiguration: AnyObject, Codable {
    func didChange() -> AnyPublisher<Any, Never>
    var wrappedType: SettingsConfiguration.Type { get }
    var className: String { get }
}

extension SettingsConfiguration {
    public var wrappedType: SettingsConfiguration.Type { Self.self }
    
    public var className: String { NSStringFromClass(Self.self) }
}
