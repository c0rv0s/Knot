//
//  QrView.swift
//  Knot
//
//  Created by Nathan Mueller on 11/16/15.
//  Copyright © 2015 Knot App. All rights reserved.
//


import UIKit

class QrView: UIViewController {
    
    //MARK: Properties
    //@IBOutlet weak var btcTextField: UITextField!
    //@IBOutlet weak var priceLabel: UILabel!
    
    var apiCall = "https://chart.googleapis.com/chart?chs=100x100&cht=qr&chl=bitcoin:"
    var address = "1A5iCBMXPJF7esUssyaaeLpTocoyW2EK6n"
    var imageURL: UIImageView!
    var BTCprice: String = ""
    var price: String = "9.99"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageURL = UIImageView(frame:CGRectMake(0, 0, 400, 700))
        
        imageURL.image = nil
        
        var qrURL = apiCall
        calcBitPrice(price)
        qrURL += address
        qrURL += "?amount="
        
        //check that price fetched
        while(true) {
            let length = self.BTCprice.characters.count
            if length > 1 {
                break
            }
        }
        qrURL += self.BTCprice
        //self.priceLabel.text = "Total BTC: " + self.BTCprice
        
        if let checkedUrl = NSURL(string: qrURL) {
            imageURL.contentMode = .ScaleAspectFit
            downloadImage(checkedUrl)
        }
        self.view.addSubview(imageURL)
        self.view.sendSubviewToBack(imageURL)
        print(qrURL)
        
    }
    /*
    // MARK: Actions
    @IBAction func Generate(sender: AnyObject) {
        imageURL.image = nil
        
        var qrURL = apiCall
        calcBitPrice("50")
        qrURL += address
        qrURL += "?amount="
        
        //check that price fetched
        while(true) {
            let length = self.BTCprice.characters.count
            if length > 1 {
                break
            }
        }
        qrURL += self.BTCprice
        //self.priceLabel.text = "Total BTC: " + self.BTCprice
        
        if let checkedUrl = NSURL(string: qrURL) {
            imageURL.contentMode = .ScaleAspectFit
            downloadImage(checkedUrl)
        }
        self.view.addSubview(imageURL)
        self.view.sendSubviewToBack(imageURL)
        print(qrURL)
    }
    */
    //MARK: Get QR code image
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadImage(url: NSURL){
        print("Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print("Finished downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
                self.imageURL.image = UIImage(data: data)
            }
        }
    }
    
    
    //MARK: get the current bitcoin price based on dollar amount
    func calcBitPrice(dollars: String) {
        self.BTCprice = ""
        var call = "https://blockchain.info/tobtc?currency=USD&value="
        call += dollars
        
        let url = NSURL(string: call)
        
        if url != nil {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
                print(data)
                
                if error == nil {
                    
                    var urlContent = NSString(data: data!, encoding: NSASCIIStringEncoding) as NSString!
                    self.BTCprice = urlContent as String
                    print(self.BTCprice)
                }
            })
            task.resume()
        }
    }
    
}

