//
//  MainViewController.swift
//  FindMyListeners
//
//  Created by Hamzah Chaudhry on 12/4/20.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    var handle: AuthStateDidChangeListenerHandle?
    
    var ref: DatabaseReference!
    
    var locationManager: CLLocationManager!
    
    var lat: Int!
    
    var long: Int!
    
    @IBOutlet weak var primaryTextField: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    // https://developer.apple.com/documentation/uikit/view_controllers/showing_and_hiding_view_controllers
    func changeViewToLogin() {
        performSegue(withIdentifier: Constants.Storyboard.mainToLoginSegue, sender: self)
//        let controller = storyboard!.instantiateViewController(identifier: Constants.Storyboard.loginViewController)
//        show(controller, sender: self)
    }
    
    func updatePrimaryTextField() {
        let user = Auth.auth().currentUser
        if let user = user {
            primaryTextField.text = "Hello \(user.email!)!"
        }
    }
    
    func determineLocation() {
        // set up for requesting location
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
//            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
            mapView.showsUserLocation = true
        }
    }
    
    func writeLocation(_ coordinate: CLLocationCoordinate2D) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 3-digit precision for location
        lat = (coordinate.latitude * 1000).toInt()
        long = (coordinate.longitude * 1000).toInt()
        
        // update database
        ref.child("lat/\(lat!)/\(uid)").setValue(true)
        ref.child("long/\(long!)/\(uid)").setValue(true)
    }
    
    func deleteLocation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // update database
        if lat != nil && long != nil {
            ref.child("lat/\(lat!)/\(uid)").setValue(nil)
            ref.child("long/\(long!)/\(uid)").setValue(nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // check if user is logged in on screen
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user == nil {
                self.changeViewToLogin()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // delete user's location from database
        deleteLocation()
        
        // remove auth listener from screen
        Auth.auth().removeStateDidChangeListener(handle!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updatePrimaryTextField()
        determineLocation()
        
        // get ref to db
        ref = Database.database(url: Constants.Database.locationsDatabase).reference()
    }
    
    @IBAction func signOutButton(_ sender: Any) {
        deleteLocation()
        let firebaseAuth = Auth.auth()
        
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            primaryTextField.text = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
            writeLocation(location.coordinate)
            
            // zoom in on map appropriately
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find location: \(error.localizedDescription)")
    }

}

extension Double {
    
    func toInt() -> Int? {
        if self >= Double(Int.min) && self < Double(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
    
}
