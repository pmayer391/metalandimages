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
            debugPrint("Image is not in RGB Format or Black and White also known as Format(.monochrome)")
        }
        
        var newImgPixels = modifiedImage
        //TODO: Add check for white pixels to save
        for y in 0 ..< newImgPixels.count {
            for x in 0 ..< newImgPixels[y].count{
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {return nil}
                if (x > 0 && x < cgImage.width - 1) && (y > 0 && y < cgImage.height - 1) {
                    /* DELETE Current Pixel if pixel has neighbor pixel to the right.
                        ex:    @ - *
                    */
                    if modifiedImage[y][x + 1] == PixelColor.black.rawValue {
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        newImgPixels[y][x] = PixelColor.brown.rawValue
                    }
                }
                setPixelNeighbors(pixelsImageMap, x, y, modifiedImage.count - 1, modifiedImage[y].count - 1, currentPixel)
            }
        }
        
        var newImgPixels2 = newImgPixels
        
        for y in 0 ..< newImgPixels2.count {
            for x in 0 ..< newImgPixels2[y].count{
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {return nil}
                if currentPixel.whitePixelNeigbors == 8, currentPixel.color == .white{
                    continue
                }
                
                /* RESTORE South East Pixels
                    ex#1:        *                  ex#2:    *
                                /                           /
                           * - @                           @
                */
                if currentPixel.color == .white,
                   currentPixel.bottomLeftPix?.color == .black,
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.leftPix?.color != .black,
                   currentPixel.topPix?.color != .black,
                   currentPixel.bottomRightPix?.color != .black,
                   currentPixel.topLeftPix?.color != .black,
                   currentPixel.topRightPix?.pixelStatus != .restoredRight,
                   !(currentPixel.bottomLeftPix?.color == .black &&
                     currentPixel.bottomLeftPix?.bottomRightPix?.color == .black),
                   !(currentPixel.leftPix?.color == .white &&
                     currentPixel.leftPix?.leftPix?.color == .black &&
                     currentPixel.bottomLeftPix?.color == .black){
                    
                    currentPixel.pixelStatus = .restoredLeft
                    currentPixel.color = .black
                    newImgPixels2[y][x] = PixelColor.red.rawValue
                }
                
                /* RESTORE East Facing Pixels
                    ex:    ... - @ - @ - *
                */
                if currentPixel.color == .white,
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.leftPix?.pixelStatus == .restoredLeft,
                   currentPixel.rightPix?.pixelStatus != .restoredLeft,
                   currentPixel.topRightPix?.color != .black,
                   currentPixel.bottomRightPix?.color != .black,
                   currentPixel.bottomPix?.color != .black,
                   currentPixel.topPix?.color != .black,
                   !(currentPixel.rightPix?.color == .black &&
                    currentPixel.rightPix?.bottomRightPix?.color == .black){
                    
                    currentPixel.pixelStatus = .restoredLeft
                    currentPixel.color = .black
                    newImgPixels2[y][x] = PixelColor.yellow.rawValue
                    
                } else if currentPixel.color == .white,
                  currentPixel.pixelStatus == .deleted,
                  currentPixel.leftPix?.pixelStatus == .restoredLeft,
                  currentPixel.topLeftPix?.color == .white,
                  currentPixel.topPix?.color == .white,
                  currentPixel.topRightPix?.color == .black,
                  currentPixel.rightPix?.color == .black,
                  currentPixel.bottomRightPix?.color == .white,
                  currentPixel.bottomPix?.color == .white,
                  currentPixel.bottomLeftPix?.color == .white{
                    
                    currentPixel.pixelStatus = .maybeRestoreLeft
                    currentPixel.color = .white
                    newImgPixels2[y][x] = PixelColor.gray.rawValue
                    
                } else if currentPixel.color == .black,
                 (currentPixel.pixelStatus == .normal ||
                  currentPixel.pixelStatus == .maybeDeleteBottom),
                  currentPixel.leftPix?.pixelStatus == .maybeRestoreLeft,
                  currentPixel.leftPix?.color == .white,
                  currentPixel.topLeftPix?.color == .white,
                  currentPixel.topPix?.color == .black,
                  currentPixel.topRightPix?.color == .white,
                  currentPixel.rightPix?.color == .white,
                  currentPixel.bottomRightPix?.color == .white,
                  currentPixel.bottomPix?.color == .white,
                  currentPixel.bottomLeftPix?.color == .white{
                    
                    currentPixel.leftPix?.pixelStatus = .restoredLeft
                    currentPixel.leftPix?.color = .black
                    newImgPixels2[y][currentPixel.leftPix?.xPos ?? x - 1] = PixelColor.yellow.rawValue
                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    newImgPixels2[y][x] = PixelColor.orange.rawValue
                }
                
                /* RESTORE South East Pixels
                    ex#1:    *                  ex#2:    *
                              \                           \
                               @ - *                       @
                */
                if currentPixel.color == .white,
                   currentPixel.topLeftPix?.color == .black,
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.topLeftPix?.pixelStatus != .restoredRight,
                   currentPixel.topLeftPix?.pixelStatus != .restoredLeft,
                   currentPixel.topLeftPix?.bottomLeftPix?.color != .black,
                   currentPixel.topLeftPix?.topRightPix?.color != .black,
                   currentPixel.leftPix?.color != .black,
                   currentPixel.topRightPix?.color != .black,
                   currentPixel.rightPix?.topRightPix?.color != .black,
                   !(currentPixel.topLeftPix?.color == .black &&
                    currentPixel.topLeftPix?.topRightPix?.color == .black &&
                    currentPixel.topLeftPix?.topPix?.topRightPix?.color == .black),
                   !(currentPixel.pixelNeighborObj.neighbors.contains(where: {$0.pixelStatus == .restoredLeft})){
                    
                    currentPixel.pixelStatus = .restoredRight
                    currentPixel.color = .black
                    newImgPixels2[y][x] = PixelColor.blue.rawValue
                }
                
                /* DELETE Unused Pixel Connectors
                    ex#1:    * - @          ex#2:    *
                                 |                   |
                                 *               * - @
                */
                if currentPixel.pixelStatus != .permanentlyDeleted,
                   currentPixel.rightPix?.color == .black,
                   (currentPixel.rightPix?.pixelStatus == .normal ||
                    currentPixel.rightPix?.pixelStatus == .maybeDeleteBottom),
                   currentPixel.rightPix?.leftPix?.color == .black,
                   (currentPixel.rightPix?.topPix?.color == .black ||
                    currentPixel.rightPix?.bottomPix?.color == .black),
                   (currentPixel.rightPix?.leftPix?.pixelStatus == .restoredLeft ||
                    currentPixel.rightPix?.leftPix?.pixelStatus == .restoredRight){
                    
                    currentPixel.rightPix?.color = .white
                    currentPixel.rightPix?.pixelStatus = .deleted
                    newImgPixels2[currentPixel.rightPix?.yPos ?? y][currentPixel.rightPix?.xPos ?? x + 1] = PixelColor.pink.rawValue
                    
                    // DELETE potentially bad intersection result
                    if currentPixel.rightPix?.bottomRightPix?.color == .black{
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        newImgPixels2[y][x] = PixelColor.pink.rawValue
                    }
                    continue
                }
                
                /* DELETE Intersections with more than  pixels intersecting
                    ex#1:    * - @ - *          ex#2:    *     *
                                 |                         \  /
                                 *                       * - @
                */
                if currentPixel.color == .black,
                   currentPixel.pixelNeighborObj.neighbors.filter({$0.color == .black}).count >= 3{
                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    newImgPixels2[y][x] = PixelColor.teal.rawValue
                }
                
                /* RESTORE East Facing Pixels
                    ex:    * - @ - @ - . . .
                */
                if currentPixel.color == .white,
                   currentPixel.pixelStatus == .deleted,
                   currentPixel.leftPix?.pixelStatus == .restoredRight,
                   currentPixel.rightPix?.pixelStatus != .restoredRight,
                   currentPixel.topRightPix?.color != .black,
                   currentPixel.bottomRightPix?.color != .black,
                   currentPixel.bottomPix?.color != .black,
                   currentPixel.topPix?.color != .black,
                   currentPixel.bottomLeftPix?.color != .black,
                   !(currentPixel.rightPix?.color == .black &&
                    currentPixel.rightPix?.topRightPix?.color == .black){
                    
                     currentPixel.pixelStatus = .restoredRight
                     currentPixel.color = .black
                     newImgPixels2[y][x] = PixelColor.green.rawValue
                    
                } else if currentPixel.color == .white,
                    currentPixel.pixelStatus == .deleted,
                    currentPixel.leftPix?.pixelStatus == .restoredRight,
                    currentPixel.topLeftPix?.color == .white,
                    currentPixel.topPix?.color == .white,
                    currentPixel.topRightPix?.color == .white,
                    currentPixel.rightPix?.color == .black,
                    currentPixel.bottomRightPix?.color == .black,
                    currentPixel.bottomPix?.color == .white,
                    currentPixel.bottomLeftPix?.color == .white{
                     
                    currentPixel.pixelStatus = .maybeRestoreRight
                    currentPixel.color = .white
                    newImgPixels2[y][x] = PixelColor.gray.rawValue
                    
                } else if currentPixel.color == .black,
                    currentPixel.pixelStatus == .normal,
                    currentPixel.leftPix?.pixelStatus == .maybeRestoreRight,
                    currentPixel.leftPix?.color == .white,
                    currentPixel.topLeftPix?.color == .white,
                    currentPixel.topPix?.color == .white,
                    currentPixel.topRightPix?.color == .white,
                    currentPixel.rightPix?.color == .white,
                    currentPixel.bottomRightPix?.color == .white,
                    currentPixel.bottomPix?.color == .black,
                    currentPixel.bottomLeftPix?.color == .white{
                    
                    currentPixel.leftPix?.pixelStatus = .restoredRight
                    currentPixel.leftPix?.color = .black
                    newImgPixels2[y][currentPixel.leftPix?.xPos ?? x - 1] = PixelColor.green.rawValue
                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    newImgPixels2[y][x] = PixelColor.orange.rawValue
                }
                
                /* DELETE Right Pixel Connector
                    ex:   *
                           \
                            @
                           /
                          *
                */
                if currentPixel.color == .black,
                   currentPixel.topLeftPix?.color == .black,
                   currentPixel.bottomLeftPix?.color == .black,
                   currentPixel.leftPix?.color == .white,
                   currentPixel.topRightPix?.color == .white,
                   currentPixel.bottomRightPix?.color == .white,
                   currentPixel.rightPix?.color == .white,
                   currentPixel.topPix?.color == .white,
                   currentPixel.bottomPix?.color == .white{

                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    newImgPixels2[y][x] = PixelColor.gold.rawValue
                }
                
                /* DELETE West Pixel Connector
                    ex:                     ex#2:
                                 *                   *
                                /                   /
                               *                    @
                               |                    \
                               @                     *
                                \
                                 *

                */
                if currentPixel.color == .black,
                   currentPixel.pixelStatus == .normal,
                   currentPixel.bottomLeftPix?.pixelStatus == .normal,
                   currentPixel.bottomLeftPix?.color == .black {
                    currentPixel.bottomLeftPix?.pixelStatus = .maybeDeleteBottom
                }
                
                if currentPixel.color == .black,
                   currentPixel.pixelStatus == .maybeDeleteBottom{
                    
                    if currentPixel.bottomRightPix?.color == .black,
                       currentPixel.bottomPix?.color == .white,
                       currentPixel.bottomLeftPix?.color == .white,
                       currentPixel.leftPix?.color == .white,
                       currentPixel.topLeftPix?.color == .white,
                       currentPixel.rightPix?.color == .white{
                        
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        newImgPixels2[y][x] = PixelColor.darkGreen.rawValue
                    } else if currentPixel.bottomRightPix?.color == .white,
                              currentPixel.bottomPix?.color == .black,
                              currentPixel.bottomLeftPix?.color == .white,
                              currentPixel.leftPix?.color == .white,
                              currentPixel.topLeftPix?.color == .white,
                              currentPixel.rightPix?.color == .white {
                        
                        currentPixel.bottomPix?.pixelStatus = .maybeDeleteBottom
                    }
                }
                
                /* DELETE Bottom Pixel Connector
                    ex:    *   *
                            \ /
                             @
                */
                if currentPixel.color == .black,
                   currentPixel.topLeftPix?.color == .black,
                   currentPixel.bottomLeftPix?.color == .white,
                   currentPixel.leftPix?.color == .white,
                   currentPixel.topRightPix?.color == .black,
                   currentPixel.bottomRightPix?.color == .white,
                   currentPixel.rightPix?.color == .white,
                   currentPixel.topPix?.color == .white,
                   currentPixel.bottomPix?.color == .white{

                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    newImgPixels2[y][x] = PixelColor.darkBlue.rawValue
                }
                
                /* DELETE Top Pixel Connector
                    ex:        @
                              / \
                             *   *
                */
                if currentPixel.color == .black,
                   currentPixel.topLeftPix?.color == .white,
                   currentPixel.bottomLeftPix?.color == .black,
                   currentPixel.leftPix?.color == .white,
                   currentPixel.topRightPix?.color == .white,
                   currentPixel.bottomRightPix?.color == .black,
                   currentPixel.rightPix?.color == .white,
                   currentPixel.topPix?.color == .white,
                   currentPixel.bottomPix?.color == .white{

                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    newImgPixels2[y][x] = PixelColor.darkGreen.rawValue
                }

                /* DELETE Intersections
                    ex:
                                 *
                                  \
                               * - @ - *
                                   |
                                   *
                              
                */
                let coloredPixelNeighbors = currentPixel.pixelNeighborObj.neighbors.filter({$0.color == .black})
                let notColoredPixelNeighbors = currentPixel.pixelNeighborObj.neighbors.filter({$0.color == .white && $0.pixelStatus == .deleted})
                if coloredPixelNeighbors.count >= 2,
                   notColoredPixelNeighbors.count >= 4,
                   currentPixel.color == .black {
                    let intsectingNeighbors = checkNeighborsForIntersection(currentPixel: currentPixel)
                    if intsectingNeighbors.count >= 3,
                       intsectingNeighbors.filter({$0.pixelStatus == .restoredRight}).count < 2{
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        newImgPixels2[y][x] = PixelColor.purple.rawValue
                        for pixel in intsectingNeighbors{
                            pixel.color = .white
                            currentPixel.pixelStatus = .permanentlyDeleted
                            newImgPixels2[pixel.yPos][pixel.xPos] = PixelColor.grayBlue.rawValue
                        }
                    }
                }
                
            }
        }
        
        var newImgPixels3 = newImgPixels2
        var lines: [Line] = []

        for y in 0 ..< newImgPixels3.count {
            for x in 0 ..< newImgPixels3[y].count{
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {return nil}
                if currentPixel.whitePixelNeigbors == 8, currentPixel.color == .white{
                    continue
                }
//                //Process Pixels
//                if let neighborProcessed = currentPixel.hasAtLeastOneNeighborProcessed(),
//                   currentPixel.pixelStatus != .processed,
//                   currentPixel.color == .black{
//                    let line = lines.filter({$0.pixelPath.contains(where: {$0.xPos == neighborProcessed.xPos && $0.yPos == neighborProcessed.yPos})}).first
//                    currentPixel.pixelStatus = .processed
//                    currentPixel.color = .orange
//                    line?.pixelPath.append(currentPixel)
//                    newImgPixels3[y][x] = PixelColor.orange.rawValue
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
//                    currentPixel.color = .purple
//                    currentPixel.pixelStatus = .processed
//                    newLine.startPixel = currentPixel
//                    newLine.pixelPath.append(currentPixel)
//                    newImgPixels3[y][x] = PixelColor.purple.rawValue
//                    lines.append(newLine)
//                    continue
//                }

            }
        }
        
        
        
        let data3 = newImgPixels3.flatMap({$0})
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
    
    func checkNeighborsForIntersection(currentPixel: ImagePixel) -> [ImagePixel]{
        for i in 2...3{
            switch i {
            case 2:
                var intersectingPixels: [ImagePixel] = []
                if let pix0 = currentPixel.topLeftPix?.topLeftPix, pix0.color == .black{
                    intersectingPixels.append(pix0)
                }
                if let pix1 = currentPixel.topPix?.topLeftPix, pix1.color == .black{
                    intersectingPixels.append(pix1)
                }
                if let pix2 = currentPixel.topPix?.topPix, pix2.color == .black{
                    intersectingPixels.append(pix2)
                }
                if let pix3 = currentPixel.topPix?.topRightPix, pix3.color == .black{
                    intersectingPixels.append(pix3)
                }
                if let pix4 = currentPixel.topRightPix?.topRightPix, pix4.color == .black{
                    intersectingPixels.append(pix4)
                }
                if let pix5 = currentPixel.rightPix?.topRightPix, pix5.color == .black{
                    intersectingPixels.append(pix5)
                }
                if let pix6 = currentPixel.rightPix?.rightPix, pix6.color == .black{
                    intersectingPixels.append(pix6)
                }
                if let pix7 = currentPixel.rightPix?.bottomRightPix, pix7.color == .black{
                    intersectingPixels.append(pix7)
                }
                if let pix8 = currentPixel.bottomRightPix?.bottomRightPix, pix8.color == .black{
                    intersectingPixels.append(pix8)
                }
                if let pix9 = currentPixel.bottomPix?.bottomRightPix, pix9.color == .black{
                    intersectingPixels.append(pix9)
                }
                if let pix10 = currentPixel.bottomPix?.bottomPix, pix10.color == .black{
                    intersectingPixels.append(pix10)
                }
                if let pix11 = currentPixel.bottomPix?.bottomLeftPix, pix11.color == .black{
                    intersectingPixels.append(pix11)
                }

                if let pix14 = currentPixel.bottomLeftPix?.bottomLeftPix, pix14.color == .black{
                    intersectingPixels.append(pix14)
                }
                if let pix15 = currentPixel.leftPix?.bottomLeftPix, pix15.color == .black{
                    intersectingPixels.append(pix15)
                }
                if let pix16 = currentPixel.leftPix?.leftPix, pix16.color == .black{
                    intersectingPixels.append(pix16)
                }
                if let pix17 = currentPixel.leftPix?.topLeftPix, pix17.color == .black{
                    intersectingPixels.append(pix17)
                }
                
                return intersectingPixels
                
            case 3:
                
                var intersectingPixels: [ImagePixel] = []
                if let pix0 = currentPixel.topLeftPix?.topLeftPix?.topLeftPix, pix0.color == .black{
                    intersectingPixels.append(pix0)
                }
                if let pix1 = currentPixel.topPix?.topLeftPix?.topLeftPix, pix1.color == .black{
                    intersectingPixels.append(pix1)
                }
                if let pix2 = currentPixel.topPix?.topPix?.topLeftPix, pix2.color == .black{
                    intersectingPixels.append(pix2)
                }
                if let pix3 = currentPixel.topPix?.topPix?.topPix, pix3.color == .black{
                    intersectingPixels.append(pix3)
                }
                if let pix4 = currentPixel.topPix?.topPix?.topRightPix, pix4.color == .black{
                    intersectingPixels.append(pix4)
                }
                if let pix5 = currentPixel.topPix?.topRightPix?.topRightPix, pix5.color == .black{
                    intersectingPixels.append(pix5)
                }
                if let pix6 = currentPixel.topRightPix?.topRightPix?.topRightPix, pix6.color == .black{
                    intersectingPixels.append(pix6)
                }
                if let pix7 = currentPixel.rightPix?.topRightPix?.topRightPix, pix7.color == .black{
                    intersectingPixels.append(pix7)
                }
                if let pix8 = currentPixel.rightPix?.rightPix?.topRightPix, pix8.color == .black{
                    intersectingPixels.append(pix8)
                }
                if let pix9 = currentPixel.rightPix?.rightPix?.rightPix, pix9.color == .black{
                    intersectingPixels.append(pix9)
                }
                if let pix10 = currentPixel.rightPix?.rightPix?.bottomRightPix, pix10.color == .black{
                    intersectingPixels.append(pix10)
                }
                if let pix11 = currentPixel.rightPix?.bottomRightPix?.bottomRightPix, pix11.color == .black{
                    intersectingPixels.append(pix11)
                }
                if let pix12 = currentPixel.bottomRightPix?.bottomRightPix?.bottomRightPix, pix12.color == .black{
                    intersectingPixels.append(pix12)
                }
                if let pix13 = currentPixel.bottomPix?.bottomRightPix?.bottomRightPix, pix13.color == .black{
                    intersectingPixels.append(pix13)
                }
                if let pix13 = currentPixel.bottomPix?.bottomPix?.bottomRightPix, pix13.color == .black{
                    intersectingPixels.append(pix13)
                }
                if let pix14 = currentPixel.bottomPix?.bottomPix?.bottomPix, pix14.color == .black{
                    intersectingPixels.append(pix14)
                }
                if let pix15 = currentPixel.bottomPix?.bottomPix?.bottomLeftPix, pix15.color == .black{
                    intersectingPixels.append(pix15)
                }
                if let pix16 = currentPixel.bottomPix?.bottomLeftPix?.bottomLeftPix, pix16.color == .black{
                    intersectingPixels.append(pix16)
                }
                if let pix17 = currentPixel.bottomLeftPix?.bottomLeftPix?.bottomLeftPix, pix17.color == .black{
                    intersectingPixels.append(pix17)
                }
                if let pix18 = currentPixel.leftPix?.bottomLeftPix?.bottomLeftPix, pix18.color == .black{
                    intersectingPixels.append(pix18)
                }
                if let pix19 = currentPixel.leftPix?.leftPix?.bottomLeftPix, pix19.color == .black{
                    intersectingPixels.append(pix19)
                }
                if let pix20 = currentPixel.leftPix?.leftPix?.leftPix, pix20.color == .black{
                    intersectingPixels.append(pix20)
                }
                if let pix21 = currentPixel.leftPix?.leftPix?.topLeftPix, pix21.color == .black{
                    intersectingPixels.append(pix21)
                }
                if let pix22 = currentPixel.leftPix?.topLeftPix?.topLeftPix, pix22.color == .black{
                    intersectingPixels.append(pix22)
                }
                if let pix23 = currentPixel.topLeftPix?.topLeftPix?.topLeftPix, pix23.color == .black{
                    intersectingPixels.append(pix23)
                }
                return intersectingPixels
                
            default:
                return []
            }
        }
        return []
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

class PixelNieghbors {
    var neighbors: [ImagePixel] = []
}

class ImagePixel {
    var color: PixelColor = .clear
    var xPos: Int
    var yPos: Int
    var pixelNeighborObj = PixelNieghbors()
    var pixelStatus: PixelStatus = .normal
    var whitePixelNeigbors = 0
    
    var topLeftPix: ImagePixel?{
        didSet{
            if let pixel = topLeftPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var topPix: ImagePixel?{
        didSet{
            if let pixel = topPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var topRightPix: ImagePixel?{
        didSet{
            if let pixel = topRightPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var rightPix: ImagePixel?{
        didSet{
            if let pixel = rightPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var bottomRightPix: ImagePixel?{
        didSet{
            if let pixel = bottomRightPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var bottomPix: ImagePixel?{
        didSet{
            if let pixel = bottomPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var bottomLeftPix: ImagePixel?{
        didSet{
            if let pixel = bottomLeftPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var leftPix: ImagePixel? {
        didSet{
            if let pixel = leftPix{
                pixelNeighborObj.neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    
    init(_ color: PixelColor, xPos: Int, yPos: Int) {
        self.color = color
        self.xPos = xPos
        self.yPos = yPos
    }
    
    func hasAtLeastOneNeighborProcessed() -> ImagePixel?{
        return pixelNeighborObj.neighbors.first(where: {$0.pixelStatus == .processed})
    }
    
    
    func canBeStartPixel() -> Bool{
        let colors = pixelNeighborObj.neighbors.map({$0.color})
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
    case processed
    case normal
    case deleted
    case permanentlyDeleted
    case maybeDeleteBottom
    case restoredRight
    case maybeRestoreRight
    case restoredLeft
    case maybeRestoreLeft
    
}

enum PixelColor: UInt32{
    case clear = 0
    case white = 0b11111111111111111111111111111111 //UInt32.max
    case black = 255
    case red = 0b11111111000000000000000011111111
    case green = 0b00000000111111110000000011111111
    case blue = 0b00000000000000001111111111111111
    case yellow = 0b11111111111111110000000011111111
    case pink = 0b11111111000000001111111111111111
    case teal = 0b00000000111111111111111111111111
    case orange = 0xFFA500FF
    case purple = 0x6A0DADFF
    case limeGreen = 0xc8f542FF
    case gold = 0xDAA520FF
    case brown = 0x964B00FF
    case gray = 0x808080FF
    case grayBlue = 0x43A6C6FF
    case darkBlue = 0x000C66FF
    case darkGreen = 0x024b30FF
    
}


