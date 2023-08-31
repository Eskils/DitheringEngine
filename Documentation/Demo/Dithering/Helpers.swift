//
//  Helpers.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 31/08/2023.
//

import Foundation
import Combine
import SwiftUI

extension CurrentValueSubject {
  var binding: Binding<Output> {
    Binding(get: {
      self.value
    }, set: {
      self.send($0)
    })
  }
}

func binding<T>(_ variable: State<T>, withChangeHandler handler: @escaping (T)->Void) -> Binding<T> {
    let binding = Binding<T> {
        return variable.wrappedValue
    } set: { val in
        variable.wrappedValue = val
        handler(val)
    }

    return binding
}

func pipingCVSToAny<T>(_ cvs: CurrentValueSubject<T, Never>, storingIn cancellables: inout Set<AnyCancellable>) -> CurrentValueSubject<Any, Never> {
    
    let erasedCvs = CurrentValueSubject<Any, Never>(cvs.value)
    
    erasedCvs.sink { val in
        if let val = val as? T {
            cvs.send(val)
        }
    }
    .store(in: &cancellables)
    
    return erasedCvs
}

func pipingCVSToAnyForward<T>(_ cvs: CurrentValueSubject<T, Never>, storingIn cancellables: inout Set<AnyCancellable>) -> CurrentValueSubject<Any, Never> {
    
    let erasedCvs = CurrentValueSubject<Any, Never>(cvs.value)
    
    cvs.sink { val in
        erasedCvs.send(val)
    }
    .store(in: &cancellables)
    
    return erasedCvs
}


extension AnyPublisher {
    
    static func empty() -> AnyPublisher<Any, Never> {
        CurrentValueSubject<Any, Never>(0).eraseToAnyPublisher()
    }
    
}

extension UIColor {
    func toColor() -> Color {
        Color(uiColor: self)
    }
}

func documentUrlForFile(withName name: String, storing data: Data) throws -> URL {
    let fs = FileManager.default
    let documentDirectoryUrl = try fs.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileUrl = documentDirectoryUrl.appendingPathComponent(name)
    
    try data.write(to: fileUrl)
    
    return fileUrl
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = scene?.windows.first
        let uiInsets = window?.safeAreaInsets ?? .zero
        return EdgeInsets(top: uiInsets.top, leading: uiInsets.left, bottom: uiInsets.bottom, trailing: uiInsets.right)
    }
}

extension EnvironmentValues {
    
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension CGImage {
    func toUIImage() -> UIImage {
        UIImage(cgImage: self)
    }
    
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

extension UIImage {
    func blur(radius: CGFloat) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let context = CIContext()
        let input = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: "inputRadius")
        guard let result = filter.value(forKey: kCIOutputImageKey) as? CIImage,
              let resCG = context.createCGImage(result, from: input.extent)
        else { return nil }
        return UIImage(cgImage: resCG)
    }
}

func renderImageInPlace(_ image: UIImage, renderSize: CGSize, imageFrame: CGRect, isRunning: Bool) -> UIImage {
    var image = image
    
    if isRunning {
        image = image.blur(radius: 5) ?? image
    }
    
    let renderer = UIGraphicsImageRenderer(size: renderSize)
    
    let frame = CGRect(x: imageFrame.minX - imageFrame.width / 2, y: imageFrame.minY - imageFrame.height / 2, width: imageFrame.width, height: imageFrame.height)
    
    let result = renderer.image { _ in
        image.draw(in: frame)
    }
    
    return result
}

extension Array where Element: Numeric {
    
    func sum() -> Element {
        self.reduce(.zero) { partialResult, value in
            partialResult + value
        }
    }
    
}

extension Numeric {
    
    func add1IfZero() -> Self {
        if self == .zero {
            return 1
        }
        
        return self
    }
    
}

func makeDidChangePublisher(from views: [any SettingView]) -> (publisher: AnyPublisher<Any, Never>, cancellables: Set<AnyCancellable>) {
    var cancellables = Set<AnyCancellable>()
    let publisher = Publishers.MergeMany(views.map { $0.publisher(cancellables: &cancellables) })
        .eraseToAnyPublisher()
    
    return (publisher, cancellables)
}

/// Clamps the value between `min` and `max`.
func clamp<T: Numeric>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable {
    return min(maxValue, max(value, minValue))
}
