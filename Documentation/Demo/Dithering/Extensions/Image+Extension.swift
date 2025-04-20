//
//  Image+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import SwiftUI

extension Image {
    init(platformImage: PlatformImage?) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage ?? UIImage())
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage ?? NSImage())
        #endif
    }
}
