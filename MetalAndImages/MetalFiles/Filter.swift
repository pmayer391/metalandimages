//
//  Filter.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 5/10/21.
//

import Metal
import MetalKit

// UIImage -> CGImage -> MTLTexture -> COMPUTE HAPPENS -> MTLTexture -> CGImage -> UIImage
class Filter {
    
    var device: MTLDevice
    var defaultLib: MTLLibrary?
    var grayscaleShader: MTLFunction?
    var commandQueue: MTLCommandQueue?
    var commandBuffer: MTLCommandBuffer?
    var commandEncoder: MTLComputeCommandEncoder?
    var pipelineState: MTLComputePipelineState?
    var flagBuffer: MTLBuffer?
    var texture2DBitMapFlags: [[uint]]? // Black == 0, White == 1
    
    var inputImage: UIImage
    var height, width: Int
    
    //TODO: Figure out how to optimize this
    // most devices have a limit of 512 threads per group
    var threadsPerBlock = MTLSize(width: 1, height: 1, depth: 1)
    
    init(img: UIImage){
        self.inputImage = img
        self.height = Int(self.inputImage.size.height)
        self.width = Int(self.inputImage.size.width)

        let texture2DBitMapFlags = [[uint]](repeating: [uint](repeating: 0, count: self.width), count: self.height)
        let flatMap = texture2DBitMapFlags.flatMap({$0})
//        for i in 0..<texture2DBitMapFlags.count{
//            for j in 0..<texture2DBitMapFlags[i].count{
//                print("Row: \(i)")
//                print("Column: \(j)")
//            }
//        }
        
        
        
        
        //SETUP METAL & GPU Configuration
        self.device = MTLCreateSystemDefaultDevice()!
        self.defaultLib = self.device.makeDefaultLibrary()
        self.grayscaleShader = self.defaultLib?.makeFunction(name: "black")
        self.commandQueue = self.device.makeCommandQueue()
        self.commandBuffer = self.commandQueue?.makeCommandBuffer()
        self.commandEncoder = self.commandBuffer?.makeComputeCommandEncoder()
        do{
            pipelineState = try device.makeComputePipelineState(function: grayscaleShader!)
        } catch{
            print("Could not setup GPU Shared Memory Pipeline with Metal Functions: \(error)")
        }
        let memoryLayoutSize = self.width * self.height
        let widthBuff = device.makeBuffer(length: MemoryLayout<Float>.size * memoryLayoutSize, options: .storageModeShared)
        let heightBuff = device.makeBuffer(length: MemoryLayout<Float>.size * memoryLayoutSize, options: .storageModeShared)
        flagBuffer = device.makeBuffer(bytes: flatMap, length: MemoryLayout<UInt32>.size * flatMap.count, options: .storageModeShared)
        commandEncoder?.setComputePipelineState(pipelineState!)
        commandEncoder?.setBuffer(widthBuff, offset: 0, index: 0)
        commandEncoder?.setBuffer(heightBuff, offset: 0, index: 1)
        commandEncoder?.setBuffer(flagBuffer, offset: 0, index: 2)
    }
    
    func computeRandomArray() -> [Float]{
        var returnArray = [Float].init(repeating: 0.0, count: 3)
        for i in 0..<3{
            returnArray[i] = Float.random(in: 1.0..<255.0)
        }
        returnArray.append(1.0)
        return returnArray
    }
    
    func getCGImage(from uiimg: UIImage) -> CGImage? {
        UIGraphicsBeginImageContext(uiimg.size)
        uiimg.draw(in: CGRect(origin: .zero, size: uiimg.size))
        let contextImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return contextImage?.cgImage
    }
    
