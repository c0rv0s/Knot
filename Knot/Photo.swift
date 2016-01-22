//
//  Photo.swift
//  RWDevCon
//
//  Created by Mic Pringle on 04/03/2015.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

import UIKit

class Photo {
    var listitem : ListItem
    var image : UIImage
    
    init( litem: ListItem, image: UIImage) {
        self.listitem = litem
        self.image = image
    }

  func heightForComment(font: UIFont, width: CGFloat) -> CGFloat {
    let rect = NSString(string: listitem.name).boundingRectWithSize(CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
    return ceil(rect.height)
  }
    
}
