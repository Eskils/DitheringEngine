//
//  MetalOrderedDithering.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 05/11/2023.
//

import Metal

struct MetalFunction {
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState
    let maxThreads: Int
    
    static func precompileMetalFunction(withName functionName: String, device: MTLDevice) throws -> MetalFunction {
        let bundle = Bundle.module
        let library = try device.makeDefaultLibrary(bundle: bundle)
        
        guard let function = library.makeFunction(name: functionName) else {
            throw PrecompieMetalError.cannotMakeMetalFunction
        }
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw PrecompieMetalError.canotMakeCommandQueue
        }
        
        let pipelineState = try device.makeComputePipelineState(function: function)
        
        let maxThreadsPerThreadgroup = device.maxThreadsPerThreadgroup
        let maxThreads = Int(sqrt(Float(maxThreadsPerThreadgroup.width)))
        
        return MetalFunction(commandQueue: commandQueue, pipelineState: pipelineState, maxThreads: maxThreads)
    }
    
    static func makeTexture(width: Int, height: Int, usage: MTLTextureUsage,  device: MTLDevice) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor()
        descriptor.width = width
        descriptor.height = height
        descriptor.textureType = .type2D
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.storageMode = .shared
        descriptor.usage = usage
        return device.makeTexture(descriptor: descriptor)
    }
    
    func perform(numWidth: Int, numHeight: Int, commandEncoderConfiguration: @escaping (MTLComputeCommandEncoder) -> Void) throws {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw PerformMetalError.cannotMakeCommandBuffer
        }
        
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw PerformMetalError.cannotMakeCommandEncoder
        }
        
        commandEncoder.setComputePipelineState(pipelineState)
        
        commandEncoderConfiguration(commandEncoder)
        
        let threadsPerThreadgroup = MTLSizeMake(min(maxThreads, numWidth), min(maxThreads, numHeight), 1)
        let threadgroups = MTLSizeMake((numWidth - 1) / threadsPerThreadgroup.width + 1, (numHeight - 1) / threadsPerThreadgroup.height + 1, 1)
        
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        #if DEBUG
        let captureManager = MTLCaptureManager.shared()
        if captureManager.isCapturing {
            captureManager.stopCapture()
        }
        #endif
        commandBuffer.waitUntilCompleted()
    }
    
    enum PrecompieMetalError: Error {
        case cannotMakeMetalLibrary
        case cannotMakeMetalFunction
        case canotMakeCommandQueue
    }
    
    enum PerformMetalError: Error {
        case cannotMakeCommandBuffer
        case cannotMakeCommandEncoder
        case cannotMakeBlitCommandEncoder
    }
}

class MetalOrderedDithering {
    
    var imageDescription: ImageDescription?
    var resultImageDescription: ImageDescription?
    
    private static let metalFunctionName = "orderedDithering"
    private lazy var device = MTLCreateSystemDefaultDevice()
    private lazy var orderedDitheringFunction: MetalFunction? = {
        device.flatMap {
            do {
                return try MetalFunction.precompileMetalFunction(withName: Self.metalFunctionName, device: $0)
            } catch {
                #if DEBUG
                print("Cannot precompile ordered dithering function with error: \(error)")
                #endif
                return nil
            }
        }
    }()
    
