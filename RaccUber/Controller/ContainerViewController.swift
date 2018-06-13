//
//  ContainerViewController.swift
//  RaccUber
//
//  Created by Andre Racco on 29/11/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState{
    case collapsed
    case leftPanelExpanded
}

enum ShowWhichVC{
    case homeVC
}

var showVC: ShowWhichVC = .homeVC

class ContainerViewController: UIViewController {

    var homeVC: HomeViewController!
    var leftVC: LeftSidePanelViewController!
    var centerController: UIViewController!
    var currentState: SlideOutState = .collapsed {
        didSet {
            let shouldShowShadown = (currentState != .collapsed)
            shouldShowShadowForCenterViewController(status: shouldShowShadown)
        }
    }

    var isHidden = false
    let centerPanelExpandedOffSet: CGFloat = 160

    var tap: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        initCenter(screen: showVC)
    }

    func initCenter(screen: ShowWhichVC){
        var presentingController: UIViewController
        showVC = screen

        if homeVC == nil{
            homeVC = UIStoryboard.homeViewController()
            homeVC.delegate = self
        }

        presentingController = homeVC

        if let con = centerController{
            con.view.removeFromSuperview()
            con.removeFromParentViewController()
        }

        centerController = presentingController

        view.addSubview(centerController.view)
        addChildViewController(centerController)
        centerController.didMove(toParentViewController: self)
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return UIStatusBarAnimation.slide
    }

    override var prefersStatusBarHidden: Bool{
        return isHidden
    }

}

extension ContainerViewController: CenterVCDelegate{
    func toggleLeftPanel() {

        let notAlreadyExpanded = (currentState != .leftPanelExpanded)

        if notAlreadyExpanded{
            addLeftPanelViewController()
            animateLeftPanel(shouldExpand: true)
        } else {
            animateLeftPanel(shouldExpand: false)
        }       

    }

    func addLeftPanelViewController() {
        if leftVC == nil{
            leftVC = UIStoryboard.leftViewController()
            addChildSidePanelViewController(leftVC)
        }
    }

    @objc func animateLeftPanel(shouldExpand: Bool) {
        
        if shouldExpand{
            isHidden = !isHidden

            setupWhiteCoverView()
            currentState = .leftPanelExpanded
            animateCenterPanelXPosition(targetPosition: centerController.view.frame.width - centerPanelExpandedOffSet)
            animateStatusBar()
        }else{
            isHidden = !isHidden
            animateStatusBar()

            hideWhiteCoverView()
            animateCenterPanelXPosition(targetPosition: 0, completion: {(finished) in
                if finished == true{
                    self.currentState = .collapsed
                    self.leftVC = nil
                }
            })

        }
    }

    func setupWhiteCoverView(){
        let whiteCoverView = UIView(frame: (CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25

        whiteCoverView.isUserInteractionEnabled = true

        self.centerController.view.addSubview(whiteCoverView)
        whiteCoverView.fadeTo(alphaValue: 0.75, withDuration: 0.2)

        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldExpand:)))
        tap.numberOfTapsRequired = 1

        self.centerController.view.addGestureRecognizer(tap)
    }

    func hideWhiteCoverView(){
        centerController.view.removeGestureRecognizer(tap)

        for subview in self.centerController.view.subviews{
            if subview.tag == 25{
                UIView.animate(withDuration: 0.2, animations: {
                    subview.alpha = 0.0
                }, completion: { (finished) in
                    subview.removeFromSuperview()
                })
            }
        }
    }

    func shouldShowShadowForCenterViewController(status: Bool){
        if status == true {
            centerController.view.layer.shadowOpacity = 0.6
        } else {
            centerController.view.layer.shadowOpacity = 0.0
        }
    }

    func addChildSidePanelViewController(_ sidePanelController: LeftSidePanelViewController) {
        view.insertSubview(sidePanelController.view, at: 0)
        addChildViewController(sidePanelController)
        sidePanelController.didMove(toParentViewController: self)
    }

    func animateStatusBar(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }

    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
        },completion: completion)
    }
}

private extension UIStoryboard{
    class func mainStoryBoard() -> UIStoryboard{
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }

    class func leftViewController() -> LeftSidePanelViewController?{
        return mainStoryBoard().instantiateViewController(withIdentifier: "LeftPanelViewController") as? LeftSidePanelViewController
    }

    class func homeViewController() -> HomeViewController?{
        return mainStoryBoard().instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController

    }
}
