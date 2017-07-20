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
}
class CameraController: NSObject,AVCapturePhotoCaptureDelegate,AVCaptureFileOutputRecordingDelegate {
    
    var delegate:CameraControllerDelegate?
    var session : AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
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
    var camera : Bool?
    var isCamera : Bool?
    var albumFound : Bool = false
    
    var resultImage : Any?
    var image: UIImage!
    
    func initialSetup(isCamera: Bool) -> AVCaptureSession{
        
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
        
        // photo output
        stillImageOutput = AVCapturePhotoOutput()
        stillImageOutput?.isHighResolutionCaptureEnabled = true
        stillImageOutput?.isLivePhotoCaptureEnabled = (stillImageOutput?.isLivePhotoCaptureSupported)!
        
        //video output
        videoOutput = AVCaptureMovieFileOutput()
        if isCamera {
            setupPicCamera()
        } else {
            setupVideoCamera()
        }
        session?.startRunning()
        createAlbum()
        return session!
    }
    func setupVideoCamera() {
        
        isCamera = false
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
        
        //  invalidateTimer()
        
        //    self.captureButton.setTitle("Capture", for: UIControlState.normal)
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
        
        if isCamera! {
            
            if (stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)) != nil {
                
                // settings
                let settings = AVCapturePhotoSettings()
                let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
                let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,kCVPixelBufferWidthKey as String: 160,kCVPixelBufferHeightKey as String: 160,
                                     ]
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
            
            self.delegate?.getImageAfterImageSave()
            print("added image to album")
            print(error ?? "error")
        }
    }
    
}
