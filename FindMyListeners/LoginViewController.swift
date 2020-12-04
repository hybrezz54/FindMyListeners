//
//  ViewController.swift
//  FindMyListeners
//
//  Created by Hamzah Chaudhry on 12/2/20.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onClickLogin(_ sender: Any) {
        let email = usernameTextField.text!
        let password = passwordTextField.text!
        
        if email.isEmpty || password.isEmpty {
            let alert = UIAlertController(title: "Invalid Credentials", message: "Please enter a username and a password and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in guard let strongSelf = self else { return }
            
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
            
//            strongSelf.performSegue(withIdentifier: "loginToMain", sender: self)
            let mainViewController = MainViewController()
            mainViewController.modalPresentationStyle = .fullScreen
            strongSelf.present(mainViewController, animated: true)
        }
    }
    
}

