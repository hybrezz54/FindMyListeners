//
//  MainViewController.swift
//  FindMyListeners
//
//  Created by Hamzah Chaudhry on 12/4/20.
//

import UIKit
import Firebase

class MainViewController: UIViewController {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        updatePrimaryTextField()
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
