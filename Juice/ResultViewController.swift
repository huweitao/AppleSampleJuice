/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main application view controller.
*/

import UIKit
import AuthenticationServices

let FetchApplePublicKeyURL:String = "https://appleid.apple.com/auth/keys"
let FetchAppleValidateTokenURL:String = "https://appleid.apple.com/auth/token"

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
        
        // logout API:https://developer.apple.com/documentation/authenticationservices/asauthorization/openidoperation/3153066-operationlogout
        
    }
    
    @IBAction func checkAuth() {
        getPublicKeyFromServer()
    }
    
    // MARK: - Tools
    
    func postValidateToken() {
        guard let authInfo:Dictionary<String,String> = UserDefaults.standard.object(forKey: TestAuthInfoKey) as? Dictionary<String,String>, let jwtString:String = authInfo["identityToken"] else {
            print("Fail to get JWT string")
            return
        }
        guard let jwtJSON = decodeJWTString(jwtString: jwtString) else {
            return
        }
        print("JWT JSON ==> \(jwtJSON)")
        guard let client_id = jwtJSON["aud"] as? String else {
            return
        }
        guard let code = authInfo["authorizationCode"] else {
            return
        }
        guard let client_secret = getClientSecret(jwtString: jwtString) else {
            return
        }
        let signInWithAppleID = "HC8RE2RV86.com.example.apple-samplecode.juiceHC8RE2RV86"
        let signInWithAppleKeyID = "37D2DR9P9R"
        let bodyData:[String:String] = [
            "client_id":client_id,
            "code":code,
            "client_secret":client_secret,
            "grant_type":"authorization_code",
            "redirect_uri":"https%3a%2f%2fappleid.apple.com"
        ]
        guard let url = URL(string: FetchAppleValidateTokenURL) else {
            return
        }
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        // create post body
        let postString = bodyData.compactMap({ (key, value) -> String in
            return "\(key)=\(value)"
        }).joined(separator: "&")
        request.httpBody = postString.data(using: .utf8)
        print("Http body: \(postString)")
        // create task
        let task = session.dataTask(with: request) {(data, response, error) in
            guard let jsonObj = self.dataToJSONDict(data: data) else {
                return
            }
            print("Apple Validate response ==> \(jsonObj)")
        }
        task.resume()
        print("Apple Generate and validate tokens task:\(task)")
    }
    
    func decodeJWTString(jwtString:String?) -> [String: Any]? {
        guard let jwtString = jwtString else {
            return nil
        }
        // seperate
        let segments = jwtString.components(separatedBy: ".")
        // get payload
        var base64String = segments[1]
        // decode by base64
        let requiredLength = (4 * ceil((Float)(base64String.count)/4.0))
        let nbrPaddings = Int(requiredLength) - base64String.count
        if nbrPaddings > 0 {
            let pading = "".padding(toLength: nbrPaddings,withPad: "=",startingAt: 0)
            base64String = base64String + pading
        }
        base64String = base64String.replacingOccurrences(of: "-",with: "+")
        base64String = base64String.replacingOccurrences(of: "_",with: "/")
        guard let decodeData = Data(base64Encoded: base64String,options: Data.Base64DecodingOptions.ignoreUnknownCharacters) else {
            return nil
        }
        let decodeString = String.init(data: decodeData,encoding: String.Encoding.utf8)
        guard let data = decodeString?.data(using: String.Encoding.utf8) else {
            return nil
        }
        guard let jsonDict = dataToJSONDict(data: data) else {
            return nil
        }
        return jsonDict
    }
    
    
    func getClientSecret(jwtString:String?) -> String? {
        guard let jwtString = jwtString else { return nil }
        let segments = jwtString.components(separatedBy: ".")
        if segments.count < 2 {
            return nil
        }
        // header + payload
        let base64String = segments[0] + "." + segments[1]
        print("ClientSecret ==> \(base64String)")
        return base64String
    }
    
    // Fetch Apple's public key for verifying token signature
    // https://developer.apple.com/documentation/signinwithapplerestapi
    func getPublicKeyFromServer() {
        // create config
        let config = URLSessionConfiguration.default
        // init URL and request
        guard let url = URL(string: FetchApplePublicKeyURL) else { return }
        let request = URLRequest(url: url)
        
        // create session
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data,response,error) in
            // data keys:https://developer.apple.com/documentation/signinwithapplerestapi/jwkset/keys
            guard let jsonObj = self.dataToJSONDict(data: data) else {
                return
            }
            print("Apple's public key response ==> \(jsonObj)")
        }
        
        task.resume()
        print("Apple's public key for verifying token task:\(task)")
    }
    
    func dataToJSONDict(data:Data?) -> Dictionary<String,Any>? {
        guard let data = data else { return nil }
        guard let info = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else {
            print("Fails to get json data!")
            return nil
        }
        return info as? Dictionary<String,Any> ?? ["":""]
    }
}
