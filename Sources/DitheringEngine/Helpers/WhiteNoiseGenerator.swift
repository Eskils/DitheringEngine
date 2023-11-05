//
//  WhiteNoiseGenerator.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Foundation

struct WhiteNoiseGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
        
    func next() -> UInt64 {
        return UInt64(drand48() * 0x1.0p64) ^ UInt64(drand48() * 0x1.0p16)
    }
}
