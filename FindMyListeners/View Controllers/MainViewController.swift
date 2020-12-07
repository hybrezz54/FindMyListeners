//
//  MainViewController.swift
//  FindMyListeners
//
//  Created by Hamzah Chaudhry on 12/4/20.
//

import CoreLocation
import UIKit
import Firebase

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    
    @IBOutlet weak var primaryTextField: UILabel!
    
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
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.significantLocationChangeMonitoringAvailable() {
//            locationManager.startUpdatingLocation()
//            locationManager.requestLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updatePrimaryTextField()
        determineLocation()
    }
    
    @IBAction func signOutButton(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
        
        changeViewToLogin()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("User's location: \(location)")
            primaryTextField.text = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find location: \(error.localizedDescription)")
    }
    
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
