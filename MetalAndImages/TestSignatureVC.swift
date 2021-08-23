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
    
    var comparePressed = false
    var debugImages: [DebugImageName] = []
    var currentTopParsedImgObj: ParsedImageObj?
    var currentTopDebugImg: DebugImageName?
    var currentBottomParsedImgObj: ParsedImageObj?
    var currentBottomDebugImg: DebugImageName?
    
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
        imgScrollView.isMultipleTouchEnabled = true
        secondaryImgScrollView.delegate = self
        secondaryImgScrollView.minimumZoomScale = 1.0
        secondaryImgScrollView.maximumZoomScale = 1000.0
        secondaryImgScrollView.tag = 1
        
        loader.isHidden = true
        loader.style = .large
        secondaryLoader.isHidden = true
        secondaryLoader.style = .large
        
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanMiddleView(_:)))
        centerView.addGestureRecognizer(dragGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOnDebugImg(_:)))
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(didTapOnDebugImg(_:)))
        imgView.isUserInteractionEnabled = true
        imgView.addGestureRecognizer(tapGesture)
        secondaryImgView.isUserInteractionEnabled = true
        secondaryImgView.addGestureRecognizer(tapGesture2)
        
        centerView.layer.cornerRadius = 10
        btnCompare.layer.cornerRadius = 12
    }
    
    @objc func didPanMiddleView(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: view)
        if translation.y < 250 && translation.y > -250{
            centerViewOffsetConstraint.constant = translation.y
        }
    }
    
    @objc func didTapOnDebugImg(_ sender: UITapGestureRecognizer){
        if comparePressed{
            debugImages = []
            if sender.view?.tag == 0{
                let debubImgTemp = currentTopParsedImgObj?.debugImageDic.map({$0.key}) ?? []
                debugImages = debubImgTemp.sorted(by: {$0.rawValue > $1.rawValue})
            } else {
                let debubImgTemp = currentBottomParsedImgObj?.debugImageDic.map({$0.key}) ?? []
                debugImages = debubImgTemp.sorted(by: {$0.rawValue > $1.rawValue})
            }
            let sourceView = sender.view?.convert(sender.view?.bounds ?? self.view.bounds, to: self.view) ?? CGRect()
            let dropdown = DropDownView(sourceView: sourceView, customCellName: "", direction: (sender.view?.tag == 0 ? .ArrowDown : .ArrowUp), maxWidth: 200, maxHeight: 39 * CGFloat(debugImages.count), xOffset: nil, yOffset: nil, arrowOffset: nil, bgColor: UIColor.DarkBlue(), cornerRadias: 12, autoDismiss: true, addShadow: true, borderWidth: nil, borderColor: nil, addCellSeparator: nil, tag: (sender.view?.tag == 0 ? 0 : 1))
            dropdown.delegate = self
            dropdown.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            dropdown.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            self.present(dropdown, animated: false, completion: nil)
        } else{
            showAlert(message: "There are no signatures to view yet.")
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
//        UIView.animate(withDuration: 0.15) {
            if let sourceImg = self.signatureView.image, let secondaryImg =  self.secondarySignatureView.image{
                sender.isEnabled = false
                self.signatureView.clearImage()
                self.loader.isHidden = false
                self.loader.startAnimating()
                self.signatureView.isUserInteractionEnabled = false
                self.secondarySignatureView.clearImage()
                self.secondaryLoader.isHidden = false
                self.secondaryLoader.startAnimating()
                self.secondarySignatureView.isUserInteractionEnabled = false
                self.comparePressed = true
                SignatureDriver.compareSignatures(sourceImg, secondaryImg, .standard, true) { percentage, error in
                    print("Here")
                }
            } else{
                self.showAlert(message: "There must be two signatures to use the compare feature.")
            }
//        }
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
    
    func signatureEnded() {
        if signatureView.image != nil && imgView.image != nil{

        }
    }
}

extension TestSignatureVC: UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView.tag == 0{
            return imgView
        } else if scrollView.tag == 1{
            return secondaryImgView
        }
        return nil
    }
}

//MARK: - Drop Down Delegate
extension TestSignatureVC : DropDownDelegate{
    
    func tableViewPopup(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return debugImages.count
    }
    
    func tableViewPopup(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let debugImage = debugImages[indexPath.row]
        if debugImage == currentTopDebugImg || debugImage == currentBottomDebugImg{
            cell.textLabel?.textColor = .YellowLime()
        } else {
            cell.textLabel?.textColor = .white
        }
        cell.contentView.backgroundColor = .DarkBlue()
        cell.textLabel?.text = debugImage.rawValue.capitalized
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.textLabel?.textAlignment = .left
        return cell
    }
    
    func tableViewPopup(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let debugImg = debugImages[indexPath.row]
        if tableView.tag == 0 {
            currentTopDebugImg = debugImg
            imgView.image = currentTopParsedImgObj?.debugImageDic[debugImg]
        } else{
            currentBottomDebugImg = debugImg
            secondaryImgView.image = currentBottomParsedImgObj?.debugImageDic[debugImg]
        }
    }
    
    func tableViewPopup(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 39
    }
    
    func popupDismissed() {
        UIView.animate(withDuration: 0.1) {
//            self.navBar.imgSort.tintColor = .white
//            self.navBar.lblSort.textColor = .white
        }
    }
}
