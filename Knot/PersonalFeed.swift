//
//  PersonalFeed.swift
//  Knot
//
//  Created by Nathan Mueller on 1/18/16.
//  Copyright © 2016 Knot App. All rights reserved.
//

import Foundation

import UIKit

class PersonalFeed: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var tableView: UITableView!
    
    var tableRows: Array<ListItem>?
    var downloadFileURLs = Array<NSURL?>()
    var tableImages = [String: UIImage]()
    
    var lock:NSLock?
    var lastEvaluatedKey:[NSObject : AnyObject]!
    var  doneLoading = false
    
    var needsToRefresh = false
    
    let currentDate = NSDate()
    let dateFormatter = NSDateFormatter()
    
    
    var refreshControl = UIRefreshControl()
    
    var cognitoID: String = ""
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // 1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        appDelegate.credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                print("Error: " + task.error!.localizedDescription)
            }
            else {
                // the task result will contain the identity id
                self.cognitoID = task.result as! String
                print(self.cognitoID)
            }
            return nil
        }
        
        
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        
        // set up the refresh control
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        
        // When activated, invoke our refresh function
        self.refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        // Register custom cell
        let nib = UINib(nibName: "storeTableCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "cell")
        self.automaticallyAdjustsScrollViewInsets = false
        
        //download data
        tableRows = []
        lock = NSLock()
        self.refreshList(true)
        
        
    }
    
    func refresh(){
        
        // -- DO SOMETHING AWESOME (... or just wait 3 seconds) --
        // This is where you'll make requests to an API, reload data, or process information
        self.refreshList(true)
        var delayInSeconds = 2.0;
        var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)));
        dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
            // When done requesting/reloading/processing invoke endRefreshing, to close the control
            self.refreshControl.endRefreshing()
        }
        // -- FINISHED SOMETHING AWESOME, WOO! --
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.needsToRefresh {
            self.refreshList(true)
            self.needsToRefresh = false
        }
    }
    
    func refreshList(startFromBeginning: Bool)  {
        if (self.lock?.tryLock() != nil) {
            if startFromBeginning {
                self.lastEvaluatedKey = nil;
                self.doneLoading = false
            }
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            let queryExpression = AWSDynamoDBScanExpression()
            queryExpression.exclusiveStartKey = self.lastEvaluatedKey
            queryExpression.limit = 20;
            dynamoDBObjectMapper.scan(ListItem.self, expression: queryExpression).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
                
                if self.lastEvaluatedKey == nil {
                    self.tableRows?.removeAll(keepCapacity: true)
                }
                
                if task.result != nil {
                    let paginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                    for item in paginatedOutput.items as! [ListItem] {
                        print(item.seller)
                        if item.seller == self.cognitoID {
                            self.tableRows?.append(item)
                            self.downloadImage(item.ID)
                        }
                        
                    }
                    
                    self.lastEvaluatedKey = paginatedOutput.lastEvaluatedKey
                    if paginatedOutput.lastEvaluatedKey == nil {
                        self.doneLoading = true
                    }
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.tableView.reloadData()
                
                if ((task.error) != nil) {
                    print("Error: \(task.error)")
                }
                return nil
            })
        }
    }
    
    func downloadImage(key: String){
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        
        //downloading image
        
        
        let S3BucketName: String = "knotcompleximages"
        let S3DownloadKeyName: String = key
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.downloadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                //self.progressView.progress = progress
                //   self.statusLabel.text = "Downloading..."
                NSLog("Progress is: %f",progress)
            })
        }
        
        
        
        completionHandler = { (task, location, data, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if ((error) != nil){
                    NSLog("Failed with error")
                    NSLog("Error: %@",error!);
                    //   self.statusLabel.text = "Failed"
                }
                    /*
                    else if(self.progressView.progress != 1.0) {
                    //    self.statusLabel.text = "Failed"
                    NSLog("Error: Failed - Likely due to invalid region / filename")
                    }   */
                else{
                    //    self.statusLabel.text = "Success"
                    self.tableImages[S3DownloadKeyName] = UIImage(data: data!)
                }
            })
        }
        
        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        
        transferUtility.downloadToURL(nil, bucket: S3BucketName, key: S3DownloadKeyName, expression: expression, completionHander: completionHandler).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                NSLog("Error: %@",error.localizedDescription);
                //  self.statusLabel.text = "Failed"
            }
            if let exception = task.exception {
                NSLog("Exception: %@",exception.description);
                //  self.statusLabel.text = "Failed"
            }
            if let _ = task.result {
                //    self.statusLabel.text = "Starting Download"
                //NSLog("Download Starting!")
                // Do something with uploadTask.
            }
            return nil;
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0)
    }
    
    // 2
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableRows!.count
    }
    
    
    // 3
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell 	{
        
        let cell:PersonalTableCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! PersonalTableCell
        
        cell.nameLabel.text = tableRows![indexPath.row].name
        cell.priceLabel.text = "$" + tableRows![indexPath.row].price
        
        cell.pic.image = tableImages[tableRows![indexPath.row].ID]
        
        if tableRows![indexPath.row].sold == "true" {
            cell.timeLabel.text = "Sold!"
            cell.timeLabel.textColor = UIColor.greenColor()
        }
        else {
            let overDate = dateFormatter.dateFromString(tableRows![indexPath.row].time)!
            let secondsUntil = secondsFrom(currentDate, endDate: overDate)
            if(secondsUntil > 0)
            {
                cell.timeLabel.text = printSecondsToDaysHoursMinutesSeconds(secondsUntil)
                if secondsUntil < 43200 {
                    cell.timeLabel.textColor = UIColor.redColor()
                }
                else {
                    cell.timeLabel.textColor = UIColor.blackColor()
                }
            }
            else {
                cell.timeLabel.textColor = UIColor.redColor()
                cell.timeLabel.text = "Ended"
            }
        }
        return cell
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        
        if (segue!.identifier == "PersonalDetailSeg") {
            let viewController:ItemDetail = segue!.destinationViewController as! ItemDetail
            let indexPath = self.tableView.indexPathForSelectedRow
            viewController.hidesBottomBarWhenPushed = true
            
            viewController.pic = tableImages[tableRows![indexPath!.row].ID]!
            
            viewController.name = tableRows![indexPath!.row].name
            viewController.price = tableRows![indexPath!.row].price
            viewController.time = tableRows![indexPath!.row].time
            viewController.IDNum = tableRows![indexPath!.row].ID
            viewController.itemSeller = tableRows![indexPath!.row].seller
            viewController.location = tableRows![indexPath!.row].location
            viewController.sold = tableRows![indexPath!.row].sold
            viewController.fbID = tableRows![indexPath!.row].sellerFBID
            viewController.descript = tableRows![indexPath!.row].descriptionKnot
            viewController.condition = tableRows![indexPath!.row].condition
            viewController.category = tableRows![indexPath!.row].category
            viewController.owned = true
        }
        
    }
    
    
    // 4
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        /*
        let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("ItemDetail") as! ItemDetail
        let indexPath = self.tableView.indexPathForSelectedRow
        //viewController.hidesBottomBarWhenPushed = true
        
        viewController.pic = tableImages[tableRows![indexPath!.row].ID]!
        
        viewController.name = tableRows![indexPath!.row].name
        viewController.price = tableRows![indexPath!.row].price
        viewController.time = tableRows![indexPath!.row].time
        viewController.IDNum = tableRows![indexPath!.row].ID
        viewController.itemSeller = tableRows![indexPath!.row].seller
        viewController.location = tableRows![indexPath!.row].location
        viewController.sold = tableRows![indexPath!.row].sold
        viewController.fbID = tableRows![indexPath!.row].sellerFBID
        viewController.descript = tableRows![indexPath!.row].descriptionKnot
        viewController.condition = tableRows![indexPath!.row].condition
        viewController.category = tableRows![indexPath!.row].category
        viewController.owned = true
        self.presentViewController(viewController, animated: true, completion: nil)
        */
        self.performSegueWithIdentifier("PersonalDetailSeg", sender: tableView)
        
    }
    
    // 5
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }
    
    func refresh(sender:AnyObject) {
        let nib = UINib(nibName: "storeTableCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "cell")
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    //timer setup stuff
    func secondsToDaysHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int, Int) {
        return (seconds / 86400, (seconds % 86400) / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func printSecondsToDaysHoursMinutesSeconds (seconds:Int) -> String {
        let (d, h, m, s) = secondsToDaysHoursMinutesSeconds (seconds)
        //more than 1 day remaining
        if d > 0 {
            if m < 10 {
                return "\(d) Days, \(h):0\(m) left"
            }
            return "\(d) Days, \(h):\(m) left"
        }
            //less than a day less
        else {
            if m < 10 {
                if s < 10 {
                    return "\(h):0\(m):0\(s) left"
                }
                return "\(h):0\(m):\(s) left"
            }
            if s < 10 {
                return "\(h):\(m):0\(s) left"
            }
            return "\(h):\(m):\(s) left"
            
        }
    }
    
    func secondsFrom(startDate:NSDate, endDate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: startDate, toDate: endDate, options: []).second
    }
    
    
}
