//
//  Nameable.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

public protocol Nameable: CaseIterable, Hashable, Identifiable {
    var title: String { get }
}
