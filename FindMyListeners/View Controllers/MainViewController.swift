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
    
    var dbHandle: DatabaseHandle?
    
    var ref: DatabaseReference!
    
    var locationManager: CLLocationManager!
    
    var lat: Int?
    
    var long: Int?
    
    var nearUsers: [String]?
    
    @IBOutlet weak var primaryTextField: UILabel!
    
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
//            mapView.showsUserLocation = true
        }
    }
    
    func readAndWriteLocation(_ coordinate: CLLocationCoordinate2D) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 3-digit precision for location
        lat = (coordinate.latitude * 1000).toInt()
        long = (coordinate.longitude * 1000).toInt()
        
        // create references
        let latRef = ref.child("lat/\(lat!)")
        let longRef = ref.child("long/\(long!)")
        
        // read users with same latitude and longitude
        dbHandle = latRef.observe(.value, with: { [weak self] (latSnapshot) in
            guard let strongSelf = self else { return }
            
            longRef.observeSingleEvent(of: .value, with: { (longSnapshot) in
                let latUsers = Set((latSnapshot.value as? [String : AnyObject] ?? [:]).keys)
                let longUsers = Set((longSnapshot.value as? [String : AnyObject] ?? [:]).keys)
                
                // update view
                strongSelf.nearUsers = [String](latUsers.intersection(longUsers).subtracting([uid]))
                print(strongSelf.nearUsers!)
            })
        }) { (error) in
            print(error.localizedDescription)
        }
        
        // update database
        latRef.child("\(uid)").setValue(true)
        longRef.child("\(uid)").setValue(true)
    }
    
    func deleteLocation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // update database
        if lat != nil && long != nil {
            ref.child("lat/\(lat!)/\(uid)").setValue(nil)
            ref.child("long/\(long!)/\(uid)").setValue(nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // delete user's location from database
        deleteLocation()
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
            readAndWriteLocation(location.coordinate)
            
            // zoom in on map appropriately
//            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//            mapView.setRegion(region, animated: true)
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
