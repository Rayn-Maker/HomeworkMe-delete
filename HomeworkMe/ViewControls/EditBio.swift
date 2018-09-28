//
//  EditBio.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/13/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class EditBio: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //// Edit School pluggings
    @IBOutlet weak var universityBtn: UIButton!
    @IBOutlet weak var degreeSubjectBtn: UIButton!
    @IBOutlet weak var classRoomTableView: UITableView!
    @IBOutlet weak var myClassesTableView: UITableView!
    /// finish edit school pluggins
    
    // edit account pluggins
//    @IBOutlet weak var editAcctView: UIView!
//    @IBOutlet weak var fNameTxt: UITextField!
//    @IBOutlet weak var lNameTxt: UITextField!
//    @IBOutlet weak var emailTxt: UITextField!
//    @IBOutlet weak var phoneNumberTxt: UITextField!
//    @IBOutlet weak var nameOnCard: UITextField!
//    @IBOutlet weak var cardNumber: UITextField!
//    @IBOutlet weak var cardPin: UITextField!
//    @IBOutlet weak var cardExpDate: UITextField!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var choosePicBtn: UIButton!
    // finish edit account pluggins
    
    // edit school var
    var handle: DatabaseHandle?; var handle2: DatabaseHandle?
    var commonFunctions = CommonFunctions()
    var uni_sub_array = [FetchObject](); var subjectArray = [FetchObject](); var classArray = [FetchObject](); var myClassesArr = [FetchObject](); var uniArray = [FetchObject]()
    var subjectID: String?; var uniID: String?
    var uniBtnOn = true; var subBtnOn = false; var classBtnOn = false;
    var subjectsDict: [String: AnyObject]?; var classeDict: [String: AnyObject]?
    var tableViewTitleCounter: Int = 0 // helps track where the search is
    var headerTitle: String = "Select School"
    var functions = CommonFunctions()
    var userStorage: StorageReference!
    var ref: DatabaseReference!
    let picker = UIImagePickerController()
    // finish edit school variable
    
    // edit account variables
    
    // finish edit account variables
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let storage = Storage.storage().reference(forURL: "gs://hmwrkme.appspot.com")
        userStorage = storage.child("Students")
        ref = Database.database().reference()
        picker.delegate = self
        editImage()
        myClassesTableView.estimatedRowHeight = 35
        myClassesTableView.rowHeight = UITableViewAutomaticDimension
        classRoomTableView.estimatedRowHeight = 35
        classRoomTableView.rowHeight = UITableViewAutomaticDimension
        degreeSubjectBtn.isEnabled = false
        degreeSubjectBtn.setTitleColor(UIColor.gray, for: .normal)
        universityBtn.isEnabled = false ; universityBtn.setTitleColor(UIColor.gray, for: .normal)
        fetchMyClassKey()
        fetchUni()
        
        if let pictureDat = UserDefaults.standard.object(forKey: "pictureData") as? Data {
            profilePic.image = UIImage(data: pictureDat)
        }
    }
    
    @IBAction func selectUniPrsd(_ sender: Any) {
        tableViewTitleCounter = 0
        headerTitle = "Select University"
        degreeSubjectBtn.isEnabled = false
        degreeSubjectBtn.setTitleColor(UIColor.gray, for: .normal); degreeSubjectBtn.setTitle("Subject", for: .normal)
        universityBtn.isEnabled = false ; universityBtn.setTitleColor(UIColor.gray, for: .normal); universityBtn.setTitle("University", for: .normal)
        uni_sub_array = uniArray
        classRoomTableView.reloadData()
        uniBtnOn = true ; subBtnOn = false
    }
    
    @IBAction func selectSubPrsd(_ sender: Any) {
        headerTitle = "Select Subject"
        tableViewTitleCounter = 1
        degreeSubjectBtn.setTitleColor(UIColor.gray, for: .normal); degreeSubjectBtn.setTitle("Subject", for: .normal); degreeSubjectBtn.isEnabled = false
        uni_sub_array = subjectArray
        classRoomTableView.reloadData()
        uniBtnOn = false ; subBtnOn = true
    }
    
