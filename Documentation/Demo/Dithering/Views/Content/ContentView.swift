import SwiftUI
import Combine
import DitheringEngine

struct ContentView: View {
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    let ditheringEngine: DitheringEngine
    let videoDitheringEngine: VideoDitheringEngine
    
    let appState = AppState()
    
    init() {
        self.ditheringEngine = DitheringEngine()
        self.videoDitheringEngine = VideoDitheringEngine()
    }
    
    @State var finalImage: UIImage?
    
    @State var cancellables = Set<AnyCancellable>()
    
    let ditherMethodSetting = DitherMethod.setting
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        macCatalystLayout()
        #else
        if horizontalSizeClass == .regular {
            regularRegularLayout()
        } else {
            regularCompactLayout()
        }
        #endif
    }
    
    @MainActor
    @ViewBuilder
    func macCatalystLayout() -> some View {
        NavigationView {
            ToolbarView(ditheringEngine: ditheringEngine, videoDitheringEngine: videoDitheringEngine, appState: appState)
                .frame(width: 300)
                .listStyle(.sidebar)
            
            ImageViewerView(appState: appState)
        }
    }
    
    @MainActor
    @ViewBuilder
    func regularRegularLayout() -> some View {
        HStack {
            ToolbarView(ditheringEngine: ditheringEngine, videoDitheringEngine: videoDitheringEngine, appState: appState)
                .frame(width: 300)
            
            ImageViewerView(appState: appState)
        }
    }
    
    @MainActor
    @ViewBuilder
    func regularCompactLayout() -> some View {
        ScrollView {
            VStack {
                ImageViewerView(appState: appState)
                    .aspectRatio(1, contentMode: .fit)
                
                ToolbarView(ditheringEngine: ditheringEngine, videoDitheringEngine: videoDitheringEngine, appState: appState)
            }
        }
    }
    
}
