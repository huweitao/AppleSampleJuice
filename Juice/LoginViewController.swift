/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Login view controller.
*/

import UIKit
import AuthenticationServices

let TestAuthInfoKey = "com.apple.authInfo.key"

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginProviderStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProviderLoginView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExistingAccountSetupFlows()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNotificationObserver() {
        let center = NotificationCenter.default
        let name = NSNotification.Name.ASAuthorizationAppleIDProviderCredentialRevoked
        let observer = center.addObserver(forName: name, object: nil, queue: nil) { (Notification) in
            
        }
        print("Observer ==> \(observer)")
    }
    
    func setupProviderLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton()
        authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        self.loginProviderStackView.addArrangedSubview(authorizationButton)
    }
    
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]
        
        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            let token = String(data: appleIDCredential.identityToken ?? Data(), encoding: String.Encoding.utf8)
            let userStatus = appleIDCredential.realUserStatus
            let authCode = String(data: appleIDCredential.authorizationCode ?? Data(), encoding: String.Encoding.utf8)
            var userKey = ""
            switch userStatus {
            case .unsupported:
                userKey = "unsupported"
            case .likelyReal:
                userKey = "likelyReal"
            case .unknown:
                userKey = "unknown"
            default:
                break
            }
            /*
             status ==> unknown
             JWT token ==> eyJraWQiOiJBSURPUEsxIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoiY29tLmV4YW1wbGUuYXBwbGUtc2FtcGxlY29kZS5qdWljZUhDOFJFMlJWODYiLCJleHAiOjE1NjA3NTUyMTYsImlhdCI6MTU2MDc1NDYxNiwic3ViIjoiMDAwODA2LmU3ZGIzOGMwYjgzOTQyZGJiYmZkNjI2ODFlM2FkOTIyLjAzMTgifQ.aD1j9oIf1ebRMulNBnvDcoQoKrTBbG5zbDiQCekQA4EVX6a0_QgAmmir90loJovs4bJqy4ecXQ9LPb-yYZRbOFXdrqSDV1t47Aq03Di06t5vJkv6zEu1V8WalZW1tw-MxK2izwg1Fe01aJBS_cQCzHRqW5ocuLbqB6ioi2j71h_hPrBcfydtP20iNzU52gVViLsJtr7Qg34BKyY1aD0rR7EBRqYodO9rxGswcD7LOzKrTZAHUeEGmgxgkY7bY915xO6FoDIjmJYomRyZUTyriUB3ngNgX_TNekd8Uo2a3PFlMvbDfjAwJzF1JFVJ9xPJYFZG3jDE6a93X3NJJA3JZg
             authCode ==> c765291a667cf456299c6faff7562cbda.0.myqw.jv3MaCjuOF8vwiUiu409_Q
                 c1af1cd295da545f8b27be7bcdc56b2a7.0.myqw.rWuzL-QwFiHwF0rkUbYXzQ
             JWT原理：http://www.ruanyifeng.com/blog/2018/07/json_web_token-tutorial.html
             JWT解析：http://jwt.calebb.net/
             {
                kid: "AIDOPK1",
                alg: "RS256"
             }.
             {
                 iss: "https://appleid.apple.com",
                 aud: "com.example.apple-samplecode.juiceHC8RE2RV86",
                 exp: 1560755216,
                 iat: 1560754616,
                 sub: "000806.e7db38c0b83942dbbbfd62681e3ad922.0318"
             }.
                [signature]
             */
            print("status ==> \(userKey)")
            print("JWT token ==> \(token ?? "")")
            print("authCode ==> \(authCode ?? "")")
            // Create an account in your system.
            // For the purpose of this demo app, store the userIdentifier in the keychain.
            do {
                try KeychainItem(service: "com.example.apple-samplecode.juice", account: "userIdentifier").saveItem(userIdentifier)
            } catch {
                print("Unable to save userIdentifier to keychain.")
            }
            
            // For the purpose of this demo app, show the Apple ID credential information in the ResultViewController.
            if let viewController = self.presentingViewController as? ResultViewController {
                DispatchQueue.main.async {
                    
                    var authInfo:[String:String] = ["user":userIdentifier,
                                                    "identityToken":token ?? "",
                                                    "realUserStatus":userKey,
                                                    "authorizationCode":authCode ?? ""
                    ]
                    
                    var trueName = ""
                    viewController.userIdentifierLabel.text = userIdentifier
                    if let givenName = fullName?.givenName {
                        trueName += givenName + "_"
                        viewController.givenNameLabel.text = givenName
                    }
                    if let familyName = fullName?.familyName {
                        trueName += familyName
                        viewController.familyNameLabel.text = familyName
                    }
                    if let email = email {
                        viewController.emailLabel.text = email
                        authInfo["email"] = email
                    }
                    authInfo["fullName"] = trueName
                    
                    UserDefaults.standard.set(authInfo, forKey: TestAuthInfoKey)
                    UserDefaults.standard.synchronize()
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
                let alertController = UIAlertController(title: "Keychain Credential Received",
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
