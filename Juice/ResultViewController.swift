/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main application view controller.
*/

import UIKit
import AuthenticationServices

class ResultViewController: UIViewController {
    
    @IBOutlet weak var userIdentifierLabel: UILabel!
    @IBOutlet weak var givenNameLabel: UILabel!
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var signOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userIdentifierLabel.text = KeychainItem.currentUserIdentifier
    }
    
    @IBAction func signOutButtonPressed() {
        // For the purpose of this demo app, delete the user identifier that was previously stored in the keychain.
        KeychainItem.deleteUserIdentifierFromKeychain()
        
        // Clear the user interface.
        userIdentifierLabel.text = ""
        givenNameLabel.text = ""
        familyNameLabel.text = ""
        emailLabel.text = ""
        
        // Display the login controller again.
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "loginViewController") as? LoginViewController
                else { return }
            viewController.modalPresentationStyle = .formSheet
            viewController.isModalInPresentation = true
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func checkAuth() {
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { (credentialState, error) in
            if let err = error {
                DispatchQueue.main.async {
                    let message = "\(err)"
                    let alertController = UIAlertController(title: "Error",
                                                            message: message,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            
            var msg = ""
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid.
                msg = "The Apple ID credential is valid."
            case .revoked:
                // The Apple ID credential is revoked.
                msg = "The Apple ID credential is revoked."
            case .notFound:
                // No credential was found, so show the sign-in UI.
                msg = "No credential was found, so show the sign-in UI."
            default:
                break
            }
            
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "AuthStatus",
                                                        message: msg,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
        return
    }
}
