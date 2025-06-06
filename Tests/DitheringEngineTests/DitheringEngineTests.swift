import XCTest
@testable import DitheringEngine

final class DitheringEngineTests: XCTestCase {
    
    let ditheringEngine = DitheringEngine()
    let testsDirectory = URL(fileURLWithPath: #filePath + "/..").standardizedFileURL.path
    
    func testDitheringImageWithSemitransparentAlpha() throws {
        XCTAssertTrue(
            try isEqual(
                image: "transparent-monochrome-gradient",
                expectedImage: "transparent-monochrome-gradient+apple2-bayer",
                transform: { input in
                    try ditheringEngine.set(image: input)
                    return try ditheringEngine.dither(
                        usingMethod: .bayer,
                        andPalette: .apple2,
                        withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
                        withPaletteSettings: EmptyPaletteSettingsConfiguration()
                    )
                }
            )
        )
    }
    
    func testDitheringImageWithAlpha() throws {
        XCTAssertTrue(
            try isEqual(
                image: "transparent-gradient-star",
                expectedImage: "transparent-gradient-start+cga-fs",
                transform: { input in
                    try ditheringEngine.set(image: input)
                    return try ditheringEngine.dither(
                        usingMethod: .floydSteinberg,
                        andPalette: .cga,
                        withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
                        withPaletteSettings: EmptyPaletteSettingsConfiguration()
                    )
                }
            )
        )
    }
    
    func testDitheringImageWithoutAlphaPerformance() throws {
        let ditheringEngine = DitheringEngine()
        ditheringEngine.preserveTransparency = false
        let inputImageName = "transparent-gradient-star"
        let inputImagePath = testsDirectory + "/InputImages/\(inputImageName).png"
        let inputImage = try image(atPath: inputImagePath)
        try ditheringEngine.set(image: inputImage)
        
        measure {
            _ = try! ditheringEngine.dither(
                usingMethod: .bayer,
                andPalette: .bw,
                withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
                withPaletteSettings: EmptyPaletteSettingsConfiguration()
            )
        }
    }
    
    func testDitheringImageAlphaPerformance() throws {
        let ditheringEngine = DitheringEngine()
        ditheringEngine.preserveTransparency = true
        let inputImageName = "transparent-gradient-star"
        let inputImagePath = testsDirectory + "/InputImages/\(inputImageName).png"
        let inputImage = try image(atPath: inputImagePath)
        try ditheringEngine.set(image: inputImage)
        
        measure {
            _ = try! ditheringEngine.dither(
                usingMethod: .bayer,
                andPalette: .bw,
                withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
                withPaletteSettings: EmptyPaletteSettingsConfiguration()
            )
        }
    }
    
}

private extension DitheringEngineTests {
    func isEqual(image: String, expectedImage: String, transform: (CGImage) throws -> CGImage) throws -> Bool {
        try imageIsEqual(
            inputImagePath: testsDirectory + "/InputImages/\(image).png",
            expectedImagePath: testsDirectory + "/ExpectedOutputImages/\(expectedImage).png",
            producedOutputsPath: testsDirectory + "/ProducedOutputImages/\(expectedImage).png",
            afterPerformingImageOperations: transform
        )
    }
}
