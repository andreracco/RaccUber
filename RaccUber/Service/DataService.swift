//
//  DataService.swift
//  RaccUber
//
//  Created by Andre Racco on 01/12/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import Foundation
import Firebase

let DB_BASE = Database.database().reference()

class DataService {
    static let instance = DataService()

    private let _REF_BASE = DB_BASE
    private let _REF_USER = DB_BASE.child("users")
    private let _REF_DRIVER = DB_BASE.child("drivers")
    private let _REF_TRIP = DB_BASE.child("trips")

    var REF_BASE: DatabaseReference{
        return _REF_BASE
    }

    var REF_USER: DatabaseReference{
        return _REF_USER
    }

    var REF_DRIVER: DatabaseReference{
        return _REF_DRIVER
    }

    var REF_TRIP: DatabaseReference{
        return _REF_TRIP
    }

    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>, isDriver: Bool){
        if isDriver{
            REF_DRIVER.child(uid).updateChildValues(userData)
        } else{
            REF_USER.child(uid).updateChildValues(userData)
        }

    }
}
