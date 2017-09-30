//
//  photoCollectionViewCell.swift
//  Sift
//
//  Created by Lauren Champeau on 9/23/17.
//  Copyright © 2017 Lauren Champeau. All rights reserved.
//

import UIKit

class photoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var gridImageView: UIImageView!
    
    var representedAssetIdentifier: String!
    
    var thumbnail: UIImage!{
        didSet{
            gridImageView.image = thumbnail
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        gridImageView.image = nil
    }
}
