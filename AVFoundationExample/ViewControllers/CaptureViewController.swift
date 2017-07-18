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
    
    let Album_Title = "CamCam"
    
    @IBOutlet var photoLibraryImageView: UIImageView!
    @IBOutlet var photoLibrarybutton: UIButton!
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
    var audioCaptureDevice:AVCaptureDevice?
    // switching camera
    var camera : Bool = true
    var camFocus : CameraFocusSquareView?
    var input : AVCaptureDeviceInput?
    var audioInput : AVCaptureDeviceInput?
    var error: NSError?
    var isCamera : Bool = true
    override func viewWillDisappear(_ animated: Bool) {
        invalidateTimer()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
        initialSetup()
        photoLibrarybutton.layer.cornerRadius = photoLibrarybutton.frame.size.width/2
        photoLibraryImageView.layer.cornerRadius = photoLibrarybutton.frame.size.width/2
        captureButton.layer.cornerRadius = captureButton.frame.size.width/2
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(tapOnView(sender:)))
        tap.delegate = self
        captureView.addGestureRecognizer(tap)
        
        self.recoderTimeLabel.isHidden = true
        
        
    }
    
    // MARK:- Methods
    func initialSetup() {
        
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//           try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with:[.defaultToSpeaker,.allowBluetooth])
//            try audioSession.setActive(true)
//        } catch let err as NSError {
//            error = err
//            input = nil
//            print(error!.localizedDescription)
//            
//        }
        
        session = AVCaptureSession()
//        session?.usesApplicationAudioSession = true
//        session?.automaticallyConfiguresApplicationAudioSession = false
        if (camera == false) {
            
            let captureDeviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .front)
            let videoDevices = captureDeviceDiscoverySession?.devices
            
            for device in videoDevices!{
                let device = device
                if device.position == AVCaptureDevicePosition.front {
                    captureDevice = device
                    break
                }
            }
            
            
        } else {
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            audioCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            
        }
        
        // image output
        stillImageOutput = AVCapturePhotoOutput()
        stillImageOutput?.isHighResolutionCaptureEnabled = true
        stillImageOutput?.isLivePhotoCaptureEnabled = (stillImageOutput?.isLivePhotoCaptureSupported)!
        
        //video output
        videoOutput = AVCaptureMovieFileOutput()
        
        setupPicCamera()
        session?.startRunning()
        createAlbum()
        getLastImageFromAlbum()
    }
    func setupVideoCamera() {
        
        isCamera = false
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
                    previewLayer!.frame = captureView.frame
                    previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    previewLayer?.connection.isEnabled = true
                    captureView.layer.addSublayer(previewLayer!)
                    
                    session!.commitConfiguration()
                }
            }
        } catch let err as NSError {
            error = err
            input = nil
            print(error!.localizedDescription)
            
        }
        
        do {
            session?.beginConfiguration()
            
            audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
            if error == nil && session!.canAddInput(audioInput) {
                session!.addInput(audioInput)
                session!.commitConfiguration()
            }
        } catch let err as NSError {
            error = err
            input = nil
            print(error!.localizedDescription)
            
        }
    
}
func setupPicCamera() {
    
    invalidateTimer()
    
    self.captureButton.setTitle("Capture", for: UIControlState.normal)
    isCamera = true
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
                previewLayer?.frame = captureView.frame
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
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



@IBAction func switchCameraBtnPressed(_ sender: UIButton) {
    
    self.camera = !camera
    session?.stopRunning()
    previewLayer?.removeFromSuperlayer()
    initialSetup()
}

func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
    
    if let error = error {
        print(error.localizedDescription)
    }
    
    if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer , let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
        
        let dataProvider = CGDataProvider(data: dataImage as CFData)
        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
        
        saveImage()
    }
}

