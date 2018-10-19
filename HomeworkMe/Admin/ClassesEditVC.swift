//
//  ClassesEditVC.swift
//  Alamofire
//
//  Created by Radiance Okuzor on 10/17/18.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Alamofire
import UserNotifications

class ClassesEditVC: UIViewController, UNUserNotificationCenterDelegate {

    @IBOutlet weak var classesTable: UITableView!
    
    var classArray = [FetchObject]()
    var handle2: DatabaseHandle?
     var ref: DatabaseReference!
    var selClassId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        fetchClass()
    }
    
    @IBAction func backPrsd(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func fetchClass() {
        let ref = Database.database().reference()
        handle2 = ref.child("Classes").queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                
                /// dont do anything
            } else {
                self.classArray.removeAll()
                let universitiesDict = response.value as! [String:AnyObject]
                for (_,b) in universitiesDict {
                    var university = FetchObject()
                    if let uid = b["uid"] {
                        university.uid = uid as? String
                    }
                    if let title = b["name"] {
                        university.title = title as? String
                    }
                    if let dict = b["subjectName"] {
                        university.subName = dict as? String
                    }
                    if let dict = b["uniName"] {
                        university.uniName = dict as? String
                    }
                    self.classArray.append(university)
                }
                self.classArray.sort(by:{ $0.title! < $1.title! } )
                self.classesTable.reloadData()
            }
        })
        ref.removeAllObservers()
    }
    
    fileprivate func setUpGroupMessages( groupName:String)
    {
        let newString = groupName.replacingOccurrences(of: " ", with: "_")
        ref = Database.database().reference()
        var headers:HTTPHeaders = HTTPHeaders()
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)","project_id":"81643141779"]
        let notification = ["operation": "create","notification_key_name":newString,"registration_ids":[ProfileVC.DEVICEID]] as [String:Any]
        
        Alamofire.request("https://fcm.googleapis.com/fcm/notification" as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            do {
                guard let json = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as? JSON else {return}
                let par = ["notificationKey": json["notification_key"] ?? "","notificationKeyName":newString] as [String: Any]
                self.ref.child("Classes").child(self.selClassId).updateChildValues(par)
            } catch {
                
            }
        }
    }
    
    fileprivate func getKey( groupName:String)
    {
        let newString = groupName.replacingOccurrences(of: " ", with: "_")
        ref = Database.database().reference()
        var headers:HTTPHeaders = HTTPHeaders()
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)","project_id":"81643141779"]
        let notification = ["operation": "create","notification_key_name":newString,"registration_ids":[ProfileVC.DEVICEID]] as [String:Any]
        
        
        Alamofire.request("https://fcm.googleapis.com/fcm/notification?notification_key_name=\(newString)" as URLConvertible, method: .get as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            do {
                guard let json = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as? JSON else {return}
                let par = ["notificationKey": json["notification_key"] ?? "","notificationKeyName":newString] as [String: Any]
                self.ref.child("Classes").child(self.selClassId).updateChildValues(par)
            } catch {
                
            }
        }
    }
 
}


extension ClassesEditVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Create class group", message: "", preferredStyle: .alert)
        let add = UIAlertAction(title: "Add", style: .default) { (_) in
            self.setUpGroupMessages( groupName: self.classArray[indexPath.row].title ?? "" + self.classArray[indexPath.row].subName  ?? "" + self.classArray[indexPath.row].uniName!)
//            self.getKey(groupName: self.classArray[indexPath.row].title ?? "")
        }
        let canc = UIAlertAction(title: "calce", style: .destructive) { (_) in
//            self.setUpGroupMessages( groupName: self.classArray[indexPath.row].title ?? "" + self.classArray[indexPath.row].subName  ?? "" + self.classArray[indexPath.row].uniName!)
                        self.getKey(groupName: self.classArray[indexPath.row].title ?? "")
        }
        alert.addAction(add); alert.addAction(canc)
        self.present(alert, animated: true, completion: nil)
        selClassId = classArray[indexPath.row].uid
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "classEdit", for: indexPath)
        cell.textLabel!.text = classArray[indexPath.row].title
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return classArray.count
    }
}
