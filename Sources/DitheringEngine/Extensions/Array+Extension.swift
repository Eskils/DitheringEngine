//
//  Array+Extension.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

extension Array where Element: Numeric {
    
    func sum() -> Element {
        self.reduce(.zero) { partialResult, value in
            partialResult + value
        }
    }
    
}
