//
//  SafeAreaInsets+EnvironmentValues.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import SwiftUI

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        #if canImport(UIKit)
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = scene?.windows.first
        let uiInsets = window?.safeAreaInsets ?? .zero
        return EdgeInsets(top: uiInsets.top, leading: uiInsets.left, bottom: uiInsets.bottom, trailing: uiInsets.right)
        #elseif canImport(AppKit)
        return EdgeInsets()
        #endif
    }
}

extension EnvironmentValues {
    
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}
