//
//  CustomPaletteSettings.swift
//  DitheringEngine
//
//  Created by Eskil Gjerde Sviggum on 28/10/2025.
//

/// Implement this protocol to define settings for a palette.
///
/// - SeeAlso: ``CustomPaletteSettingsConfiguration``
public protocol CustomPaletteSettings: SettingsConfiguration {
    /// Called by the dithering engine before dithering an image/video, and when extracting colors from a palette
    /// - Parameters:
    ///   - imageDescription: An optional reference to the currently dithered image.
    ///   - preferNoGray: Use this flag if you are able to filter out gray colors.
    /// - Returns: The palette as a ``BytePalette``
    ///
    /// `imageDescription` is nil if no image has been set, or if extracting colors outside of the dithering engine context—for example by calling `colors` directly on a palette.
    func palette(imageDescription: ImageDescriptionFormat?, preferNoGray: Bool) -> BytePalette
}
