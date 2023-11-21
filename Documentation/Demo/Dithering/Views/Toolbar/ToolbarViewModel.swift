//
//  ToolbarViewModel.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 06/12/2022.
//

import Foundation
import Combine
import CoreGraphics
import DitheringEngine

extension ToolbarView {
    
    @MainActor
    class ViewModel: ObservableObject {
        
        let appState: AppState
        let ditheringEngine: DitheringEngine
        let videoDitheringEngine: VideoDitheringEngine
        
        let ditherMethodSetting = DitherMethodSettingsConfigurationWithView(settingsConfiguration: DitherMethodSettingsConfiguration())
        let paletteSelectionSetting = PaletteSelectionSettingsConfigurationWithView(settingsConfiguration: PaletteSelectionSettingsConfiguration())
        
        @Published
        var additionalPaletteSelectionSetting: PaletteSettingsConfigurationWithView = EmptyPaletteSettingsConfigurationWithView()
        
        @Published
        var additionalDitherMethodSetting: PaletteSettingsConfigurationWithView = EmptyPaletteSettingsConfigurationWithView()
        
        @Published
        var isInVideoMode: Bool = false
        
        init(ditheringEngine: DitheringEngine, videoDitheringEngine: VideoDitheringEngine, appState: AppState) {
            self.ditheringEngine = ditheringEngine
            self.videoDitheringEngine = videoDitheringEngine
            self.appState = appState
        }
        
        func handleNew(image: CGImage) {
            appState.isRunning = true
            DispatchQueue.global().async { [self] in
                do {
                    try ditheringEngine.set(image: image)
                    let image = try ditheringEngine.generateOriginalImage()
                    DispatchQueue.main.async {
                        self.appState.originalImage = image
                        self.isInVideoMode = false
                        self.performDithering()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.appState.isRunning = false
                    }
                    print(error)
                    assertionFailure()
                }
            }
        }
        
        func handleNew(video url: URL) {
            appState.isRunning = true
            
            DispatchQueue.global().async {
                Task {
                    do {
                        let originalVideo = VideoDescription(url: url)
                        let previewImage = try await originalVideo.getPreviewImage()
                        try self.ditheringEngine.set(image: previewImage)
                        DispatchQueue.main.async {
                            self.appState.originalImage = previewImage
                            self.appState.originalVideo = originalVideo
                            self.isInVideoMode = true
                            self.performDithering()
                        }
                    } catch {
                        print("Could not make preview image: \(error)")
                    }
                }
            }
        }
        
        func didChangePalette() {
            let palette = paletteSelectionSetting.palette.value
            let settingsConfiguration = palette.settings()
            additionalPaletteSelectionSetting = CustomPaletteSettingsConfigurationWithView.from(paletteSettingsConfiguration: settingsConfiguration)
            listenToPaletteSettingUpdates()
        }
        
        func didChangeDitherMethod() {
            let ditherMethod = ditherMethodSetting.ditherMethod.value
            let settingsConfiguration = ditherMethod.settings()
            additionalDitherMethodSetting = CustomPaletteSettingsConfigurationWithView.from(paletteSettingsConfiguration: settingsConfiguration)
            listenToDitherSettingUpdates()
        }
        
        var paletteSettingUpdatesCancellable: AnyCancellable?
        
        func listenToPaletteSettingUpdates() {
            paletteSettingUpdatesCancellable?.cancel()
            paletteSettingUpdatesCancellable = additionalPaletteSelectionSetting.didChangePublisher.sink { _ in
                self.performDithering()
            }
        }
        
        var ditherSettingUpdatesCancellable: AnyCancellable?
        
        func listenToDitherSettingUpdates() {
            ditherSettingUpdatesCancellable?.cancel()
            ditherSettingUpdatesCancellable = additionalDitherMethodSetting.didChangePublisher.sink { _ in
                self.performDithering()
            }
        }
        
        func ditherVideo(name: String, progressHandler: @escaping (Float) -> Void, completionHandler: @escaping (Result<URL, Error>) -> Void) {
            let additionalPalleteSettings = additionalPaletteSelectionSetting
            let additionalDitherMethodSetting = additionalDitherMethodSetting
            
            DispatchQueue.global().async { [self] in
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.appState.isRunning = true
                    }
                }
                
                do {
                    let palette = paletteSelectionSetting.palette.value
                    let ditherMethod = ditherMethodSetting.ditherMethod.value
                    
                    if var originalVideo = appState.originalVideo {
                        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.absoluteURL
                        let outputURL = baseURL.appendingPathComponent(name)
                        if FileManager.default.fileExists(atPath: outputURL.path) {
                            try FileManager.default.removeItem(at: outputURL)
                        }
                        print("Output URL: ", outputURL)
                        //FIXME: Support landscape video
                        originalVideo.renderSize = CGSize(width: 360, height: 1)
                        videoDitheringEngine.dither(videoDescription: originalVideo, usingMethod: ditherMethod, andPalette: palette, withDitherMethodSettings: additionalDitherMethodSetting.settingsConfiguration, andPaletteSettings: additionalPalleteSettings.settingsConfiguration, outputURL: outputURL, progressHandler: progressHandler) { error in
                            timer.invalidate()
                            DispatchQueue.main.async {
                                self.appState.isRunning = false
                                if let error {
                                    print("Finished dithering video with error: \(String(describing: error))")
                                    completionHandler(.failure(error))
                                } else {
                                    completionHandler(.success(outputURL))
                                }
                            }
                        }
                    }
                    
                } catch {
                    timer.invalidate()
                    DispatchQueue.main.async {
                        self.appState.isRunning = false
                    }
                    print("Failed dithering with error: ", error)
                }
            }
        }
        
        func performDithering() {
            let additionalPalleteSettings = additionalPaletteSelectionSetting
            let additionalDitherMethodSetting = additionalDitherMethodSetting
            
            DispatchQueue.global().async { [self] in
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.appState.isRunning = true
                    }
                }
                
                do {
                    let palette = paletteSelectionSetting.palette.value
                    let ditherMethod = ditherMethodSetting.ditherMethod.value
                    let result = try ditheringEngine.dither(
                        usingMethod: ditherMethod,
                        andPalette: palette,
                        withDitherMethodSettings: additionalDitherMethodSetting.settingsConfiguration,
                        withPaletteSettings: additionalPalleteSettings.settingsConfiguration
                    )
                    
                    timer.invalidate()
                    DispatchQueue.main.async {
                        self.appState.isRunning = false
                        self.appState.finalImage = result
                    }
                    
                } catch {
                    timer.invalidate()
                    DispatchQueue.main.async {
                        self.appState.isRunning = false
                    }
                    print("Failed dithering with error: ", error)
                }
            }
        }
        
    }
}