func saveImage() {
    
    PHPhotoLibrary.shared().performChanges({
        let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: self.image)
        let assetPlaceholder = assetRequest.placeholderForCreatedAsset
        let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
        albumChangeRequest?.addAssets([assetPlaceholder!] as NSArray)
        
    }) { (success, error) in
        
        self.getLastImageFromAlbum()
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
    fetchOptions.predicate = NSPredicate(format: "title = %@", Album_Title)
    let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
    //Check return value - If found, then get the first album out
    if let _: AnyObject = collection.firstObject {
        self.albumFound = true
        assetCollection = collection.firstObject!
    } else {
        //If not found - Then create a new album
        PHPhotoLibrary.shared().performChanges({
            let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.Album_Title)
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

func getLastImageFromAlbum() {
    
    var albumFound = false
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "title = %@", Album_Title)
    let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
    
    if let first_obj:Any = collection.firstObject {
        albumFound = true
        print(first_obj)
    }
    
    if albumFound {
        let imageManager = PHCachingImageManager()
        photosAsset = PHAsset.fetchAssets(in: assetCollection, options: nil) as! PHFetchResult<AnyObject>
        
        print(photosAsset.count)
        photosAsset.enumerateObjects({ (object, count, stop) in
            
            let asset = self.photosAsset.lastObject as! PHAsset
            
            let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = true
            
            imageManager.requestImage(for: asset , targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: { (result, info) in
                DispatchQueue.main.async {
                    self.photoLibraryImageView.image = result
                }
            })
        })
        
        if photosAsset.count == 0 {
            photoLibrarybutton.isHidden = true
            photoLibraryImageView.isHidden = true
        } else {
            photoLibrarybutton.isHidden = false
            photoLibraryImageView.isHidden = false
        }
    }
    
}

func invalidateTimer() {
    
    recoderTimeLabel.isHidden = true
    
    timeInHour = 0
    timeInMinute = 0
    timeInSec = 0
    
    if timer != nil {
        timer!.invalidate()
        timer = nil
    }
    
   
    
}


//MARK: - Button Actions


@IBAction func captureBtnClicked(_ sender: UIButton) {
    
    if isCamera {
        
        previewLayer?.connection.isEnabled = false
        
        let popTime =  DispatchTime.now() + 2.0
        
        
        if (stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)) != nil {
            
            // settings
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,kCVPixelBufferWidthKey as String: 160,kCVPixelBufferHeightKey as String: 160,
                                 ]
            settings.previewPhotoFormat = previewFormat
            self.stillImageOutput?.capturePhoto(with: settings, delegate: self)
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            self.previewLayer?.connection.isEnabled = true
        }
    } else {
        
        let popTime =  DispatchTime.now() + 2.0
        
        if (self.videoOutput?.isRecording)!{
            //Change camera button for video recording
            DispatchQueue.main.asyncAfter(deadline: popTime) {
                self.previewLayer?.connection.isEnabled = true
                
            }
            
            invalidateTimer()
            self.videoOutput?.stopRecording()
            self.recoderTimeLabel.isHidden = true
            
            print("stopped")
            self.captureButton.setTitle("Capture", for: UIControlState.normal)
            
        } else {
            let fileName = "video.mp4";
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            let filePath = documentsURL.appendingPathComponent(fileName)
            
            self.recoderTimeLabel.isHidden = false
            self.recoderTimeLabel.text = String(format :"%2d : %2d : %2d",timeInHour,timeInMinute,timeInSec)
            
            self.captureButton.setTitle("Stop", for: UIControlState.normal)
            self.videoOutput!.startRecording(toOutputFileURL: filePath, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
            
            //                timer = Timer(timeInterval: 0.1, target: self, selector: #selector(timerOnVideoCapture(timer:)), userInfo: nil, repeats: true)
            //                timer?.fire()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerOnVideoCapture(timer:)), userInfo: nil, repeats: true)
            timer?.fire()
        }
        
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
//MARK: - Get completed video path

func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
    
    //Saves the video in Photos
    doVideoProcessing(outputPath: outputFileURL! as NSURL)
    
}
func doVideoProcessing(outputPath:NSURL){
    
    PHPhotoLibrary.shared().performChanges({
        
        let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputPath as URL)
        let assetPlaceholder = assetRequest?.placeholderForCreatedAsset
        let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
        albumChangeRequest?.addAssets([assetPlaceholder!] as NSArray)
        self.getLastImageFromAlbum()
    }) { (success, error) in
        print("added video to album")
        print(error ?? "error")
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

//MARK: - UIButton Actions

@IBAction func shoImageBtnPressed(_ sender: UIButton) {
    
    
    
}

@IBAction func swapBtnPressed(_ sender: UIButton) {
    
    if isCamera {
        sender.setTitle("Photo", for: UIControlState.normal)
        setupVideoCamera()
        
    } else {
        sender.setTitle("Video", for: UIControlState.normal)
        setupPicCamera()
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

override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
}


// MARK: - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    
    let vc :GalleryImageViewController = segue.destination as! GalleryImageViewController
    vc.assetCollection = assetCollection
}


}
