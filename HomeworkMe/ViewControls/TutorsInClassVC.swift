//
//  TutorsInClassVC.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 10/22/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class TutorsInClassVC: UIViewController {

    @IBOutlet weak var tutorsTableView: UITableView!
    
    var handle: DatabaseHandle?
    var fetchObject = FetchObject()
    let ref = Database.database().reference()
    var tutorArr = [Student]()
    var tutorsInClass = [String:AnyObject]()
    
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
                 self.tutorArr.removeAll()
                let resp = response.value as! [String:AnyObject]
                for (x,_) in self.tutorsInClass {
                    for (a,b) in resp {
                        if x == a {
                            var student = Student()
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
                            self.tutorArr.append(student)
                        }
                    }
                }
            }
            self.tutorArr.sort(by:{ $0.full_name! < $1.full_name! })
            self.tutorsTableView.reloadData()
        })
    }
}

extension TutorsInClassVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tutorArr.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "tutorsInClassCell", for: indexPath)
        
        cell.textLabel?.text = tutorArr[indexPath.row].full_name
        
        return cell
    }
}
