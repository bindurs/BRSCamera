//
//  CaptureViewController.swift
//  AVFoundationExample
//
//  Created by Bindu on 06/07/17.
//  Copyright © 2017 Xminds. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CaptureViewController: UIViewController ,AVCapturePhotoCaptureDelegate,UIImagePickerControllerDelegate,UIGestureRecognizerDelegate,AVCaptureFileOutputRecordingDelegate{
    
    //    var keyFromMenu :String?
    var touchPoint : CGPoint?
    @IBOutlet var captureView: UIView!
    var image: UIImage!
    var assetCollection: PHAssetCollection!
    var albumFound : Bool = false
    var photosAsset: PHFetchResult<AnyObject>!
    var assetThumbnailSize:CGSize!
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    @IBOutlet var recoderTimeLabel: UILabel!
    @IBOutlet var captureButton: UIButton!
    var timer : Timer?
    var timeInMinute :Int = 0
    var timeInSec :Int = 0
    var timeInHour :Int = 0
    // camera session
    var session : AVCaptureSession?
    // captured image
    var stillImageOutput: AVCapturePhotoOutput?
    //captured video
    var videoOutput : AVCaptureMovieFileOutput?
    // preview
    var previewLayer :AVCaptureVideoPreviewLayer?
    // captued cam h/w
    var captureDevice:AVCaptureDevice?
    // switching camera
    var camera : Bool = true
    var camFocus : CameraFocusSquareView?
    
    var input : AVCaptureDeviceInput?
    var error: NSError?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        createAlbum()
    }
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        session = AVCaptureSession()

        if (camera == false) {
            let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            
            
            for device in videoDevices!{
                let device = device as! AVCaptureDevice
                if device.position == AVCaptureDevicePosition.front {
                    captureDevice = device
                    break
                }
                
            }
        } else {
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(tapOnView(sender:)))
        tap.delegate = self
        captureView.addGestureRecognizer(tap)
        
        let capturePicOntap = UITapGestureRecognizer(target: self, action: #selector (capturePicOnTap(sender:)))
        capturePicOntap.numberOfTapsRequired = 1
        captureButton.addGestureRecognizer(capturePicOntap)
        
        let captureVideoOnTap = UILongPressGestureRecognizer(target: self, action: #selector (captureVideoOnTap(sender:)))
        captureButton.addGestureRecognizer(captureVideoOnTap)
        self.recoderTimeLabel.isHidden = true
        
        stillImageOutput = AVCapturePhotoOutput()
        stillImageOutput?.isHighResolutionCaptureEnabled = true
        stillImageOutput?.isLivePhotoCaptureEnabled = (stillImageOutput?.isLivePhotoCaptureSupported)!
        videoOutput = AVCaptureMovieFileOutput()
         setupPicCamera()
        session?.startRunning()

    }
    
    // MARK:- Methods
    func setupVideoCamera() {
        
        session!.sessionPreset = AVCaptureSessionPresetHigh
        
        do {
            
            session?.beginConfiguration()
            session!.removeInput(input)

            input = try AVCaptureDeviceInput(device: captureDevice)

            if error == nil && session!.canAddInput(input) {
                session!.addInput(input)
                
                if session!.canAddOutput(videoOutput) {
                    session!.addOutput(videoOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    previewLayer!.frame = captureView.bounds
                    previewLayer?.connection.isEnabled = true
                    captureView.layer.addSublayer(previewLayer!)
                    
                    session!.commitConfiguration()
                }
            }
            
        }
        catch let err as NSError {
            error = err
            input = nil
            print(error!.localizedDescription)
            
        }
    }
    func setupPicCamera() {
        
        session?.sessionPreset = AVCaptureSessionPresetPhoto
        do {
            
            session?.beginConfiguration()
            session!.removeInput(input)
            
            input = try AVCaptureDeviceInput(device: captureDevice)
            
            if (error == nil && session!.canAddInput(input)) {
                
                session?.addInput(input)
                
                
                
                if session!.canAddOutput(stillImageOutput) {
                    session?.addOutput(stillImageOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                    previewLayer?.frame = captureView.bounds
                    previewLayer?.connection.isEnabled = true
                    captureView.layer.addSublayer(previewLayer!)
                    session?.commitConfiguration()
                }
            }
        } catch let err as NSError {
            error = err
            input = nil
            print(error?.localizedDescription ?? "error")
        }
    }
    
    
    @IBAction func switchCameraBtnPressed(_ sender: UIBarButtonItem) {
        
        self.camera = !camera
        session?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        setupPicCamera()
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer , let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            // print(image: UIImage(data: dataImage)?.size)
            
            //            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: sampleBuffer)
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
            image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
             UIImageWriteToSavedPhotosAlbum(image, self,#selector(CaptureViewController.image(image:didFinishSavingWithError:contextInfo:)), nil)
           // saveImage()
        }
    }
    
    func saveImage(){
       
        PHPhotoLibrary.shared().performChanges({
            
            let assetRequest  = PHAssetChangeRequest.creationRequestForAsset(from: self.image)
            let assetPlaceholder = assetRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            albumChangeRequest?.addAssets(assetPlaceholder as! NSFastEnumeration)
            
        }) {  success, error in
            print("added image to album")
            print(error ?? "error")
        }
    }
    
    func focus(aPoint:CGPoint) {
        
        let captureDeviceClass :AnyClass = NSClassFromString("AVCaptureDevice")!
        
        let device :AVCaptureDevice = captureDeviceClass.defaultDevice(withMediaType: AVMediaTypeVideo)
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(AVCaptureFocusMode.autoFocus) {
            
            let screenRect : CGRect = captureView.frame
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let focus_x = aPoint.x/screenWidth
            let focus_y = aPoint.y/screenHeight
            
            do {
                
                try device.lockForConfiguration()
                device.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                device.focusMode = AVCaptureFocusMode.autoFocus
                
                if device.isExposureModeSupported(AVCaptureExposureMode.autoExpose){
                    device.exposureMode = AVCaptureExposureMode.autoExpose
                }
                
                device.unlockForConfiguration()
                
            } catch {
                
            }
        }
    }
    func createAlbum() {
        //Get PHFetch Options
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "camcam")
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        //Check return value - If found, then get the first album out
        if let _: AnyObject = collection.firstObject {
            self.albumFound = true
            assetCollection = collection.firstObject!
        } else {
            //If not found - Then create a new album
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "camcam")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                self.albumFound = success
                
                if (success) {
                    let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.assetCollectionPlaceholder.localIdentifier], options: nil)
                    print(collectionFetchResult)
                    self.assetCollection = collectionFetchResult.firstObject!
                }
            })
        }
    }
    //MARK: - Shows alert when image is saved
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        guard error == nil else {
            //Error saving image
            print(error ?? "error")
            return
        }
        
        //Image saved successfully
        //        showAlert("Saved", message: "Image Saved to Photos")
        print("saved")
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Shows alert when image is saved
    //MARK: - Get completed video path
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        //Saves the video in Photos
        doVideoProcessing(outputPath: outputFileURL! as NSURL)
        
    }
    func doVideoProcessing(outputPath:NSURL){
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputPath as URL)
            
            
            
        }) { (success, error) in
            
            if error == nil{
                
                print("Success:\(success)")
                DispatchQueue.main.async(execute: {
                    //                    self.activityIndicator!.stopAnimating()
                    //                    self.showAlert("Saved", message: "Video saved to Photos")
                })
                
            }
            else{
                
                DispatchQueue.main.async(execute: {
                    //                    self.activityIndicator!.stopAnimating()
                    //
                    //                    self.showAlert("Error", message: error!.localizedDescription)
                    
                })
            }
        }
    }
    
    // MARK: - TapGesture Recogniser
    func tapOnView(sender: UITapGestureRecognizer) {
        // handling code
        
        touchPoint = sender.location(in: captureView)
        
        focus(aPoint: touchPoint!)
        
        if ((camFocus) != nil) {
            camFocus?.removeFromSuperview()
        }
        
        camFocus = CameraFocusSquareView(frame: CGRect(x: (touchPoint?.x)!-40, y: (touchPoint?.y)!-40, width:80, height: 80))
        camFocus?.backgroundColor = UIColor.clear
        captureView.addSubview(camFocus!)
        camFocus?.setNeedsDisplay()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        camFocus?.alpha  = 0
        UIView.commitAnimations()
    }
    
    func capturePicOnTap(sender: UITapGestureRecognizer) {
        
        
        if (self.videoOutput?.isRecording)! {
            //Change camera button for video recording
            self.videoOutput?.stopRecording()
            self.captureButton.setTitle("Capture", for: UIControlState.normal)
            timer?.invalidate()
        } else {
            
            setupPicCamera()
            previewLayer?.connection.isEnabled = false
            
            let popTime =  DispatchTime.now() + 2.0
            
            
            if (stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)) != nil {
                
                // settings
                let settings = AVCapturePhotoSettings()
                let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
                let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                     kCVPixelBufferWidthKey as String: 160,
                                     kCVPixelBufferHeightKey as String: 160,
                                     ]
                settings.previewPhotoFormat = previewFormat
                self.stillImageOutput?.capturePhoto(with: settings, delegate: self)
                
            }
            
            DispatchQueue.main.asyncAfter(deadline: popTime) {
                self.previewLayer?.connection.isEnabled = true
            }
        }
    }
    func captureVideoOnTap(sender: UILongPressGestureRecognizer) {
        
        sender.isEnabled = false
        let popTime =  DispatchTime.now() + 2.0
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            sender.isEnabled = true
        }
        if (self.videoOutput?.isRecording)! {
            //Change camera button for video recording
            self.videoOutput?.stopRecording()
            self.recoderTimeLabel.isHidden = true
            timer?.invalidate()
            print("stopped")
            self.captureButton.setTitle("Capture", for: UIControlState.normal)
            
        } else {
           
            setupVideoCamera()
            
            let fileName = "video.mp4";
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            let filePath = documentsURL.appendingPathComponent(fileName)
            
            self.recoderTimeLabel.isHidden = false
            self.recoderTimeLabel.text = String(format :"%2d : %2d : %2d",timeInHour,timeInMinute,timeInSec)
            
            self.captureButton.setTitle("Stop", for: UIControlState.normal)
            self.videoOutput!.startRecording(toOutputFileURL: filePath, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
            
            timer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerOnVideoCapture(timer:)), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: RunLoopMode.defaultRunLoopMode)
            
        }
        
    }
    
    //MARK: - NSTimer
    
    func timerOnVideoCapture(timer:Timer)  {
        
        timeInSec+=1
        if (timeInSec == 60) {
            timeInSec = 0
            timeInMinute+=1
            
            if (timeInMinute == 60) {
                timeInMinute = 0
                timeInHour+=1
            }
        }
        self.recoderTimeLabel.text = String(format :"%2d : %2d : %2d",timeInHour,timeInMinute,timeInSec)
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
