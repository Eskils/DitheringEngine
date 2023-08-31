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

struct NumberSettingViewDescription<Number: BinaryFloatingPoint>: SettingView, ViewConstructable, Identifiable where Number.Stride: BinaryFloatingPoint {
    let id = UUID().uuidString
    
    let subject: CurrentValueSubject<Number, Never>
    let title: String
    
    let min: Number
    let max: Number
    
    func makeView() -> AnyView {
        AnyView(NumberSettingView(description: self))
    }
}

struct NumberSettingView<Number: BinaryFloatingPoint>: View where Number.Stride: BinaryFloatingPoint {
    
    let description: NumberSettingViewDescription<Number>
    
    @State
    var state: Number
    
    init(description: NumberSettingViewDescription<Number>) {
        self.description = description
        self._state = State(wrappedValue: description.subject.value)
    }
    
    var body: some View {
        let bindedValue = binding(_state) { val in
            self.description.subject.send(val)
        }
        
        VStack {
            TitleLabel(title: description.title)
                .frame(maxWidth: .infinity)
            
            HStack {
                Slider(value: bindedValue, in: description.min...description.max) {
                    Text(description.title)
                }
                Text(Int(state).formatted())
            }
        }
    }
    
}

struct EnumSettingViewDescription<Enum: SettingsEnum>: SettingView, ViewConstructable, Identifiable {
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

struct EnumSettingView<Enum: SettingsEnum>: View {
    
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
            TitleLabel(title: description.title)
                .frame(maxWidth: .infinity)
            
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
