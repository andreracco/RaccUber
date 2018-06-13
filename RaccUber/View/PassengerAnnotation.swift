//
//  PassengerAnnotation.swift
//  RaccUber
//
//  Created by Andre Racco on 07/12/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, key: String) {
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
}
