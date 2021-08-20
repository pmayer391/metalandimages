//
//  SignatureDriver.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 8/16/21.
//

import Foundation
import UIKit


public class SignatureDriver {
    
    
    class public func compareSignatures(_ primarySignature: UIImage,_ secondarySignature: UIImage,_ accuracy: SignatureAccuracy = .standard, handler: @escaping (Double?, ImageParserError?) -> Void) {
        
//        let parsedPrimaryIm
        let parseImgQueue = OperationQueue()
           
        parseImgQueue.addOperation {
            let imgParser = ParseImage()
            let parsedPrimaryImg = imgParser.parseImage(inputImage: primarySignature)
        }
        parseImgQueue.addOperation {
            let imgParser = ParseImage()
            let parsedSecondaryImg = imgParser.parseImage(inputImage: primarySignature)
        }
        parseImgQueue.waitUntilAllOperationsAreFinished()
        
        
        
        return handler(nil, nil)
    }
    
}
