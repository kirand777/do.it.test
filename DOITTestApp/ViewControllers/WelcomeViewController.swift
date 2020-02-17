//
//  WelcomeViewController.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/15/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.proceedFlow()
    }
    
    func proceedFlow() {
        if TokenKeychainStore().retrieveAccessToken() != nil {
            self.performSegue(withIdentifier: "toMain", sender: nil)
        }
        else {
            self.performSegue(withIdentifier: "toLogin", sender: nil)
        }
    }
}
