//
//  makeDidChangePublisher.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//

import Combine

func makeDidChangePublisher(from views: [any SettingView]) -> (publisher: AnyPublisher<Any, Never>, cancellables: Set<AnyCancellable>) {
    var cancellables = Set<AnyCancellable>()
    let publisher = Publishers.MergeMany(views.map { $0.publisher(cancellables: &cancellables) })
        .eraseToAnyPublisher()
    
    return (publisher, cancellables)
}
