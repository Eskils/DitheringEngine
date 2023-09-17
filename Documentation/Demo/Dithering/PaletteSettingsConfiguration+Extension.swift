//
//  PaletteSettingsConfiguration+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 31/08/2023.
//

import Foundation
import Combine
import DitheringEngine

protocol PaletteSettingsConfigurationWithView: AnyObject {
    var views: [any SettingView] { get }
    var didChangePublisher: AnyPublisher<Any, Never> { get }
    var settingsConfiguration: PaletteSettingsConfiguration { get }
}

protocol WithView: AnyObject {
    var views: [any SettingView] { get }
    var didChangePublisher: AnyPublisher<Any, Never> { get }
}

class DitherMethodSettingsConfigurationWithView: WithView {
    
    typealias Enum = DitheringEngine.DitherMethod
    
    let settingsConfiguration: DitherMethodSettingsConfiguration
    
    let views: [any SettingView]
    
    let didChangePublisher: AnyPublisher<Any, Never> = .empty()
    
    init(settingsConfiguration: DitherMethodSettingsConfiguration) {
        self.settingsConfiguration = settingsConfiguration
        
        self.views = [
            EnumSettingViewDescription(subject: settingsConfiguration.ditherMethod, title: "Dither Method", options: Enum.allCases)
        ]
    }
    
    var ditherMethod: CurrentValueSubject<Enum, Never> {
        settingsConfiguration.ditherMethod
    }
}

class PaletteSelectionSettingsConfigurationWithView: PaletteSettingsConfiguration, ObservableObject {
    typealias Enum = Palette
    
    let settingsConfiguration: PaletteSelectionSettingsConfiguration
    
    var palette: CurrentValueSubject<Enum, Never> {
        settingsConfiguration.palette
    }
    
    let didChangePublisher: AnyPublisher<Any, Never> = .empty()
    
    let views: [any SettingView]
    
    init(settingsConfiguration: PaletteSelectionSettingsConfiguration) {
        self.settingsConfiguration = settingsConfiguration
        
        self.views = [
            EnumSettingViewDescription(subject: settingsConfiguration.palette, title: "", options: Enum.allCases)
        ]
    }
}

class EmptyPaletteSettingsConfigurationWithView: PaletteSettingsConfigurationWithView {
    let settingsConfiguration: PaletteSettingsConfiguration = EmptyPaletteSettingsConfiguration()
    
    let didChangePublisher: AnyPublisher<Any, Never> = .empty()
    
    let views: [any SettingView] = []
}

class CustomPaletteSettingsConfigurationWithView: PaletteSettingsConfigurationWithView {
    
    let settingsConfiguration: PaletteSettingsConfiguration
    
    let views: [any SettingView]
    
    let didChangePublisher: AnyPublisher<Any, Never>
    
    var cancellables = Set<AnyCancellable>()
    
    init(settingsConfiguration: PaletteSettingsConfiguration, views: [any SettingView], didChangePublisher: AnyPublisher<Any, Never>, cancellables: Set<AnyCancellable>? = nil) {
        self.settingsConfiguration = settingsConfiguration
        self.views = views
        self.didChangePublisher = didChangePublisher
        
        if let cancellables {
            self.cancellables = cancellables
        }
    }
    
    static func from(paletteSettingsConfiguration: PaletteSettingsConfiguration) -> PaletteSettingsConfigurationWithView {
        switch paletteSettingsConfiguration {
        case is EmptyPaletteSettingsConfiguration:
            return EmptyPaletteSettingsConfigurationWithView()
        case is FloydSteinbergSettingsConfiguration:
            let settingsConfiguration = paletteSettingsConfiguration as! FloydSteinbergSettingsConfiguration
            
            let views: [any SettingView] = [
                MatrixInputSettingViewDescription(matrix: settingsConfiguration.matrix, title: "Matrix"),
                EnumSettingViewDescription(subject: settingsConfiguration.direction, title: "Direction", options: FloydSteinbergDitheringDirection.allCases)
            ]
            
            let (didChange, cancellables) = makeDidChangePublisher(from: views)
            
            return CustomPaletteSettingsConfigurationWithView(settingsConfiguration: settingsConfiguration, views: views, didChangePublisher: didChange, cancellables: cancellables)
        case is QuantizedColorSettingsConfiguration:
            let settingsConfiguration = paletteSettingsConfiguration as! QuantizedColorSettingsConfiguration
            
            let views = [
                NumberSettingViewDescription(subject: settingsConfiguration.bits, title: "Bits", min: 0, max: 8)
            ]
            
            let (didChange, cancellables) = makeDidChangePublisher(from: views)
            
            return CustomPaletteSettingsConfigurationWithView(settingsConfiguration: settingsConfiguration, views: views, didChangePublisher: didChange, cancellables: cancellables)
        case is CGASettingsConfiguration:
            let settingsConfiguration = paletteSettingsConfiguration as! CGASettingsConfiguration
            
            let views = [
                EnumSettingViewDescription(subject: settingsConfiguration.mode, title: "Mode", options: CGASettingsConfiguration.Enum.allCases)
            ]
            
            let (didChange, cancellables) = makeDidChangePublisher(from: views)
            return CustomPaletteSettingsConfigurationWithView(settingsConfiguration: settingsConfiguration, views: views, didChangePublisher: didChange, cancellables: cancellables)
        case is CustomPaletteSettingsConfiguration:
            let settingsConfiguration = paletteSettingsConfiguration as! CustomPaletteSettingsConfiguration
            
            let views = [
                CustomPaletteSettingViewDescription(palette: settingsConfiguration.palette, title: "Colors")
            ]
            
            let (didChange, cancellables) = makeDidChangePublisher(from: views)
            return CustomPaletteSettingsConfigurationWithView(settingsConfiguration: settingsConfiguration, views: views, didChangePublisher: didChange, cancellables: cancellables)
        default:
            return EmptyPaletteSettingsConfigurationWithView()
        }
    }
}
