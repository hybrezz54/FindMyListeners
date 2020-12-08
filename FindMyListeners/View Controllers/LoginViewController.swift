//
//  ViewController.swift
//  FindMyListeners
//
//  Created by Hamzah Chaudhry on 12/2/20.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var handle: AuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    // https://developer.apple.com/documentation/uikit/view_controllers/showing_and_hiding_view_controllers
    func changeViewToMain() {
        performSegue(withIdentifier: Constants.Storyboard.loginToMainSegue, sender: self)
//        let controller = storyboard!.instantiateViewController(identifier: Constants.Storyboard.mainViewController)
//        show(controller, sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // check if user is logged in on login screen
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                self.changeViewToMain()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // remove auth listener from login screen
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onClickLogin(_ sender: Any) {
        let email = usernameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if email.isEmpty || password.isEmpty {
            let alert = UIAlertController(title: "Invalid Credentials", message: "Please enter a username and a password and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let strongSelf = self else { return }
            
            if let error = error as NSError? {
                var message: String?
                
                switch AuthErrorCode(rawValue: error.code) {
                case .operationNotAllowed:
                    // Error: Indicates that email and password accounts are not enabled. Enable them in the Auth section of the Firebase console.
                    message = "This type of login is not enabled."
                case .userDisabled:
                // Error: The user account has been disabled by an administrator.
                    message = "Your account has been disabled by an administrator and needs to be enabled to continue."
                case .wrongPassword:
                // Error: The password is invalid or the user does not have a password.
                    message = "The password is invalid. Please try again."
                case .invalidEmail:
                // Error: Indicates the email address is malformed.
                    message = "The email address is invalid. Please try again."
                default:
                    message = "Please enter a valid username and password and try again."
                    print(error.localizedDescription)
                }
                
                let alert = UIAlertController(title: "Invalid Credentials", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                strongSelf.present(alert, animated: true)
                return
            }
        }
        
    }
    
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}

