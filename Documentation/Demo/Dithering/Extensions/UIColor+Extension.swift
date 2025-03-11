//
//  UIColor+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

#if canImport(UIKit)
import SwiftUI

extension UIColor {
    
    func toColor() -> Color {
        Color(uiColor: self)
    }
    
}
#endif