//    @IBAction func displayViewChanger(_ sender: UISegmentedControl) {
//        if sender.selectedSegmentIndex == 0{
//            editAcctView.isHidden = true
//        }
//        if sender.selectedSegmentIndex == 1{
//            editAcctView.isHidden = false
//        }
//    }
    
    @IBAction func backPrsd(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    ///////////////////////////////////////// edit Account \\\\\\\\\\\\\\\\\\\\\\
    @IBAction func savePrsd(_ sender: Any) {
        let user = Auth.auth().currentUser
        let imageRef = self.userStorage.child("\(user?.uid ?? "").jpg")
        let data = UIImageJPEGRepresentation(self.profilePic.image!, 0.5)

        let uploadTask = imageRef.putData(data!, metadata: nil, completion: { (metadata, err) in
            if err != nil {
                print(err!.localizedDescription)
                self.present(self.functions.alertWithOk(errorMessagTitle: "Save Failed", errorMessage: err!.localizedDescription), animated: true, completion: nil)
                return
            } else {
                UserDefaults.standard.set(data, forKey: "pictureData")
            }
            
                imageRef.downloadURL(completion: { (url, er) in
                    if er != nil {
                        print(er!.localizedDescription)
                    }
                    if let url = url {
                        self.ref.child("Students").child(user!.uid).child("pictureUrl").setValue(url.absoluteString)
                        self.present(self.functions.alertWithOk(errorMessagTitle: "Congrats!!", errorMessage: "Edits successfully made"), animated: true, completion: nil)
                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile")
                        self.present(vc, animated: true, completion: nil)
                        
                    }
                })
        })
         uploadTask.resume()
    }
    
    @IBAction func selectImagePressed(_ sender: Any) { 
        choosePicBtn.setTitle("Change", for: .normal)
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profilePic.image = image
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func editImage(){
        profilePic.layer.borderWidth = 1
        profilePic.layer.masksToBounds = false
        profilePic.layer.borderColor = UIColor.black.cgColor
        profilePic.layer.cornerRadius = profilePic.frame.height/2
        profilePic.clipsToBounds = true
    }
    
    var storageRef: Storage {
        return Storage.storage()
    }
    
    func fetchUni() {
        let ref = Database.database().reference()
        ref.child("Universities").queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                self.uni_sub_array.removeAll()
                let universities = response.value as! [String:AnyObject]
                for (_,b) in universities {
                    var university = FetchObject()
                    if let uid = b["uid"] {
                        university.uid = uid as? String
                    }
                    if let title = b["name"] {
                        university.title = title as? String
                    }
                    if let subDict = b["Subjects"]  {
                        university.dict = subDict as? [String : AnyObject]
                        
                    }
                    self.uni_sub_array.append(university)
                }
                self.classRoomTableView.reloadData()
            }
        })
    }
    
    func fetchClass(subKey:String) {
        let ref = Database.database().reference()
        ref.child("Subjects").child(subKey).queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                self.uni_sub_array.removeAll()
                let universities = response.value as! [String:AnyObject]
                if let dict =  universities["Classes"] as? [String : AnyObject] {
                    self.fetchSub(uniKey: self.subjectID!,dictCheck: dict)
                    self.classeDict = universities
                }
                
            }
        })
    }
    
    func fetchMyClassKey() {
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        handle2 = ref.child("Students").child(uid!).queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                self.myClassesArr.removeAll()
                let myclass = response.value as! [String:AnyObject]
                if let dict = myclass["Classes"] as? [String : AnyObject] {
                    self.fetchMyClass(dictCheck: dict)
                }
                if let fname = myclass["fName"] as? String {
                    UserDefaults.standard.set(fname, forKey: "fName")
                }
                if let lname = myclass["lName"] as? String {
                    UserDefaults.standard.set(lname, forKey: "lName")
                }
                
            }
        })
    }
    
    func fetchMyClass(dictCheck: [String:AnyObject]){
        let ref = Database.database().reference()
        handle = ref.child("Classes").queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                /// dont do anything \\\
            } else {
                self.myClassesArr.removeAll()
                let classes = response.value as! [String:AnyObject]
                for (a,_) in dictCheck {
                    for (c,b) in classes {
                        if a == c {
                            var classe = FetchObject()
                            if let uid = b["uid"] {
                                classe.uid = uid as? String
                            }
                            if let title = b["name"] {
                                classe.title = title as? String
                            }
                            self.myClassesArr.append(classe)
                        }
                    }
                }
                self.myClassesTableView.reloadData()
            }
        })
    }
    
    func fetchSub(uniKey:String, dictCheck: [String:AnyObject]) {
        let ref = Database.database().reference()
        if uniBtnOn {
            ref.child("Subjects").queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
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
                    self.classRoomTableView.reloadData()
                }
            })
        } else if subBtnOn {
            ref.child("Classes").queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
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
                                if let title = b["subjectID"] {
                                    subject.subjectID = title as? String
                                } //uniId
                                if let title = b["uniId"] {
                                    subject.uniID = title as? String
                                } //uniName
                                if let title = b["uniName"] {
                                    subject.uniName = title as? String
                                }
                                if let title = b["subjectName"] {
                                    subject.subName = title as? String
                                }
                                self.uni_sub_array.append(subject)
                            }
                        }
                    }
                    self.uniBtnOn = false; self.subBtnOn = false; self.classBtnOn = true
                    self.classRoomTableView.reloadData()
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profileToClasses" {
            let vc = segue.destination as? MyClassRoomVC
            let indexPath = myClassesTableView.indexPathForSelectedRow
            vc?.fetchObject = myClassesArr[(indexPath?.row)!]
        }
    }
}

