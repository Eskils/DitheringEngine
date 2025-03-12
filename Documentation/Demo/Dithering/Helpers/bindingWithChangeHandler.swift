//
//  bindingWithChangeHandler.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import SwiftUI

func binding<T>(_ variable: State<T>, withChangeHandler handler: @escaping (T)->Void) -> Binding<T> {
    let binding = Binding<T> {
        return variable.wrappedValue
    } set: { val in
        variable.wrappedValue = val
        handler(val)
    }

    return binding
}
