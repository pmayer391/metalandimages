////
////  Phase4.swift
////
////
////  Created by Paul Mayer on 9/13/21.
////
//
//import UIKit
//
////MARK: - Phase 4
//extension ParseImage{
//    
//    /// - Process all lines and turn them into vectors with vertices.
//    func parseImagePhase4(){
//        for currentPixel in imagePixelsArray{
//            //Process pixel lines into vectors
//            if currentPixel.color == .black,
//               currentPixel.hasAtLeastOneNeighborProcessed() == nil,
//               currentPixel.canBeStartPixel(){
//
//                let vector = PixelVector()
//                vector.startPixel = currentPixel
//                currentPixel.pixelStatus = .processed
//                imagePixelsPhase4[currentPixel.yPos][currentPixel.xPos] = PixelColor.red.rawValue
//                processLine(pixelImage: currentPixel, line: vector, &imagePixelsPhase4)
//                let lastPixel = vector.pixelPath.last
//                vector.endPixel = lastPixel
//                imagePixelsPhase4[lastPixel?.yPos ?? 0][lastPixel?.xPos ?? 0] = PixelColor.white.rawValue
//                if vector.pixelPath.count > 14{
//                    vectors.append(vector)
//                }
//                continue
//            }
//        }
//    }
//}
//
//
//
