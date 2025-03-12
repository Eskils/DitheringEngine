//
//  Array+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//


extension Array where Element: Numeric {
    
    func sum() -> Element {
        self.reduce(.zero) { partialResult, value in
            partialResult + value
        }
    }
    
}
