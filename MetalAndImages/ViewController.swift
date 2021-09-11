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
        imgScrollView.maximumZoomScale = 100.0
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
                                          true) { (percentage,
                                                   error,
                                                   parsedImgObjects) in
            
            DispatchQueue.main.async {
                if let parsedImgs = parsedImgObjects, parsedImgs.count > 0, let percent = percentage{
                    self.showAlert(message: "\(Int(round(percent * 100)))% Match")
                } else if let error = error{
                    self.showAlert(message: error)
                } else {
                    self.showAlert(message: "Unknown Result Occurred")
                }
            }
        }
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

