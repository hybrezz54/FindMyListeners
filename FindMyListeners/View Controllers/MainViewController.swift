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

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    var dbHandle: DatabaseHandle?
    
    var ref: DatabaseReference!
    
    var locationManager: CLLocationManager!
    
    var lat: Int?
    
    var long: Int?
    
    var nearUsers: [String]?
    
    let countries: [String] = ["New Zealand", "Australia", "United Arab Emirates"]
    
    @IBOutlet weak var primaryTextField: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
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
                let nearUIDs = [String](latUsers.intersection(longUsers).subtracting([uid]))
                strongSelf.updateUsers(nearUIDs)
//                print(nearUIDs)
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
        guard let lat = lat, let long = long else { return }
        
        // create references
        let latRef = ref.child("lat/\(lat)")
        let longRef = ref.child("long/\(long)")
        
        // update database
        latRef.child("\(uid)").setValue(nil)
        longRef.child("\(uid)").setValue(nil)
        
        // clean up
        self.lat = nil
        self.long = nil
        nearUsers = []
        guard let dbHandle = dbHandle else { return }
        latRef.removeObserver(withHandle: dbHandle)
    }
    
    func updateUsers(_ uids: [String]) {
        guard let _ = Auth.auth().currentUser?.uid else { return }
        nearUsers = []
        
        if !uids.isEmpty {
            let db = Firestore.firestore()
            db.collection("users").whereField("uid", in: uids).getDocuments() { [weak self] (snapshot, err) in
                guard let strongSelf = self else { return }
                
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in snapshot!.documents {
                        let data = document.data()
                        let name = data["name"] as? String ?? "Unknown"
                        strongSelf.nearUsers!.append(name)
                    }
                    
                    strongSelf.tableView!.reloadData()
                }
            }
        } else {
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //        return countries.count
        return nearUsers?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Storyboard.mainTableViewUserCell, for: indexPath)
        cell.textLabel!.text = nearUsers?[indexPath.row] ?? ""
        return cell
    }
    
    @objc func appMovedToForeground() {
        // determine location again
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        }
    }
    
    @objc func appMovedToBackground() {
        // delete user's location from db
        deleteLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get ref to db
        ref = Database.database(url: Constants.Database.locationsDatabase).reference()
        
        // add background observers
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // location setup
        updatePrimaryTextField()
        determineLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("MainViewController's ViewWillDisappear!")
        
        // remove background observers
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // delete user's location from database
        deleteLocation()
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
