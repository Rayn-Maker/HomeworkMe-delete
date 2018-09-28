//
//  Sign_In.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/1/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase
import FirebaseAuth
import FacebookLogin
import FBSDKLoginKit

class Sign_In: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    @IBOutlet weak var faceBookSignIn: UIButton!
    
    var ref: DatabaseReference!
    var ref2: DatabaseReference!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref2 = Database.database().reference()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
    }
 
    func signIn(signIn: GIDSignIn!,
                dismissViewController viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        ref = Database.database().reference()
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // ...
        if let error = error {
            print("\(error.localizedDescription)")
        } else {
            // Perform any operations on signed in user here.
            let userId = user.userID
            user.userID// For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            // ...
        }
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                
                return
            } else {
                self.ref.child("Students").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.hasChild(Auth.auth().currentUser?.uid ?? ""){
                        
                    } else {
                        let userInfo: [String: Any] = ["uid": Auth.auth().currentUser?.uid ?? "",
                                                       "fName": user.profile.givenName ?? " ",
                                                       "lName": user.profile.familyName ?? " ",
                                                       "full_name": user.profile.name ?? " ",
                                                       "email": user.profile.email ?? " "]
                        
                        self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").setValue(userInfo)
                        self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").setValue(userInfo, withCompletionBlock: { (err, resp) in
                            if err != nil {
                                
                            } else {
                                
                            }
                        })
                        self.addCustomer(child: Auth.auth().currentUser?.uid ?? "", userEmail: user.profile.email)
                    }
                })
//                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile")
                self.performSegue(withIdentifier: "signIntoProf", sender: self)
                // self.present(vc, animated: true, completion: nil)
                let appDel : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDel.logUser()
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        //
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "signIntoProf" {
            let vc = segue.destination as? ProfileVC
            vc?.classView = true
        }
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
