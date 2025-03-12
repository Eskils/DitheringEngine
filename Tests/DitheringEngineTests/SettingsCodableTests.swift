//
//  SettingsCodableTests.swift
//  DitheringEngine
//
//  Created by Eskil Gjerde Sviggum on 06/03/2025.
//

import XCTest
@testable import DitheringEngine

final class SettingsCodableTests: XCTestCase {
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    // MARK: - Encoding settings configurations
    
    func testEncodeApple2SettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            Apple2SettingsConfiguration(mode: .loRes)
        )
        
        let expectedResult = """
        {
          "mode" : "loRes"
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeBayerSettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            BayerSettingsConfiguration(thresholdMapSize: 5, performOnCPU: true)
        )
        
        let expectedResult = """
        {
          "intensity" : 1,
          "performOnCPU" : true,
          "thresholdMapSize" : 5
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeCGASettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            CGASettingsConfiguration(mode: .palette1High)
        )
        
        let expectedResult = """
        {
          "mode" : "palette1High"
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeCustomPaletteSettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            CustomPaletteSettingsConfiguration(entries: [SIMD3(180, 150, 160), SIMD3(255, 255, 255), SIMD3(0, 0, 0)])
        )
        
        let expectedResult = """
        {
          "entries" : [
            [
              180,
              150,
              160
            ],
            [
              255,
              255,
              255
            ],
            [
              0,
              0,
              0
            ]
          ]
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeDitherMethodSettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            DitherMethodSettingsConfiguration(mode: .floydSteinberg)
        )
        
        let expectedResult = """
        {
          "ditherMethod" : "floydSteinberg"
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeEmptySettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            EmptyPaletteSettingsConfiguration()
        )
        
        let expectedResult = """
        {
        
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeFloydSteinbergSettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            FloydSteinbergSettingsConfiguration(direction: .leftToRight, matrix: [7, 3, 5, 1])
        )
        
        let expectedResult = """
        {
          "direction" : "leftToRight",
          "matrix" : [
            7,
            3,
            5,
            1
          ]
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeNoiseSettingsConfiguration() throws {
        let noiseImage = CIImage(color: CIColor(color: .cyan)!)
        let cgImage = CIContext().createCGImage(noiseImage, from: CGRect(x: 0, y: 0, width: 2, height: 2))
        let stringRepresentation = try settingsConfigurationAsJSON(
            NoiseDitheringSettingsConfiguration(noisePattern: cgImage, performOnCPU: true)
        )
        
        let expectedResult = """
        {
          "intensity" : 0.5,
          "noisePattern" : "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAAXNSR0IArs4c6QAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAqADAAQAAAABAAAAAgAAAADO0J6QAAAAE0lEQVQIHWNk+P+fgYGBCYiBAAAXEwICUYYCvQAAAABJRU5ErkJggg==",
          "performOnCPU" : true
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodePaletteSelectionSettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            PaletteSelectionSettingsConfiguration(mode: .bw)
        )
        
        let expectedResult = """
        {
          "palette" : "bw"
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeQuantizedColorSettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            QuantizedColorSettingsConfiguration(bits: 5)
        )
        
        let expectedResult = """
        {
          "bits" : 5
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    func testEncodeWhiteNoiseSettingsConfiguration() throws {
        let stringRepresentation = try settingsConfigurationAsJSON(
            WhiteNoiseSettingsConfiguration(thresholdMapSize: 5, performOnCPU: true)
        )
        
        let expectedResult = """
        {
          "intensity" : 0.5,
          "performOnCPU" : true,
          "thresholdMapSize" : 5
        }
        """
        
        XCTAssertEqual(stringRepresentation, expectedResult)
    }
    
    // MARK: - Decoding settings configurations
    
    func testDecodeApple2SettingsConfiguration() throws {
        let settingsData = """
        {
          "mode" : "loRes"
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: Apple2SettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.mode.value, .loRes)
    }
    
    func testDecodeBayerSettingsConfiguration() throws {
        let settingsData = """
        {
          "intensity" : 0.65,
          "performOnCPU" : true,
          "thresholdMapSize" : 5
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: BayerSettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.performOnCPU.value, true)
        XCTAssertEqual(settingsConfiguration.thresholdMapSize.value, 5)
        XCTAssertEqual(settingsConfiguration.intensity.value, 0.65)
    }
    
    func testDecodeCGASettingsConfiguration() throws {
        let settingsData = """
        {
          "mode" : "palette1High"
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: CGASettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.mode.value, .palette1High)
    }
    
    func testDecodeCustomPaletteSettingsConfiguration() throws {
        let settingsData = """
        {
          "entries" : [
            [
              180,
              150,
              160
            ],
            [
              255,
              255,
              255
            ],
            [
              0,
              0,
              0
            ]
          ]
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: CustomPaletteSettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.palette.value.colors(), [SIMD3(180, 150, 160), SIMD3(255, 255, 255), SIMD3(0, 0, 0)])
    }
    
    func testDecodeDitherMethodSettingsConfiguration() throws {
        let settingsData = """
        {
          "ditherMethod" : "floydSteinberg"
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: DitherMethodSettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.ditherMethod.value, .floydSteinberg)
    }
    
    func testDecodeEmptySettingsConfiguration() throws {
        let settingsData = """
        {
        
        }
        """
        
        _ = try decodeJSONToSettings(
            json: settingsData,
            type: EmptyPaletteSettingsConfiguration.self
        )
    }
    
    func testDecodeFloydSteinbergSettingsConfiguration() throws {
        let settingsData = """
        {
          "direction" : "leftToRight",
          "matrix" : [
            7,
            3,
            5,
            1
          ]
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: FloydSteinbergSettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.direction.value, .leftToRight)
        XCTAssertEqual(settingsConfiguration.matrix.value, [7, 3, 5, 1])
    }
    
    func testDecodeNoiseSettingsConfiguration() throws {
        let noiseImage = CIImage(color: CIColor(color: .cyan)!)
        let cgImage = CIContext().createCGImage(noiseImage, from: CGRect(x: 0, y: 0, width: 2, height: 2))
        
        let settingsData = """
        {
          "noisePattern" : "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAAXNSR0IArs4c6QAAAHhlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAKgAgAEAAAAAQAAAAKgAwAEAAAAAQAAAAIAAAAAUepZGwAAAAlwSFlzAAALEwAACxMBAJqcGAAAABxpRE9UAAAAAgAAAAAAAAABAAAAKAAAAAEAAAABAAAAQg5iYRkAAAAOSURBVBgZYmD4/x+IAAAAAP//l3y8zQAAAAtJREFUY2D4/x+IADPaB/n1SOwrAAAAAElFTkSuQmCC",
          "performOnCPU" : true,
          "intensity": 1.0
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: NoiseDitheringSettingsConfiguration.self
        )
        
        let receivedImage = settingsConfiguration.noisePattern.value
        XCTAssertTrue(try isImagesEqual(expected: cgImage, received: receivedImage))
        XCTAssertEqual(settingsConfiguration.performOnCPU.value, true)
        XCTAssertEqual(settingsConfiguration.intensity.value, 1.0)
    }
    
    
    func testDecodePaletteSelectionSettingsConfiguration() throws {
        let settingsData = """
        {
          "palette" : "bw"
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: PaletteSelectionSettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.palette.value, .bw)
    }
    
    func testDecodeQuantizedColorSettingsConfiguration() throws {
        let settingsData = """
        {
          "bits" : 5
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: QuantizedColorSettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.bits.value, 5)
    }
    
    func testDecodeWhiteNoiseSettingsConfiguration() throws {
        let settingsData = """
        {
          "intensity" : 0.4,
          "performOnCPU" : true,
          "thresholdMapSize" : 5
        }
        """
        
        let settingsConfiguration = try decodeJSONToSettings(
            json: settingsData,
            type: WhiteNoiseSettingsConfiguration.self
        )
        
        XCTAssertEqual(settingsConfiguration.performOnCPU.value, true)
        XCTAssertEqual(settingsConfiguration.thresholdMapSize.value, 5)
        XCTAssertEqual(settingsConfiguration.intensity.value, 0.4)
    }
    
}

private extension SettingsCodableTests {
    func decodeJSONToSettings<T: SettingsConfiguration>(json: String, type: T.Type) throws -> T {
        guard let data = json.data(using: .utf8) else {
            throw NSError(domain: "Cannot make data", code: -1)
        }
        return try decoder.decode(type, from: data)
    }
    
    func settingsConfigurationAsJSON(_ settingsConfiguration: SettingsConfiguration) throws -> String {
        let data = try encoder.encode(settingsConfiguration)
        return try jsonAsPrettyString(data: data)
    }
    
    func jsonAsPrettyString(data: Data) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    func isImagesEqual(expected left: CGImage?, received right: CGImage?) throws -> Bool {
        guard let left, let right else {
            let isBothNil = left == nil && right == nil
            XCTAssertTrue(isBothNil)
            return isBothNil
        }
        
        let isWidthEqual = left.width == right.width
        XCTAssertTrue(isWidthEqual)
        guard isWidthEqual else {
            return false
        }
        
        let isHeightEqual = left.height == right.height
        XCTAssertTrue(isHeightEqual)
        guard isHeightEqual else {
            return false
        }
        
        let leftData = ImageDescription(width: left.width, height: left.height, components: 4)
        _ = leftData.setBufferFrom(image: left)
        
        let rightData = ImageDescription(width: left.width, height: left.height, components: 4)
        _ = rightData.setBufferFrom(image: right)
        
        
        for y in 0..<left.height {
            for x in 0..<left.width {
                let index = y * left.width + x
                let leftColor = leftData.getColorAt(index: index)
                let rightColor = rightData.getColorAt(index: index)
                if leftColor != rightColor {
                    XCTFail("Color at position (\(x), \(y)) should be \(leftColor), but is \(rightColor)")
                    return false
                }
            }
        }
        
        leftData.release()
        rightData.release()
        
        return true
    }
}
