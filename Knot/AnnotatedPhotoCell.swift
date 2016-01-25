//
//  AnnotatedPhotoCell.swift
//  RWDevCon
//
//  Created by Mic Pringle on 26/02/2015.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

import UIKit

class AnnotatedPhotoCell: UICollectionViewCell {
  
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var roundCornersView: RoundedCornersView!
    
    var cellItem : ListItem!
    var cellPic : UIImage!
    
    let currentDate = NSDate()
    let dateFormatter = NSDateFormatter()


}
