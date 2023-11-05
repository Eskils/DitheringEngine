//
//  Numeric+Extension.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Numeric {
    
    func add1IfZero() -> Self {
        if self == .zero {
            return 1
        }
        
        return self
    }
    
}
