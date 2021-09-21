//
//  ViewController.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 5/10/21.
//

import UIKit

struct ImgDetails{
    var img: UIImage!
    var description: String!
}

class ViewController: UIViewController {

    @IBOutlet weak var imgCollectionView: UICollectionView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var imgScrollView: UIScrollView!
    
    var imgArr: [ImgDetails] = [ImgDetails(img: UIImage(named: "img1"), description: "252 × 200 JPEG"),
                                ImgDetails(img: UIImage(named: "img2"), description: "165 × 305 PNG"),
                                ImgDetails(img: UIImage(named: "img3"), description: "200 × 200 PNG"),
                                ImgDetails(img: UIImage(named: "img4"), description: "512 × 509 PNG"),
                                ImgDetails(img: UIImage(named: "img5"), description: "293 x 172 PNG")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imgCollectionView.delegate = self
        imgCollectionView.dataSource = self
        imgCollectionView.register(UINib(nibName: "CustomCell", bundle: nil), forCellWithReuseIdentifier: "CustomCell")
        imgScrollView.delegate = self
        imgScrollView.minimumZoomScale = 1.0
        imgScrollView.maximumZoomScale = 1000.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imgCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    func computeRandomArray() -> [Float]{
        var returnArray = [Float].init(repeating: 0.0, count: 3)
        for i in 0..<3{
            returnArray[i] = Float.random(in: 1.0..<255.0)
        }
        returnArray.append(1.0)
        return returnArray
    }
    
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.configureCell(obj: imgArr[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        SignatureDriver.compareSignatures(imgArr[indexPath.row].img,
                                          imgArr[indexPath.row].img,
                                          true) { result,
                                                  parsedImages in
            DispatchQueue.main.async {
                switch result{
                case .success(let percentage):
    //                if let parsedImgs = parsedImgObjects, parsedImgs.count > 0, let percent = percentage{
    //                    sender.isEnabled = true
    //                    self.loader.isHidden = true
    //                    self.loader.stopAnimating()
    //                    self.signatureView.isUserInteractionEnabled = true
    //                    self.lblSignHere.isHidden = false
    //                    self.secondaryLoader.isHidden = true
    //                    self.secondaryLoader.stopAnimating()
    //                    self.secondarySignatureView.isUserInteractionEnabled = true
    //                    self.secondaryLblSignHere.isHidden = false
    //                    self.currentTopParsedImgObj = parsedImgs.first
    //                    self.imgView.image = self.currentTopParsedImgObj?.debugImageDic[.phase3]
    //                    self.currentBottomParsedImgObj = parsedImgs.last
    //                    self.imgScrollView.zoomScale = 1.0
    //                    self.secondaryImgScrollView.zoomScale = 1.0
    //                    self.secondaryImgView.image = self.currentBottomParsedImgObj?.debugImageDic[.phase3]
    //                            let formattedPercent = (String(format: "%2f", percent))
    //                    self.mainImageView.image = parsedImgs.first?.debugImageDic[.phase1]
                        self.showAlert(message: "\(Int(round(percentage * 100)))% Match")
    //            }
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
        
//        let filter = Filter(img: imgArr[indexPath.row].img ?? UIImage())
//        let resultImage = filter.applyFilter()
//        mainImageView.image = resultImage
//        mainImageView.image = ParseImage.parseImage(inputImage: imgArr[indexPath.row].img ?? UIImage())
        
//        let rgbaImg = RGBA(image: imgArr[indexPath.row].img)
//        mainImageView.image = rgbaImg?.toUIImage()
        
//        let imageParser = ParseImage()
//        do {
//            self.mainImageView.image = try imageParser.parseImage(inputImage: imgArr[indexPath.row].img).map({$0.debugImageDic}).get()
//        } catch {
//            debugPrint("\(exception()): Unable to retrieve debug image.")
//        }
        
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let doneBtn = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alert.addAction(doneBtn)
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension ViewController : UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let insetOffset : CGFloat = 20
        let width = 200 - insetOffset
        return CGSize(width: width, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension ViewController: UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mainImageView
    }
}

