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

//https://stackoverflow.com/questions/38229027/how-to-create-a-bitmap-image-from-the-byte-array-in-swift
//https://stackoverflow.com/questions/36393436/convert-a-double-array-to-uiimage-in-swift

class ParseImage{
    
    struct ImageDataObj {
        var topPixels = 0
        var rightPixels = 0
        var bottomPixels = 0
        var leftPixels = 0
        var image: UIImage?
    }
    
    func parseImage(inputImage: UIImage) -> ImageDataObj?{
        
        var imageDataObj = ImageDataObj()
        
        guard let cgImage = inputImage.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data)
        else {
            debugPrint("Couldn't access CG Image Data")
            return nil
        }
        
        var modifiedImage = [[UInt32]](repeating: [UInt32](repeating: 0, count: cgImage.width), count: cgImage.height)
        
        if cgImage.colorSpace?.model == .rgb || cgImage.colorSpace?.model == .monochrome{
            let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
            for y in 0 ..< cgImage.height {
                for x in 0 ..< cgImage.width {
                    let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                    let r = bytes[offset]
                    let g = bytes[offset + 1]
                    let b = bytes[offset + 2]
                    let a = bytes[offset + 3]
                    
                    if (r >= 245 && g >= 245 && b >= 245) || a < 255{
                        modifiedImage[y][x] = UINT32_MAX
                    } else{
                        modifiedImage[y][x] = 255
                    }
                    
//                    print("[x:\(x), y:\(y)] \(modifiedImage[y][x])")
//                    let components = (r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2], a: bytes[offset + 3])
//                    print("[x:\(x), y:\(y)] \(components)")
                }
            }
        } else{
            debugPrint("Image is not in RGB Format or Black and White Format(.monochrome)")
        }
        
        var newImgPixels = modifiedImage
        
        for y in 0 ..< newImgPixels.count {
            for x in 0 ..< newImgPixels[y].count{
                if processPixel(arr: newImgPixels, x: x, y: y, xOffset: nil, yOffset: nil){
                    //Check Boundries
                    if (x > 0 && x < cgImage.width - 1) && (y > 0 && y < cgImage.height - 1) {
                        
                        //Check for Top Pixel
                        if processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: -1, yOffset: -1),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: 0, yOffset: -1),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: 1, yOffset: -1){
                            newImgPixels[y][x] = 1543488989
                            imageDataObj.topPixels += 1
                            continue
                        }
                        
                        //Check for Right Pixel
                        if processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: 1, yOffset: 1),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: 1, yOffset: 0),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: 1, yOffset: -1){
                            newImgPixels[y][x] = 1543488989
                            imageDataObj.rightPixels += 1
                            continue
                        }
                        
                        //Check for Left Pixel
                        if processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: -1, yOffset: 1),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: -1, yOffset: 0),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: -1, yOffset: -1){
                            newImgPixels[y][x] = 1543488989
                            imageDataObj.leftPixels += 1
                            continue
                        }
                        
                        //Check for Bottom Pixel
                        if processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: -1, yOffset: 1),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: 0, yOffset: 1),
                           processWhitePixel(arr: newImgPixels, x: x, y: y, xOffset: 1, yOffset: 1){
                            newImgPixels[y][x] = 1543488989
                            imageDataObj.bottomPixels += 1
                            continue
                        }
                    }
                }
            }
        }
        
        let data3 = newImgPixels.flatMap({$0})
        let width = Int(cgImage.width)
        let height = Int(cgImage.height)
        let bitsPerComponent = 8
        let bytesPerPixel2 = 4
        let bytesPerRow = width * bytesPerPixel2
        let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue

        guard let imageContext = CGContext(data: imageData,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: bitsPerComponent,
                                           bytesPerRow: bytesPerRow,
                                           space: colorSpace,
                                           bitmapInfo: bitmapInfo),
              let buffer = imageContext.data?.bindMemory(to: UInt32.self, capacity: data3.count)
        else { return nil }

        for index in 0 ..< width * height {
            buffer[index] = data3[index]
        }
        imageDataObj.image = imageContext.makeImage().flatMap { UIImage(cgImage: $0) }
        return imageDataObj
    }
}

private extension ParseImage{
    
    func processPixel(arr: [[UInt32]], x: Int, y: Int, xOffset: Int?, yOffset: Int?) -> Bool{
        let postion = arr[y + (yOffset ?? 0)][x + (xOffset ?? 0)]
        if postion == 255{
            return true
        } else {
            return false
        }
    }
    
    func processWhitePixel(arr: [[UInt32]], x: Int, y: Int, xOffset: Int?, yOffset: Int?) -> Bool{
        let postion = arr[y + (yOffset ?? 0)][x + (xOffset ?? 0)]
        if postion == UInt32.max{
            return true
        } else {
            return false
        }
    }
    
    func checkPixelForColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> Bool{
        if (r >= 245 && g >= 245 && b >= 245) || a < 255{
            return false //Pixel == White
        } else{
            return true //Pixel == Has Color
        }
    }
    
    class func getRGBAFromPixel(bytes: UnsafePointer<UInt8>, offset: Int) -> (UInt8, UInt8, UInt8, UInt8){
        return (bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3])
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
