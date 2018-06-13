//
//  CenterVCDelegate.swift
//  RaccUber
//
//  Created by Andre Racco on 29/11/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    func toggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldExpand: Bool)
}
