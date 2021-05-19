//
//  RoundButton.swift
//  Running App
//
//  Created by Rohit Jangid on 11/05/21.
//

import UIKit

class RoundButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        layer.cornerRadius = layer.frame.height / 2
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 25
        layer.shadowOpacity = 0.6
    }
    
}
