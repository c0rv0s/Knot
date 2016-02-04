//
//  CollectionViewController.swift
//  Knot
//
//  Created by Nathan Mueller on 1/20/16.
//  Copyright © 2016 Knot App. All rights reserved.
//

import UIKit
import AVFoundation

class PhotoStreamViewController: UICollectionViewController{
    var lock:NSLock?
    var lastEvaluatedKey:[NSObject : AnyObject]!
    
    @IBOutlet var colView: UICollectionView!
    var collectionItems: Array<ListItem>!
    var collectionImages = [String: UIImage]()
    
    let currentDate = NSDate()
    let dateFormatter = NSDateFormatter()
    
    var cognitoID = ""
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var selectedRow: Int!
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the PinterestLayout delegate
        
        if let layout = self.colView.collectionViewLayout as? FeedLayout {
            print("delegated")
            layout.delegate = self
        }
        collectionView!.contentInset = UIEdgeInsets(top: 23, left: 5, bottom: 10, right: 5)
        lock = NSLock()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"

        self.collectionItems = []
        //self.loadPhotos()
        
        appDelegate.credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                print("Error: " + task.error!.localizedDescription)
            }
            else {
                // the task result will contain the identity id
                self.cognitoID = task.result as! String
            }
            return nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.colView.reloadData()
        self.loadPhotos()
        
    }
    
    
    func loadPhotos() {
        if (self.lock?.tryLock() != nil) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        print("finna fetch those photos")
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBScanExpression()
        queryExpression.exclusiveStartKey = self.lastEvaluatedKey
        queryExpression.limit = 20;
        
        //load left
        dynamoDBObjectMapper.scan(ListItem.self, expression: queryExpression).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
            
            if self.lastEvaluatedKey == nil {
                self.collectionItems?.removeAll(keepCapacity: true)
            }
            
            if task.result != nil {
                let paginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                for item in paginatedOutput.items as! [ListItem] {
                    if item.sold == "false" {
                        
                        self.collectionItems?.append(item)
                        self.downloadImage(item.ID)
                        //let newPhoto = Photo(litem: item, image: self.collectionImages[item.ID]!)
                        //self.photos.append(newPhoto)

                        print("\(item.ID) added")
                    }
                }
                
                self.lastEvaluatedKey = paginatedOutput.lastEvaluatedKey
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.colView.reloadData()
            })
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
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
                    self.collectionImages[S3DownloadKeyName] = UIImage(data: data!)
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
                /*
                dispatch_async(dispatch_get_main_queue(), {
                    self.colView.reloadData()
                })
                */
                self.colView.reloadData()
            }
            return nil;
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionItems!.count
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedRow = indexPath.row
        self.performSegueWithIdentifier("FeedDetailSeg", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if (segue!.identifier == "FeedDetailSeg") {
            let viewController:ItemDetail = segue!.destinationViewController as! ItemDetail
            viewController.hidesBottomBarWhenPushed = true
            
            viewController.pic = collectionImages[collectionItems![self.selectedRow].ID]!

            viewController.name = collectionItems![self.selectedRow].name
            viewController.price = collectionItems![self.selectedRow].price
            viewController.time = collectionItems![self.selectedRow].time
            viewController.IDNum = collectionItems![self.selectedRow].ID
            viewController.itemSeller = collectionItems![self.selectedRow].seller
            viewController.location = collectionItems![self.selectedRow].location
            viewController.sold = collectionItems![self.selectedRow].sold
            viewController.fbID = collectionItems![self.selectedRow].sellerFBID
            viewController.descript = collectionItems![self.selectedRow].descriptionKnot
            viewController.condition = collectionItems![self.selectedRow].condition
            viewController.category = collectionItems![self.selectedRow].category
            viewController.numPics = collectionItems![self.selectedRow].numberOfPics
            
            if self.cognitoID == collectionItems![self.selectedRow].seller {
                viewController.owned = true
            }
            else {
                viewController.owned = false
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AnnotatedPhotoCell", forIndexPath: indexPath) as! AnnotatedPhotoCell
        cell.cellItem = collectionItems![indexPath.row]
        
        cell.cellPic = collectionImages[collectionItems![indexPath.row].ID]

        let overDate = self.dateFormatter.dateFromString(cell.cellItem.time)!
        let secondsUntil = secondsFrom(currentDate, endDate: overDate)
        if(secondsUntil > 0)
        {
            cell.countdownLabel.text = printSecondsToDaysHoursMinutesSeconds(secondsUntil)
            if secondsUntil < 43200 {
                cell.countdownLabel.textColor = UIColor.redColor()
            }
            else {
                cell.countdownLabel.textColor = UIColor.blackColor()
            }
        }
        else {
            cell.countdownLabel.textColor = UIColor.redColor()
            cell.countdownLabel.text = "Ended"
        }
        cell.titleLabel.text = cell.cellItem.name
        cell.imageView.image = cell.cellPic

        print("cell made")
        return cell
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
    
    /*
func fadeInNewImage(newImage: UIImage) {
let tmpImageView = UIImageView(image: newImage)
tmpImageView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
tmpImageView.contentMode = photoImageView.contentMode
tmpImageView.frame = photoImageView.bounds
tmpImageView.alpha = 0.0
photoImageView.addSubview(tmpImageView)

UIView.animateWithDuration(0.75, animations: {
tmpImageView.alpha = 1.0
}, completion: {
finished in
self.photoImageView.image = newImage
tmpImageView.removeFromSuperview()
})
}
*/
}

extension PhotoStreamViewController : FeedLayoutDelegate {
    // 1. Returns the photo height
    func collectionView(collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath:NSIndexPath , withWidth width:CGFloat) -> CGFloat {
        var photo: UIImage
        if collectionImages[collectionItems![indexPath.row].ID] != nil {
            photo = collectionImages[collectionItems![indexPath.row].ID]!
        }
        else {
            photo = UIImage(named: "example")!
        }
        let boundingRect =  CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
        let rect  = AVMakeRectWithAspectRatioInsideRect(photo.size, boundingRect)
        return rect.size.height
    }
    
    // 2. Returns the annotation size based on the text
    func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        return 60
    }
}

