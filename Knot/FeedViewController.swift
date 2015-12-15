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
    
    var tableData: [String] = ["AstroCoffee", "Lambo", "Dog"]
    
    var refreshControl = UIRefreshControl()
    
    // 1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up the refresh control
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView?.addSubview(refreshControl)
        
        // Register custom cell
        let nib = UINib(nibName: "vwTableCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "cell")
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLayoutSubviews() {
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0)
    }
    
    // 2
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    
    // 3
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell 	{
        
        let cell:TableCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! TableCell
        
        cell.nameLabel.text = tableData[indexPath.row]
        cell.priceLabel.text = "$50 - BTC: 0.3576234"
        cell.pic.image = UIImage(named: tableData[indexPath.row])
        
        return cell
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if (segue!.identifier == "DetailSeg") {
            let viewController:ItemDetail = segue!.destinationViewController as! ItemDetail
            let indexPath = self.tableView.indexPathForSelectedRow
            viewController.pic = UIImage(named: tableData[indexPath!.row])!
            viewController.name = tableData[indexPath!.row]
            viewController.price = "$50 - BTC: 0.3576234"
            
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

