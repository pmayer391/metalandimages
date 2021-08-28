//
//  ParseImage.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 5/12/21.
//

import Foundation
import UIKit
import CoreGraphics
import Accelerate

//https://stackoverflow.com/questions/38229027/how-to-create-a-bitmap-image-from-the-byte-array-in-swift
//https://stackoverflow.com/questions/36393436/convert-a-double-array-to-uiimage-in-swift

class ParseImage{
    
    func parseImage(
        inputImage: UIImage,
        runInDebugMode: Bool = false,
        degreeOfSignatureAccuracy: SignatureAccuracy = .standard
    ) -> Result<ParsedImage>{
        
        //MARK: - INIT VARS
        let startTiming = CFAbsoluteTimeGetCurrent()
        guard let cgImage = inputImage.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data)
        else {
            return .failure(.unableToParseImage("Couldn't access CG Image Data"))
        }
        var imagePixelsPhase1 = [[UInt32]](
            repeating: [UInt32](
                repeating: 0,
                count: cgImage.width),
            count: cgImage.height)
        var pixelsImageMap: [String:ImagePixel] = [:]
        let parsedImageObj = ParsedImage()
        var imagePixelsPhase2 = imagePixelsPhase1
        var imagePixelsPhase3 = imagePixelsPhase2
        var imagePixelsPhase4 = imagePixelsPhase3
        var vectors: [PixelVector] = []
        var quadrantDictionary: [VectorQuadtrant:Int] = [:]
        for i in 0..<Int(degreeOfSignatureAccuracy.rawValue){
            switch i {
            case VectorQuadtrant.q1.rawValue:
                quadrantDictionary[VectorQuadtrant.q1] = 0
            case VectorQuadtrant.q2.rawValue:
                quadrantDictionary[VectorQuadtrant.q2] = 0
            case VectorQuadtrant.q3.rawValue:
                quadrantDictionary[VectorQuadtrant.q3] = 0
            case VectorQuadtrant.q4.rawValue:
                quadrantDictionary[VectorQuadtrant.q4] = 0
            case VectorQuadtrant.q5.rawValue:
                quadrantDictionary[VectorQuadtrant.q5] = 0
            case VectorQuadtrant.q6.rawValue:
                quadrantDictionary[VectorQuadtrant.q6] = 0
            default:
                quadrantDictionary[VectorQuadtrant.q1] = 0
            }
        }

        //MARK: - PHASE 1 - Converts image to black and white pixels only.
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
                    
                    if r == 0 && g == 0 && b == 0 && a >= 200{ //If its already black
                        color = .black
                    } else{ //White
                        color = .white
                    }
                    
                    //Boundry Check: If pixel is on the boundry then turn it white.
                    if x == 0 || x == cgImage.width - 1 || y == 0 || y == cgImage.height - 1 {
                        color = .white
                    }
                    
