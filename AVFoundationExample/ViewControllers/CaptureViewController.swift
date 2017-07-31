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
import QuartzCore

let Tonal = "Tonal"
let TonalFilter = CIFilter(name: "CIPhotoEffectTonal")

let Noir = "Noir"
let NoirFilter = CIFilter(name: "CIPhotoEffectNoir")

let Mono = "Mono"
let MonoFilter = CIFilter(name: "CIPhotoEffectMono")

let Gaussian = "Gaussian Blur"
let GaussianEffectFilter = CIFilter(name: "CIGaussianBlur")

let CMYKHalftone = "CMYK Halftone"
let CMYKHalftoneFilter = CIFilter(name: "CICMYKHalftone")

let ComicEffect = "Comic Effect"
let ComicEffectFilter = CIFilter(name: "CIComicEffect")

let Crystallize = "Crystallize"
let CrystallizeFilter = CIFilter(name: "CICrystallize")

let Edges = "Edges"
let EdgesEffectFilter = CIFilter(name: "CIEdges")

let HexagonalPixellate = "Hex Pixellate"
let HexagonalPixellateFilter = CIFilter(name: "CIHexagonalPixellate")

let Invert = "Invert"
let InvertFilter = CIFilter(name: "CIColorInvert")

let Pointillize = "Pointillize"
let PointillizeFilter = CIFilter(name: "CIPointillize")

let LineOverlay = "Line Overlay"
let LineOverlayFilter = CIFilter(name: "CILineOverlay")

let Posterize = "Posterize"
let PosterizeFilter = CIFilter(name: "CIColorPosterize")


let Filters = [
    (Tonal,TonalFilter),
    (Noir,NoirFilter),
    (Mono,MonoFilter),
    (Gaussian,GaussianEffectFilter),
    (CMYKHalftone, CMYKHalftoneFilter),
    (ComicEffect, ComicEffectFilter),
    (Crystallize, CrystallizeFilter),
    (Edges, EdgesEffectFilter),
    (HexagonalPixellate, HexagonalPixellateFilter),
    (Invert, InvertFilter),
    (Pointillize, PointillizeFilter),
    (LineOverlay, LineOverlayFilter),
    (Posterize, PosterizeFilter)
]

let filterTypeArray = Filters.map({$0.1})
let filterName = Filters.map({$0.0})

class CaptureViewController: UIViewController ,UIImagePickerControllerDelegate,UIGestureRecognizerDelegate,CameraControllerDelegate,UICollectionViewDelegate,UICollectionViewDataSource {
    
    let Album_Title = "CamCam"
    
    @IBOutlet var previewImage: UIImageView!
    @IBOutlet var photoLibraryImageView: UIImageView!
    @IBOutlet var photoLibrarybutton: UIButton!
    @IBOutlet var captureView: PreviewView!
    @IBOutlet var recoderTimeLabel: UILabel!
    @IBOutlet var captureButton: UIButton!
    
    @IBOutlet var filterCollectionview: UICollectionView!
    var touchPoint : CGPoint?
    var timer : Timer?
    var timeInMinute :Int = 0
    var timeInSec :Int = 0
    var timeInHour :Int = 0
    // session
    var session : AVCaptureSession?
    
    var camFocus : CameraFocusSquareView?
    var isPhoto : Bool = true
    var isFrontCamera : Bool = false
    var albumFound : Bool = false
    
    var cameraController: CameraController?
    
    override func viewWillDisappear(_ animated: Bool) {
        invalidateTimer()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        

        cameraController = CameraController()
        // Do any additional setup after loading the view.
        cameraController?.delegate = self
        
        session = cameraController?.setupCamera(withPhoto: isPhoto, isFrontCamera: isFrontCamera)
        
        getImageAfterImageSave()
        photoLibrarybutton.layer.cornerRadius = photoLibrarybutton.frame.size.width/2
        photoLibraryImageView.layer.cornerRadius = photoLibrarybutton.frame.size.width/2
        captureButton.layer.cornerRadius = captureButton.frame.size.width/2
        
        //focus - tap gesture
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(tapOnView(sender:)))
        tap.delegate = self
        captureView.addGestureRecognizer(tap)
        
        self.recoderTimeLabel.isHidden = true

