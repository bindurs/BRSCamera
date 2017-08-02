//
//  CameraController.swift
//  AVFoundationExample
//
//  Created by Bindu on 20/07/17.
//  Copyright © 2017 Xminds. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

protocol CameraControllerDelegate{
    func getImageAfterImageSave()
    func capturedImage(image:UIImage)
}

class CameraController: NSObject,AVCapturePhotoCaptureDelegate,AVCaptureFileOutputRecordingDelegate,AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var delegate:CameraControllerDelegate?
    var session : AVCaptureSession?
    var stillImageOutput : AVCapturePhotoOutput?
    var videoDataOutput : AVCaptureVideoDataOutput?
    var videoOutput : AVCaptureMovieFileOutput?
    var previewLayer :AVCaptureVideoPreviewLayer?
    var captureDevice:AVCaptureDevice?
    var audioCaptureDevice:AVCaptureDevice?
    var camFocus : CameraFocusSquareView?
    var input : AVCaptureDeviceInput?
    var audioInput : AVCaptureDeviceInput?
    let Album_Title = "CamCam"
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult<AnyObject>!
    var assetThumbnailSize:CGSize!
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    var error: NSError?
    var isPhoto : Bool?
    var isFrontCam : Bool?
    var albumFound : Bool = false
    var resultImage : Any?
    var filteredImage : UIImage?
    //    var outputImage : UIImage?
    
    
    override init() {
        super.init()
        selectedFilter = nil
    }
    
    var selectedFilter: CIFilter? {
        
        willSet {
            self.selectedFilter = newValue
        }
    }
    
    func setupCamera(withPhoto:Bool, isFrontCamera: Bool) -> AVCaptureSession {
        
        isPhoto = withPhoto
        isFrontCam = isFrontCamera
        
        session = AVCaptureSession()
        
        if (isFrontCamera) {
            
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
        
        
        // output
        videoDataOutput = AVCaptureVideoDataOutput()
        
        let newSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable:kCVPixelFormatType_32BGRA as Any]
        videoDataOutput?.videoSettings = newSettings
        // discard if the data output queue is blocked (as we process the still image
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput?.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: videoDataOutputQueue)
        
        session?.addOutput(videoDataOutput)
        
        // photo output
        
        stillImageOutput = AVCapturePhotoOutput()
        stillImageOutput?.isHighResolutionCaptureEnabled = true
        stillImageOutput?.isLivePhotoCaptureEnabled = (stillImageOutput?.isLivePhotoCaptureSupported)!
        
        //video output
        videoOutput = AVCaptureMovieFileOutput()
        if isPhoto! {
            setupPicCamera()
        } else {
            setupVideoCamera()
        }
        session?.startRunning()
        createAlbum()
        
        return session!
    }
    func setupVideoCamera() {
        
        isPhoto = false
        session!.sessionPreset = AVCaptureSessionPresetHigh
        
        //video input
        do {
            session?.beginConfiguration()
            session!.removeInput(input)
            
            input = try AVCaptureDeviceInput(device: captureDevice)
            if error == nil && session!.canAddInput(input) {
                session!.addInput(input)
                
                
                if session!.canAddOutput(videoOutput) {
                    session!.addOutput(videoOutput)
                    
                    
                    session!.commitConfiguration()
                }
            }
        } catch let err as NSError {
            error = err
            input = nil
            print(error!.localizedDescription)
            
        }
        // audio input
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
        
        isPhoto = true
        session?.sessionPreset = AVCaptureSessionPresetPhoto
        
        do {
            
            session?.beginConfiguration()
            session!.removeInput(input)
            
            input = try AVCaptureDeviceInput(device: captureDevice)
            
            
            if (error == nil && session!.canAddInput(input)) {
                
                session?.addInput(input)
                
                if session!.canAddOutput(stillImageOutput) {
                    session?.addOutput(stillImageOutput)
                    session?.commitConfiguration()
                }
            }
        } catch let err as NSError {
            error = err
            input = nil
            print(error?.localizedDescription ?? "error")
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
    
    func getLastImageFromAlbum(Success:   @escaping ( _ success: UIImage) -> Void, Faliure:  @escaping ( _ faliure: NSDictionary) -> Void ) {
        
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
            
            if (photosAsset.count > 0) {
                photosAsset.enumerateObjects({ (object, count, stop) in
                    let asset = self.photosAsset.lastObject as! PHAsset
                    
                    let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .fastFormat
                    options.isSynchronous = true
                    
                    imageManager.requestImage(for: asset , targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: { (result, info) in
                        DispatchQueue.main.async {
                            
                            if (result != nil) {
                                Success(result!)
                            } else {
                                Faliure(["message" : "result not found"])
                            }
                        }
                    })
                })
            }  else {
                Faliure(["message" : "result not found"])
            }
            
        } else {
            Faliure(["message" : "result not found"])
        }
    }
    
    func capture() {
        
        if isPhoto! {
            
            if (stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)) != nil {
                
                //  photo settings
                let settings = AVCapturePhotoSettings()
                let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
                let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,kCVPixelBufferWidthKey as String: 160,kCVPixelBufferHeightKey as String: 160]
                settings.previewPhotoFormat = previewFormat
                
                self.stillImageOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
            }
        } else {
            
            if (self.videoOutput?.isRecording)!{
                self.videoOutput?.stopRecording()
            } else {
                let fileName = "video.mp4";
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                
                let filePath = documentsURL.appendingPathComponent(fileName)
                self.videoOutput!.startRecording(toOutputFileURL: filePath, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
            }
        }
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
        }) { (success, error) in
            self.delegate?.getImageAfterImageSave()
            print("added video to album")
            print(error ?? "error")
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        connection.videoOrientation = .portrait
        let pixelBuffer  :CVPixelBuffer  = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        if (selectedFilter != nil) {
            
            selectedFilter!.setDefaults()
            selectedFilter?.setValue(image, forKey: kCIInputImageKey)
            
            guard let output = selectedFilter?.value(forKey: kCIOutputImageKey) as? CIImage else {
                print("CIFilter failed to render image")
                return
            }
            
            let context = CIContext(options: [kCIContextUseSoftwareRenderer: true])
            let cgimg = context.createCGImage(output, from: output.extent)
            filteredImage = UIImage(cgImage: cgimg!)
        } else {
            let context = CIContext(options: [kCIContextUseSoftwareRenderer: true])
            let cgimg = context.createCGImage(image, from: image.extent)
            filteredImage = UIImage(cgImage: cgimg!)
        }
        delegate?.capturedImage(image: filteredImage!)
        
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer , let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
            //                outputImage = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
            
            saveImage()
        }
    }
    
    func saveImage() {
        
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: self.filteredImage!)
            let assetPlaceholder = assetRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            albumChangeRequest?.addAssets([assetPlaceholder!] as NSArray)
            
        }) { (success, error) in
            
            self.delegate?.getImageAfterImageSave()
            print("added image to album")
            print(error ?? "error")
        }
        
        
    }
    
}
