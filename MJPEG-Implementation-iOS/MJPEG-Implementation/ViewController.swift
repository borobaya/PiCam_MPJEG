//
//  ViewController.swift
//  MJPEG-Implementation
//
//  Created by Muhammed Miah on 19/06/2016.
//  Copyright © 2016 Muhammed Miah. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSURLConnectionDataDelegate, NSURLSessionDataDelegate {
    
    let uv4lServer = "192.168.1.82:8080"
    let urlResizeRequest = "/panel?width=160&height=120&format=875967048"
    let urlMjpegStream = "/stream/video.mjpeg"
    
    let imageView = UIImageView()
    var endMarkerData = NSData()
    var receivedData = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        // Edit width and height, so streaming is not too slow
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let url = "http://"+uv4lServer+urlResizeRequest
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let task = session.dataTaskWithRequest(request)
        task.resume()
        
        imageView.frame = CGRect(x: 0, y: 60, width: self.view.frame.width, height: self.view.frame.height-60)
        imageView.contentMode = .ScaleAspectFit
        imageView.clearsContextBeforeDrawing = false
        self.view.addSubview(imageView)
        
        self.endMarkerData = NSData(bytes: [0xFF, 0xD9] as [UInt8], length: 2)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupMjpegStreamDeprecated() {
        // This method of connecting to URLs is deprecated but the video looks better
        // The video does not flicker
        // http://stackoverflow.com/questions/26692617/ios-and-live-streaming-mjpeg
        // https://github.com/mateagar/Motion-JPEG-Image-View-for-iOS/blob/master/MotionJpegImageView/MotionJpegImageView.mm
        
        let url = "http://"+uv4lServer+urlMjpegStream
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let _ = NSURLConnection(request: request, delegate: self)
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        receivedData.appendData(data)
        
        let endRange = receivedData.rangeOfData(endMarkerData,
                                                options: NSDataSearchOptions.Backwards,
                                                range: NSMakeRange(0, receivedData.length))
        let endLocation = endRange.location + endRange.length
        
        if receivedData.length >= endLocation {
            let imageData = receivedData.subdataWithRange(NSMakeRange(0, endLocation))
            let receivedImage = UIImage(data: imageData)
            self.imageView.image = receivedImage
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        receivedData = NSMutableData()
    }
    
    func setupMjpegStreamNew(){
        // http://stackoverflow.com/questions/26692617/ios-and-live-streaming-mjpeg
        // https://github.com/mateagar/Motion-JPEG-Image-View-for-iOS/blob/master/MotionJpegImageView/MotionJpegImageView.mm
        // http://www.stefanovettor.com/2016/03/30/ios-mjpeg-streaming/
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        let url = "http://"+uv4lServer+urlMjpegStream
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let task2 = session.dataTaskWithRequest(request)
        task2.resume()
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        if (dataTask.currentRequest?.URL?.absoluteString.containsString(urlMjpegStream))! {
            receivedData.appendData(data)
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if (dataTask.currentRequest?.URL?.absoluteString.containsString(urlResizeRequest))! {
            if dataTask.state == NSURLSessionTaskState.Suspended {
                print("Resize request completed")
                // Now asynchronously connect to the MJPEG stream
                dispatch_async(dispatch_get_main_queue()) {
                    
                    // Use the new method of connecting to URLs
                    // Which is non-deprecated but causes the video to flicker
                    self.setupMjpegStreamNew()
                    
                    // Or use the old method of connecting to URLs
                    // Which is deprecated but the video shows up fine
//                    self.setupMjpegStreamDeprecated()
                    
                }
            } else {
                print("Error occurred in resize request")
            }
        } else if (dataTask.currentRequest?.URL?.absoluteString.containsString(urlMjpegStream))! {
            
            let imageData = NSData(data: self.receivedData)
            if imageData.length > 0,
                let image = UIImage(data: imageData) {
                
                //http://stackoverflow.com/questions/19179185/how-to-asynchronously-load-an-image-in-an-uiimageview/19251240#19251240
                // Draw the image on the background thread before the main thread
                // This is meant to stop the flickering but doesn't
                UIGraphicsBeginImageContext(CGSizeMake(1,1))
                let context = UIGraphicsGetCurrentContext();
                CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), image.CGImage);
                UIGraphicsEndImageContext();
                
                dispatch_async(dispatch_get_main_queue()) { self.imageView.image = image }
            }
            
            receivedData = NSMutableData()
            // Enable the didReceiveData delegate method
            completionHandler(.Allow)
        }
    }
    
}

