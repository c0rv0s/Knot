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
    
    var tableRows: Array<ListItem>?
    
    var lock:NSLock?
    var lastEvaluatedKey:[NSObject : AnyObject]!
    var  doneLoading = false
    
    var needsToRefresh = false

    
    var refreshControl = UIRefreshControl()
    let bucket = "knotcomplex-userfiles-mobilehub-1874622474/public"
    
    // 1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //load signup page
        /*
        let webV:UIWebView = UIWebView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        let localfilePath = NSBundle.mainBundle().URLForResource("signup", withExtension: "html");
        let myRequest = NSURLRequest(URL: localfilePath!);
        webV.loadRequest(myRequest);
        self.view.addSubview(webV)
        self.view.sendSubviewToBack(webV)
        */

        // set up the refresh control
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView?.addSubview(refreshControl)
        
        // Register custom cell
        let nib = UINib(nibName: "vwTableCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "cell")
        self.automaticallyAdjustsScrollViewInsets = false
        
        //download data
        tableRows = []
        lock = NSLock()
        
        self.refreshList(true)
        

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
                        self.tableRows?.append(item)
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
    
    override func viewDidLayoutSubviews() {
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0)
    }
    
    // 2
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableRows!.count
    }
    
    
    // 3
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell 	{
        
        let cell:TableCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! TableCell
        
        cell.nameLabel.text = tableRows![indexPath.row].name
        cell.priceLabel.text = "$" + tableRows![indexPath.row].price
        cell.pic.image = UIImage(named: tableRows![indexPath.row].name)
        cell.timeLabel.text = tableRows![indexPath.row].time
        
        return cell
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if (segue!.identifier == "DetailSeg") {
            let viewController:ItemDetail = segue!.destinationViewController as! ItemDetail
            let indexPath = self.tableView.indexPathForSelectedRow
            //viewController.pic = UIImage(named: tableRows![indexPath!.row].name)!
            viewController.name = tableRows![indexPath!.row].name
            viewController.price = tableRows![indexPath!.row].price
            viewController.time = tableRows![indexPath!.row].time
        }
        
    }
    
    // 4
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            self.performSegueWithIdentifier("DetailSeg", sender: tableView)
    }
    
    // 5
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 380
    }
    
    func refresh(sender:AnyObject) {
        let nib = UINib(nibName: "vwTableCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "cell")
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    @IBAction func unwindToViewOtherController(segue:UIStoryboardSegue) {
    }


}

