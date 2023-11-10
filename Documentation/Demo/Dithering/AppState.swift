//
//  AppState.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 06/12/2022.
//

import Combine
import CoreGraphics
import DitheringEngine

class AppState: ObservableObject {
    
    @Published
    var originalImage: CGImage?
    
    @Published
    var finalImage: CGImage?
    
    @Published
    var originalVideo: VideoDescription?
    
    var isInVideoMode: Bool = false
    
    @Published
    var isRunning: Bool = false
}
