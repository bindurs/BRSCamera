//
//  FlashController.swift
//  AVFoundationExample
//
//  Created by Bindu on 02/08/17.
//  Copyright © 2017 Xminds. All rights reserved.
//

import UIKit
import AVFoundation

class FlashController: NSObject {
    
    //MARK: FLASH UITLITY METHODS
    func toggleFlash(session:AVCaptureSession) {
        
        var device : AVCaptureDevice!
        
        let videoDeviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera], mediaType: AVMediaTypeVideo, position: .unspecified)!
        let devices = videoDeviceDiscoverySession.devices!
        device = devices.first!
        
        if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
            
            if (device.hasTorch) {
                
                session.beginConfiguration()
                
                if device.isTorchActive == false {
                    
                    do{
                        try device.lockForConfiguration()
                        device.torchMode = .auto
                        device.unlockForConfiguration()
                        
                    } catch {
                        //DISABLE FLASH BUTTON HERE IF ERROR
                        print("Device tourch Flash Error ");
                    }
                    
                } else if (device.torchMode == .auto) {
                    
                    do{
                        try device.lockForConfiguration()
                        device.torchMode = .on
                        device.unlockForConfiguration()
                    } catch {
                        //DISABLE FLASH BUTTON HERE IF ERROR
                        print("Device tourch Flash Error ");
                    }
                    
                    
                } else {
                    do{
                        try device.lockForConfiguration()
                        device.torchMode = .off
                        device.unlockForConfiguration()
                    } catch {
                        //DISABLE FLASH BUTTON HERE IF ERROR
                        print("Device tourch Flash Error ");
                    }                }
                session.commitConfiguration()
            }
        }
    }
    
    
    
}
