//
//  SettingView.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 31/08/2023.
//

import SwiftUI
import Combine
import DitheringEngine
import SafeSanFrancisco
import UniformTypeIdentifiers

protocol SettingView: Identifiable, ViewConstructable {
    associatedtype T
    var subject: CurrentValueSubject<T, Never> { get }
    var id: String { get }
    
    func makeView() -> AnyView
    func publisher(cancellables: inout Set<AnyCancellable>) -> CurrentValueSubject<Any, Never>
}

protocol ViewConstructable {
    
    @ViewBuilder
    func makeView() -> AnyView
}

extension SettingView {
    func publisher(cancellables: inout Set<AnyCancellable>) -> CurrentValueSubject<Any, Never> {
        pipingCVSToAnyForward(subject, storingIn: &cancellables)
    }
}

protocol RepresentableAsFloatingPoint {
    init(floatingPoint: Double)
    func toDouble() -> Double
}

extension Double: RepresentableAsFloatingPoint {
    func toDouble() -> Double {
        return self
    }
    
    init(floatingPoint: Double) {
        self = floatingPoint
    }
}

extension Int: RepresentableAsFloatingPoint {
    func toDouble() -> Double {
        return Double(self)
    }
    
    init(floatingPoint: Double) {
        self = Int(floatingPoint)
    }
}

extension Float: RepresentableAsFloatingPoint {
    func toDouble() -> Double {
        return Double(self)
    }
    
    init(floatingPoint: Double) {
        self = Float(floatingPoint)
    }
}

struct NumberSettingViewDescription<Number: RepresentableAsFloatingPoint>: SettingView, ViewConstructable, Identifiable {
    let id = UUID().uuidString
    
    let subject: CurrentValueSubject<Number, Never>
    let title: String
    
    let min: Number
    let max: Number
    
    func makeView() -> AnyView {
        AnyView(NumberSettingView(description: self))
    }
}

struct NumberSettingView<Number: RepresentableAsFloatingPoint>: View {
    
    let description: NumberSettingViewDescription<Number>
    
    @State
    var state: Double
    
    init(description: NumberSettingViewDescription<Number>) {
        self.description = description
        self._state = State(wrappedValue: description.subject.value.toDouble())
    }
    
    var body: some View {
        let bindedValue = binding(_state) { val in
            self.description.subject.send(Number.init(floatingPoint: val))
        }
        
        VStack {
            TitleLabel(title: description.title)
                .frame(maxWidth: .infinity)
            
            HStack {
                Slider(value: bindedValue, in: description.min.toDouble()...description.max.toDouble()) {
                    Text(description.title)
                }
                Text(Int(state).formatted())
            }
        }
    }
    
}

struct EnumSettingViewDescription<Enum: Nameable>: SettingView, ViewConstructable, Identifiable {
    let id = UUID().uuidString
    
    let subject: CurrentValueSubject<Enum, Never>
    let title: String
    let options: [Enum]
    
    func makeView() -> AnyView {
        AnyView(EnumSettingView(description: self))
    }
}

struct TitleLabel: View {
    
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(UIColor.tertiaryLabel.toColor())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

struct EnumSettingView<Enum: Nameable>: View {
    
    let description: EnumSettingViewDescription<Enum>
    
    @State
    var state: Enum
    
    init(description: EnumSettingViewDescription<Enum>) {
        self.description = description
        self._state = State(wrappedValue: description.subject.value)
    }
    
    var body: some View {
        let bindedValue = binding(_state) { val in
            self.description.subject.send(val)
        }
        
        VStack {
            #if !targetEnvironment(macCatalyst)
            TitleLabel(title: description.title)
                .frame(maxWidth: .infinity)
            #endif
            
            Picker(description.title, selection: bindedValue) {
                ForEach(description.options) { option in
                    Text(option.title).tag(option)
                }
            }
        }
    }
    
}

struct MatrixInputSettingViewDescription: SettingView, ViewConstructable, Identifiable {
    let id = UUID().uuidString
    
    let subject: CurrentValueSubject<[Int], Never>
    let title: String
    
    let a: CurrentValueSubject<String, Never>
    let b: CurrentValueSubject<String, Never>
    let c: CurrentValueSubject<String, Never>
    let d: CurrentValueSubject<String, Never>
    
    let cancellables: Set<AnyCancellable>
    
    init(matrix: CurrentValueSubject<[Int], Never>, title: String) {
        var cancellables = Set<AnyCancellable>()
        
        self.title = title
        
        self.a = CurrentValueSubject(matrix.value[0].formatted())
        self.b = CurrentValueSubject(matrix.value[1].formatted())
        self.c = CurrentValueSubject(matrix.value[2].formatted())
        self.d = CurrentValueSubject(matrix.value[3].formatted())
        
        self.subject = matrix
        Publishers.CombineLatest4(a, b, c, d)
            .map { [$0, $1, $2, $3].map { Int($0) ?? 0 } }
            .sink { array in
                matrix.send(array)
            }
            .store(in: &cancellables)
        
        self.cancellables = cancellables
    }
    
    func makeView() -> AnyView {
        AnyView(MatrixInputSettingView(description: self))
    }
}

struct MatrixInputSettingView: View {
    
    let description: MatrixInputSettingViewDescription
    
    @State var a: String
    @State var b: String
    @State var c: String
    @State var d: String
    
    init(description: MatrixInputSettingViewDescription) {
        self.description = description
        
        self._a = State(wrappedValue: description.a.value)
        self._b = State(wrappedValue: description.b.value)
        self._c = State(wrappedValue: description.c.value)
        self._d = State(wrappedValue: description.d.value)
    }
    
