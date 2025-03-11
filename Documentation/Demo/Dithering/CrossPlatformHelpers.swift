//
//  CrossPlatformHelpers.swift
//  DitheringEngine
//
//  Created by Eskil Gjerde Sviggum on 10/03/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage

import AppKit
extension NSImage {
    var cgImage: CGImage? {
        self.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}

#endif