                    imagePixelsPhase1[y][x] = color.rawValue
                    let newPixel = ImagePixel(color, xPos: x, yPos: y)
                    pixelsImageMap["\(x)-\(y)"] = newPixel
                }
            }
        } else{
            return .failure(.invalidImageSupplied("Image is not in the correct format. Acceptable formats include RGBA and MonoChrome"))
        }
        let phase1Interval: Double = Double(CFAbsoluteTimeGetCurrent() - startTiming)
        
        //MARK: - PHASE 2 - Delete all neighbor pixels to the left.
        imagePixelsPhase2 = imagePixelsPhase1
        for y in 0 ..< imagePixelsPhase2.count {
            for x in 0 ..< imagePixelsPhase2[y].count{
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {
                    return .failure(.unableToParseImage("Unable to access Image Pixel Dictionary"))}
                if (x > 0 && x < cgImage.width - 1) && (y > 0 && y < cgImage.height - 1) {
                    /* DELETE Current Pixel if pixel has neighbor pixel to the right.
                        ex:    @ - *
                    */
                    if imagePixelsPhase1[y][x + 1] == PixelColor.black.rawValue {
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        imagePixelsPhase2[y][x] = PixelColor.brown.rawValue
                    }
                }
                setPixelNeighbors(
                    pixelsImageMap,
                    x,
                    y,
                    imagePixelsPhase1.count - 1,
                    imagePixelsPhase1[y].count - 1,
                    currentPixel)
            }
        }
        let phase2Interval: Double = Double(CFAbsoluteTimeGetCurrent() - startTiming)
        
        //MARK: - PHASE 3 - Transform image signature into vectors.
        imagePixelsPhase3 = imagePixelsPhase2
        for y in 0 ..< imagePixelsPhase3.count {
            for x in 0 ..< imagePixelsPhase3[y].count{
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {
                    return .failure(.unableToParseImage("Unable to access Image Pixel Dictionary"))}
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
                   currentPixel.topPix?.pixelStatus != .maybeDeleteBottomLeft,
                   currentPixel.topLeftPix?.topPix?.color != .black,
                   !(currentPixel.bottomLeftPix?.color == .black &&
                     currentPixel.bottomLeftPix?.bottomRightPix?.color == .black),
                   !(currentPixel.leftPix?.color == .white &&
                     currentPixel.leftPix?.leftPix?.color == .black &&
                     currentPixel.bottomLeftPix?.color == .black){
                    
                    currentPixel.pixelStatus = .restoredLeft
                    currentPixel.color = .black
                    imagePixelsPhase3[y][x] = PixelColor.red.rawValue
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
                   currentPixel.topPix?.topPix?.color != .black,
                   !(currentPixel.rightPix?.color == .black &&
                    currentPixel.rightPix?.bottomRightPix?.color == .black){
                    
                    currentPixel.pixelStatus = .restoredLeft
                    currentPixel.color = .black
                    imagePixelsPhase3[y][x] = PixelColor.yellow.rawValue
                    
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
                    imagePixelsPhase3[y][x] = PixelColor.gray.rawValue
                    
                } else if currentPixel.color == .black,
                 (currentPixel.pixelStatus == .normal ||
                  currentPixel.pixelStatus == .maybeDeleteBottomLeft),
                  currentPixel.leftPix?.pixelStatus == .maybeRestoreLeft,
                  currentPixel.leftPix?.color == .white,
                  currentPixel.topLeftPix?.color == .white,
                  currentPixel.topPix?.color == .black,
                  currentPixel.topRightPix?.color == .white,
                  currentPixel.rightPix?.color == .white,
                  currentPixel.bottomRightPix?.color == .white,
                  currentPixel.bottomPix?.color == .white,
                  currentPixel.bottomLeftPix?.color == .white{
                    
                    currentPixel.leftPix?.pixelStatus = .deleted
                    currentPixel.leftPix?.color = .white
                    imagePixelsPhase3[y][currentPixel.leftPix?.xPos ?? x - 1] = PixelColor.orange.rawValue
                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    imagePixelsPhase3[y][x] = PixelColor.orange.rawValue
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
                   currentPixel.topLeftPix?.pixelStatus != .maybeDeleteBottomRight,
                   currentPixel.topPix?.pixelStatus != .deleted,
                   !(currentPixel.topLeftPix?.color == .black &&
                    currentPixel.rightPix?.pixelStatus == .deleted &&
                    currentPixel.leftPix?.pixelStatus == .deleted &&
                    currentPixel.bottomLeftPix?.color == .black),
                   !(currentPixel.topLeftPix?.color == .black &&
                    currentPixel.rightPix?.pixelStatus == .deleted &&
                    currentPixel.bottomRightPix?.color == .black &&
                    currentPixel.leftPix?.pixelStatus == .deleted),
                   !(currentPixel.topLeftPix?.color == .black &&
                    currentPixel.topLeftPix?.topRightPix?.color == .black &&
                    currentPixel.topLeftPix?.topPix?.topRightPix?.color == .black),
                   !(currentPixel.neighbors.contains(where: {$0.pixelStatus == .restoredLeft})){
                    
                    currentPixel.pixelStatus = .restoredRight
                    currentPixel.color = .black
                    imagePixelsPhase3[y][x] = PixelColor.blue.rawValue
                }
                
                /* DELETE Unused Pixel Connectors
                    ex#1:    * - @          ex#2:    *
                                 |                   |
                                 *               * - @
                */
                if currentPixel.pixelStatus != .permanentlyDeleted,
                   currentPixel.rightPix?.color == .black,
                   (currentPixel.rightPix?.pixelStatus == .normal ||
                    currentPixel.rightPix?.pixelStatus == .maybeDeleteBottomLeft ||
                    currentPixel.rightPix?.pixelStatus == .maybeDeleteBottomRight),
                   currentPixel.rightPix?.leftPix?.color == .black,
                   (currentPixel.rightPix?.topPix?.color == .black ||
                    currentPixel.rightPix?.bottomPix?.color == .black),
                   (currentPixel.rightPix?.leftPix?.pixelStatus == .restoredLeft ||
                    currentPixel.rightPix?.leftPix?.pixelStatus == .restoredRight){
                    
                    currentPixel.rightPix?.color = .white
                    currentPixel.rightPix?.pixelStatus = .deleted
                    imagePixelsPhase3[currentPixel.rightPix?.yPos ?? y][currentPixel.rightPix?.xPos ?? x + 1] = PixelColor.pink.rawValue
                    
                    // DELETE potentially bad intersection result
                    if currentPixel.rightPix?.bottomRightPix?.color == .black{
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        imagePixelsPhase3[y][x] = PixelColor.pink.rawValue
                    }
                    continue
                }
                
                /* DELETE Intersections with more than  pixels intersecting
                    ex#1:    * - @ - *          ex#2:    *     *
                                 |                         \  /
                                 *                       * - @
                */
                if currentPixel.color == .black,
                   currentPixel.neighbors.filter({$0.color == .black}).count >= 3{
                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    imagePixelsPhase3[y][x] = PixelColor.teal.rawValue
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
                   currentPixel.bottomPix?.bottomPix?.color != .black,
                   !(currentPixel.rightPix?.color == .black &&
                    currentPixel.rightPix?.topRightPix?.color == .black){
                    
                     currentPixel.pixelStatus = .restoredRight
                     currentPixel.color = .black
                     imagePixelsPhase3[y][x] = PixelColor.green.rawValue
                    
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
                    imagePixelsPhase3[y][x] = PixelColor.gray.rawValue
                    
                } else if currentPixel.color == .black,
                   (currentPixel.pixelStatus == .normal ||
                    currentPixel.pixelStatus == .maybeDeleteBottomRight),
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
                    imagePixelsPhase3[y][currentPixel.leftPix?.xPos ?? x - 1] = PixelColor.green.rawValue
                    currentPixel.color = .white
                    currentPixel.pixelStatus = .deleted
                    imagePixelsPhase3[y][x] = PixelColor.orange.rawValue
                    if currentPixel.bottomPix?.color == .black{
                        currentPixel.bottomPix?.pixelStatus = .maybeDeleteBottomLeft
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
                    imagePixelsPhase3[y][x] = PixelColor.darkBlue.rawValue
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
                    imagePixelsPhase3[y][x] = PixelColor.darkGreen.rawValue
                }
                
                /* DELETE West Pixel Connector
                    ex:                     ex#2:
                             *                   *
                              \                   \
                               *                   @
                               |                  /
                               @                 *
                              /
                             *

                */
                if currentPixel.color == .black,
                   currentPixel.bottomRightPix?.color == .black {
                    currentPixel.bottomRightPix?.pixelStatus = .maybeDeleteBottomLeft
                }
                
                if currentPixel.color == .black,
                   currentPixel.pixelStatus == .maybeDeleteBottomLeft{
                    
                    if currentPixel.bottomLeftPix?.color == .black,
                       currentPixel.bottomPix?.color == .white,
                       currentPixel.bottomRightPix?.color == .white,
                       currentPixel.leftPix?.color == .white,
                       currentPixel.topLeftPix?.color == .white,
                       currentPixel.rightPix?.color == .white,
                       currentPixel.topRightPix?.color == .white{
                        
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        imagePixelsPhase3[y][x] = PixelColor.lightGreen.rawValue
                    }
                    
                    if currentPixel.bottomRightPix?.color == .white,
                       currentPixel.bottomPix?.color == .black,
                       currentPixel.bottomLeftPix?.color == .white,
                       currentPixel.leftPix?.color == .white,
                       currentPixel.rightPix?.color == .white,
                       currentPixel.topRightPix?.color == .white{
                        
                        currentPixel.bottomPix?.pixelStatus = .maybeDeleteBottomLeft
                    }
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
                   currentPixel.bottomLeftPix?.color == .black {
                    currentPixel.bottomLeftPix?.pixelStatus = .maybeDeleteBottomRight
                }
                
                if currentPixel.color == .black,
                   currentPixel.pixelStatus == .maybeDeleteBottomRight{
                    
                    if currentPixel.bottomRightPix?.color == .black,
                       currentPixel.bottomPix?.color == .white,
                       currentPixel.bottomLeftPix?.color == .white,
                       currentPixel.leftPix?.color == .white,
                       currentPixel.topLeftPix?.color == .white,
                       currentPixel.rightPix?.color == .white{
                        
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        imagePixelsPhase3[y][x] = PixelColor.darkGreen.rawValue
                        
                    } else if currentPixel.bottomRightPix?.color == .white,
                              currentPixel.bottomPix?.color == .black,
                              currentPixel.bottomLeftPix?.color == .white,
                              currentPixel.leftPix?.color == .white,
                              currentPixel.topLeftPix?.color == .white,
                              currentPixel.rightPix?.color == .white {
                        
                        currentPixel.bottomPix?.pixelStatus = .maybeDeleteBottomRight
                    }
                }

                /* DELETE Intersections
                    ex:
                                 *
                                  \
                               * - @ - *
                                   |
                                   *
                              
                */
                let coloredPixelNeighbors = currentPixel.neighbors.filter({$0.color == .black})
                let notColoredPixelNeighbors = currentPixel.neighbors.filter({$0.color == .white && $0.pixelStatus == .deleted})
                if coloredPixelNeighbors.count >= 2,
                   notColoredPixelNeighbors.count >= 4,
                   currentPixel.color == .black {
                    let intsectingNeighbors = checkNeighborsForIntersection(currentPixel: currentPixel)
                    if intsectingNeighbors.count >= 3,
                       intsectingNeighbors.filter({$0.pixelStatus == .restoredRight}).count < 2{
                        currentPixel.color = .white
                        currentPixel.pixelStatus = .deleted
                        imagePixelsPhase3[y][x] = PixelColor.gold.rawValue
                        for pixel in intsectingNeighbors{
                            pixel.color = .white
                            currentPixel.pixelStatus = .permanentlyDeleted
                            imagePixelsPhase3[pixel.yPos][pixel.xPos] = PixelColor.grayBlue.rawValue
                        }
                    }
                }
            }
        }
        let phase3Interval: Double = Double(CFAbsoluteTimeGetCurrent() - startTiming)

        //MARK: - PHASE 4 - Process all vectors and mapped them to their appropriate quadrants.
        for y in 0 ..< imagePixelsPhase4.count {
            for x in 0 ..< imagePixelsPhase4[y].count{
                guard let currentPixel = pixelsImageMap["\(x)-\(y)"] else {
                    return .failure(.unableToParseImage("Unable to access Image Pixel Dictionary"))}
                //Process Pixels into Vectors
                if currentPixel.color == .black,
                   currentPixel.hasAtLeastOneNeighborProcessed() == nil,
                   currentPixel.canBeStartPixel(){

                    let vector = PixelVector()
                    vector.startPixel = currentPixel
                    currentPixel.pixelStatus = .processed
                    imagePixelsPhase4[y][x] = PixelColor.red.rawValue
                    processLine(pixelImage: currentPixel, line: vector, &imagePixelsPhase4)
                    let lastPixel = vector.pixelPath.last
                    vector.endPixel = lastPixel
                    imagePixelsPhase4[lastPixel?.yPos ?? 0][lastPixel?.xPos ?? 0] = PixelColor.white.rawValue
                    if vector.pixelPath.count > 6{
                        vectors.append(vector)
                    }
                    continue
                }
            }
        }
        
        //MARK: - MAP vectors and quadrants together.
        let quadrantRanges = generateQuadrants(degreeOfSignatureAccuracy).0
        let quadrants = generateQuadrants(degreeOfSignatureAccuracy).1
        for vector in vectors{
            if let quadrantRangeIndex = quadrantRanges.firstIndex(where: {$0.contains(vector.angle)}){
                let quadrant = quadrants[quadrantRangeIndex]
                quadrantDictionary[quadrant] = (quadrantDictionary[quadrant] ?? 0) + 1
            }
        }
        parsedImageObj.quadrants = quadrantDictionary
        let phase4Interval: Double = Double(CFAbsoluteTimeGetCurrent() - startTiming)
        
        //MARK: - Debug Info
        let secondsPhase1 = (String(format: "%.4f", phase1Interval))
        let secondsPhase2 = (String(format: "%.4f", phase2Interval))
        let secondsPhase3 = (String(format: "%.4f", phase3Interval))
        let secondsPhase4 = (String(format: "%.4f", phase4Interval))
        debugPrint("Phase1: \(secondsPhase1)")
        debugPrint("Phase2: \(secondsPhase2)")
        debugPrint("Phase3: \(secondsPhase3)")
        debugPrint("Phase4: \(secondsPhase4)")
        
        if runInDebugMode{
            parsedImageObj.debugImageDic[.phase1] = generateDebugImage(pixelArray: imagePixelsPhase1, cgImage: cgImage)
            parsedImageObj.debugImageDic[.phase2] = generateDebugImage(pixelArray: imagePixelsPhase2, cgImage: cgImage)
            parsedImageObj.debugImageDic[.phase3] = generateDebugImage(pixelArray: imagePixelsPhase3, cgImage: cgImage)
            parsedImageObj.debugImageDic[.phase4] = generateDebugImage(pixelArray: imagePixelsPhase4, cgImage: cgImage)
        }
        
        return .success(parsedImageObj)
    }
    
    
    //MARK: - Functions
    func generateQuadrants(_ degreeOfSignatureAccuracy: SignatureAccuracy) -> ([Range<Double>], [VectorQuadtrant]){
        let quadrantDegrees = 180.0 / degreeOfSignatureAccuracy.rawValue
        var quadrantRanges: [Range<Double>] = []
        var quadrants: [VectorQuadtrant] = []

        let q1PosMax: Double = 90
        let q1NegMax: Double = -90
        let q1PosMin = q1PosMax - (quadrantDegrees / 2)
        let q1NegMin = q1NegMax + (quadrantDegrees / 2)
        let q1PosRange: Range<Double> = q1PosMin..<q1PosMax
        let q1NegRange: Range<Double> = q1NegMax..<q1NegMin
        quadrantRanges.append(q1PosRange)
        quadrants.append(VectorQuadtrant.q1)
        quadrantRanges.append(q1NegRange)
        quadrants.append(VectorQuadtrant.q1)

        switch degreeOfSignatureAccuracy {
        case .relaxed:
            let q2And3Min = q1PosMin - quadrantDegrees
            let q2Range: Range<Double> = q2And3Min..<q1PosMin
            quadrantRanges.append(q2Range)
            quadrants.append(VectorQuadtrant.q2)
            let q3Range: Range<Double>  = q1NegMin..<q2And3Min
            quadrantRanges.append(q3Range)
            quadrants.append(VectorQuadtrant.q3)
        case .standard:
            let q2Min = q1PosMin - quadrantDegrees
            let q2Range: Range<Double> = q2Min..<q1PosMin
            quadrantRanges.append(q2Range)
            quadrants.append(VectorQuadtrant.q2)
            let q4Min = q1NegMin + quadrantDegrees
            let q4Range: Range<Double> = q1NegMin..<q4Min
            quadrantRanges.append(q4Range)
            quadrants.append(VectorQuadtrant.q4)
            let q3Range: Range<Double>  = q4Min..<q2Min
            quadrantRanges.append(q3Range)
            quadrants.append(VectorQuadtrant.q3)
        case .stern:
            let q2Min = q1PosMin - quadrantDegrees
            let q2Range: Range<Double> = q2Min..<q1PosMin
            quadrantRanges.append(q2Range)
            quadrants.append(VectorQuadtrant.q2)
            let q3Min = q2Min - quadrantDegrees
            let q3Range: Range<Double>  = q3Min..<q2Min
            quadrantRanges.append(q3Range)
            quadrants.append(VectorQuadtrant.q3)
            let q5Min = q1NegMin + quadrantDegrees
            let q5Range: Range<Double> = q1NegMin..<q5Min
            quadrantRanges.append(q5Range)
            quadrants.append(VectorQuadtrant.q5)
            let q4Min = q5Min + quadrantDegrees
            let q4Range: Range<Double> = q5Min..<q4Min
            quadrantRanges.append(q4Range)
            quadrants.append(VectorQuadtrant.q4)
        case .strict:
            let q2Min = q1PosMin - quadrantDegrees
            let q2Range: Range<Double> = q2Min..<q1PosMin
            quadrantRanges.append(q2Range)
            quadrants.append(VectorQuadtrant.q2)
            let q3Min = q2Min - quadrantDegrees
            let q3Range: Range<Double>  = q3Min..<q2Min
            quadrantRanges.append(q3Range)
            quadrants.append(VectorQuadtrant.q3)
            let q5Min = q1NegMin + quadrantDegrees
            let q5Range: Range<Double> = q1NegMin..<q5Min
            quadrantRanges.append(q5Range)
            quadrants.append(VectorQuadtrant.q5)
            let q4Min = q5Min + quadrantDegrees
            let q4Range: Range<Double> = q5Min..<q4Min
            quadrantRanges.append(q4Range)
            quadrants.append(VectorQuadtrant.q4)
            let q6Range: Range<Double> = q4Min..<q3Min
            quadrantRanges.append(q6Range)
            quadrants.append(VectorQuadtrant.q6)
        }
        return (quadrantRanges, quadrants)
    }
    
    func generateDebugImage(pixelArray: [[UInt32]], cgImage: CGImage) -> UIImage?{
        let imageData = pixelArray.flatMap({$0})
        let width = Int(cgImage.width)
        let height = Int(cgImage.height)
        let bitsPerComponent = 8
        let bytesPerPixel2 = 4
        let bytesPerRow = width * bytesPerPixel2
        let imageDataMemoryAllocation = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue

        guard let imageContext = CGContext(data: imageDataMemoryAllocation,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: bitsPerComponent,
                                           bytesPerRow: bytesPerRow,
                                           space: colorSpace,
                                           bitmapInfo: bitmapInfo),
              let buffer = imageContext.data?.bindMemory(to: UInt32.self,
                                                         capacity: imageData.count)
        else { return nil}

        for index in 0 ..< width * height {
            buffer[index] = imageData[index]
        }
        return imageContext.makeImage().flatMap { UIImage(cgImage: $0) }
    }
    
    func processLine(pixelImage: ImagePixel?, line: PixelVector, _ imgPixels: inout [[UInt32]]){
        guard let currentPixel = pixelImage else { return }
        
        let nextNeighbor = currentPixel.neighbors.filter({$0.color == .black && $0.pixelStatus != .processed})
        if nextNeighbor.count == 1{
            guard let pixelToProcess = nextNeighbor.first else {debugPrint("Something strange happened."); return }
            pixelToProcess.pixelStatus = .processed
            imgPixels[pixelToProcess.yPos][pixelToProcess.xPos] = PixelColor.knowInkYellow.rawValue
            line.pixelPath.append(pixelToProcess)
            processLine(pixelImage: pixelToProcess, line: line, &imgPixels)
        } else if nextNeighbor.count == 0{
            return
        } else{
            debugPrint("Something went awfully wrong with parsing this signature.")
        }
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
        
        //TODO: Fix this. . . This is a really ugly solution and needs a better approach to check whether one list contains an elemnt from another list.
        var tempIntersectingPixels = intersectingPixels
        for pixel in intersectingPixels{
            let neighbors = pixel.neighbors
            for (index2, pixel2) in intersectingPixels.enumerated(){
                if neighbors.contains(where: {$0.xPos == pixel2.xPos && $0.yPos == pixel2.yPos}) {
                    let range = 0..<tempIntersectingPixels.count
                    if range.contains(index2){
                        tempIntersectingPixels.remove(at: index2)
                    }
                }
            }
        }
        return tempIntersectingPixels
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

class PixelVector{
    var startPixel: ImagePixel!
    var endPixel: ImagePixel!{
        didSet{
            let firstPixel: ImagePixel!
            let secondPixel: ImagePixel!
            if startPixel.xPos <= endPixel.xPos{
                firstPixel = startPixel
                secondPixel = endPixel
            } else {
                firstPixel = endPixel
                secondPixel = startPixel
            }
            angle = atan((Double(secondPixel.yPos) - Double(firstPixel.yPos)) / (Double(secondPixel.xPos) - Double(firstPixel.xPos))) * (180 / Double.pi)
        }
    }
    var pixelPath: [ImagePixel] = []
    var angle: Double = 0.0
    
}

class ImagePixel{
    var color: PixelColor = .clear
    var xPos: Int
    var yPos: Int
    var pixelStatus: PixelStatus = .normal
    var whitePixelNeigbors = 0
    var neighbors: [ImagePixel] = []
    
    var topLeftPix: ImagePixel?{
        didSet{
            if let pixel = topLeftPix{
                neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var topPix: ImagePixel?{
        didSet{
            if let pixel = topPix{
                neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var topRightPix: ImagePixel?{
        didSet{
            if let pixel = topRightPix{
                neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var rightPix: ImagePixel?{
        didSet{
            if let pixel = rightPix{
                neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var bottomRightPix: ImagePixel?{
        didSet{
            if let pixel = bottomRightPix{
                neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var bottomPix: ImagePixel?{
        didSet{
            if let pixel = bottomPix{
                neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var bottomLeftPix: ImagePixel?{
        didSet{
            if let pixel = bottomLeftPix{
                neighbors.append(pixel)
                if pixel.color == .white {whitePixelNeigbors = whitePixelNeigbors + 1}
            } else{
                whitePixelNeigbors = whitePixelNeigbors + 1
            }
        }
    }
    var leftPix: ImagePixel? {
        didSet{
            if let pixel = leftPix{
                neighbors.append(pixel)
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
        return neighbors.first(where: {$0.pixelStatus == .processed})
    }
    
    
    func processPixelNeighbors() -> [ImagePixel]{
        return neighbors.filter({$0.color == .black && $0.pixelStatus != .processed})
    }
    
    
    func canBeStartPixel() -> Bool{
        if neighbors.filter({$0.color == .black}).count == 1{
            return true
        }
        return false
    }
}







public class ParsedImage {
    var quadrants: [VectorQuadtrant:Int] = [:]
    var silentErrors: [String] = []
    var debugImageDic: [DebugImageName: UIImage] = [:]
}

enum DebugImageName: String{
    case phase1 = "PHASE: 1 - Black White Image"
    case phase2 = "PHASE: 2 - Trimmed Image"
    case phase3 = "PHASE: 3 - Altered Image"
    case phase4 = "PHASE: 4 - Processed Image"
}

enum VectorQuadtrant: Int{
    case q1 = 0
    case q2 = 1
    case q3 = 2
    case q4 = 3
    case q5 = 4
    case q6 = 5
}

enum PixelStatus{
    case processed
    case normal
    case deleted
    case permanentlyDeleted
    case maybeDeleteBottomLeft
    case maybeDeleteBottomRight
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
    case lightGreen = 0x90EE90FF
    case gold = 0xDAA520FF
    case brown = 0x964B00FF
    case gray = 0x808080FF
    case grayBlue = 0x43A6C6FF
    case darkBlue = 0x000C66FF
    case darkGreen = 0x024b30FF
    case knowInkYellow = 0xC5D428FF
}

public enum SignatureAccuracy: Double{
    case relaxed = 3
    case standard = 4
    case stern = 5
    case strict = 6
}

public enum ImageParserError: Error {
    case invalidImageSupplied(String)
    case unableToParseImage(String)
}

enum Result<Value> {
    case success(Value)
    case failure(ImageParserError)
}


