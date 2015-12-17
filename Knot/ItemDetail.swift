//
//  ItemDetail.swift
//  Knot
//
//  Created by Nathan Mueller on 11/15/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import UIKit

class ItemDetail: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    //@IBOutlet weak var descrip: UITextView!

    
    var picView: UIImageView!
    var pic : UIImage = UIImage()
    var name : String = "Text"
    var price : String = "Text"
    var time: String = "Time"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picView = UIImageView(frame:CGRectMake(0, 60, 380, 380))
        
        nameLabel.text = name
        priceLabel.text = price
        picView.image = pic
        
        self.view.addSubview(picView)
        self.view.sendSubviewToBack(picView)
        
    }

    
}