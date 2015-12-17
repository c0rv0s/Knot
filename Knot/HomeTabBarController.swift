//
//  HomeTabBarController.swift
//  Knot
//
//  Created by Nathan Mueller on 12/11/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import Foundation
import UIKit

class HomeTabBarController: UITabBarController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    override func viewDidAppear(animated: Bool) {
        print("checking fb token status")
        if (FBSDKAccessToken.currentAccessToken() == nil) {
            print("user not logged in")
            
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("LoginView") as! UIViewController
            self.presentViewController(vc, animated: true, completion: nil)
        }
        else {
            print("user logged in")
            let token = FBSDKAccessToken.currentAccessToken().tokenString
            appDelegate.credentialsProvider.logins = [AWSCognitoLoginProviderKey.Facebook.rawValue: token]
        }
    }

}