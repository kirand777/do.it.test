//
//  SignInViewController.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/15/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import UIKit
import MBProgressHUD
import Alamofire
import AlamofireObjectMapper
import AlamofireSwiftyJSON
import SwiftyJSON

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var pswdTextField: UITextField!
    @IBOutlet weak var regSwitch: UISwitch!
    @IBOutlet weak var loginBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let email = UserDefaults.standard.string(forKey: Constants.userEmail) {
            self.emailTextField.text = email
        }

        self.loginBtn.layer.cornerRadius = 4.0
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        guard self.isValid() else {
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let email = self.emailTextField.text!
        let pswd = self.pswdTextField.text!
        let params = ["email" : email, "password": pswd]
        
        
        let commonHandler: (DataResponse<JSON>) -> Void = {
            response in
            MBProgressHUD.hide(for: self.view, animated: true)
            if response.result.isSuccess {
                if let tokenId = response.result.value?["token"].string {
                    let validUntil = Date(timeIntervalSinceNow: 24 * 3600)
                    let token = Token(id: tokenId, validUntil: validUntil)
                    TokenKeychainStore().storeAccessToken(token)
                }
                UserDefaults.standard.set(email, forKey: Constants.userEmail)
                UserDefaults.standard.synchronize()
                self.performSegue(withIdentifier: "toMain", sender: nil)
            }
            else {
                print(response.error!)
            }
        }
        
        if (regSwitch.isOn) {
            Alamofire.request(ApiService.Router.newUser(params)).validate().responseSwiftyJSON(completionHandler: commonHandler)
        }
        else {
            Alamofire.request(ApiService.Router.authUser(params)).validate().responseSwiftyJSON(completionHandler: commonHandler)
        }
    }
    
    private func isValid() -> Bool {
        
        guard let email = self.emailTextField.text, !email.isEmpty else {
            ErrorManager.showErrorWithMessage("Email text is empty", inViewController: self)
            return false
        }
        
        guard self.isEmailValid(email) else {
            ErrorManager.showErrorWithMessage("Email is not valid", inViewController: self)
            return false
        }
        
        guard let pswd = self.pswdTextField.text, !pswd.isEmpty else {
            ErrorManager.showErrorWithMessage("Password text is empty", inViewController: self)
            return false
        }
            
        guard pswd.count >= 6 else {
            ErrorManager.showErrorWithMessage("Password should have at least 6 characters", inViewController: self)
            return false
        }
        
        return true
    }
    
    private func isEmailValid(_ email: String) -> Bool {
        let emailRegex: NSString = "^([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x22([^\\x0d\\x22\\x5c\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x22)(\\x2e([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x22([^\\x0d\\x22\\x5c\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x22))*\\x40([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x5b([^\\x0d\\x5b-\\x5d\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x5d)(\\x2e([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x5b([^\\x0d\\x5b-\\x5d\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x5d))*$"
        let emailTest: NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
}
