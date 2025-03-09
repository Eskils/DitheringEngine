//
//  SettingsConfiguration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Foundation
import Combine

#if canImport(UIKit)
public protocol SettingsConfiguration: AnyObject, Codable {
    func didChange() -> AnyPublisher<Any, Never>
    var className: String { get }
}
#else
public protocol SettingsConfiguration: AnyObject {
    func didChange() -> AnyPublisher<Any, Never>
    var className: String { get }
}
#endif

extension SettingsConfiguration {
    public var className: String { NSStringFromClass(Self.self) }
}
