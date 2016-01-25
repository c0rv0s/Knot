//
//  AddScene.swift
//  Knot
//
//  Created by Nathan Mueller on 1/19/16.
//  Copyright © 2016 Knot App. All rights reserved.
//

import Foundation

class AddScene: UINavigationController {
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        
        //let vc = self.storyboard!.instantiateViewControllerWithIdentifier("NewItemView") as! UIViewController
        //self.presentViewController(vc, animated: true, completion: nil)
        self.performSegueWithIdentifier("PresentNewItemView", sender: self)
    }
    
}