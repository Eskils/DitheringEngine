# DitheringEngine

Framework for iOS and Mac Catalyst to dither images.

Dithering is the process of adding noise to an image in order for us to perceive the image more colorful.

![A dithered image with four colors. A rose bush on a field in foreground with a pergola in the background.](Documentation/Resources/DitheredImage2.png)

> This image has only four colors: black, white, cyan, and magenta.

Check out the [demo application](./Documentation/Demo/) for iOS and macOS.

## Usage

The engine works on CGImages.

Supported dithering methods are: 
  - Threshold
  - Floyd Steinberg
  - Atkinson
  - Jarvis-Judice-Ninke
  - Bayer (Ordered dithering)

Supported out of the box palettes are:
  - Black & White
  - Grayscale
  - Quantized Color
  - Apple ][
  - Game Boy
  - CGA 

Example usage: 
```swift
// Create an instance of DitheringEngine
let ditheringEngine = DitheringEngine()
// Set input image
try ditheringEngine.set(image: inputCGImage)
// Dither to quantized color with 5 bits using Floyd-Steinberg.
let cgImage = try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .quantizedColor,
    withDitherMethodSettings: FloydSteinbergSettingsConfiguration(direction: .leftToRight),
    withPaletteSettings: QuantizedColorSettingsConfiguration(bits: 5)
)
```

### Dithering methods

Here is an overview over the available dithering methods.

#### Threshold

Threshold gives the nearest match of the color in the image to the color in the palette without adding any noise or improvements.

![Threshold with default settings. CGA Mode 4 | Palette 0 | High](Documentation/Resources/ThresholdAlg.png)

**Token:** `.threshold`  
**Settings:** `EmptyPaletteSettingsConfiguration`

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .threshold,
    andPalette: .cga,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: CGASettingsConfiguration(mode: .palette0High)
)
```

#### Floyd-Steinberg

Floyd-Steinberg dithering spreads the error from reducing the color of a pixel to the neighbouring pixels—yielding an image looking close to the original in areas of fine detail (e.g. grass and trees) and with interesting artifacts in areas of little detail (e.g. the sky).

![Floyd-Steinberg dithering with default settings. CGA Text Mode palette](Documentation/Resources/FSAlg2.png)

**Token:** `.floydSteinberg`  
**Settings:** `FloydSteinbergSettingsConfiguration`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| direction | FloydSteinbergDitheringDirection | `.leftToRight` | Specifies in what order to go through the pixels of the image. This has an effect on where the error is distributed. |
| matrix | [Int] | [7, 3, 5, 1] | A matrix (array of four numbers) which specifies what weighting of the error to give the neighbouring pixels. The weighing is a fraction of the number and the sum of all numbers in the matrix. For instance: in the default matrix, the first is given the weight 7/16. The image explains how the weights in the matrix are distributed. ![](Documentation/Resources/FSMatrixExplanation.png).

**`FloydSteinbergDitheringDirection`**:
  - `.leftToRight`
  - `.rightToLeft`
  - `.topToBottom`
  - `.bottomToTop`

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .cga,
    withDitherMethodSettings: FloydSteinbergSettingsConfiguration(direction: .leftToRight),
    withPaletteSettings: CGASettingsConfiguration(mode: .textMode)
)
```

#### Atkinson

Atkinson dithering is a variant of Floyd-Steinberg dithering, and works by spreading error from reducing the color of a pixel to the neighbouring pixels. Atkinson spreads over a larger area, but does not distribute the full error—making colors matching the palette have less noise.

![Atkinson dithering with default settings. CGA Text Mode](Documentation/Resources/Atkinson.png)

**Token:** `.atkinson`  
**Settings:** `EmptyPaletteSettingsConfiguration`

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .atkinson,
    andPalette: .cga,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: CGASettingsConfiguration(mode: .textMode)
)
```

#### Jarvis-Judice-Ninke

Jarvis-Judice-Ninke dithering is a variant of Floyd-Steinberg dithering, and works by spreading error from reducing the color of a pixel to the neighbouring pixels. This method spreads distributes the error over a larger area and therefore leaves a smoother look to your image.

![Jarvis-Judice-Ninke dithering with default settings. CGA Text Mode](Documentation/Resources/JarvisJudiceNinke.png)

**Token:** `.jarvisJudiceNinke`  
**Settings:** `EmptyPaletteSettingsConfiguration`

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .jarvisJudiceNinke,
    andPalette: .cga,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: CGASettingsConfiguration(mode: .textMode)
)
```

