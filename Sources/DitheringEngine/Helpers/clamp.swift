//
//  clamp.swift
//
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

/// Clamps the value between `min` and `max`.
func clamp<T: Numeric>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable {
    return min(maxValue, max(value, minValue))
}

/// Clamps the value between `0` and `1`.
func clampDecimal<T: BinaryFloatingPoint>(_ value: T) -> T {
    return min(1, max(value, 0))
}
