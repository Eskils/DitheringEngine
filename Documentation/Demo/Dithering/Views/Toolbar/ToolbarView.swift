//
//  ToolbarView.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 06/12/2022.
//

import SafeSanFrancisco
import SwiftUI
import DitheringEngine

struct ToolbarView: View {
    
    @State var selectedImage: UIImage? = nil
    @State var showImagePicker = false
    @State var showFilePicker = false
    
    @State var ditherMethod: DitheringEngine.DitherMethod = .none
    
    @ObservedObject
    var viewModel: ViewModel
    
    @MainActor
    init(ditheringEngine: DitheringEngine, appState: AppState) {
        self._viewModel = ObservedObject(
            wrappedValue: ViewModel(ditheringEngine: ditheringEngine, appState: appState)
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Dithering Engine")
                .font(.title)
                .bold()
            
            VStack(spacing: 16) {
                Button(action: didPressChooseImage) {
                    Label(title: { Text("Choose from Photos") },
                          icon: SF.photo.on.rectangle.swiftUIImage)
                }
                
                Button(action: didPressChooseImageFromFile) {
                    Label(title: { Text("Choose from file") },
                          icon: SF.photo.on.rectangle.swiftUIImage)
                }
                
                Button { didPressExport() } label: {
                    Label(title: { Text("Export dithered image") },
                          icon: SF.square.and.arrow.up.swiftUIImage)
                }
            }
            
            Divider()
            
            VStack {
                Text("Dithering")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                SettingsView(fromDescriptions: viewModel.ditherMethodSetting.views)
                
                SettingsView(fromDescriptions: viewModel.additionalDitherMethodSetting.views)
            }
            
            Divider()
            
            VStack() {
                Text("Palette")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                SettingsView(fromDescriptions: viewModel.paletteSelectionSetting.views)
                
                SettingsView(fromDescriptions: viewModel.additionalPaletteSelectionSetting.views)
            }
            
        }
        .padding(8)
        .onChange(of: selectedImage ?? UIImage()) { didChoose(image: $0) }
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $selectedImage) }
        .sheet(isPresented: $showFilePicker) { DocumentPicker(image: $selectedImage) }
        .onAppear(perform: didAppear)
        .onReceive(viewModel.ditherMethodSetting.settingsConfiguration.ditherMethod) { _ in viewModel.didChangeDitherMethod() }
        .onReceive(viewModel.paletteSelectionSetting.palette) { _ in viewModel.didChangePalette() }
    }
    
    @ViewBuilder
    func SettingsView(fromDescriptions descriptions: [any SettingView]) -> some View {
        ForEach(0..<descriptions.count, id: \.self) { i in
            let description = descriptions[i]
            description.makeView()
        }
    }
    
    func didPressChooseImage() {
        showImagePicker = true
    }
    
    private func didPressChooseImageFromFile() {
        showFilePicker = true
    }
    
    func didAppear() {
        self.selectedImage = UIImage(named: "Bergen")
    }
    
    @MainActor
    func refreshDithering(sending uselessValue: Any) {
        viewModel.performDithering()
    }
    
    @MainActor
    func didChoose(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return
        }
        
        viewModel.handleNew(image: cgImage)
    }
    
    @MainActor
    func didPressExport() {
        guard
            let image = viewModel.appState.finalImage?.toUIImage(),
            let imageData = image.pngData()
        else {
            return
        }
        
        share(data: imageData, name: "DitheredImage" + ".png")
    }
    
    func share(data: Data, name: String) {
        do {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            guard let root = scene?.windows.first?.rootViewController else { return }
            
            let url = try documentUrlForFile(withName: name, storing: data)
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = root.view
            vc.popoverPresentationController?.sourceRect = .zero
            
            root.present(vc, animated: true)
        } catch {
            print(error)
        }
    }
    
}
