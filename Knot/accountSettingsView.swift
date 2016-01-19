//
//  accountView.swift
//  Knot
//
//  Created by Nathan Mueller on 12/21/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import Foundation
import UIKit

class accountSettingsView: UIViewController, UITextFieldDelegate {

    
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
        SwiftSpinner.show("Saving Wallet ID")
        let syncClient = AWSCognito.defaultCognito()
        var wallet = walletText.text
        let dataset = syncClient.openOrCreateDataset("userWallet")
        dataset.setString(wallet, forKey:"walletBTC")
        dataset.synchronize().continueWithBlock {(task) -> AnyObject! in
            if task.cancelled {
                // Task cancelled.
                SwiftSpinner.hide()

            } else if task.error != nil {
                SwiftSpinner.hide()
                // Error while executing task

            } else {
                SwiftSpinner.hide()
                // Task succeeded. The data was saved in the sync store.


            }
            return nil
        }
    }
    
}
