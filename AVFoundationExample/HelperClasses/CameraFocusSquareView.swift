//
//  CameraFocusSquareView.swift
//  AVFoundationExample
//
//  Created by Bindu on 06/07/17.
//  Copyright © 2017 Xminds. All rights reserved.
//

import UIKit

class CameraFocusSquareView: UIView {
    
//    let squreLength : Float = 80.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 3.0
        self.layer.borderColor = UIColor.white.cgColor
        
        let selectionAnimation = CABasicAnimation(keyPath: "borderColor")
        selectionAnimation.toValue = UIColor.blue.cgColor
        selectionAnimation.repeatCount = 8
        self.layer.add(selectionAnimation, forKey: "selectionAnimation")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
