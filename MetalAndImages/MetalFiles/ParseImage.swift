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
        var pixelsImageMap: [String:ImagePixel] = [:]
        
        if cgImage.colorSpace?.model == .rgb || cgImage.colorSpace?.model == .monochrome{
            let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
            for y in 0 ..< cgImage.height {
                for x in 0 ..< cgImage.width {
                    let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                    let r = bytes[offset]
                    let g = bytes[offset + 1]
                    let b = bytes[offset + 2]
                    let a = bytes[offset + 3]
                    
                    var color: PixelColor = .clear
                    
                    if r == 0 && g == 0 && b == 0 && a >= 240{ //If its already black
                        color = .black
                    } else{ //White
                        color = .white
                    }
                    
                    //Boundry Check: If pixel is on the boundry then turn it white.
                    if x == 0 || x == cgImage.width - 1 || y == 0 || y == cgImage.height - 1 {
                        color = .white
                    }
                    
                    modifiedImage[y][x] = color.rawValue
                    let newPixel = ImagePixel(color, xPos: x, yPos: y)
                    pixelsImageMap["\(x)-\(y)"] = newPixel
                    
                    
                    //R = 0, G = 0, B=0 A=255 Black
                    // A == 0 Transparent
                    
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
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {return nil}
                if (x > 0 && x < cgImage.width - 1) && (y > 0 && y < cgImage.height - 1) {
                    if modifiedImage[y][x + 1] == PixelColor.black.rawValue {
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        newImgPixels[y][x] = PixelColor.white.rawValue
                    }
                }
                setPixelNeighbors(pixelsImageMap, x, y, modifiedImage.count - 1, modifiedImage[y].count - 1, currentPixel)
            }
        }
        
        var newImgPixels2 = newImgPixels
        
        for y in 0 ..< newImgPixels2.count {
            for x in 0 ..< newImgPixels2[y].count{
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {return nil}
                
                if currentPixel.color == .white,
                   currentPixel.bottomLeftPix?.color == .black,
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.leftPix?.color != .black
//                   ,currentPixel.topRightPix?.color != .black
                {
                    
                    currentPixel.pixelStatus = .restoredLeft
                    currentPixel.color = .black
                    newImgPixels2[y][x] = PixelColor.red.rawValue
                }
                
                if currentPixel.color == .white,
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.leftPix?.pixelStatus == .restoredLeft,
                   currentPixel.rightPix?.pixelStatus != .restoredLeft,
                   currentPixel.topRightPix?.color != .black,
                   currentPixel.bottomRightPix?.color != .black{
                    
                    currentPixel.pixelStatus = .restoredLeft
                    currentPixel.color = .black
                    newImgPixels2[y][x] = PixelColor.yellow.rawValue
                }
                
                if currentPixel.color == .white,
                   (currentPixel.topLeftPix?.color == .black || currentPixel.topLeftPix?.color == .red),
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.topLeftPix?.pixelStatus != .restoredRight,
                   currentPixel.topLeftPix?.pixelStatus != .restoredLeft,
                   currentPixel.topLeftPix?.bottomLeftPix?.color != .black,
                   currentPixel.topLeftPix?.topRightPix?.color != .black,
                   currentPixel.leftPix?.color != .black
//                   ,currentPixel.
                
                //TODO: Write condition for red and yellow pixels touching blue pixels
                {
                    
                    currentPixel.pixelStatus = .restoredRight
                    currentPixel.color = .black
                    newImgPixels2[y][x] = PixelColor.blue.rawValue
                }
                
                if currentPixel.color == .white,
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.leftPix?.pixelStatus == .restoredRight,
                   currentPixel.rightPix?.pixelStatus != .restoredRight,
                   currentPixel.topRightPix?.color != .black,
                   currentPixel.bottomRightPix?.color != .black{
                    
                    currentPixel.pixelStatus = .restoredRight
                    currentPixel.color = .black
                    newImgPixels2[y][x] = PixelColor.green.rawValue
                }
                

                
            }
        }
        
//        var newImgPixels3 = newImgPixels2
//        var rightLines: [Line] = []
//
//        for y in 0 ..< newImgPixels3.count {
//            for x in 0 ..< newImgPixels3[y].count{
//                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {return nil}
//
//                //Process Pixels
//                if let neighborProcessed = currentPixel.hasAtLeastOneNeighborProcessed(),
//                   currentPixel.pixelStatus != .processed,
//                   currentPixel.color == .black{
//                    let line = rightLines.filter({$0.pixelPath.contains(where: {$0.xPos == neighborProcessed.xPos && $0.yPos == neighborProcessed.yPos})}).first
//                    currentPixel.pixelStatus = .processed
//                    currentPixel.color = .green
//                    line?.pixelPath.append(currentPixel)
//                    newImgPixels3[y][x] = PixelColor.green.rawValue
//                    continue
//                }
//
//                //Start Pixel
//                if currentPixel.pixelStatus != .processed,
//                   currentPixel.color == .black,
//                   currentPixel.hasAtLeastOneNeighborProcessed() == nil,
//                   currentPixel.canBeStartPixel(){
//
//                    let newLine = Line()
//                    currentPixel.color = .red
//                    currentPixel.pixelStatus = .processed
//                    newLine.startPixel = currentPixel
//                    newLine.pixelPath.append(currentPixel)
//                    newImgPixels3[y][x] = PixelColor.red.rawValue
//                    continue
//                }
//
//            }
//        }
        
        
        
        let data3 = newImgPixels2.flatMap({$0})
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
    
    func setPixelNeighbors(_ imgPixels: [String:ImagePixel],_ x: Int,_ y: Int,_ yMax: Int,_ xMax: Int,_ currentPixel: ImagePixel){
        if x != 0 && y != 0{
            currentPixel.topLeftPix = imgPixels["\(x - 1)-\(y - 1)"]
        }
        
        if y != 0{
            currentPixel.topPix = imgPixels["\(x)-\(y - 1)"]
        }
        
        if x < xMax && y != 0{
            currentPixel.topRightPix = imgPixels["\(x + 1)-\(y - 1)"]
        }
        
        if x < xMax{
            currentPixel.rightPix = imgPixels["\(x + 1)-\(y)"]
        }
        
        if x < xMax && y < yMax{
            currentPixel.bottomRightPix = imgPixels["\(x + 1)-\(y + 1)"]
        }
        
        if y < yMax{
            currentPixel.bottomPix = imgPixels["\(x)-\(y + 1)"]
        }
        
        if x != 0 && y < yMax{
            currentPixel.bottomLeftPix = imgPixels["\(x - 1)-\(y + 1)"]
        }
        
        if x != 0 {
            currentPixel.leftPix = imgPixels["\(x - 1)-\(y)"]
        }
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

class Line{
    var startPixel: ImagePixel!
    var endPixel: ImagePixel!
    var pixelPath: [ImagePixel] = []
    
    func processPixelPath() -> PixelQuadtrant?{
        if pixelPath.count > 3{
            //Return the Quadrant
        }
        return nil
    }
}

class ImagePixel {
    var color: PixelColor = .clear
    var xPos: Int
    var yPos: Int
    var largestYPos: Int?
    var topLeftPix: ImagePixel?{
        didSet{
            neighboringPixels.append(topLeftPix)
        }
    }
    var topPix: ImagePixel?{
        didSet{
            neighboringPixels.append(topPix)
        }
    }
    var topRightPix: ImagePixel?{
        didSet{
            neighboringPixels.append(topRightPix)
        }
    }
    var rightPix: ImagePixel?{
        didSet{
            neighboringPixels.append(rightPix)
        }
    }
    var bottomRightPix: ImagePixel?{
        didSet{
            neighboringPixels.append(bottomRightPix)
        }
    }
    var bottomPix: ImagePixel?{
        didSet{
            neighboringPixels.append(bottomPix)
        }
    }
    var bottomLeftPix: ImagePixel?{
        didSet{
            neighboringPixels.append(bottomLeftPix)
        }
    }
    var leftPix: ImagePixel? {
        didSet{
            neighboringPixels.append(leftPix)
        }
    }
    var neighboringPixels: [ImagePixel?] = []
    
    var pixelStatus: PixelStatus = .normal
    
    init(_ color: PixelColor, xPos: Int, yPos: Int) {
        self.color = color
        self.xPos = xPos
        self.yPos = yPos
    }
    
    func hasAtLeastOneNeighborProcessed() -> ImagePixel?{
        return neighboringPixels.first(where: {$0?.pixelStatus == .processed}) ?? nil
    }
    
    func largestNeighborYValue() -> Int?{
        let largestYValue = neighboringPixels.map({$0?.largestYPos ?? 0}).max() ?? 0
        if largestYValue == 0 {
            return nil
        } else {
            return largestYValue
        }
    }
    
    func canBeStartPixel() -> Bool{
        let colors = neighboringPixels.map({$0?.color})
        let count = colors.filter({$0 == .black}).count
        if count == 1{
            return true
        }
        return false
    }
}

enum PixelQuadtrant{
    case p1 // 270 - 314 degrees
    case p2 // 315 - 360 degrees
    case p3 // 0 - 44 degrees
    case p4 // 45 - 90 degrees
}

enum PixelStatus{
    case startLine
    case processed
    case normal
    case deleted
    case markForDelete
    case restoredRight
    case restoredLeft
    
}

enum PixelColor: UInt32{
    case clear = 0
    case white = 0b11111111111111111111111111111111 //UInt32.max
    case black = 255
    case red = 0b11111111000000000000000011111111
    case green = 0b00000000111111110000000011111111
    case blue = 0b00000000000000001111111111111111
    case yellow = 0b11111111111111110000000011111111
    
}


extension UIColor {

    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }

    class func DarkBlue() -> UIColor{
        return UIColor(rgb: 0x191C4B)
    }
    
    class func YellowLime() -> UIColor{
        return UIColor(rgb: 0xC5D428)
    }
}


