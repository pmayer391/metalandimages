//
//  ParseImage.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 5/12/21.
//

import Foundation
import UIKit
import CoreGraphics
import ImageIO

//#define Mask8(x) ( (x) & 0xFF )
//#define R(x) ( Mask8(x) )
//#define G(x) ( Mask8(x >> 8 ) )
//#define B(x) ( Mask8(x >> 16) )
//#define A(x) ( Mask8(x >> 24) )
//#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )
//https://stackoverflow.com/questions/38229027/how-to-create-a-bitmap-image-from-the-byte-array-in-swift
//https://stackoverflow.com/questions/36393436/convert-a-double-array-to-uiimage-in-swift

class ImageParsing{
    
    class func parseImage(inputImage: UIImage) -> UIImage?{
        
        guard let cgImage = inputImage.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            debugPrint("Couldn't access cgImage data")
            return nil
        }
        
        if cgImage.colorSpace?.model == .rgb || cgImage.colorSpace?.model == .monochrome{
            var modifiedImage = [[UInt32]](repeating: [UInt32](repeating: 0, count: cgImage.width), count: cgImage.height)
            let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
            for y in 0 ..< cgImage.height {
                for x in 0 ..< cgImage.width {
                    let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                    let r = bytes[offset]
                    let g = bytes[offset + 1]
                    let b = bytes[offset + 2]
                    let a = bytes[offset + 3]
                    
                    //TODO: Need to figure out how alpha works and should be handled
                    if r >= 245 && g >= 245 && b >= 245{
                        modifiedImage[y][x] = 255
                    } else{
                        modifiedImage[y][x] = 0
                    }
//                    print("[x:\(x), y:\(y)] \(modifiedImage[y][x])")
//
//                    let components = (r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2], a: bytes[offset + 3])
//                    print("[x:\(x), y:\(y)] \(components)")
                }
            }
            
            let data = modifiedImage.flatMap({$0})
            let width = Int(cgImage.width)
            let height = Int(cgImage.height)
            let bitsPerComponent = 8
            let bytesPerPixel2 = 4
            let bytesPerRow = width * bytesPerPixel2
            let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
            bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
            
            guard let imageContext = CGContext(data: imageData,
                                               width: width,
                                               height: height,
                                               bitsPerComponent: bitsPerComponent,
                                               bytesPerRow: bytesPerRow,
                                               space: colorSpace,
                                               bitmapInfo: bitmapInfo),
                  let buffer = imageContext.data?.bindMemory(to: UInt32.self, capacity: data.count)
            else { return nil }
            
            for index in 0 ..< width * height {
                buffer[index] = data[index]
            }
            
            return imageContext.makeImage().flatMap { UIImage(cgImage: $0) }
            
        } else{
            debugPrint("Image is not in RGB Format")
        }
        
        
        
        return nil
    }
    
}

struct RGBA {
    var pixels: UnsafeMutableBufferPointer<Pixel>
    var width: Int
    var height: Int
    
    init?(image: UIImage) {
        guard let cgImage = image.cgImage else { return nil }
        width = Int(image.size.width)
        height = Int(image.size.height)
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        guard let imageContext = CGContext(data: imageData,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: bitsPerComponent,
                                           bytesPerRow: bytesPerRow,
                                           space: colorSpace,
                                           bitmapInfo: bitmapInfo)
        else { return nil }
        
        imageContext.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
        pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
    }
    
    func toUIImage() -> UIImage? {
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        let imageContext = CGContext(data: pixels.baseAddress,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: bitsPerComponent,
                                     bytesPerRow: bytesPerRow,
                                     space: colorSpace,
                                     bitmapInfo: bitmapInfo)!
        
        guard let cgImage = imageContext.makeImage() else {return nil}
        let image = UIImage(cgImage: cgImage)
        return image
    }
}


struct Pixel {
    var value: UInt32
    var red: UInt8 {
        get { return UInt8(value & 0xFF) }
        set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
    }
    var green: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
        set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
    }
    var blue: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
        set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
    }
    var alpha: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
        set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
    }
}
