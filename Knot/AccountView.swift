//
//  AccountView.swift
//  Knot
//
//  Created by Nathan Mueller on 1/19/16.
//  Copyright © 2016 Knot App. All rights reserved.
//

import Foundation

class AccountView: UIViewController {

    @IBOutlet weak var emial: UILabel!
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var profPic: UIImageView!
    var dict : NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    print(self.dict)
                    NSLog(self.dict.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as! String)
                    
                    
                    if let url = NSURL(string: self.dict.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as! String) {
                        if let data = NSData(contentsOfURL: url){
                            var profilePicture = UIImage(data: data)
                            /*
                            self.profPic.layer.borderWidth = 1.0
                            self.profPic.layer.masksToBounds = false
                            self.profPic.layer.borderColor = UIColor.whiteColor().CGColor
                            self.profPic.layer.cornerRadius = profilePicture.frame.size.width/2
                            self.profPic.clipsToBounds = true
*/
                            self.profPic.image = profilePicture
                        }
                    }
                    let nametext = (self.dict.objectForKey("first_name") as! String) + " " + (self.dict.objectForKey("last_name") as! String)
                    self.Name.text = nametext
                    self.emial.text = (self.dict.objectForKey("email") as! String)

                }
            })
        }
        
    }

        

}