//
//  pipingCVSToAnyForward.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import Combine

func pipingCVSToAnyForward<T>(_ cvs: CurrentValueSubject<T, Never>, storingIn cancellables: inout Set<AnyCancellable>) -> CurrentValueSubject<Any, Never> {
    
    let erasedCvs = CurrentValueSubject<Any, Never>(cvs.value)
    
    cvs.sink { val in
        erasedCvs.send(val)
    }
    .store(in: &cancellables)
    
    return erasedCvs
}
