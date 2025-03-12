//
//  AnyPublisher+Extension.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import Combine

extension AnyPublisher {

    static func empty() -> AnyPublisher<Any, Never> {
        CurrentValueSubject<Any, Never>(0).eraseToAnyPublisher()
    }
    
}
