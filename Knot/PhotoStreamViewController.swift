//
//  CollectionViewController.swift
//  Knot
//
//  Created by Nathan Mueller on 1/20/16.
//  Copyright © 2016 Knot App. All rights reserved.
//

import UIKit
import AVFoundation

class PhotoStreamViewController: UICollectionViewController {
    var lock:NSLock?
    var lastEvaluatedKey:[NSObject : AnyObject]!
    
    @IBOutlet var colView: UICollectionView!
    var photos : Array<Photo>!
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lock = NSLock()
        self.photos = []
        
        // Set the PinterestLayout delegate
        if let layout = collectionView?.collectionViewLayout as? FeedLayout {
            layout.delegate = self
        }
        collectionView!.backgroundColor = UIColor.lightGrayColor()
        collectionView!.contentInset = UIEdgeInsets(top: 23, left: 5, bottom: 10, right: 5)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPhotos()
    }
    
    func loadPhotos() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBScanExpression()
        queryExpression.exclusiveStartKey = self.lastEvaluatedKey
        queryExpression.limit = 20;
        
        //load left
        dynamoDBObjectMapper.scan(ListItem.self, expression: queryExpression).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
            
            if self.lastEvaluatedKey == nil {
                self.photos.removeAll(keepCapacity: true)
            }
            
            if task.result != nil {
                let paginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                for item in paginatedOutput.items as! [ListItem] {
                    if item.sold == "false" {
                        var pic = self.downloadImage(item.ID)
                        var newPhoto = Photo(litem: item, image: pic)
                        self.photos.append(newPhoto)
                        print("\(item.ID) added")
                    }
                }
                
                self.lastEvaluatedKey = paginatedOutput.lastEvaluatedKey
            }
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if ((task.error) != nil) {
                print("Error: \(task.error)")
            }
            return nil
        })
    }
    
    
    func downloadImage(key: String) -> UIImage {
    
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
    
            //downloading image
        var returnValue: UIImage = UIImage(named: "Knot380")!
    
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
                    print("Failed")
                }
                else{
                    print("Success")
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

                    returnValue = UIImage(data: data!)!
                }
            })
        }
    
        return returnValue
    }

    
}

extension PhotoStreamViewController {
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AnnotatedPhotoCell", forIndexPath: indexPath) as! AnnotatedPhotoCell
        cell.photo = photos[indexPath.item]
        if cell.photo?.image == nil {
            cell.photo?.image = downloadImage(cell.photo!.listitem.ID)
            collectionView.reloadItemsAtIndexPaths([indexPath])
        }
        return cell
    }
    
}

extension PhotoStreamViewController : FeedLayoutDelegate {
    // 1. Returns the photo height
    func collectionView(collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath:NSIndexPath , withWidth width:CGFloat) -> CGFloat {
        let photo = photos[indexPath.item]
        let boundingRect =  CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
        let rect  = AVMakeRectWithAspectRatioInsideRect(photo.image.size, boundingRect)
        return rect.size.height
    }
    
    // 2. Returns the annotation size based on the text
    func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let annotationPadding = CGFloat(4)
        let annotationHeaderHeight = CGFloat(17)
        
        let photo = photos[indexPath.item]
        let font = UIFont(name: "AvenirNext-Regular", size: 10)!
        let commentHeight = photo.heightForComment(font, width: width)
        let height = annotationPadding + annotationHeaderHeight + commentHeight + annotationPadding
        return height
    }
}
