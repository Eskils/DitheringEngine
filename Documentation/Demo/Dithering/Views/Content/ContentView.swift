import SwiftUI
import Combine
import DitheringEngine

struct ContentView: View {
    
    let ditheringEngine = DitheringEngine()
    let appState = AppState()
    
    @State var finalImage: UIImage?
    
    @State var cancellables = Set<AnyCancellable>()
    
    let ditherMethodSetting = DitheringEngine.DitherMethod.setting
    
    var body: some View {
        HStack {
            ToolbarView(ditheringEngine: ditheringEngine, appState: appState)
            .frame(width: 300)
            
            ImageViewerView(appState: appState)
        }
    }
    
    
}
