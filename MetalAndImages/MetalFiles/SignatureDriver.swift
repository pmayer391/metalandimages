//
//  SignatureDriver.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 8/16/21.
//

import Foundation
import UIKit


public class SignatureDriver {
    
    
    public class func compareSignatures(_ primarySignature: UIImage,
                                  _ secondarySignature: UIImage,
                                  _ accuracy: SignatureAccuracy = .standard,
                                  _ handler: @escaping (_ percentage: Double?,
                                                        _ breakingError: String?,
                                                        _ nonBreakingErrors: String?) -> Void) {
        compareSignatures(primarySignature,
                          secondarySignature,
                          accuracy,
                          false) { percentage,
                                   breakingErrors,
                                   parsedImageObjs in
            
            let silentErrors = parsedImageObjs.map({$0.map({$0.silentErrors.joined(separator: ",")}).joined(separator: "|")})
            handler(percentage, breakingErrors, silentErrors)
        }
        
    }
    
    class func compareSignatures(_ primarySignature: UIImage,
                           _ secondarySignature: UIImage,
                           _ accuracy: SignatureAccuracy = .standard,
                           _ isDebugMode: Bool = false,
                           _ handler: @escaping (_ percentage: Double?,
                                                 _ breakingError: String?,
                                                 _ imageObj: [ParsedImage]?) -> Void) {
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        var primaryImgObj: ParsedImage?
        var secondaryImgObj: ParsedImage?
           
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
                    switch error {
                    case .invalidImageSupplied(let errorMessage):
                        handler(nil, "INVALID PRIMARY IMAGE SUPPLIED: \(errorMessage)", nil)
                        operationQueue.cancelAllOperations()
                    case .unableToParseImage(let errorMessage):
                        handler(nil,"PRIMARY IMAGE PARSING ERROR: \(errorMessage)", nil)
                        operationQueue.cancelAllOperations()
                    }
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
                    switch error {
                    case .invalidImageSupplied(let errorMessage):
                        handler(nil, "INVALID SECONDARY IMAGE SUPPLIED: \(errorMessage)", nil)
                        operationQueue.cancelAllOperations()
                    case .unableToParseImage(let errorMessage):
                        handler(nil,"SECONDARY IMAGE PARSING ERROR: \(errorMessage)", nil)
                        operationQueue.cancelAllOperations()
                    }
                }
            }
            
            operationQueue.addOperations([primaryBlock, secondaryBlock], waitUntilFinished: true)
            
            if let primaryImage = primaryImgObj, let secondaryImage = secondaryImgObj{
                let quadrants = primaryImage.quadrants
                var overallPercentage: Double = 0.0
                for (key, primaryQuadrantCount) in quadrants{
                    let secondQuadrantCount = secondaryImage.quadrants[key] ?? 0
                    let pCount = primaryQuadrantCount == 0 ? 1 : primaryQuadrantCount
                    let sCount = secondQuadrantCount == 0 ? 1 : secondQuadrantCount
                    let quadrantPercentage = computePercentage(pCount, sCount)
                    let overallQuadrantPercentage = (quadrantPercentage / Double(quadrants.count)) * 100
                    overallPercentage = overallPercentage + overallQuadrantPercentage
                }
                handler(overallPercentage, nil, [primaryImage, secondaryImage])
            } else {
                handler(nil, "ERROR: Empty parsed image objects", nil)
            }
        }
    }
}

private extension SignatureDriver{
    
    class func computePercentage(_ first: Int, _ second: Int) -> Double{
        if first >= second{
            return Double(second) / Double(first)
        } else {
            return Double(first) / Double(second)
        }
    }
}