extension EditBio: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == classRoomTableView {
            if uniBtnOn {
                tableViewTitleCounter = 1
                uniID = uni_sub_array[indexPath.row].uid
                uniArray = uni_sub_array
                self.fetchSub(uniKey: uniID!, dictCheck: uni_sub_array[indexPath.row].dict!)
                uniBtnOn = false ; subBtnOn = true ; classBtnOn = false
                headerTitle = uni_sub_array[indexPath.row].title!
                universityBtn.isEnabled = true ; universityBtn.setTitleColor(UIColor.black, for: .normal)
            } else if subBtnOn {
                tableViewTitleCounter = 2
                subjectID = uni_sub_array[indexPath.row].uid
                headerTitle = uni_sub_array[indexPath.row].title!
                subjectArray = uni_sub_array
                degreeSubjectBtn.isEnabled = true
                degreeSubjectBtn.setTitleColor(UIColor.black, for: .normal)
                self.fetchClass(subKey: subjectID!)
            } else if classBtnOn {
                // here add classes to the user and user to the class
                classArray = uni_sub_array
                let ref = Database.database().reference()
                let key = uni_sub_array[indexPath.row].uid
                let subId = uni_sub_array[indexPath.row].subjectID
                let uniId = uni_sub_array[indexPath.row].uniID
                let uid = Auth.auth().currentUser?.uid
                let parameters: [String:String] = [key! : key!]
                let parameters2: [String:String] = [uid! : uid!]
                let parameters3: [String:String] = [subId!:subId!]
                let parameters4: [String:String] = [uniID!:uniID!]
                if myClassesArr.contains(where: { $0.uid == key }) {
                    // print a statement saying class already added
                    
                } else {
                    ref.child("Students").child(uid!).child("University").updateChildValues(parameters4)
                    ref.child("Students").child(uid!).child("Subjects").updateChildValues(parameters3)
                    ref.child("Students").child(uid!).child("Classes").updateChildValues(parameters)
                    ref.child("Classes").child(key!).child("Students").updateChildValues(parameters2)
                }
            }
        } else if tableView == myClassesTableView{
            // delete class or go to class with a popup
            let ref = Database.database().reference()
            let key = myClassesArr[indexPath.row].uid
            let uid = Auth.auth().currentUser?.uid
            let alert = UIAlertController(title: "\(myClassesArr[indexPath.row].title ?? "")", message: "Perform action", preferredStyle: .alert)
            let delete = UIAlertAction(title: "Delete", style: .destructive) { (_) in
                // delete class from student and student from class
                ref.child("Students").child(uid!).child("Classes").child(key!).removeValue()
                ref.child("Classes").child(key!).child("Students").child(uid!).removeValue()
                
            }
            let view = UIAlertAction(title: "View", style: .default) { (_) in
                // view the class room Segue to the classroom.
                self.performSegue(withIdentifier: "profileToClasses", sender: self)
            }
            alert.addAction(delete);  alert.addAction(view); present(alert, animated: true, completion: nil)
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == classRoomTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bioClassRoomCells", for: indexPath)
            cell.textLabel!.text = uni_sub_array[indexPath.row].title
            cell.textLabel?.numberOfLines = 0
            if myClassesArr.contains(where: { $0.uid == uni_sub_array[indexPath.row].uid }) {
                // print a statement saying class already added
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        } else if tableView == myClassesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bioMyClasses", for: indexPath)
            cell.textLabel!.text = myClassesArr[indexPath.row].title
            cell.textLabel?.numberOfLines = 0
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bioMyClasses", for: indexPath)
            cell.textLabel!.text = myClassesArr[indexPath.row].title
            return cell
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == classRoomTableView {
            return uni_sub_array.count
        } else if tableView == myClassesTableView {
            return myClassesArr.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == classRoomTableView {
            if tableViewTitleCounter == 0 {
                return headerTitle
            }
            if tableViewTitleCounter == 1 {
                return headerTitle
            }
            if tableViewTitleCounter == 2 {
                return headerTitle
            }
            
        }
        if tableView == myClassesTableView {
            return "My Classes"
        } else {
            return ""
        }
    }
}
