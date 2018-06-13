//
//  UpdateService.swift
//  RaccUber
//
//  Created by Andre Racco on 06/12/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MapKit

class UpdateService{
    static let instance = UpdateService()

    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for user in userSnapshot{
                    if user.key == Auth.auth().currentUser?.uid{
                        DataService.instance.REF_USER.child(user.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
                    }
                }
            }
        })
    }

    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_DRIVER.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot{
                    if driver.key == Auth.auth().currentUser?.uid{
                        if driver.childSnapshot(forPath: "isPickupModeEnable").value as? Bool == true{
                            DataService.instance.REF_DRIVER.child(driver.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
                        }
                    }
                }
            }
        })
    }
}
