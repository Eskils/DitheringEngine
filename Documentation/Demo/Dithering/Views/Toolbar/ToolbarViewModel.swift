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
        
        let ditherMethodSetting = DitherMethodSettingsConfigurationWithView(settingsConfiguration: DitherMethodSettingsConfiguration())
        let paletteSelectionSetting = PaletteSelectionSettingsConfigurationWithView(settingsConfiguration: PaletteSelectionSettingsConfiguration())
        
        @Published
        var additionalPaletteSelectionSetting: PaletteSettingsConfigurationWithView = EmptyPaletteSettingsConfigurationWithView()
        
        @Published
        var additionalDitherMethodSetting: PaletteSettingsConfigurationWithView = EmptyPaletteSettingsConfigurationWithView()
        
        init(ditheringEngine: DitheringEngine, appState: AppState) {
            self.ditheringEngine = ditheringEngine
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
                    //ditherMethodSetting.ditherMethod
                    let palette = paletteSelectionSetting.palette.value
                    let ditherMethod = ditherMethodSetting.ditherMethod.value
                    let result = try ditheringEngine.dither(usingMethod: ditherMethod, andPalette: palette, withDitherMethodSettings: additionalDitherMethodSetting.settingsConfiguration, withPaletteSettings: additionalPalleteSettings.settingsConfiguration)
                    
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
                    print(error)
                    //assertionFailure()
                }
            }
        }
        
    }
}
