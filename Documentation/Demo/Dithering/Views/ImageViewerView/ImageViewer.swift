//
//  ImageViewerView.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 05/12/2022.
//

import SwiftUI
import SafeSanFrancisco

struct ImageViewerView: View {
    
    @StateObject var appState: AppState

    @State var shouldUpdateMergedImage = false
    
    @State var imageScaleTemp: CGSize = .zero
    @State var prevPos: CGSize = .zero
    @State var imageRect: CGRect = .zero
    
    @State var hasSetInitialSize: Bool = false
    
    @State var shouldShowOriginalImage: Bool = false
    
    @Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(appState: AppState) {
        self._appState = StateObject(wrappedValue: appState)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    if let image = mergedImage(
                        geo: geo,
                        rect: imageRect,
                        originalImage: appState.originalImage,
                        finalImage: appState.finalImage,
                        shouldShowOriginalImage: shouldShowOriginalImage,
                        isRunning: appState.isRunning
                    ) {
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .gesture(
                                DragGesture().simultaneously(with: MagnificationGesture())
                                    .onChanged(shouldTransformImage(gestureResult:))
                                    .onEnded(commitTransformImage(gestureResult:))
                            )
                    }
                }
                .overlay {
                    if appState.isRunning {
                        ProgressView()
                            .tint(.white)
                            .position(x: imageSplitWidth(geo: geo), y: imageRect.minY + geo.size.height / 2)
                    }
                }
                
                VStack(spacing: 20) {
                    Button(action: { shouldShowOriginalImage = !shouldShowOriginalImage },
                           label: {
                        (shouldShowOriginalImage
                            ? SF.square.and.line.vertical.and.square.filled.swiftUIImage()
                            : SF.square.and.line.vertical.and.square.swiftUIImage())
                            .resizable()
                            .frame(width: 25, height: 25)
                    })
                    #if !targetEnvironment(macCatalyst)
                    .tint(.white)
                    .buttonStyle(BorderedProminentButtonStyle())
                    .foregroundStyle(Color.accentColor)
                    #endif
                    
                    Button(action: didPressMoveToHome) {
                        SF.house.swiftUIImage()
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                    #if !targetEnvironment(macCatalyst)
                    .tint(.white)
                    .buttonStyle(BorderedProminentButtonStyle())
                    .foregroundStyle(Color.accentColor)
                    #endif
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                .padding(.top, 16)
                
            }
            .background(Material.ultraThin)
        }
        .onReceive(appState.$originalImage, perform: didChange(image:))
    }
    
    func imageScale() -> CGFloat {
        let originalSize = appState.originalImage?.size.width ?? 400
        return imageRect.width / originalSize
    }
    
    func getAspectRatio(forImage image: CGImage?) -> CGFloat {
        guard let image else {
            return 1
        }
        
        let width = image.size.width
        let height = image.size.height
        
        return width / height
    }
    
    func imageSplitWidth(geo: GeometryProxy) -> CGFloat {
        let imgStart = imageRect.minX + geo.size.width / 2
        let wid = (imageRect.width / 2) - imgStart
        return max(geo.size.width / 2, (wid / 2))
    }
    
    func mergedImage(geo: GeometryProxy, rect: CGRect, originalImage: CGImage?, finalImage: CGImage?, shouldShowOriginalImage: Bool, isRunning: Bool) -> CGImage? {
        let image = shouldShowOriginalImage ? originalImage : finalImage
        
        let pos = CGPoint(
            x: imageRect.minX * imageScale() + (geo.size.width / 2),
            y: geo.size.height - (imageRect.minY * imageScale() + (geo.size.height / 2))
        )
        
        return renderImageInPlace(image, renderSize: geo.size, imageFrame: CGRect(origin: pos, size: rect.size), isRunning: isRunning)
    }
    
    func shouldTransformImage(gestureResult: SimultaneousGesture<DragGesture, MagnificationGesture>.Value) {
        
        let drag = gestureResult.first
        let newScale = gestureResult.second ?? 1
        
        imageRect.size.width = imageScaleTemp.width * newScale
        imageRect.size.height = imageScaleTemp.height * newScale
        let scale = imageScale()
        
        let pos = drag?.translation ?? .zero
        imageRect.origin.x += (pos.width - prevPos.width) / scale
        imageRect.origin.y += (pos.height - prevPos.height) / scale
        prevPos = pos
        
        shouldUpdateMergedImage.toggle()
    }
    
    func commitTransformImage(gestureResult: SimultaneousGesture<DragGesture, MagnificationGesture>.Value) {
        
        imageScaleTemp = imageRect.size
        prevPos = .zero
        shouldUpdateMergedImage.toggle()
    }
    
    func didChange(image: CGImage?) {
        guard let image else {
            return
        }
        
        imageRect.size = image.size
        imageScaleTemp = image.size
        
        if !hasSetInitialSize {
            hasSetInitialSize = true
        }
    }
    
    func didPressShowOriginal(showOriginal: Bool) {
        shouldShowOriginalImage = showOriginal
    }
    
    func didPressMoveToHome() {
        imageRect.size = appState.originalImage?.size ?? .zero
        imageScaleTemp = appState.originalImage?.size ?? .zero
        prevPos = .zero
        imageRect.origin = .zero
        shouldUpdateMergedImage.toggle()
    }
}
