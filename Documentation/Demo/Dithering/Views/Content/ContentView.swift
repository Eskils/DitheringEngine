import SwiftUI
import Combine
import DitheringEngine

struct ContentView: View {
    
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
        HStack {
            ToolbarView(ditheringEngine: ditheringEngine, videoDitheringEngine: videoDitheringEngine, appState: appState)
            .frame(width: 300)
            
            ImageViewerView(appState: appState)
        }
    }
    
    
}
