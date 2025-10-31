//
//  CustomPaletteSettings.swift
//  DitheringEngine
//
//  Created by Eskil Gjerde Sviggum on 28/10/2025.
//

public protocol CustomPaletteSettings: SettingsConfiguration {
    func palette(imageDescription: ImageDescriptionFormat?, preferNoGray: Bool) -> BytePalette
}
