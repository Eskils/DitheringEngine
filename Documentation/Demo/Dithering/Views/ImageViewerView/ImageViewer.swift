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
    
    init(appState: AppState) {
        self._appState = StateObject(wrappedValue: appState)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    Image(uiImage: mergedImage(geo: geo, rect: imageRect, originalImage: appState.originalImage, finalImage: appState.finalImage, shouldShowOriginalImage: shouldShowOriginalImage, isRunning: appState.isRunning))
                        .resizable()
                        .interpolation(.none)
                        .blur(radius: blurRadius(renderSize: geo, imageFrame: imageRect))
                        .frame(width: geo.size.width, height: geo.size.height)
                        .gesture(
                            DragGesture().simultaneously(with: MagnificationGesture())
                                .onChanged(shouldTransformImage(gestureResult:))
                                .onEnded(commitTransformImage(gestureResult:))
                        )
                }
                .overlay {
                    if appState.isRunning {
                        ProgressView()
                            .tint(.white)
                            .position(x: imageSplitWidth(geo: geo), y: imageRect.minY + geo.size.height / 2)
                    }
                }
                
                VStack(spacing: 20) {
                    Button(action: {},
                           label: {
                        SF.square.split._2x1.swiftUIImage()
                            .resizable()
                            .frame(width: 25, height: 25)
                    })
                    ._onButtonGesture(pressing: didPressShowOriginal(showOriginal:), perform: {})
                    
                    Button(action: didPressMoveToHome) {
                        SF.house.swiftUIImage()
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                
            }.background(Color(UIColor.systemGray6))
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
    
    func mergedImage(geo: GeometryProxy, rect: CGRect, originalImage: CGImage?, finalImage: CGImage?, shouldShowOriginalImage: Bool, isRunning: Bool) -> UIImage {
        var img: UIImage!
        if shouldShowOriginalImage {
            img = originalImage?.toUIImage() ?? UIImage()
        } else {
            img = finalImage?.toUIImage() ?? UIImage()
        }
        
        let pos = CGPoint(x: imageRect.minX * imageScale() + (geo.size.width / 2), y: imageRect.minY * imageScale() + (geo.size.height / 2))
        
        return renderImageInPlace(img, renderSize: geo.size, imageFrame: CGRect(origin: pos, size: rect.size), isRunning: isRunning)
    }
    
    func blurRadius(renderSize: GeometryProxy, imageFrame: CGRect) -> CGFloat {
        let scale = imageFrame.width / renderSize.size.width
        
        if scale > 1 {
            return 0
        }
        
        if scale > 0.8 {
            return 0.5
        }
        
        if scale > 0.6 {
            return 0.7
        }
        
        if scale <= 0.6 {
            return 1
        }
        
        return 0
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
