//
//  CustomCell.swift
//  MetalAndImages
//
//  Created by Paul Mayer on 5/10/21.
//

import UIKit

class CustomCell: UICollectionViewCell {

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    
    func configureCell(obj: ImgDetails){
        self.img.image = obj.img
        self.lbl.text = obj.description
    }

}