    func getMTLTexture(from cgimg: CGImage) -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self.device)
        do{
            let texture = try textureLoader.newTexture(cgImage: cgimg, options: nil)
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: texture.pixelFormat, width: width, height: height, mipmapped: false)
            textureDescriptor.usage = [.shaderRead, .shaderWrite]
            return texture
        } catch {
            fatalError("Couldn't convert CGImage to MTLtexture")
        }
    }
    
    func getCGImage(from mtlTexture: MTLTexture) -> CGImage? {
        var data = Array<UInt8>(repeatElement(0, count: 4*width*height))
        mtlTexture.getBytes(&data,
                            bytesPerRow: 4*width,
                            from: MTLRegionMake2D(0, 0, width, height),
                            mipmapLevel: 0)
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &data,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: 4*width,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        return context?.makeImage()
    }
    
    func getUIImage(from cgimg: CGImage) -> UIImage? {
        return UIImage(cgImage: cgimg)
    }
    
    func getEmptyMTLTexture() -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        return self.device.makeTexture(descriptor: textureDescriptor)
    }
    
    func getInputMTLTexture() -> MTLTexture? {
        if let inputImage = getCGImage(from: self.inputImage) {
            return getMTLTexture(from: inputImage)
        }
        else { fatalError("Unable to convert Input image to MTLTexture") }
    }
    
    func getBlockDimensions() -> MTLSize {
        let blockWidth = width / self.threadsPerBlock.width
        let blockHeight = height / self.threadsPerBlock.height
        return MTLSizeMake(blockWidth, blockHeight, 1)
    }
    
    func applyFilter() -> UIImage? {
        if let encoder = self.commandEncoder, let buffer = self.commandBuffer,
            let outputTexture = getEmptyMTLTexture(), let inputTexture = getInputMTLTexture() {
            encoder.setTextures([outputTexture, inputTexture], range: 0..<2)
//            encoder.setBuffer(commandBuffer!, offset: 0, index: 2)
//            encoder.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1), threadsPerThreadgroup: threadsPerBlock)
            
            let memoryLayoutSize = self.width * self.height
//            let threadsPerGrid = MTLSize(width: memoryLayoutSize, height: 1, depth: 1) // Since this is a 1D we only populate width
            let maxThreadsPerThreadGroup = (pipelineState?.maxTotalThreadsPerThreadgroup)! //Since a machine only can support so many threads we have to create thread groups my device says it has 512 threads
            let threadsPerThreadGroup = MTLSize(width: maxThreadsPerThreadGroup, height: 1, depth: 1)
            commandEncoder?.dispatchThreadgroups(self.getBlockDimensions(), threadsPerThreadgroup: threadsPerThreadGroup)
            encoder.endEncoding()
    
            buffer.commit()
            buffer.waitUntilCompleted()
            
            
//            let memoryLayoutSize = self.width * self.height
            var resultBufferPointer = flagBuffer?.contents().bindMemory(to: UInt32.self, capacity: MemoryLayout<UInt32>.size * memoryLayoutSize)
//                print("Pixel Flag: \(resultBufferPointer )")
                
//            }
            
            //Get the pointer to the beginning of our data
            
//            var resultBufferPointer = flagBuffer?.contents().bindMemory(to: SIMD2<UInt32>.self, capacity: MemoryLayout<SIMD2<UInt32>>.size * memoryLayoutSize)
//            let blah1 = SIMD2<UInt32>
//            let blah = SIMD2<UInt32>()
            //Print out all of our new added together array information
//            let texture2DBitMapFlags = [[uint]](repeating: [uint](repeating: 0, count: self.width), count: self.height)
            
            for i in 0..<memoryLayoutSize {
                let pointerVal = resultBufferPointer!.pointee as UInt32
                print("Value:  \(pointerVal) index: \(i)")
                resultBufferPointer = resultBufferPointer?.advanced(by: 1)
            }
            guard let outputImage = getCGImage(from: outputTexture) else { fatalError("Couldn't obtain CGImage from MTLTexture") }
            return getUIImage(from: outputImage)
            

        } else { fatalError("optional unwrapping failed") }
        
    }
    
    
}
