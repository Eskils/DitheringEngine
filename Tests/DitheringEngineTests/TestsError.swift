//
//  TestsError.swift
//  DitheringEngine
//
//  Created by Eskil Gjerde Sviggum on 06/03/2025.
//

enum TestsError: Error {
    case cannotFindImageResource
    case cannotMakeImageSource
    case cannotMakeCGImageFromData
    case cannotMakeImageDestination
}
