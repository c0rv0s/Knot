//
//  accountView.swift
//  Knot
//
//  Created by Nathan Mueller on 12/21/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import Foundation
import UIKit

class accountView: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var walletText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletText.delegate = self
    }
    
    //keyboard
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func savewallet(sender: AnyObject) {
        let syncClient = AWSCognito.defaultCognito()
        var wallet = walletText.text
        let dataset = syncClient.openOrCreateDataset("userWallet")
        dataset.setString(wallet, forKey:"walletBTC")
        dataset.synchronize().continueWithBlock {(task) -> AnyObject! in
            if task.cancelled {
                // Task cancelled.
            } else if task.error != nil {
                // Error while executing task
            } else {
                // Task succeeded. The data was saved in the sync store.
            }
            return nil
        }
    }
    
}
