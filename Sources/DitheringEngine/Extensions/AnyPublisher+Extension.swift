//
//  AnyPublisher+Extension.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Combine

extension AnyPublisher {
    
    static func empty() -> AnyPublisher<Any, Never> {
        CurrentValueSubject<Any, Never>(0).eraseToAnyPublisher()
    }
    
}
