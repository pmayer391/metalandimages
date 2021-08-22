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
    @IBOutlet weak var lblSignHere: UILabel!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    

    @IBOutlet weak var secondarySignatureView: CanvasView!
    @IBOutlet weak var secondaryImgView: UIImageView!
    @IBOutlet weak var secondaryImgScrollView: UIScrollView!
    @IBOutlet weak var secondaryLblSignHere: UILabel!
    @IBOutlet weak var secondaryLoader: UIActivityIndicatorView!

    
    @IBOutlet weak var btnSaveImg: UIButton!
    @IBOutlet weak var btnGetImg: UIButton!
    @IBOutlet weak var btnCompare: UIButton!
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var centerViewOffsetConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        signatureView.drawColor = .black
        signatureView.drawWidth = 1
        signatureView.delegate = self
        
        secondarySignatureView.drawColor = .black
        secondarySignatureView.drawWidth = 3
        secondarySignatureView.delegate = self
        
        imgScrollView.delegate = self
        imgScrollView.minimumZoomScale = 1.0
        imgScrollView.maximumZoomScale = 1000.0
        imgScrollView.tag = 0
        
//        btnDone.layer.cornerRadius = 10
//        secondaryBtnDone.layer.cornerRadius = 10
//        btnSelectImg.layer.cornerRadius = 10
//        secondaryBtnSelectImg.layer.cornerRadius = 10
        centerView.layer.cornerRadius = 10
        btnCompare.layer.cornerRadius = 12
        
        loader.isHidden = true
        loader.style = .large
        secondaryLoader.isHidden = true
        secondaryLoader.style = .large
        
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanMiddleView(_:)))
        centerView.addGestureRecognizer(dragGesture)
        
//        originalScrollView.delegate = self
//        originalScrollView.minimumZoomScale = 1.0
//        originalScrollView.maximumZoomScale = 1000.0
//        originalScrollView.tag = 1
    }
    
    @objc func didPanMiddleView(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: view)
        if translation.y < 250 && translation.y > -250{
            centerViewOffsetConstraint.constant = translation.y
            
        }
    }
    
    func parseImg(for img: UIImage?) {
//        self.imgScrollView.zoomScale = 1.0
//        self.originalScrollView.zoomScale = 1.0
        
//        if let parsableImg = img{
//            let imgParser = ParseImage()
//            imgParser.parseImage(inputImage: parsableImg, runInDebugMode: true)
//            do {
//                self.imgView.image = try signatureImageObj.map({$0.debugModeImage}).get()
//            } catch {
//                debugPrint("\(exception()): Unable to retrieve debug image.")
//            }
//        }
        
//        self.imgOriginal.image = self.signatureView.image
//        self.signatureView.clearImage()
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let doneBtn = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alert.addAction(doneBtn)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnCompare(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            if self.signatureView.image != nil && self.secondarySignatureView.image != nil{
                sender.isEnabled = false
                self.signatureView.clearImage()
                self.loader.isHidden = false
                self.loader.startAnimating()
                self.signatureView.isUserInteractionEnabled = false
                self.secondarySignatureView.clearImage()
                self.secondaryLoader.isHidden = false
                self.secondaryLoader.startAnimating()
                self.secondarySignatureView.isUserInteractionEnabled = false
            } else{
                self.showAlert(message: "There must be two signatures to use the compare feature.")
            }

//            do {
//                try self.parseImg(for: self.signatureView.image)
//            } catch {
//                debugPrint("\(exception()): Unable to retrieve debug image.")
//            }
//
        }
    }
    
    @IBAction func btnDoneSigning(_ sender: UIButton) {
//        UIView.animate(withDuration: 0.15) {
//            if sender.tag == 0{
//                self.signatureView.clearImage()
//                self.loader.isHidden = false
//                self.loader.startAnimating()
//            } else {
//                self.secondarySignatureView.clearImage()
//                self.secondaryLoader.isHidden = false
//                self.secondaryLoader.startAnimating()
//            }
//            do {
//                try self.parseImg(for: self.signatureView.image)
//            } catch {
//                debugPrint("\(exception()): Unable to retrieve debug image.")
//            }
//
//        }
    }
    
    @IBAction func btnSelectDebugImage(_ sender: UIButton) {
//        let title = sender.title(for: .normal)
//        if title?.contains("Show") ?? false{
////            originalImgView.isHidden = false
//            sender.setTitle("Hide Signature", for: .normal)
//        } else {
////            originalImgView.isHidden = true
//            sender.setTitle("Show Signature", for: .normal)
//        }
    }
    
    @IBAction func btnSaveImg(_ sender: UIButton) {
//        if let pngImg = imgOriginal.image{
//            let pngImgData = pngImg.pngData()
//            UserDefaults.standard.setValue(pngImgData, forKey: "LatestImg")
//            showAlert(message: "Img Saved")
//        } else{
//            showAlert(message: "There is no signature to save yet.")
//        }
    }
    
    
    @IBAction func btnGetImg(_ sender: UIButton) {
//        if let imgData = UserDefaults.standard.value(forKey: "LatestImg") as? Data{
//            parseImg(for: UIImage(data: imgData))
//        } else {
//            showAlert(message: "There is no img saved yet.")
//        }
    }
    
    
    
}

extension TestSignatureVC: CanvasViewDelegate{
    func signatureStarted(tag: Int) {
        if tag == 0{
            lblSignHere.isHidden = true
        } else {
            secondaryLblSignHere.isHidden = true
        }
    }
    
    func signatureStarted() {

    }
    
    func signatureEnded() {
        if signatureView.image != nil && imgView.image != nil{

        }
    }
}

extension TestSignatureVC: UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView.tag == 0{
            return imgView
        } else{
//            return imgOriginal
        }
        return nil
    }
    
}
