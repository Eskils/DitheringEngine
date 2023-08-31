//
//  AppState.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 06/12/2022.
//

import Combine
import CoreGraphics

class AppState: ObservableObject {
    
    @Published
    var originalImage: CGImage?
    
    @Published
    var finalImage: CGImage?
    
    @Published
    var isRunning: Bool = false
}