        captureView.session = session
    }
    
    // MARK:- Methods
    
    @IBAction func switchCameraBtnPressed(_ sender: UIButton) {
        
        isFrontCamera = !isFrontCamera
        session?.stopRunning()
        session = cameraController?.setupCamera(withPhoto: isPhoto, isFrontCamera: isFrontCamera)
        captureView.session = session
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
    
    func getImageAfterImageSave() {
        
        cameraController?.getLastImageFromAlbum(Success: { (data) -> Void in
            
            self.photoLibraryImageView.image =  data as UIImage
            self.photoLibraryImageView.isHidden = false
            self.photoLibrarybutton.isHidden = false
            
        }, Faliure : { (error) -> Void in
            
            self.photoLibraryImageView.isHidden = true
            self.photoLibrarybutton.isHidden = true
        })
        
    }
    
    func capturedImage(image:UIImage) {
        
        DispatchQueue.main.sync(execute: {
            
            previewImage.image = image
            
        })
        
    }
    //MARK: - Button Actions
    
    @IBAction func captureBtnClicked(_ sender: UIButton) {
        
        if isPhoto {
            
            captureView.videoPreviewLayer.connection.isEnabled = false
            
            let popTime =  DispatchTime.now() + 2.0
            cameraController?.capture()
            DispatchQueue.main.asyncAfter(deadline: popTime) {
                self.captureView.videoPreviewLayer.connection.isEnabled = true
            }
        } else {
            
            let popTime =  DispatchTime.now() + 2.0
            
            if (cameraController?.videoOutput?.isRecording)!{
                //Change camera button for video recording
                DispatchQueue.main.asyncAfter(deadline: popTime) {
                    self.captureView.videoPreviewLayer.connection.isEnabled = true
                    
                }
                cameraController?.videoOutput?.stopRecording()
                invalidateTimer()
                self.recoderTimeLabel.isHidden = true
                
                print("stopped")
                self.captureButton.setTitle("Capture", for: UIControlState.normal)
                
            } else {
                
                self.recoderTimeLabel.isHidden = false
                self.recoderTimeLabel.text = String(format :"%02d : %02d : %02d",timeInHour,timeInMinute,timeInSec)
                
                self.captureButton.setTitle("Stop", for: UIControlState.normal)
                
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerOnVideoCapture(timer:)), userInfo: nil, repeats: true)
                timer?.fire()
                cameraController?.capture()
            }
        }
    }
    
    //MARK: - Shows alert when image is saved
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        
        guard error == nil else {
            print(error ?? "error")
            return
        }
        
        //Image saved successfully
        print("saved")
        
    }
    
    // MARK: - TapGesture Recogniser
    func tapOnView(sender: UITapGestureRecognizer) {
        // handling code
        
        touchPoint = sender.location(in: captureView)
        
        focus(aPoint: touchPoint!)
        
        if ((camFocus) != nil) {
            camFocus?.removeFromSuperview()
        }
        
        camFocus = CameraFocusSquareView(frame: CGRect(x: (touchPoint?.x)!-45, y: (touchPoint?.y)!-45, width:90, height: 90))
        camFocus?.backgroundColor = UIColor.clear
        self.view.addSubview(camFocus!)
        camFocus?.setNeedsDisplay()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        camFocus?.alpha  = 0
        UIView.commitAnimations()
    }
    
    //MARK: - UIButton Actions
    
    @IBAction func swapBtnPressed(_ sender: UIButton) {
        
        cameraController?.delegate = self
       
        if isPhoto {
            sender.setImage(#imageLiteral(resourceName: "camera"), for: UIControlState.normal)
            cameraController?.setupVideoCamera()
            
        } else {
            sender.setImage(#imageLiteral(resourceName: "videocam"), for: UIControlState.normal)
            invalidateTimer()
            cameraController?.setupPicCamera()
        }
        isPhoto = !isPhoto
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
        self.recoderTimeLabel.text = String(format :"%2d : %02d : %2d",timeInHour,timeInMinute,timeInSec)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UICollectionViewDelegate And DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterTypeArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell : FilterCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "fCell", for: indexPath) as! FilterCollectionViewCell
        
        cell.filterNameLabel.text = filterName[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cameraController?.selectedFilter = filterTypeArray[indexPath.row]!
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let vc :GalleryImageViewController = segue.destination as! GalleryImageViewController
        vc.assetCollection = cameraController?.assetCollection
    }
    
}
