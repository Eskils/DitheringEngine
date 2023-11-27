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
    
    @State var selection: MediaFormat?
    @State var selectedImage: UIImage? = nil
    @State var showImagePicker = false
    @State var showFilePicker = false
    
    @State var exportURL: URL?
    
    @State var error: Error?
    @State var showErrorAlert = false
    
    @State var isExporting = false
    @State var exportProgress: Float = 0
    
    let percentFormat = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        return numberFormatter
    }()
    
    @State var ditherMethod: DitherMethod = .none
    
    @ObservedObject
    var viewModel: ViewModel
    
    @MainActor
    init(ditheringEngine: DitheringEngine, videoDitheringEngine: VideoDitheringEngine, appState: AppState) {
        self.viewModel = ViewModel(ditheringEngine: ditheringEngine, videoDitheringEngine: videoDitheringEngine, appState: appState)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(.ditheringEngineLogo)
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("Dithering Engine")
                .font(.title)
                .bold()
            
            Text("Choose an image or a video to dither")
                .font(.body)
                .foregroundStyle(Color(UIColor.secondaryLabel))
            
            VStack(spacing: 16) {
                Button(action: didPressChooseImage) {
                    Label(title: { Text("Choose from Photos") },
                          icon: SF.photo.on.rectangle.swiftUIImage)
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button(action: didPressChooseImageFromFile) {
                    Label(title: { Text("Choose from file") },
                          icon: SF.folder.swiftUIImage)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            
            Divider()
            
            VStack {
                Text("Dithering")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                SettingsView(fromDescriptions: viewModel.ditherMethodSetting.views)
                
                SettingsView(fromDescriptions: viewModel.additionalDitherMethodSetting.views)
            }
            
            Divider()
            
            VStack() {
                Text("Palette")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                SettingsView(fromDescriptions: viewModel.paletteSelectionSetting.views)
                
                SettingsView(fromDescriptions: viewModel.additionalPaletteSelectionSetting.views)
            }
            
            Divider()
            
            VStack {
                Button { didPressExport() } label: {
                    Label(title: { Text(viewModel.isInVideoMode ? "Export dithered video" : "Export dithered image") },
                          icon: SF.square.and.arrow.up.swiftUIImage)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .foregroundStyle(Color.white)
                
                if isExporting {
                    HStack {
                        ProgressView("Export progress", value: exportProgress)
                        Text(percentFormat.string(for: exportProgress) ?? "--")
                    }
                }
                
            }
        }
        .padding(8)
        .onChange(of: selection) { didChoose(media: $0) }
        .sheet(isPresented: $showImagePicker) { ImagePicker(selection: $selection) }
        .sheet(isPresented: $showFilePicker) { DocumentPicker(selection: $selection) }
        .sheet(item: $exportURL) { url in
            DocumentExporter(exporting: url)
        }
        .alert("An error occured", isPresented: $showErrorAlert, actions: {
            Button(action: {}) {
                Text("Ok")
            }
        }, message: {
            Text(error?.localizedDescription ?? "--")
        })
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
        guard let image = UIImage(named: "Bergen") else {
            return
        }
        
        self.selection = .image(image)
    }
    
    @MainActor
    func refreshDithering(sending uselessValue: Any) {
        viewModel.performDithering()
    }
    
    @MainActor
    func didChoose(media: MediaFormat?) {
        guard let media else {
            return
        }
        
        switch media {
        case .image(let image):
            didChoose(image: image)
        case .video(let videoURL):
            viewModel.handleNew(video: videoURL)
        }
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
        self.exportProgress = 0
        if viewModel.isInVideoMode {
            exportVideo()
        } else {
            exportImage()
        }
    }
    
    private func exportImage() {
        guard
            let image = viewModel.appState.finalImage?.toUIImage(),
            let imageData = image.pngData()
        else {
            return
        }
        
        do {
            let url = try documentUrlForFile(withName: "DitheredImage.png", storing: imageData)
            exportURL = url
        } catch {
            print("Could not export: ", error)
            self.error = error
            self.showErrorAlert = true
        }
        
    }
    
    private func exportVideo() {
        withAnimation {
            self.isExporting = true
        }
        
        viewModel.ditherVideo(
            name: "DitheredVideo.mp4",
            progressHandler: didProcessVideo(withProgress:),
            completionHandler: didFinishProcessingVideo(withResult:)
        )
    }
    
    private func didProcessVideo(withProgress progress: Float) {
        self.exportProgress = progress
    }
    
    private func didFinishProcessingVideo(withResult result: Result<URL, Error>) {
        withAnimation {
            self.isExporting = false
        }
        
        switch result {
        case .success(let url):
            exportURL = url
        case .failure(let error):
            self.error = error
            self.showErrorAlert = true
        }
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

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}