    var body: some View {
        
        VStack {
            TitleLabel(title: description.title)
            
            HStack {
                TextField("a", text: binding(_a, withChangeHandler: { description.a.send($0) } ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                TextField("b", text: binding(_b, withChangeHandler: { description.b.send($0) } ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
            }
            
            HStack {
                TextField("c", text: binding(_c, withChangeHandler: { description.c.send($0) } ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                TextField("d", text: binding(_d, withChangeHandler: { description.d.send($0) } ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
            }
        }
        
    }
    
}


struct CustomPaletteSettingViewDescription: SettingView, ViewConstructable, Identifiable {
    let id = UUID().uuidString
    
    let subject: CurrentValueSubject<BytePalette, Never>
    let title: String
    
    init(palette: CurrentValueSubject<BytePalette, Never>, title: String) {
        self.title = title
        self.subject = palette
    }
    
    func makeView() -> AnyView {
        AnyView(CustomPaletteSettingView(description: self))
    }
}

struct CustomPaletteSettingView: View {
    
    let description: CustomPaletteSettingViewDescription
    
    init(description: CustomPaletteSettingViewDescription) {
        self.description = description
    }
    
    @State
    var colors: [Color] = [.black, .white]
    
    var body: some View {
        
        LazyVGrid(columns: [GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80))], content: {
            ForEach(0..<colors.count, id: \.self) { i in
                let color = $colors[i]
                ColorPicker("", selection: color)
            }
            Button(action: addColorPicker) {
                SF.plus.swiftUIImage()
            }
        })
        .onReceive($colors.publisher, perform: { _ in
            didChangeColor()
        })
        
    }
    
    private func addColorPicker() {
        colors.append(Color.gray)
    }
    
    private func didChangeColor() {
        let entries = colors.map {
            let color = UIColor($0)
            
            var redDouble: CGFloat = 0
            var greenDouble: CGFloat = 0
            var blueDouble: CGFloat = 0
            
            color.getRed(&redDouble, green: &greenDouble, blue: &blueDouble, alpha: nil)
            
            let red = UInt8(clamp(redDouble * 255, min: 0, max: 255))
            let green = UInt8(clamp(greenDouble * 255, min: 0, max: 255))
            let blue = UInt8(clamp(blueDouble * 255, min: 0, max: 255))
            
            return SIMD3(x: red, y: green, z: blue)
        }
        let collection = LUTCollection<UInt8>(entries: entries)
        let palette = BytePalette.from(lutCollection: collection)
        
        description.subject.send(palette)
    }
    
}

struct CustomImageSettingViewDescription: SettingView, ViewConstructable, Identifiable {
    let id = UUID().uuidString
    
    let subject: CurrentValueSubject<CGImage?, Never>
    let title: String
    
    init(image: CurrentValueSubject<CGImage?, Never>, title: String) {
        self.title = title
        self.subject = image
    }
    
    func makeView() -> AnyView {
        AnyView(CustomImageSettingView(description: self))
    }
}

struct CustomImageSettingView: View {
    
    let description: CustomImageSettingViewDescription
    
    @State var selection: MediaFormat?
    
    @State
    private var patternImage: UIImage?
    
    @State
    private var showPhotoPicker = false
    
    @State
    private var showDocumentPicker = false
    
    @State
    private var showPickPhotoActionSheet = false
    
    var body: some View {
        HStack {
            Image(uiImage: patternImage ?? UIImage())
                .resizable()
                .frame(width: 100, height: 100)
                .background(Color.gray)
                .border(Color.black)
            
            Button {
                showPickPhotoActionSheet = true
            } label: {
                Text("Choose image")
            }

        }
        .sheet(isPresented: $showPhotoPicker, content: {
            ImagePicker(selection: $selection)
        })
        .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.image], onCompletion: { result in
            switch result {
            case .success(let url):
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    self.patternImage = image
                }
            case .failure(let error):
                print(error)
            }
        })
        .confirmationDialog("Choose image", isPresented: $showPickPhotoActionSheet) {
            Button("Choose from photos") {
                showPhotoPicker = true
            }
            
            Button("Choose from files") {
                showDocumentPicker = true
            }
        }
        .onChange(of: selection, perform: { mediaFormat in
            guard let mediaFormat else {
                return
            }
            
            switch mediaFormat {
            case .image(let image):
                self.patternImage = image
            case .video(_):
                print("Videos are not supported as patterns")
                break
            }
        })
        .onChange(of: patternImage, perform: { patternImage in
            guard 
                let patternImage,
                let cgImage = patternImage.cgImage
            else {
                return
            }
            
            self.description.subject.send(cgImage)
        })
        .onAppear(perform: {
            self.patternImage = UIImage(named: "bluenoise")
        })
    }
}

struct BooleanSettingViewDescription: SettingView, ViewConstructable, Identifiable {
    let id = UUID().uuidString
    
    let subject: CurrentValueSubject<Bool, Never>
    let title: String
    
    init(isOn: CurrentValueSubject<Bool, Never>, title: String) {
        self.title = title
        self.subject = isOn
    }
    
    func makeView() -> AnyView {
        AnyView(BooleanSettingView(description: self))
    }
}

struct BooleanSettingView: View {
    
    let description: BooleanSettingViewDescription
    
    @State
    var state: Bool
    
    init(description: BooleanSettingViewDescription) {
        self.description = description
        self._state = State(wrappedValue: description.subject.value)
    }
    
    var body: some View {
        let bindedValue = binding(_state) { val in
            self.description.subject.send(val)
        }
                    
        Toggle(isOn: bindedValue) {
            Text(description.title)
        }
    }
    
}
