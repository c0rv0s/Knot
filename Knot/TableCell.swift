//
//  TableCell.swift
//  ShopKeeper
//
//  Created by Nathan Mueller on 11/12/15.
//  Copyright © 2015 HashWage. All rights reserved.
//

import UIKit

class TableCell: UITableViewCell {
    @IBOutlet weak var picOne: UIImageView!
    @IBOutlet weak var picTwo: UIImageView!
    @IBOutlet weak var timerTwo: UILabel!
    @IBOutlet weak var timerOne: UILabel!
    
    /*
    //var delegate: MyTableViewCellDelegate?
    var leftSide:Bool = false
    
    func viewDidLoad() {
        
        // Other setup here...

        picOne.userInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapImageLeft:")
        picOne.addGestureRecognizer(tapGestureRecognizer)
        
        picTwo.userInteractionEnabled = true
        let tapGestureRecognizerR = UITapGestureRecognizer(target: self, action: "didTapImageRight:")
        picTwo.addGestureRecognizer(tapGestureRecognizerR)
        
    }
    
    func didTapImageLeft(sender: AnyObject) {
        self.leftSide = true
    }
    func didTapImageRight(sender: AnyObject) {
        self.leftSide = false
    }
*/
    
}

