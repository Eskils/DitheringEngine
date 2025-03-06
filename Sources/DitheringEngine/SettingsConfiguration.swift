//
//  SettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Foundation
import Combine

public protocol SettingsConfiguration: AnyObject {
    func didChange() -> AnyPublisher<Any, Never>
    var className: String { get }
}

#if canImport(UIKit)
extension SettingsConfiguration: Codable {
    
}
#endif

extension SettingsConfiguration {
    public var className: String { NSStringFromClass(Self.self) }
}
