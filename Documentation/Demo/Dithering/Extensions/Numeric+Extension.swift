//
//  Numeric+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//


extension Numeric {
    
    func add1IfZero() -> Self {
        if self == .zero {
            return 1
        }
        
        return self
    }
    
}
