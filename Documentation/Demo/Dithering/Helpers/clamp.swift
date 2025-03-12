//
//  clamp.swift
//  Dithering
//
//  Created by Eskil Gjerde Sviggum on 11/03/2025.
//


/// Clamps the value between `min` and `max`.
func clamp<T: Numeric>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable {
    return min(maxValue, max(value, minValue))
}
