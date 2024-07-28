#include <metal_stdlib>
using namespace metal;

enum PaletteType {
    LUT             = 0,
    ColorLUT        = 1,
    LUTCollection   = 2
};
    
float innerSum(float3 vector) {
    return vector.x + vector.y + vector.z;
}
    
float3 convertToXYZ(float3 color) {
    float3 col0 = float3(0.412453, 0.212671, 0.019334);
    float3 col1 = float3(0.357580, 0.715160, 0.119193);
    float3 col2 = float3(0.180423, 0.072169, 0.950227);
    float3x3 conversionMatrix = float3x3(col0, col1, col2);
    return conversionMatrix * color;
}

float getPaletteEntryWithLightness(float lightness, device const uint8_t *palette, int paletteCount) {
    int index = (int)round(saturate(lightness) * (float)(paletteCount - 1));
    return ((float)palette[index]);
}
    
float4 pickColorFromLUT(float4 baseColor, device const uint8_t *palette, int paletteCount) {
    float3 color = baseColor.xyz;
    float lightness = innerSum(color) / (3 * 255);
    float newColor = getPaletteEntryWithLightness(lightness, palette, paletteCount);
    return float4(float3(newColor), baseColor.w);
}
    
float4 pickColorFromColorLUT(float4 baseColor, device const uint8_t *palette, int paletteCount) {
    float3 color = baseColor.xyz / 255;
    float newRed = getPaletteEntryWithLightness(color.x, palette, paletteCount);
    float newGreen = getPaletteEntryWithLightness(color.y, palette, paletteCount);
    float newBlue = getPaletteEntryWithLightness(color.z, palette, paletteCount);
    
    return float4(float3(newRed, newGreen, newBlue), baseColor.w);
}

float4 pickColorFromLUTCollection(float4 baseColor, device const uint8_t *palette, int paletteCount) {
    float3 color = baseColor.xyz;
    float3 result = float3(0);
    float distanceRecord = INFINITY;
    
    for (int i = 0; i < paletteCount; i++) {
        float3 lutColor = float3((float)palette[4 * i + 0], (float)palette[4 * i + 1], (float)palette[4 * i + 2]);
        float redmean = (lutColor.x + color.x) / 2;
        float3 coeficients = (redmean < 128) ? float3(2, 4, 3) : float3(3, 4, 2);
        
        float3 convertedLutColor = coeficients * lutColor;
        float3 convertedBaseColor = coeficients * color;
        
        float distance = distance_squared(convertedLutColor, convertedBaseColor);
        
        if (distance < distanceRecord) {
            distanceRecord = distance;
            result = lutColor;
        }
    }
    
    return float4(result, baseColor.w);
}
    
float4 pickColor(PaletteType paletteType, float4 baseColor, device const uint8_t *palette, int paletteCount) {
    switch (paletteType) {
        case LUT:
            return pickColorFromLUT(baseColor, palette, paletteCount);
        case ColorLUT:
            return pickColorFromColorLUT(baseColor, palette, paletteCount);
        case LUTCollection:
            return pickColorFromLUTCollection(baseColor, palette, paletteCount);
    }
}

kernel void orderedDithering(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    device const float *thresholdMap        [[buffer(0)]],
    device const int *thresholdMapSize      [[buffer(1)]],
    device const uint8_t *palette           [[buffer(2)]],
    device const int *paletteCount          [[buffer(3)]],
    device const PaletteType *paletteType   [[buffer(4)]],
    device const float *normalizationOffset [[buffer(5)]],
    device const float *thresholdMultiplier [[buffer(6)]],
    uint2 gid [[thread_position_in_grid]]
) {
    float4 colorIn = inTexture.read(gid) * 255;
    
    int thresholdMapNum = *thresholdMapSize;
    int thresholdMapIndex = (gid.y % thresholdMapNum) * thresholdMapNum + gid.x % thresholdMapNum;
    float threshold = *thresholdMultiplier * (thresholdMap[thresholdMapIndex] - *normalizationOffset);
    
    float4 thresholdVector = float4(float3(threshold), 1);
    float4 newColor = colorIn + thresholdVector;
    float4 clampedNewColor = round(newColor);
    float4 pickedColor = pickColor(*paletteType, clampedNewColor, palette, *paletteCount) / 255;
    float4 resultColor = float4(pickedColor.xyz, 1);
    
    outTexture.write(resultColor, gid);
}

