//
//  CodeKit.Metal.swift
//  pap
//
//  Created by HYOJIN MO on 19/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//
//  https://github.com/BradLarson/GPUImage3

import UIKit
import Metal
import MetalKit
import MetalPerformanceShaders

struct MTLUtility {
    static let standardImageVertices: [Float] = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0]
    
    static func makeTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat = .rgba8Unorm) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        textureDescriptor.usage = [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
        
        return MTLContext.shared.device.makeTexture(descriptor: textureDescriptor)
    }
}

public class MTLContext {
    static let shared = MTLContext()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue?
    let library: MTLLibrary?
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Could not create Metal Device") }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        if let libFilepath = Bundle.main.path(forResource: "default", ofType: "metallib") {
            self.library = try? device.makeLibrary(filepath: libFilepath)
        }
        else {
            self.library = device.makeDefaultLibrary()
        }
    }
}

extension MTLContext {
    func makeRenderPipelineState(vertexFunction vertexFunctionName: String, fragmentFunction fragmentFunctionName: String) -> MTLRenderPipelineState? {
        guard
            let vertexFunction = library?.makeFunction(name: vertexFunctionName),
            let fragmentFunction = library?.makeFunction(name: fragmentFunctionName)
        else {
            return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        descriptor.rasterSampleCount = 1
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
}

extension MTLTexture {
    func textureCoordinates(normalized: Bool) -> [Float] {
        let xLimit:Float
        let yLimit:Float
        
        if normalized {
            xLimit = 1.0
            yLimit = 1.0
        } else {
            xLimit = Float(self.width)
            yLimit = Float(self.height)
        }
        
        return [0.0, 0.0, xLimit, 0.0, 0.0, yLimit, xLimit, yLimit]
    }
}

extension MTLCommandBuffer {
    func renderQuad(pipelineState: MTLRenderPipelineState, inputTexture: MTLTexture, useNormalizedTextureCoordinates: Bool = true, imageVertices: [Float] = MTLUtility.standardImageVertices, outputTexture: MTLTexture) {
        guard let vertexBuffer = MTLContext.shared.device.makeBuffer(bytes: imageVertices, length: imageVertices.count * MemoryLayout<Float>.size, options: []) else { return }
        vertexBuffer.label = "Vertices"
        
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else { return }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let inputTextureCoordinates = inputTexture.textureCoordinates( normalized:useNormalizedTextureCoordinates)
        guard let textureBuffer = MTLContext.shared.device.makeBuffer(bytes: inputTextureCoordinates, length: inputTextureCoordinates.count * MemoryLayout<Float>.size, options: []) else { return }
        textureBuffer.label = "Texture Coordinates"
        
        renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(inputTexture, index: 0)
        
//        uniformSettings?.restoreShaderSettings(renderEncoder: renderEncoder)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}

class CIImageView: MTKView {
    var image: CIImage? {
        didSet {
            self.draw()
        }
    }
    
    var scale: CGFloat {
        guard let image = image else { return 0 }
        return max(self.frame.width / image.extent.width, self.frame.height / image.extent.height)
    }
    
    private lazy var ciContext: CIContext = {
        return CIContext(mtlDevice: MTLContext.shared.device, options: [CIContextOption.useSoftwareRenderer: false])
    }()
    
    private var commandQueue: MTLCommandQueue? {
        return MTLContext.shared.commandQueue
    }
    
    private var renderPipelineState: MTLRenderPipelineState?
    
    convenience init(frame: CGRect) {
        self.init(frame: frame, device: MTLContext.shared.device)
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        guard let device = device else {
            fatalError("Can't use Metal")
        }
        
        super.init(frame: frameRect, device: device)
        
        contentScaleFactor = UIScreen.main.scale
        framebufferOnly = false
        enableSetNeedsDisplay = false
        isPaused = true
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        autoResizeDrawable = true
        
        renderPipelineState = MTLContext.shared.makeRenderPipelineState(vertexFunction: "oneInputVertex", fragmentFunction: "passthroughFragment")
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let image = self.image else { return }
        
        guard let currentDrawable = self.currentDrawable else {
            return
        }
        
        guard let inputTexture = MTLUtility.makeTexture(width: Int(image.extent.width), height: Int(image.extent.height)) else { return }
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        ciContext.render(image, to: inputTexture, commandBuffer: commandBuffer, bounds: image.extent, colorSpace: image.defaultColorSpace)
        
        if let renderPipelineState = renderPipelineState {
            #if !targetEnvironment(simulator) //currentDrawable.texture is only for real device.
            commandBuffer?.renderQuad(pipelineState: renderPipelineState, inputTexture: inputTexture, outputTexture: currentDrawable.texture)
            #endif
        }
        
        commandBuffer?.present(currentDrawable)
        commandBuffer?.commit()
    }
}

extension MTLUtility {
    static func commitComputeShader(_ functionName: String, input inputTexture: MTLTexture, output outputTexture: MTLTexture, with uniformBuffers: [MTLBuffer]? = nil) {
        guard
            let commandQueue = MTLContext.shared.commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeComputeCommandEncoder(),
            let kernelFunction = MTLContext.shared.library?.makeFunction(name: functionName),
            let pipelineState = try? MTLContext.shared.device.makeComputePipelineState(function: kernelFunction)
        else { return }
        
        encoder.setComputePipelineState(pipelineState)
        
        for (idx, uniformBuffer) in (uniformBuffers ?? []).enumerated() {
            encoder.setBuffer(uniformBuffer, offset: 0, index: idx)
        }
        
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)
        
        // https://developer.apple.com/documentation/metal/calculating_threadgroup_and_grid_sizes
        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        
        let threadsPerGrid = MTLSizeMake(inputTexture.width, inputTexture.height, 1)
        let threadgroupsPerGrid = MTLSizeMake((threadsPerGrid.width + w - 1) / w, (threadsPerGrid.height + h - 1) / h, 1)
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        encoder.endEncoding()
        
        commandBuffer.commit()
    }
}
