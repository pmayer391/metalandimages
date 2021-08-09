//
//  TestSignatureVC.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 7/22/21.
//

import UIKit

class TestSignatureVC: UIViewController {
    
    @IBOutlet weak var signatureView: CanvasView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var imgScrollView: UIScrollView!
    @IBOutlet var imgOriginal: UIImageView!
    @IBOutlet var originalScrollView: UIScrollView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        signatureView.drawColor = .black
        signatureView.drawWidth = 1
        signatureView.delegate = self
        
        imgScrollView.delegate = self
        imgScrollView.minimumZoomScale = 1.0
        imgScrollView.maximumZoomScale = 1000.0
        imgScrollView.tag = 0
        
        originalScrollView.delegate = self
        originalScrollView.minimumZoomScale = 1.0
        originalScrollView.maximumZoomScale = 1000.0
        originalScrollView.tag = 1
    }
    
    @IBAction func btnDoneSigning(_ sender: Any) {
        UIView.animate(withDuration: 0.15) {
            
            self.imgScrollView.zoomScale = 1.0
            self.originalScrollView.zoomScale = 1.0
            
            let imgParser = ParseImage()
            if let signatureImg = self.signatureView.image{
                let signatureImageObj = imgParser.parseImage(inputImage: signatureImg)
                self.imgView.image = signatureImageObj?.image

            }
            
            self.imgOriginal.image = self.signatureView.image
            self.signatureView.clearImage()
        }
    }
}

extension TestSignatureVC: CanvasViewDelegate{
    func signatureStarted() {
        UIView.animate(withDuration: 0.15) {
//            self.lblSignHere.isHidden = true
            print("Nothing")
        }
    }
    
    func signatureEnded() {
        if signatureView.image != nil && imgView.image != nil{

        }
    }
}

extension TestSignatureVC: UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView.tag == 0{
            print("blah")
            return imgView
        } else{
            return imgOriginal
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        print("blah1")
    }
}
