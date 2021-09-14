////
////  Phase2.swift
////
////
////  Created by Paul Mayer on 9/13/21.
////
//
//import UIKit
//
////MARK: - Phase 2
//extension ParseImage{
//
//
//
//    
//    /// - Delete all neighbor pixels to the left, in order to create single connecting lines and handle different stroke sizes.
//    /// - Parameter cgImage: The image signature in Core Graphic format
//    func parseImagePhase2(_ cgImage: CGImage){
//        for currentPixel in imagePixelsArray{
//            if (currentPixel.xPos > 0 && currentPixel.xPos < cgImage.width - 1) && (currentPixel.yPos > 0 && currentPixel.yPos < cgImage.height - 1) {
//                /* DELETE Current Pixel if pixel has neighbor pixel to the right.
//                    ex:    @ - *
//                */
//                if imagePixelsPhase1[currentPixel.yPos][currentPixel.xPos + 1] == PixelColor.black.rawValue {
//                    currentPixel.color = .white
//                    currentPixel.pixelStatus = .deleted
//                    imagePixelsPhase2[currentPixel.yPos][currentPixel.xPos] = PixelColor.brown.rawValue
//                }
//            }
//
//            setPixelNeighbors(
//                pixelsImageMap,
//                currentPixel.xPos,
//                currentPixel.yPos,
//                imagePixelsPhase1.count - 1,
//                imagePixelsPhase1[currentPixel.yPos].count - 1,
//                currentPixel)
//        }
//    }
//}
//
//
//
