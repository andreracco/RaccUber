//
//  LoginViewController.swift
//  RaccUber
//
//  Created by Andre Racco on 30/11/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: RoundedCornerTextField!
    @IBOutlet weak var passwordField: RoundedCornerTextField!
    @IBOutlet weak var segmentedDriverPassenger: UISegmentedControl!
    @IBOutlet weak var authButton: ShadowButton!


    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
        self.view.bindToKeyboard()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    @IBAction func closeButtonTouched(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func authButtonWasPressed(_ sender: Any) {
        if emailField.text != nil && passwordField != nil {
            authButton.animateButton(shoudLoad: true, withMessage: nil)
            self.view.endEditing(true)

            if let email = emailField.text, let password = passwordField.text{
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    if error == nil{
                        if let user = user{
                            if self.segmentedDriverPassenger.selectedSegmentIndex == 0 {
                                let userData = ["provider": user.providerID] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                            } else {
                                let userData = ["provider": user.providerID, "userIsDriver": true, "isPickupModeEnable": false, "driverIsOnTrip": false] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                            }
                        }
                        print("Email user authenticated successful with FireBase!")
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        
                        if let errorCode = AuthErrorCode(rawValue: error!._code) {
                            switch errorCode {
                                case .invalidCredential: print("Invalid Credential")
                                case .wrongPassword: print("Wrong password")
                                default: print ("Unexpected error \(errorCode.rawValue)")
                            }
                        }
                        
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                    if errorCode == .invalidEmail{
                                        print("Invalid Email")
                                    } else {
                                        print ("Unexpected error \(errorCode.rawValue)")
                                    }
                                } else {
                                    if let user = user {
                                        if self.segmentedDriverPassenger.selectedSegmentIndex == 0 {
                                            let userData = ["provider": user.providerID] as [String: Any]
                                            DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                                        } else {
                                            let userData = ["provider": user.providerID, "userIsDriver": true, "isPickupModeEnable": false, "driverIsOnTrip": false] as [String: Any]
                                            DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                                        }
                                    }
                                    print("Successfully create new account in Firebase")
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        })
                    }
                    
                })
            }
        }
    }

}
