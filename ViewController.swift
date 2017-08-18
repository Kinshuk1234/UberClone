/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController {
    
    var signupMode = true
    
    func displayAlert(title: String, message: String) {
        
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated: true, completion: nil)
        
    }
    
    
    @IBOutlet weak var usernameText: UITextField!
    
    @IBOutlet weak var passwordText: UITextField!
    
    @IBOutlet weak var switchBtw: UISwitch!
    
    @IBOutlet weak var driverText: UILabel!
    
    @IBOutlet weak var riderText: UILabel!
    
    
    @IBOutlet weak var loginOrSignupButtonText: UIButton!
    
    @IBAction func loginOrSignupButton(_ sender: Any) {
        
        if usernameText.text == "" || passwordText.text == "" {
            
            displayAlert(title: "Error in form", message: "Username and password are required")
            
        } else {
        
        if signupMode {
        
            let user = PFUser()
            user.username = usernameText.text
            user.password = passwordText.text
            user["isDriver"] = switchBtw.isOn
            
            user.signUpInBackground(block: { (success, error) in
                
                if error != nil {
                
                    if let error = error {
                        
                        var displayedErrorMessage = "Please try again later"
                        
                        let error = error as NSError
                        
                        if let parseError = error.userInfo["error"] as? String {
                            
                            displayedErrorMessage = parseError
                            
                            
                        }
                        
                        self.displayAlert(title: "Sign Up Failed", message: displayedErrorMessage)
                        
                    }
                    
                } else {
                
                    print("user successfully signed up")
                    
                    if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                    
                        if isDriver {
                        
                            self.performSegue(withIdentifier: "driverViewController", sender: self)
                            
                        } else {
                        
                            self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                            
                        }
                        
                    }
                    
                }
                
            })
            
        } else {
        
            PFUser.logInWithUsername(inBackground: usernameText.text!, password: passwordText.text!, block: { (user, error) in
                
                if error != nil {
                
                    if let error = error {
                        
                        var displayedErrorMessage = "Please try again later"
                        
                        let error = error as NSError
                        
                        if let parseError = error.userInfo["error"] as? String {
                            
                            displayedErrorMessage = parseError
                            
                            
                        }
                        
                        self.displayAlert(title: "Sign Up Failed", message: displayedErrorMessage)
                        
                    }
                    
                } else {
                
                    print("user successfully logged in")
                    
                    if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                        
                        if isDriver {
                            
                            self.performSegue(withIdentifier: "driverViewController", sender: self)
                            
                        } else {
                            
                            self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                            
                        }
                        
                    }
                    
                }
                
            })
            
        }
            
        }
        
    }
    
    @IBOutlet weak var changeModeText: UIButton!
    
    @IBAction func changeModeButton(_ sender: Any) {
        
        if signupMode == false {
            
            signupMode = true
            changeModeText.setTitle("Switch to Log In", for: [])
            loginOrSignupButtonText.setTitle("Sign Up", for: [])
            switchBtw.isHidden = false
            driverText.isHidden = false
            riderText.isHidden = false
            
        } else {
            
            signupMode = false
            changeModeText.setTitle("Switch to Sign Up", for: [])
            loginOrSignupButtonText.setTitle("Log In", for: [])
            switchBtw.isHidden = true
            driverText.isHidden = true
            riderText.isHidden = true
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let isDriver = PFUser.current()?["isDriver"] as? Bool {
            
            if isDriver {
                
                self.performSegue(withIdentifier: "driverViewController", sender: self)
                
            } else {
                
                self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                
            }
            
        }
        
    }
    
       override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
