//
//  SignatureVC.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 5/24/21.
//

import UIKit

class SignatureVC: UIViewController {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var lblSignHere: UILabel!
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var lblAlert: UILabel!
    @IBOutlet weak var signatureView: CanvasView!
    @IBOutlet weak var signatureViewSet: UIImageView!
    @IBOutlet weak var btnSetImage: UIButton!
    @IBOutlet weak var btnCompare: UIButton!
    @IBOutlet weak var btnClear: UIButton!
    @IBOutlet weak var btnImageInfo: UIButton!
    
    var signatureImgParsed: UIImage?
    var savedImgParsed: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.isHidden = true
        btnCompare.isHidden = true
        btnSetImage.isHidden = true
        signatureView.drawColor = .black
        signatureView.drawWidth = 2
        signatureView.delegate = self
        btnSetImage.layer.cornerRadius = 6
        btnCompare.layer.cornerRadius = 6
        btnClear.layer.cornerRadius = 6
    }
    
    func showSignLbl(){
        UIView.animate(withDuration: 0.15) {
            self.lblSignHere.isHidden = false
        }
    }
    
    func computePercentage(first: Int, second: Int) -> Double{
        if first >= second{
            return Double(second) / Double(first)
        } else {
            return Double(first) / Double(second)
        }
    }
    
    @IBAction func btnComparePressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            self.bottomView.isHidden = false
            self.btnSetImage.isHidden = true
            self.btnCompare.isHidden = true
            self.btnSetImage.isHidden = true
        }
        
        let imgParser = ParseImage()
        if let signatureImg = signatureView.image, let savedImage = signatureViewSet.image{
            let signatureImageObj = imgParser.parseImage(inputImage: signatureImg)
            let savedImageObj = imgParser.parseImage(inputImage: savedImage)
//            signatureImgParsed = signatureImageObj?.image
//            savedImgParsed = savedImageObj?.image
//            let topPercentage = computePercentage(first: signatureImageObj?.topPixels ?? 1, second: savedImageObj?.topPixels ?? 1)
//            let bottomPercentage = computePercentage(first: signatureImageObj?.bottomPixels ?? 1, second: savedImageObj?.bottomPixels ?? 1)
//            let leftPercentage = computePercentage(first: signatureImageObj?.leftPixels ?? 1, second: savedImageObj?.leftPixels ?? 1)
//            let rightPercentage = computePercentage(first: signatureImageObj?.rightPixels ?? 1, second: savedImageObj?.rightPixels ?? 1)
            
//            let topP = (topPercentage / 4) * 100
//            let bottomP = (bottomPercentage / 4) * 100
//            let leftP = (leftPercentage / 4) * 100
//            let rightP = (rightPercentage / 4) * 100

//            let totalPercentage = Int(topP + bottomP + leftP + rightP)
            
//            let totalPercentage = Int(((topPercentage + bottomPercentage + leftPercentage + rightPercentage) / 4) * 100)
//            lblAlert.text = "\(totalPercentage)% Match"
        }
        
    }
    
    @IBAction func btnClearPressed(_ sender: UIButton) {
        signatureImgParsed = nil
        savedImgParsed = nil
        UIView.animate(withDuration: 0.15) {
            self.signatureView.clearImage()
            self.signatureViewSet.image = nil
            self.btnCompare.isHidden = true
            self.bottomView.isHidden = true
            self.lblSignHere.isHidden = false
            self.btnSetImage.isHidden = true
        }
    }
    
    @IBAction func btnSetPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            self.signatureViewSet.image = self.signatureView.image
            self.signatureView.clearImage()
            self.btnCompare.isHidden = true
            self.lblSignHere.isHidden = false
        }
    }
    
    @IBAction func btnImageInfoPressed(_ sender: UIButton) {
        self.signatureView.image = signatureImgParsed
        self.signatureViewSet.image = savedImgParsed
    }
}

extension SignatureVC: CanvasViewDelegate{
    func signatureStarted(tag: Int) {
        print("Huh")
    }
    
//    func signatureStarted() {
//        UIView.animate(withDuration: 0.15) {
//            self.lblSignHere.isHidden = true
//        }
//    }
    
    func signatureEnded() {
        self.btnSetImage.isHidden = false
        if signatureView.image != nil && signatureViewSet.image != nil{
            UIView.animate(withDuration: 0.15) {
                self.btnCompare.isHidden = false
            }
        }
    }
}
