//
//  MediaFormat.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 09/11/2023.
//
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum MediaFormat {
    #if canImport(UIKit)
    case image(UIImage)
    #elseif canImport(AppKit)
    case image(NSImage)
    #endif
    case video(URL)
}

extension MediaFormat: Equatable {}
