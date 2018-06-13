//
//  LeftSidePanelViewController.swift
//  RaccUber
//
//  Created by Andre Racco on 29/11/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import UIKit
import Firebase

class LeftSidePanelViewController: UIViewController {

    let appDelegate = AppDelegate.getAppDelegate()
    var currentUserId = Auth.auth().currentUser?.uid

    @IBOutlet weak var switchPickUpMode: UISwitch!
    @IBOutlet weak var lblPickUpMode: UILabel!
    @IBOutlet weak var imageUser: RoundImageView!
    @IBOutlet weak var lblEmailAccount: UILabel!
    @IBOutlet weak var lblAccoutType: UILabel!
    @IBOutlet weak var btnLoginOut: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        switchPickUpMode.isOn = false
        switchPickUpMode.isHidden = true
        lblPickUpMode.isHidden = true
        lblEmailAccount.text = ""
        imageUser.isHidden = true
        lblAccoutType.text = ""

        observePassengerAndDrivers()

        if Auth.auth().currentUser == nil {
            lblEmailAccount.text = ""
            lblAccoutType.text = ""
            imageUser.isHidden = true
            btnLoginOut.setTitle("SIGN UP / LOGIN", for: .normal)
        } else {
            lblEmailAccount.text = Auth.auth().currentUser?.email
            imageUser.isHidden = false
            btnLoginOut.setTitle("LOGOUT", for: .normal)
        }

        currentUserId = Auth.auth().currentUser?.uid
    }

    @IBAction func signUpLoginButtonTouched(_ sender: Any) {
        if Auth.auth().currentUser == nil{
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController
            present(loginVC!, animated: true, completion: nil)
        }else{
            do {
                try Auth.auth().signOut()
                lblEmailAccount.text = ""
                switchPickUpMode.isHidden = true
                lblPickUpMode.isHidden = true
                lblAccoutType.text = ""
                imageUser.isHidden = true
                btnLoginOut.setTitle("SIGN UP / LOGIN", for: .normal)
            } catch (let error){
                print(error)
            }
        }
    }

    @IBAction func switchWasToggled(_ sender: Any) {
        if switchPickUpMode.isOn {
            lblPickUpMode.text = "PICKUP MODE ENABLED"
           appDelegate.MenuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVER.child(currentUserId!).updateChildValues(["isPickupModeEnable": true])
        } else {
            lblPickUpMode.text = "PICKUP MODE DISABLED"
            appDelegate.MenuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVER.child(currentUserId!).updateChildValues(["isPickupModeEnable": false])
        }
    }

    func observePassengerAndDrivers(){
        DataService.instance.REF_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.lblAccoutType.text = "PASSENGER"
                    }
                }
            }
        })

        DataService.instance.REF_DRIVER.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.lblAccoutType.text = "DRIVER"
                        self.lblPickUpMode.isHidden = false
                        self.switchPickUpMode.isHidden = false
                        self.switchPickUpMode.isEnabled = true

                        let switchStatus = snap.childSnapshot(forPath: "isPickupModeEnable").value as! Bool
                        print(switchStatus)
                        self.switchPickUpMode.isOn = switchStatus
                    }
                }
            }

        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
