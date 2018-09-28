//
//  UniSubCrteVC.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/2/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class UniSubCrteVC: UIViewController {
    
    @IBOutlet weak var uniTxt: UITextField!
    @IBOutlet weak var degre_subTxt: UITextField!
    @IBOutlet weak var uniTableView: UITableView!
    @IBOutlet weak var subTableview: UITableView!
    var commonFunctions = CommonFunctions()
    var universities = [FetchObject](); var uni_sub_array = [FetchObject]()
    var universityID: String!; var subId: String!; var subName: String!; var universityName:String!
    var handle: DatabaseHandle?; var handle2: DatabaseHandle?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchUni()
    }
    
    @IBAction func addUniBtn(_ sender: Any) {
        let ref = Database.database().reference()
        let key = ref.child("Universities").childByAutoId().key
        
        present(commonFunctions.addToDirecotory(key: key, title: "Add Uni", message: "add new University", subKey: self.subId, uniName: self.universityName, foldername: "Universities", universityKey: ""), animated: true, completion: nil)
        fetchUni()
    }
    
    @IBAction func addSubBtn(_ sender: Any) {
        let ref = Database.database().reference()
        let key = ref.child("Subjects").childByAutoId().key
       
        present(commonFunctions.addToDirecotory(key: key, title: "Add Subject/Degree", message: "add new Subjecct/Degree", subKey: "uid", uniName: universityName, foldername: "Subjects", universityKey: self.universityID), animated: true, completion: nil)
    }
    
    @IBAction func addClassPrsd(_ sender: Any) {
        let ref = Database.database().reference()
        let key = ref.child("Universities").childByAutoId().key 
        let alert = UIAlertController(title: "create class", message: "Perform action", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter name here"
        }
        let add = UIAlertAction(title: "ADD", style: .destructive) { (_) in
            // delete class from student and student from class
            guard let text = alert.textFields?.first?.text else { return }
            let parameters = ["uid": key,
                              "name": text,
                              "subjectID":self.subId,
                              "subjectName":self.subName,
                              "uniId":self.universityID,
                              "uniName":self.universityName]
            let classs = [key:parameters]
            let subFldr = [key:key]
            
            ref.child("Classes").updateChildValues(classs)
            ref.child("Subjects").child(self.subId).child("Classes").updateChildValues(subFldr)
            ref.child("Universities").child(self.universityID).child("Classes").updateChildValues(subFldr)
            
        }
        
        alert.addAction(add); present(alert, animated: true, completion: nil)
    }
    
    func fetchUni() {
        let ref = Database.database().reference()
       handle2 = ref.child("Universities").queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                
                /// dont do anything
            } else {
                self.universities.removeAll()
                let universitiesDict = response.value as! [String:AnyObject]
                for (_,b) in universitiesDict {
                    var university = FetchObject()
                    if let uid = b["uid"] {
                        university.uid = uid as? String
                    }
                    if let title = b["name"] {
                        university.title = title as? String
                    }
                    if let dict = b["Subjects"] {
                        university.dict = dict as? [String : AnyObject]
                    }
                    self.universities.append(university)
                }
                self.uniTableView.reloadData()
            }
        })
        ref.removeAllObservers()
    }
    
    func fetchSub(uniKey:String, dictCheck: [String:AnyObject]) {
        let ref = Database.database().reference()
           handle = ref.child("Subjects").queryOrderedByKey().observe( .value, with: { response in
                if response.value is NSNull {
                    /// dont do anything \\\
                } else {
                    self.uni_sub_array.removeAll()
                    let subjects = response.value as! [String:AnyObject]
                    for (a,_) in dictCheck {
                        for (c,b) in subjects {
                            if a == c {
                                var subject = FetchObject()
                                if let uid = b["uid"] {
                                    subject.uid = uid as? String
                                }
                                if let title = b["name"] {
                                    subject.title = title as? String
                                }
                                self.uni_sub_array.append(subject)
                            }
                        }
                    }
                    self.subTableview.reloadData()
                }
            })
    }
    
}

extension UniSubCrteVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == uniTableView {
            self.universityID = universities[indexPath.row].uid
            self.universityName = universities[indexPath.row].title
            if universities[indexPath.row].dict != nil {
                fetchSub(uniKey: self.universityID, dictCheck: universities[indexPath.row].dict!)
            }
        }
        if tableView == subTableview {
            self.subName = uni_sub_array[indexPath.row].title
            self.subId = uni_sub_array[indexPath.row].uid
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == uniTableView{
        let cell = tableView.dequeueReusableCell(withIdentifier: "uniTable", for: indexPath)
        cell.textLabel!.text = universities[indexPath.row].title
        return cell
        }
        if tableView == subTableview {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subCell", for: indexPath)
            cell.textLabel!.text = uni_sub_array[indexPath.row].title
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subCell", for: indexPath)
            cell.textLabel!.text = uni_sub_array[indexPath.row].title
            return cell
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == uniTableView {
            return universities.count
        }
        if tableView == subTableview {
            return uni_sub_array.count
        } else {
            return 0
        }
    }
}