    func orderedDitheringMetal(palette: BytePalette, thresholdMap: FloatingThresholdMap, normalizationOffset: Float, thresholdMultiplier: Float) throws {
        guard let imageDescription, let resultImageDescription else {
            throw MetalOrderedDitheringError.missingImageDescriptions
        }
        guard let device else {
            throw MetalOrderedDitheringError.cannotCreateDevice
        }
        
//        #if DEBUG
//        triggerProgrammaticCapture(device: device)
//        #endif
        
        guard let orderedDitheringFunction else {
            throw MetalOrderedDitheringError.cannotPrecompileMetalFunction
        }
        
        let width = imageDescription.width
        let height = imageDescription.height
        
        guard 
            let inTexture = MetalFunction.makeTexture(width: width, height: height, usage: .shaderRead, device: device),
            let outTexture = MetalFunction.makeTexture(width: width, height: height, usage: .shaderWrite, device: device)
        else {
            throw MetalOrderedDitheringError.cannotMakeTexture
        }
        
        let fullImageRegion = MTLRegion(
            origin: MTLOrigin(x: 0, y: 0, z: 0), 
            size: MTLSize(width: width, height: height, depth: 1)
        )
        
        inTexture.replace(
            region: fullImageRegion,
            mipmapLevel: 0,
            withBytes: imageDescription.buffer,
            bytesPerRow: imageDescription.bytesPerRow
        )
        
        guard let paletteBufferResult = paletteBuffer(fromPalette: palette) else {
            throw MetalOrderedDitheringError.cannotMakePaletteBuffer
        }
        
        let paletteBuffer = paletteBufferResult.buffer
        let paletteBufferLength = paletteBufferResult.count
        
        try orderedDitheringFunction.perform(
            numWidth: width,
            numHeight: height
        ) { commandEncoder in
            commandEncoder.setTexture(inTexture, index: 0)
            commandEncoder.setTexture(outTexture, index: 1)
            
            let thresholdMapBuffer = device.makeBuffer(bytes: thresholdMap.buffer, length: thresholdMap.count * MemoryLayout<Float>.size, options: .storageModeShared)
            commandEncoder.setBuffer(thresholdMapBuffer, offset: 0, index: 0)
            
            var thresholdMapSize = thresholdMap.num
            let thresholdMapSizeBuffer = device.makeBuffer(bytes: &thresholdMapSize, length: MemoryLayout<Int>.size, options: .storageModeShared)
            commandEncoder.setBuffer(thresholdMapSizeBuffer, offset: 0, index: 1)
            
            let paletteBufferM = device.makeBuffer(bytes: paletteBuffer, length: paletteBufferLength * MemoryLayout<UInt8>.size, options: .storageModeShared)
            commandEncoder.setBuffer(paletteBufferM, offset: 0, index: 2)
            
            var paletteCount = palette.numberOfEntries
            let paletteCountBuffer = device.makeBuffer(bytes: &paletteCount, length: MemoryLayout<Int>.size, options: .storageModeShared)
            commandEncoder.setBuffer(paletteCountBuffer, offset: 0, index: 3)
            
            var paletteType = self.paletteType(fromPalette: palette).rawValue
            let paletteTypeBuffer = device.makeBuffer(bytes: &paletteType, length: MemoryLayout<Int>.size, options: .storageModeShared)
            commandEncoder.setBuffer(paletteTypeBuffer, offset: 0, index: 4)
            
            var normalizationOffset = normalizationOffset
            let normalizationOffsetBuffer = device.makeBuffer(bytes: &normalizationOffset, length: MemoryLayout<Float>.size, options: .storageModeShared)
            commandEncoder.setBuffer(normalizationOffsetBuffer, offset: 0, index: 5)
            
            var thresholdMultiplier = thresholdMultiplier
            let thresholdMultiplierBuffer = device.makeBuffer(bytes: &thresholdMultiplier, length: MemoryLayout<Float>.size, options: .storageModeShared)
            commandEncoder.setBuffer(thresholdMultiplierBuffer, offset: 0, index: 6)
        }
        
        let buffer = resultImageDescription.buffer
        outTexture.getBytes(
            buffer,
            bytesPerRow: resultImageDescription.bytesPerRow,
            from: fullImageRegion,
            mipmapLevel: 0
        )
        
    }
    
    private func paletteType(fromPalette palette: BytePalette) -> OrderedDitheringPaletteType {
        switch palette.type {
        case .lut(let lut):
            if lut.isColor {
                return .colorLut
            } else {
                return .lut
            }
        case .lutCollection(_):
            return .lutCollection
        }
    }
    
    private func paletteBuffer(fromPalette palette: BytePalette) -> (buffer: UnsafeRawPointer, count: Int)? {
        switch palette.type {
        case .lut(let lut):
            (UnsafeRawPointer(lut.buffer), lut.count)
        case .lutCollection(let lutCollection):
            (UnsafeRawPointer(lutCollection.lut), MemoryLayout<SIMD3<UInt8>>.size * lutCollection.count)
        }
    }
    
    private func triggerProgrammaticCapture(device: MTLDevice) {
        let captureManager = MTLCaptureManager.shared()
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = self.device
        captureDescriptor.destination = .developerTools
        do {
            try captureManager.startCapture(with: captureDescriptor)
        } catch {
            fatalError("error when trying to capture: \(error)")
        }
    }
    
    private enum OrderedDitheringPaletteType: Int {
        case lut            = 0
        case colorLut       = 1
        case lutCollection  = 2
    }
    
    enum MetalOrderedDitheringError: Error {
        case missingImageDescriptions
        case cannotCreateDevice
        case cannotPrecompileMetalFunction
        case cannotMakeTexture
        case cannotMakePaletteBuffer
    }
    
}
