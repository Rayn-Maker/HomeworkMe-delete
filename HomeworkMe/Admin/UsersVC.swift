//
//  UsersVC.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 10/24/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class UsersVC: UIViewController {
 
    @IBOutlet weak var tutorsTableView: UITableView!
    
    var handle: DatabaseHandle?
    var fetchObject = FetchObject()
    let ref = Database.database().reference()
    var allStudentsArr = [Student]()
    @IBOutlet weak var userCount: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchStudents()
    }
    
    @IBAction func backPrsd(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    func fetchStudents() {
        
        handle = ref.child("Students").queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                self.allStudentsArr.removeAll()
                let resp = response.value as! [String:AnyObject]
                for (_,b) in resp {
                    let student = Student()
                    if let fname = b["full_name"] as? String {
                        student.full_name = fname
                    }
                    if let email = b["email"] as? String {
                        student.email = email
                    }
                    if let pictureUrl = b["pictureUrl"] as? String {
                        student.pictureUrl = pictureUrl
                    }
                    if let isTutor = b["isTutor"] as? String {
                        student.full_name = isTutor
                    }
                    self.allStudentsArr.append(student)
                    self.userCount.text = "Users: \(self.allStudentsArr.count)"
                }
            }
//            self.allStudentsArr.sort(by:{ $0.fName! < $1.fName! })
            self.tutorsTableView.reloadData()
        })
    }
}

extension UsersVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allStudentsArr.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "allUsers", for: indexPath)
        
        cell.textLabel?.text = allStudentsArr[indexPath.row].full_name
        
        return cell
    }
}

