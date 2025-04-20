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
    @State var selectedImage: PlatformImage? = nil
    @State var showImagePicker = false
    @State var showFilePicker = false
    
    #if canImport(AppKit)
    @State var showFileExporter = false
    #endif
    @State var exportURL: URL? {
        didSet {
        #if canImport(AppKit)
            showFileExporter = exportURL != nil
        #endif
        }
    }
    
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
                .foregroundColor(Color.secondary)
            
            VStack(spacing: 16) {
                #if canImport(UIKit)
                Button(action: didPressChooseImage) {
                    Label(title: { Text("Choose from Photos") },
                          icon: SF.photo.on.rectangle.swiftUIImage)
                }
                .buttonStyle(BorderedButtonStyle())
                #endif
                
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
                Text("Image options")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Toggle(isOn: $viewModel.preserveTransparency) {
                    Text("Preserve transparency")
                }
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
        #if canImport(UIKit)
        .sheet(isPresented: $showImagePicker) { ImagePicker(selection: $selection) }
        .sheet(isPresented: $showFilePicker) { DocumentPicker(selection: $selection) }
        .sheet(item: $exportURL) { url in
            DocumentExporter(exporting: url)
        }
        #elseif canImport(AppKit)
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image, .video, .mpeg4Movie, .movie]) { result in
            switch result {
            case .success(let url):
                if let data = try? Data(contentsOf: url),
                   let image = PlatformImage(data: data) {
                    self.selection = .image(image)
                } else {
                    self.selection = .video(url)
                }
            case .failure(let error):
                print(error)
            }
        }
        .fileMover(isPresented: $showFileExporter, file: exportURL) { result in
            switch result {
            case .success(let url):
                break
            case .failure(let error):
                print(error)
            }
        }
        #endif
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
        guard let image = PlatformImage(named: "Bergen") else {
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
    func didChoose(image: PlatformImage) {
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
        let imageData = NSMutableData()
        
        guard
            let image = viewModel.appState.finalImage,
            let imageDestination = CGImageDestinationCreateWithData(imageData as CFMutableData, "public.png" as CFString, 1, nil)
        else {
            return
        }
        
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        
        do {
            let url = try documentUrlForFile(withName: "DitheredImage.png", storing: imageData as Data)
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
    
    private func didProcessVideo(withProgress progress: Float) -> Bool {
        self.exportProgress = progress
        return true
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
        #if canImport(UIKit)
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
        #endif
    }
    
}

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}