#### Bayer

Bayer dithering is a type of ordered dithering which adds a precalculated threshold to every pixel, baking in a special pattern.

![Bayer dithering with default settings. CGA Mode 5 | High palette](Documentation/Resources/BayerAlg.png)

**Token:** `.bayer`  
**Settings:** `BayerSettingsConfiguration`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| thresholdMapSize | Int | `4` | Specifies the size of the square threshold matrix. Default is 4x4. |

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .bayer,
    andPalette: .cga,
    withDitherMethodSettings: BayerSettingsConfiguration(),
    withPaletteSettings: CGASettingsConfiguration(mode: .mode5High)
)
```

### Built-in palettes

Here is an overview of the built-in palettes:

#### Black & White

A palette with the two colors: black, and white.

![Floyd-Steinberg dithering with the black and white palette](Documentation/Resources/FSBW.png)

**Token:** `.bw`  
**Settings:** `EmptyPaletteSettingsConfiguration`

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .bw,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: EmptyPaletteSettingsConfiguration()
)
```

#### Grayscale

A palette with all shades of gray.

![Floyd-Steinberg dithering with the grayscale palette](Documentation/Resources/FSGray.png)

**Token:** `.grayscale`  
**Settings:** `QuantizedColorSettingsConfiguration`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| bits | Int | 0 | Specifies the number of bits to quantize to. The number of bits can be between 0 and 8. The number of shades of gray is given by 2^n where n is the number of bits. |

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .grayscale,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: EmptyPaletteSettingsConfiguration()
)
```

#### Quantized Color

A palette with quantized bits for the color channel. Specify the number of bits to use for color—from 0 to 8. The number of colors is given by 2^n where n is the number of bits.

![Floyd-Steinberg dithering with the quantized palette. Here with 2 bits](Documentation/Resources/FSQuant.png)

**Token:** `.quantizedColor`  
**Settings:** `QuantizedColorSettingsConfiguration`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| bits | Int | 0 | Specifies the number of bits to quantize to. The number of bits can be between 0 and 8. The number of colors is given by 2^n where n is the number of bits. |

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .quantizedColor,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: QuantizedColorSettingsConfiguration(bits: 2)
)
```

#### CGA

A palette with the oldschool CGA palettes. CGA was a graphics card introduced in 1981 with the ability to display colour on the IBM PC. It used a 4 bit interface (Red, Green, Blue, Intensity) giving a total of 16 possible colors. Due to limited video memory however, the most common resolution of 320x200 would only allow you four colors on screen simultaneously. In this mode, d developer could choose from four palettes, with beautiful colour combinations such as black, cyan, magenta and white or black, green, red and yellow.

![Floyd-Steinberg dithering with the CGA palette. Here in mode 4 with pallet 1 high](Documentation/Resources/FSCGA.png)

**Token:** `.cga`  
**Settings:** `CGASettingsConfiguration`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| mode | CGAMode | `.palette1High` | Specifies the graphics mode to use. Each graphics mode has a unique set of colors. The one with the most colors is `.textMode`. |

