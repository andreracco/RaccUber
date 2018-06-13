//
//  RoundImageView.swift
//  RaccUber
//
//  Created by Andre Racco on 28/11/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {
    
    override func awakeFromNib() {
        setupView()
    }

    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }

}
