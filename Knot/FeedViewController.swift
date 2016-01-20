//
//  ViewController.swift
//  Knot
//
//  Created by Nathan Mueller on 11/15/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import UIKit

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tableRowLeft: Array<ListItem>?
    var tableRowRight: Array<ListItem>?
    var downloadFileURLs = Array<NSURL?>()
    var tableImages = [String: UIImage]()
    
    var lock:NSLock?
    var lastEvaluatedKey:[NSObject : AnyObject]!
    var  doneLoading = false
    
    var loadLeft = true
    var indexToLoad: Int = 0
    
    var needsToRefresh = false
    
    let currentDate = NSDate()
    let dateFormatter = NSDateFormatter()

    
    var refreshControl = UIRefreshControl()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // 1
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        
        // set up the refresh control
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        
        // When activated, invoke our refresh function
        self.refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        // Register custom cell
        let nib = UINib(nibName: "vwTableCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "cell")
        self.automaticallyAdjustsScrollViewInsets = false

        
        //download data
        tableRowLeft = []
        tableRowRight = []
        lock = NSLock()
        self.refreshList(true)
        
    }
    
    func refresh(){
        
        // -- DO SOMETHING AWESOME (... or just wait 3 seconds) --
        // This is where you'll make requests to an API, reload data, or process information
        self.refreshList(true)
        var delayInSeconds = 3.0;
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
        //SwiftSpinner.show("Loading Data")
        self.tableRowLeft?.removeAll(keepCapacity: true)
        self.tableRowRight?.removeAll(keepCapacity: true)
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
            
            //load left
            dynamoDBObjectMapper.scan(ListItem.self, expression: queryExpression).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
                
                if self.lastEvaluatedKey == nil {
                    self.tableRowLeft?.removeAll(keepCapacity: true)
                    self.tableRowRight?.removeAll(keepCapacity: true)
                }
                
                if task.result != nil {
                    let paginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                    var checked = false
                    var left = true
                    for item in paginatedOutput.items as! [ListItem] {
                        checked = false
                        if item.sold == "false" {
                            if left && !checked {
                                self.tableRowLeft?.append(item)
                                left = false
                                checked = true
                            }
                            if !left && !checked {
                                self.tableRowRight?.append(item)
                                left = true
                                checked = true
                            }
                        }
                        self.downloadImage(item.ID)
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
        
        transferUtility?.downloadToURL(nil, bucket: S3BucketName, key: S3DownloadKeyName, expression: expression, completionHander: completionHandler).continueWithBlock { (task) -> AnyObject! in
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
        return self.tableRowLeft!.count
    }
    
    
    // 3
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell 	{
        
        let cell:TableCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! TableCell
        
        //left side
        cell.picOne.image = tableImages[tableRowLeft![indexPath.row].ID]
        let overDateLeft = dateFormatter.dateFromString(tableRowLeft![indexPath.row].time)!
        let secondsUntilLeft = secondsFrom(currentDate, endDate: overDateLeft)
        if(secondsUntilLeft > 0)
        {
            cell.timerOne.text = printSecondsToDaysHoursMinutesSeconds(secondsUntilLeft)
        }
        else {
            cell.timerOne.text = "Ended"
        }
        
        cell.picOne.userInteractionEnabled = true;
        let tapRecognizerLeft = UITapGestureRecognizer(target: self, action: "imageTappedLeft:")
        cell.picOne.addGestureRecognizer(tapRecognizerLeft)
        
        //right side
        if tableRowRight!.count > indexPath.row {
            cell.picTwo.image = tableImages[tableRowRight![indexPath.row].ID]
            let overDateRight = dateFormatter.dateFromString(tableRowRight![indexPath.row].time)!
            let secondsUntilRight = secondsFrom(currentDate, endDate: overDateRight)
            if(secondsUntilRight > 0)
            {
                cell.timerTwo.text = printSecondsToDaysHoursMinutesSeconds(secondsUntilRight)
            }
            else {
                cell.timerTwo.text = "Ended"
            }
            
            cell.picTwo.userInteractionEnabled = true;
            let tapRecognizerRight = UITapGestureRecognizer(target: self, action: "imageTappedRight:")
            cell.picTwo.addGestureRecognizer(tapRecognizerRight)

        }

        return cell
        
    }
    
    func imageTappedLeft(sender: AnyObject)
    {
        loadLeft = true
        let touch = sender.locationInView(tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(touch) {
            // Access the image or the cell at this index path
            indexToLoad = indexPath.row
        }
        self.performSegueWithIdentifier("DetailSeg", sender: self)
    }
    func imageTappedRight(sender: AnyObject)
    {
        loadLeft = false
        let touch = sender.locationInView(tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(touch) {
            // Access the image or the cell at this index path
            indexToLoad = indexPath.row
        }
        self.performSegueWithIdentifier("DetailSeg", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if (segue!.identifier == "DetailSeg") {
            let viewController:ItemDetail = segue!.destinationViewController as! ItemDetail
            //let indexPath = self.tableView.indexPathForSelectedRow
            if loadLeft {
                //viewController.pic = tableImages[tableRowLeft![indexToLoad].ID]!
                viewController.name = tableRowLeft![indexToLoad].name
                viewController.price = tableRowLeft![indexToLoad].price
                viewController.time = tableRowLeft![indexToLoad].time
                viewController.IDNum = tableRowLeft![indexToLoad].ID
                viewController.itemSeller = tableRowLeft![indexToLoad].seller
                viewController.location = tableRowLeft![indexToLoad].location
                viewController.sold = tableRowLeft![indexToLoad].sold
                viewController.fbID = tableRowLeft![indexToLoad].sellerFBID
                viewController.descript = tableRowLeft![indexToLoad].descriptionKnot
                viewController.condition = tableRowLeft![indexToLoad].condition
                viewController.category = tableRowLeft![indexToLoad].category
            }
            else {
                //viewController.pic = tableImages[tableRowRight![indexToLoad].ID]!
                viewController.name = tableRowRight![indexToLoad].name
                viewController.price = tableRowRight![indexToLoad].price
                viewController.time = tableRowRight![indexToLoad].time
                viewController.IDNum = tableRowRight![indexToLoad].ID
                viewController.itemSeller = tableRowRight![indexToLoad].seller
                viewController.location = tableRowRight![indexToLoad].location
                viewController.sold = tableRowRight![indexToLoad].sold
                viewController.fbID = tableRowRight![indexToLoad].sellerFBID
                viewController.descript = tableRowRight![indexToLoad].descriptionKnot
                viewController.condition = tableRowRight![indexToLoad].condition
                viewController.category = tableRowRight![indexToLoad].category
            }
        }
        
    }
    
    
    // 4
    /*
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            let currentCell = tableView.cellForRowAtIndexPath(indexPath) as! TableCell
            loadLeft = currentCell.leftSide
            self.performSegueWithIdentifier("DetailSeg", sender: tableView)
    }
*/
    
    // 5
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 190
    }
    
    func refreshTable(sender:AnyObject) {
        let nib = UINib(nibName: "vwTableCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "cell")
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    //timer setup stuff
    func secondsToDaysHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int, Int) {
        return (seconds / 86400, (seconds % 86400) / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func printSecondsToDaysHoursMinutesSeconds (seconds:Int) -> String {
        let (d, h, m, s) = secondsToDaysHoursMinutesSeconds (seconds)
        if m < 10 {
            if s < 10 {
                return "\(d) Days, \(h):0\(m):0\(s) left"
            }
            return "\(d) Days, \(h):0\(m):\(s) left"
        }
        if s < 10 {
            return "\(d) Days, \(h):\(m):0\(s) left"
        }
        return "\(d) Days, \(h):\(m):\(s) left"
    }
    
    func secondsFrom(startDate:NSDate, endDate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: startDate, toDate: endDate, options: []).second
    }


}

