//
//  AnnotatedPhotoCell.swift
//  RWDevCon
//
//  Created by Mic Pringle on 26/02/2015.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

import UIKit

class AnnotatedPhotoCell: UICollectionViewCell {
  
  @IBOutlet private weak var imageView: UIImageView!
  //@IBOutlet private weak var imageViewHeightLayoutConstraint: NSLayoutConstraint!
  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var countdownLabel: UILabel!
    
    let currentDate = NSDate()
    let dateFormatter = NSDateFormatter()
    
  
  var photo: Photo? {
    didSet {
      if let photo = photo {
        imageView.image = photo.image
        titleLabel.text = photo.listitem.name
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let overDateLeft = dateFormatter.dateFromString(photo.listitem.time)!
        let secondsUntilLeft = secondsFrom(currentDate, endDate: overDateLeft)
        if(secondsUntilLeft > 0)
        {
            countdownLabel.text = printSecondsToDaysHoursMinutesSeconds(secondsUntilLeft)
        }
        else {
            countdownLabel.text = "Ended"
        }
      }
    }
  }
  /*
  override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
    super.applyLayoutAttributes(layoutAttributes)
    if let attributes = layoutAttributes as? FeedLayoutAttributes {
      imageViewHeightLayoutConstraint.constant = attributes.photoHeight
    }
  }
   */
    //timer setup stuff
    func secondsToDaysHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int, Int) {
        return (seconds / 86400, (seconds % 86400) / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func printSecondsToDaysHoursMinutesSeconds (seconds:Int) -> String {
        let (d, h, m, s) = secondsToDaysHoursMinutesSeconds (seconds)
        if m < 10 {
            if s < 10 {
                return "\(d) Days, \(h):0\(m):0\(s) left"
            }
            return "\(d) Days, \(h):0\(m):\(s) left"
        }
        if s < 10 {
            return "\(d) Days, \(h):\(m):0\(s) left"
        }
        return "\(d) Days, \(h):\(m):\(s) left"
    }
    
    func secondsFrom(startDate:NSDate, endDate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: startDate, toDate: endDate, options: []).second
    }

}
