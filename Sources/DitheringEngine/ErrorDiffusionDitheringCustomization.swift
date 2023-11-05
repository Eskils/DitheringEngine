//
//  ErrorDiffusionDitheringCustomization.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

protocol ErrorDiffusionDitheringCustomization {
    var isYDirection: Bool { get }
    func index(forX x: Int, y: Int, width: Int, andHeight height: Int) -> Int
    func offsetsWith(matrix: [Int], andWidth w: Int) -> [(offset: Int, weight: Float)]
}