**`CGAMode`**:
| Name | Colors | Image |
|------|------|---------|
| `.palette0Low` | Black, green, red, brown | <img alt="Palette 0 Low" src="Documentation/Resources/CGAp0l.png" height="200" width="auto"> |
| `.palette0High` | Black, light green, light red, yellow | <img alt="Palette 0 High" src="Documentation/Resources/CGAp0h.png" height="200" width="auto"> |
| `.palette1Low` | Black, cyan, magenta, light gray | <img alt="palette 1 Low" src="Documentation/Resources/CGAp1l.png" height="200" width="auto"> |
| `.palette1High` | Black, light cyan, light magenta, white | <img alt="Palette 1 High" src="Documentation/Resources/CGAp1h.png" height="200" width="auto"> |
| `.mode5Low` | Black, cyan, red, light gray | <img alt="Mode 5 Low" src="Documentation/Resources/CGAm5l.png" height="200" width="auto"> |
| `.mode5High` | Black, light cyan, light red, white | <img alt="Mode 5 High" src="Documentation/Resources/CGAm5h.png" height="200" width="auto"> |
| `.textMode` | All 16 colors | <img alt="Text Mode" src="Documentation/Resources/CGAtm.png" height="200" width="auto"> |

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .quantizedColor,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: CGASettingsConfiguration(mode: .palette1High)
)
```

#### Apple ][

The Apple II was one of the first personal computers with color. Technical challenges related to reducing cost enabled two modes for graphics—a high resolution mode with six colors, and a low resolution mode with 16 colors.

![Atkinson dithering with the Apple II palette. Here in HiRes graphics mode.](Documentation/Resources/AtkApple2HiRes.png)

**Token:** `.apple2`  
**Settings:** `Apple2SettingsConfiguration`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| mode | Apple2Mode | `.hiRes` | Specifies the graphics mode to use. Each graphics mode has a unique set of colors. |

**`Apple2Mode`**:
| Name | Num. Colors | Image |
|------|------|---------|
| `.hiRes` | 6 colors | <img alt="Hi-Res" src="Documentation/Resources/AtkApple2HiRes.png" height="200" width="auto"> |
| `.loRes` | 16 colors | <img alt="Lo-Res" src="Documentation/Resources/AtkApple2LoRes.png" height="200" width="auto"> |

> **Note:** The 16 colors of the Apple2 Lo-Res palette are different from CGA’s text mode palette.

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .atkinson,
    andPalette: .apple2,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: Apple2SettingsConfiguration(mode: .hiRes)
)
```

#### Game Boy

Oldschool four color green-shaded monochrome display.

![Atkinson dithering with the Game Boy palette.](Documentation/Resources/AtkGameBoy.png)

**Token:** `.gameBoy`  
**Settings:** `EmptyPaletteSettingsConfiguration`

Example: 
```swift
let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
let cgImage = try ditheringEngine.dither(
    usingMethod: .atkinson,
    andPalette: .gameBoy,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: EmptyPaletteSettingsConfiguration()
)
```

## Creating your own palette

You can create your own palettes using the appropriate APIs.

![Floyd-Steinberg dithering with a custom palette](Documentation/Resources/DitheredImageCustomPalette.png)

A palette is represented with the `BytePalette` structure, which can be constructed from a lookup-table (LUT), and a collection of colors (LUTCollection). The most useful is perhaps the LUTCollection.

If you have an array of UIColors contained in the palette, you first need to extract the color values into a list of `SIMD3<UInt8>`s. This can be done as follows:

```swift
let entries = colors.map { color in
    var redNormalized: CGFloat = 0
    var greenNormalized: CGFloat = 0
    var blueNormalized: CGFloat = 0

    color.getRed(&redNormalized, green: &greenNormalized, blue: &blueNormalized, alpha: nil)

    let red = UInt8(clamp(redDouble * 255, min: 0, max: 255))
    let green = UInt8(clamp(greenDouble * 255, min: 0, max: 255))
    let blue = UInt8(clamp(blueDouble * 255, min: 0, max: 255))

    return SIMD3(x: red, y: green, z: blue)
}
```

After this, you can make a `LUTCollection` and from it a palette:

```swift
let collection = LUTCollection<UInt8>(entries: entries)
let palette = BytePalette.from(lutCollection: collection)
```

When dithering an image, choose the `.custom` palette and provide your palette in the `CustomPaletteSettingsConfiguration`:

```swift
try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .custom,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: CustomPaletteSettingsConfiguration(palette: palette)
)
```

Full example: 
```swift
let entries = colors.map { color in
    var redNormalized: CGFloat = 0
    var greenNormalized: CGFloat = 0
    var blueNormalized: CGFloat = 0

    color.getRed(&redNormalized, green: &greenNormalized, blue: &blueNormalized, alpha: nil)

    let red = UInt8(clamp(redDouble * 255, min: 0, max: 255))
    let green = UInt8(clamp(greenDouble * 255, min: 0, max: 255))
    let blue = UInt8(clamp(blueDouble * 255, min: 0, max: 255))

    return SIMD3(x: red, y: green, z: blue)
}
let collection = LUTCollection<UInt8>(entries: entries)
let palette = BytePalette.from(lutCollection: collection)

let ditheringEngine = DitheringEngine()
try ditheringEngine.set(image: inputCGImage)
try ditheringEngine.dither(
    usingMethod: .floydSteinberg,
    andPalette: .custom,
    withDitherMethodSettings: EmptyPaletteSettingsConfiguration(),
    withPaletteSettings: CustomPaletteSettingsConfiguration(palette: palette)
)
```