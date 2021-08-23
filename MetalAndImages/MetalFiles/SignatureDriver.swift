//
//  SignatureDriver.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 8/16/21.
//

import Foundation
import UIKit


public class SignatureDriver {
    
    
    class public func compareSignatures(_ primarySignature: UIImage,
                                        _ secondarySignature: UIImage,
                                        _ accuracy: SignatureAccuracy = .standard,
                                        _ isDebugMode: Bool = false,
                                        _ handler: @escaping (Double?, String?) -> Void) {
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        var primaryImgObj: ParsedImageObj?
        var secondaryImgObj: ParsedImageObj?
           
        DispatchQueue.global().async {
            let primaryBlock = BlockOperation{
                let imgParser = ParseImage()
                let result = imgParser.parseImage(inputImage: primarySignature,
                                                            runInDebugMode: isDebugMode,
                                                            degreeOfSignatureAccuracy: accuracy)
                switch result {
                case .success(let data):
                    primaryImgObj = data
                case .failure(let error):
                    debugPrint("Failure: \(error)")
                }
            }
            
            let secondaryBlock = BlockOperation{
                let imgParser = ParseImage()
                let result = imgParser.parseImage(inputImage: secondarySignature,
                                                            runInDebugMode: isDebugMode,
                                                            degreeOfSignatureAccuracy: accuracy)
                switch result {
                case .success(let data):
                    secondaryImgObj = data
                case .failure(let error):
                    debugPrint("Failure: \(error)")
                }
            }
            
            operationQueue.addOperations([primaryBlock, secondaryBlock], waitUntilFinished: true)
            print("All Done")
            print("Image 1 Obj: \(primaryImgObj)")
            print("Image 2 Obj: \(secondaryImgObj)")
        }
        
        
        
        return handler(nil, nil)
    }
    
}
