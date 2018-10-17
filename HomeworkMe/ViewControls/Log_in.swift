//
//  Log_in.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/8/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase


class Log_in: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var pwField: UITextField!
    var ref: DatabaseReference!
    var alert: CommonFunctions!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dismissKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginPressed(_ sender: Any) {
         ref = Database.database().reference()
        guard emailField.text != "", pwField.text != "" else {return}
        
        Auth.auth().signIn(withEmail: emailField.text!, password: pwField.text!, completion: { (user, error) in
            
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                let ok = UIAlertAction(title: "dismiss", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true)
            }
            
            
            if let user = user {
//                self.addCustomer(child: Auth.auth().currentUser?.uid ?? "", userEmail: emailField.text)
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile")
                
               // self.present(vc, animated: true, completion: nil)
                let appDel : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDel.logUser()
            }
        })
    }
    
    func dismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    func addCustomer(child:String, userEmail:String){
        StripeClient.shared.creatCustomer(email: userEmail, completion: { (res) in
            print(res)
            do {
                guard let json = try JSONSerialization.jsonObject(with: res.data!, options: .mutableContainers) as? JSON else {return}
                print("the Json \( json)")
                let par = ["customerId": json["id"]] as [String: Any]
                self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(par)
                UserDefaults.standard.set(json["id"], forKey: "customerId")
            } catch {
                
            }
        })
    }

}
