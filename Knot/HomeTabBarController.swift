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
        super.viewDidAppear(animated)
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
            
            // Retrieve your Amazon Cognito ID
            appDelegate.credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject! in
                
                if (task.error != nil) {
                    print("CognitoID Error: " + task.error!.localizedDescription)
                    
                } else {
                    // the task result will contain the identity id
                    self.appDelegate.cognitoId = task.result
                    print("Cognito ID: ")
                    print (self.appDelegate.cognitoId)
                }
                return nil
            }
        }
    }
}