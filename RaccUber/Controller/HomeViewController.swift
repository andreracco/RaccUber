//
//  HomeViewController.swift
//  RaccUber
//
//  Created by Andre Racco on 27/11/17.
//  Copyright © 2017 raccon1c. All rights reserved.
//

import UIKit
import RevealingSplashView
import MapKit
import CoreLocation
import Firebase

class HomeViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var requestRideButton: ShadowButton!
    @IBOutlet weak var btnCenterMap: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: SmallCircleView!
    
    var delegate: CenterVCDelegate?
    var manager: CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    var currentUserId: String?
    var selectedItemPlacemark: MKPlacemark? = nil
    var route: MKRoute!

    let revealingSplashView = RevealingSplashView(iconImage: #imageLiteral(resourceName: "launchScreenIcon"), iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    var tableView = UITableView()
    var matchingItems: [MKMapItem] = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUserId = Auth.auth().currentUser?.uid

        destinationTextField.delegate = self
        mapView?.delegate = self
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest

        checkLocationAuthStatus()
        centerMapOnUserLocation()
        
        DataService.instance.REF_DRIVER.observe(.value, with: { (snapshot) in
            self.loadDriverAnnotationFromFB()
        })

        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.squeezeAndZoomOut
        revealingSplashView.startAnimation()

        revealingSplashView.heartAttack = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    @IBAction func requestRideButtonTouched(_ sender: Any) {
        requestRideButton.animateButton(shoudLoad: true, withMessage: nil)
    }

    @IBAction func menuButtonTouched(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }

    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
        centerMapOnUserLocation()
        btnCenterMap.fadeTo(alphaValue: 0.0, withDuration: 0.2)
    }

    func checkLocationAuthStatus(){
        if CLLocationManager.authorizationStatus() == .authorizedAlways{
            manager?.startUpdatingLocation()
        } else {
            manager?.requestAlwaysAuthorization()
        }
    }

    func centerMapOnUserLocation(){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView?.setRegion(coordinateRegion, animated: true)
    }
    
    func loadDriverAnnotationFromFB(){
        DataService.instance.REF_DRIVER.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot{
                    if driver.hasChild("coordinate"){
                        if driver.childSnapshot(forPath: "isPickupModeEnable").value as? Bool == true{
                            if let driverDict = driver.value as? Dictionary<String, Any>{
                                let coordinateArray = driverDict["coordinate"] as! NSArray
                                let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                
                                let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                var driverIsVisible: Bool {
                                    return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                        if let driverAnnotation = annotation as? DriverAnnotation{
                                            if driverAnnotation.key == driver.key {
                                                driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                                return true
                                            }
                                        }
                                        return false
                                    })
                                }
                                
                                if !driverIsVisible{
                                    self.mapView.addAnnotation(annotation)
                                }
                            }
                        } else {
                            for annotation in self.mapView.annotations{
                                if annotation.isKind(of: DriverAnnotation.self){
                                    if let annotation = annotation as? DriverAnnotation{
                                        if annotation.key == driver.key{
                                            self.mapView.removeAnnotation(annotation)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
}

extension HomeViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        checkLocationAuthStatus()
        if status == .authorizedAlways {
            mapView?.showsUserLocation = true
            mapView?.userTrackingMode = .follow
        } else {

        }
    }
}

extension HomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation{
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        } else if let annotation = annotation as? MKAnnotation {
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "destinationAnnotation")
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        btnCenterMap.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRender = MKPolylineRenderer(overlay: self.route.polyline)
        lineRender.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRender.lineWidth = 3
        return lineRender
    }
    
    func performSearch() {
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) in
            if error != nil {
                print(error.debugDescription)
            } else if response?.mapItems.count == 0{
                print("no results")
            } else {
                for mapItem in response!.mapItems{
                    self.matchingItems.append(mapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
    }
    
    func dropPinFor(placemark: MKPlacemark){
        selectedItemPlacemark = placemark
        
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        
        mapView.addAnnotation(annotation)
    }
    
    func searchMapKitForResultWithPolyline(forMapItem mapItem: MKMapItem) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapItem
        request.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                print(error.debugDescription)
                return
            }
            
            self.route = response.routes[0]
            self.mapView.add(self.route.polyline)
            
            self.shouldPresentLoadingView(false)
        }
    }
}

extension HomeViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == destinationTextField{
        
            tableView.frame = CGRect(x: 16, y: view.frame.height, width: view.frame.width - 32, height: view.frame.height - 190)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
            
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.tag = 18
            tableView.rowHeight = 60
            
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            })
        }
    }
    
    /*func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == destinationTextField{
            if textField.text!.count >= 3 {
                performSearch()
            }else{
                
            }
        }
        
        return true
    }*/
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray
                })
            }
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        //animateTableView(shouldShow: false)
        centerMapOnUserLocation()
        return true
    }
    
    func animateTableView(shouldShow: Bool){
        if shouldShow {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 16, y: 190, width: self.view.frame.width - 32, height: self.view.frame.height - 190)
            })
        } else{
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 16, y: self.view.frame.height, width: self.view.frame.width - 32, height: self.view.frame.height - 190)
            }, completion: { (finished) in
                for subview in self.view.subviews {
                    if subview.tag == 18 {
                        subview.removeFromSuperview()
                    }
                }
            })
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        shouldPresentLoadingView(true)
        
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: currentUserId!)
        mapView.addAnnotation(passengerAnnotation)
        
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let selectedMapItem = matchingItems[indexPath.row]
        DataService.instance.REF_USER.child(currentUserId!).updateChildValues(["tripCoordinate": [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
        
        dropPinFor(placemark: selectedMapItem.placemark)
        searchMapKitForResultWithPolyline(forMapItem: selectedMapItem)
        
        animateTableView(shouldShow: false)
        print("selected")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}
