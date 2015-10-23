import UIKit
import AVFoundation

class SolutionLogger: NSObject {
    let logbookScheme = "appquest://submit"
    var viewController:UIViewController!
    
    required init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    private func urlEncode(string: String) -> String? {
        return string.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
    
    func JSONStringify(jsonObj: AnyObject) -> String {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(jsonObj, options: NSJSONWritingOptions(rawValue: 0))
            return NSString(data: jsonData, encoding: NSUTF8StringEncoding) as! String
        } catch _ {
            return ""
        }
    }
    
    func logSolution(solution: String) {
        let path = "\(logbookScheme)/\(urlEncode(solution)!)"
        UIApplication.sharedApplication().openURL(NSURL(string: path)!)
    }
    
    func scanQRCode(completion: String -> Void) {
        let reader = QRCodeReaderViewController(nibName: nil,bundle: nil)
        reader.onCodeDetected = { code in
            reader.dismissViewControllerAnimated(true, completion: { () -> Void in
                completion(code)
            })
        }
        viewController.presentViewController(reader, animated: true, completion: nil)
    }
    
    internal class QRCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate
    {
        var session: AVCaptureSession
        var device:AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var input:AVCaptureDeviceInput?
        var output:AVCaptureMetadataOutput
        var previewLayer:AVCaptureVideoPreviewLayer
        var highlightView:UIView
        var qrCodeContent:String?
        var onCodeDetected:((String) -> ())? = nil
        
        override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
            highlightView = UIView()
            highlightView.layer.borderColor = UIColor.greenColor().CGColor
            highlightView.layer.borderWidth = 3
            session = AVCaptureSession()
            
            let preset = AVCaptureSessionPresetHigh
            if session.canSetSessionPreset(preset) {
                session.sessionPreset = preset
            }
            
            output = AVCaptureMetadataOutput()
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        }
        
        required convenience init(coder aDecoder: NSCoder) {
            self.init(nibName: nil,bundle: nil)
        }
        
        override func viewDidLayoutSubviews() {
            previewLayer.frame = view.bounds
        }
        
        override func viewDidLoad()
        {
            super.viewDidLoad()
            
            self.view.addSubview(highlightView)
            
            do {
                input = try AVCaptureDeviceInput(device: device)
                session.addInput(input)
            } catch _ {
                print("Error: Can't create AVCaptureDeviceInput")
            }
            
            output.setMetadataObjectsDelegate(self, queue:dispatch_get_main_queue())
            session.addOutput(output)
            
            output.metadataObjectTypes = output.availableMetadataObjectTypes
            
            previewLayer.frame = self.view.bounds;
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            view.layer.addSublayer(previewLayer)
            session.startRunning()
            
            self.view.bringSubviewToFront(highlightView)
        }
        
        
        func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
            var highlightViewRect = CGRectZero
            var barCodeObject: AVMetadataMachineReadableCodeObject
            var detectionString:String?
            highlightView.frame = highlightViewRect
            
            for metadata in metadataObjects {
                if let metadataObject = metadata as? AVMetadataObject {
                    
                    if (metadataObject.type == AVMetadataObjectTypeQRCode) {
                        barCodeObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject) as! AVMetadataMachineReadableCodeObject
                        highlightViewRect = barCodeObject.bounds
                        
                        if let machineReadableObject = metadataObject as? AVMetadataMachineReadableCodeObject {
                            detectionString = machineReadableObject.stringValue
                            highlightView.frame = highlightViewRect
                        }
                    }
                    
                    if (detectionString != nil) {
                        self.qrCodeContent = detectionString
                        self.session.stopRunning()
                        onCodeDetected?(self.qrCodeContent!)
                        return
                    }
                }
            }
        }
        
        override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
            switch toInterfaceOrientation {
            case UIInterfaceOrientation.Portrait :
                previewLayer.connection.videoOrientation = .Portrait
            case UIInterfaceOrientation.PortraitUpsideDown :
                previewLayer.connection.videoOrientation = .PortraitUpsideDown
            case UIInterfaceOrientation.LandscapeLeft :
                previewLayer.connection.videoOrientation = .LandscapeLeft
            case UIInterfaceOrientation.LandscapeRight :
                previewLayer.connection.videoOrientation = .LandscapeRight
            default:
                previewLayer.connection.videoOrientation = .Portrait
            }
        }
    }
}