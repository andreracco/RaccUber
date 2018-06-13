//
//  SmallCircleView.swift
//  RaccUber
//
//  Created by Andre Racco on 28/11/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import UIKit

class SmallCircleView: UIView {

    @IBInspectable var borderColor: UIColor?{
        didSet{
            setupView()
        }
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = borderColor?.cgColor
    }
}
