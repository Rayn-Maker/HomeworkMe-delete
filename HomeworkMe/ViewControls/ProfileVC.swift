//
//  ProfileVC.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/2/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import Stripe
import GoogleSignIn
import UserNotifications
import paper_onboarding
import Alamofire


class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GIDSignInUIDelegate, UNUserNotificationCenterDelegate  {
    //// Edit School pluggings
    @IBOutlet weak var selectSchoolBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var myClassesTableView: UITableView!
    @IBOutlet weak var classInUniSearch: UITableView!
    @IBOutlet weak var selectedClassesTableView: UITableView!
    @IBOutlet weak var listOfColleges: UIPickerView!
    /// finish edit school pluggins
    
    // Onboarding stuff
    @IBOutlet weak var onBoardingView: OnboardingView!
    @IBOutlet weak var getStarted: UIButton!
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var preveiwPic: UIImageView!
    @IBOutlet weak var editViewBtn: UIButton!
    @IBOutlet weak var changePicBtn: UIButton!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var tutorEdit: UIView!
    @IBOutlet weak var classEdit: UIView!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var goLiveSwitch: UISwitch!
    @IBOutlet weak var searchClassTxt: UITextField!
    @IBOutlet weak var goLiveLable: UILabel!
    @IBOutlet weak var goliveView: UIStackView!
    
    // finish edit account pluggins
    
    // edit school var
    var handle2: DatabaseHandle?
    var uni_sub_array = [FetchObject](); var myClassesArr = [FetchObject]()
    let picker = UIImagePickerController()
    var userStorage: StorageReference!
    var functions = CommonFunctions()
    var ref: DatabaseReference!
    var imageChangeCheck = false
    var phoneNumberString = String()
    static var DEVICEID = String()
    static var hasCard = false
    static var senderCustomerId = ""
    static var full_name = ""
    static var paymentSurce = [String]()
    var student = Student()
    var devicNotes = [String]()
    var allClassesArr = [FetchObject](); var allClassesArrFilterd = [FetchObject]()
    var window: UIWindow?
    var allColleges = [FetchObject]()
    var allClasses = [String:AnyObject]()
    var uniClasses = [FetchObject]()
    var selectedClasses = [FetchObject]()
    var inSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        GIDSignIn.sharedInstance().uiDelegate = self // google sign in
        picker.delegate = self
        let storage = Storage.storage().reference(forURL: "gs://hmwrkme.appspot.com")
        userStorage = storage.child("Students")
       

        
        cancelBtn.setTitleColor(.gray, for: .normal)
        // on boarding stuff
        onBoardingView.dataSource = self
        onBoardingView.delegate = self
        
        if student.tutorStatus == "live" {
            goLiveSwitch.isOn = true
        } else if student.tutorStatus == "off" {
             goLiveSwitch.isOn = false
        }
        if student.tutorApproved ?? false  {
            goliveView.isHidden = true
        } else {
            goliveView.isHidden = false
        }
        
        if goLiveSwitch.isOn {
            goLiveLable.text = "I'm Live!!!"
        } else {
            goLiveLable.text = "Go Live!!"
        }
        
        // check to display on baording screen
        
        if let ob = UserDefaults.standard.object(forKey: "hasSeenOS1") as? Bool {
            if ob {
                onBoardingView.isHidden = true
            }
        }
        
        //notifications
       registerForPushNotifications()
        
        // setup date picker
        phoneNumber.text = phoneNumberString
        tutorEdit.isHidden = true
        
        fetchAllClasses()
        dismissKeyboard()
        ref = Database.database().reference()
        myClassesTableView.estimatedRowHeight = 35
        myClassesTableView.rowHeight = UITableViewAutomaticDimension
        activitySpinner.startAnimating()
        fetchStudentInfo()
        fetchUni()
        if let pictureDat = UserDefaults.standard.object(forKey: "pictureData") as? Data {
            profilePic.image = UIImage(data: pictureDat)
            preveiwPic.image = UIImage(data: pictureDat)
        }
        editImage(image: preveiwPic)
        editImage(image: profilePic)
        dismissKeyboard()
        
    }
 
    
    @IBAction func editViewPrsd(_ sender: Any) {
        classEdit.isHidden = false 
    }
    
    @IBAction func changePicPrsd(_ sender: Any) {
        changePicBtn.setTitle("Change", for: .normal)
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
        imageChangeCheck = true
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        logout()
        performSegue(withIdentifier: "logout", sender: self)
    }
    
    @IBAction func cancelSavePrsd(_ sender: Any) {
        editViewBtn.setTitle("Edit", for: .normal)
        changePicBtn.isHidden = true
        cancelBtn.isEnabled = false
        cancelBtn.setTitleColor(.gray, for: .normal)
        view.endEditing(true)
    }
    
    @IBAction func goLivePrsed(_ sender: Any) {
    if goLiveSwitch.isOn {
        goLiveLable.text = "I'm Live"
        let par = ["status": "live"] as [String: Any]
        
        
        ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(par) { (err, resp) in
            if err != nil {
                
            }
        }
    } else {
        goLiveLable.text = "Go Live!!!"
        let par = ["status": "off"] as [String: Any]
        
        
        ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(par) { (err, resp) in
            if err != nil {
                
            }
        }
    }
        
    }
    
    
    // Done button for editView pressed
    
    @IBAction func backToEditView(_ sender: Any) {
        tutorEdit.isHidden = true
    }
    
    @IBAction func tutorRegistrationPrsd(_ sender: Any) {
        let alert = UIAlertController(title: "Tutor Registration", message: "Get extra cash tutoring your peers on the go!", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = "What classes are you taking?"
        }
        alert.addTextField { (textfield2) in
            textfield2.placeholder = "What subjects are you best at?"
        }
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let Register = UIAlertAction(title: "Register", style: .default) { (_) in
            guard let text = alert.textFields?.first?.text else { return }
            guard let text2 = alert.textFields?[1].text else { return }
            if text != "" && text != nil && text2 != nil && text2 != "" {
                let userInfo: [String: Any] = ["isTutor":true]
                
                self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(userInfo) { (err, resp) in
                    if err != nil {
                        
                    }
                }
            } else {
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        alert.addAction(Register); alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func saveTutor(_ sender: Any) {
        if changePicBtn.isHidden {
            editViewBtn.setTitle("Save", for: .normal)
            changePicBtn.isHidden = false
            
            cancelBtn.isEnabled = true
            cancelBtn.setTitleColor(.black, for: .normal)
        }
        if phoneNumber.text != nil && phoneNumber.text != "" && !student.meetUpLocation.isEmpty {
            
            let userInfo: [String: Any] = ["status":"live",
                                           "phoneNumber": self.phoneNumber.text]
            
            ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(userInfo) { (err, resp) in
                if err != nil {
                    
                }
            }
             tutorEdit.isHidden = true
        } else {
            // show warning
            let alert = UIAlertController(title: "Missing Info", message: "make sure you select at least 2 public places (library or coffee shop) to meet up and your phone number is filled", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
     
    @IBAction func srchInCls(_ sender: UITextField) {
        inSearching = true
        if sender.text! == "" {
            inSearching = false
        }
        if sender.text! == " " {
            inSearching = false
        }
        filterContentForSearchText(sender.text!)
    }
    @IBAction func addPaymentMethod(_ sender: Any) {
        addCard()
    }
    
    @IBAction func showEditCls(_ sender: Any) {
        let alert = UIAlertController(title: "Admin Support", message: "You must be an admin support, or confirmed ambassador to have access to this page, contact HomeworkMeInfo@gmail.com to get access.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Hi Nicole, Sevanna, Joshua, Harrison & Radiance"
        }
        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            guard let text = alert.textFields?.first?.text else { return }
            
            if text == "addMySchool100" {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "ClassesEditVC") as! UsersVC
                self.present(newViewController, animated: true, completion: nil)
            }
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func showCreateClass(_ sender: Any) {
        let alert = UIAlertController(title: "Admin Support", message: "You must be an admin support, or confirmed ambassador to have access to this page, contact HomeworkMeInfo@gmail.com to get access.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Hi Nicole, Sevanna, Joshua, Harrison & Radiance"
        }
        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            guard let text = alert.textFields?.first?.text else { return }
            
            if text == "addMySchool100" {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "UniSubCrteVC") as! UniSubCrteVC
                self.present(newViewController, animated: true, completion: nil)
            }
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func selectSchoolPrsd(_ sender: Any) {
        // show list of schools in picker
        listOfColleges.isHidden = false
    }
    
    @IBAction func getStarted(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.onBoardingView.isHidden = true
            self.getStarted.isHidden = true
            UserDefaults.standard.set(true, forKey: "hasSeenOS1")
        }
    }
    
    @IBAction func nextPrsd(_ sender: Any) {
        tutorEdit.isHidden = false
        classEdit.isHidden = true
    }
    
    @IBAction func donePrsd(_ sender: Any) {
        // save info hide screens
        
        tutorEdit.isHidden = true
        classEdit.isHidden = true
    }
    
    @IBAction func back(_ sender: Any) {
        // save info hide screens
        tutorEdit.isHidden = true
        classEdit.isHidden = false
    }
    
    func logout() {
        if Auth.auth().currentUser != nil {
            do {
                try? Auth.auth().signOut()
                 GIDSignIn.sharedInstance().signOut()
            } catch  {
            }
        }
    }
    
    //notifications configuration
    
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            guard let token = InstanceID.instanceID().token() else {return}
            var ref: DatabaseReference!
            ref = Database.database().reference()
            let userInfo: [String: Any] = ["fromDevice":token]
            
            ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(userInfo)
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    @available(iOS 10.0, *)
    func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void)
    {
        //Handle the notification
        completionHandler(
            [UNNotificationPresentationOptions.alert,
             UNNotificationPresentationOptions.sound,
             UNNotificationPresentationOptions.badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        connectToFCM() 
    }
    
    fileprivate func setUpGroupMessages(fromDevice:String, groupName:String, body:String)
    {
        //        guard let message = "text.text" else {return}
        let toDeviceID = fromDevice
        var headers:HTTPHeaders = HTTPHeaders()
        
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)","project_id":fromDevice]
        let notification = ["operation": "create","notification_key_name":groupName,"registration_ids":["4", "8", "15", "16", "23", "42"]] as [String:Any]
        
        Alamofire.request("https://fcm.googleapis.com/fcm/notification" as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
        }
        
    }
    
    
    func connectToFCM()
    {
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
   
    
    func dismissKeyboard() { 
        let tap = UITapGestureRecognizer(target: self.view, action: Selector("endEditing:"))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profilePic.image = image
            self.preveiwPic.image = image
            self.student.pictureUrl = "url"
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    var storageRef: Storage {
        return Storage.storage()
    }
    
    func addCard() {
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self
        
        // Present add card view controller
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        present(navigationController, animated: true)
    }
    
    func editImage(image:UIImageView){
        image.layer.borderWidth = 1
        image.layer.masksToBounds = false
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.cornerRadius = image.frame.height/2
        image.clipsToBounds = true
    }
    
    func deletValue(indexPathRow:Int) {
        let ref = Database.database().reference()
        let key = myClassesArr[indexPathRow].uid
        let uid = Auth.auth().currentUser?.uid
            // delete class from student and student from class
        ref.child("Students").child(uid!).child("Classes").child(key!).removeValue()
        ref.child("Classes").child(key!).child("Students").child(uid!).removeValue()
        ref.child("Classes").child(uid!).child("Notification_Devices").child(ProfileVC.DEVICEID).removeValue { (err, ref) in
            if err != nil {
                print("errero is not nil")
            }
        }
        Messaging.messaging().subscribe(toTopic: "\(myClassesArr[indexPathRow].uniName ?? "")\(myClassesArr[indexPathRow].subName ?? "")\(myClassesArr[indexPathRow].title ?? "")") { error in
            if error  == nil {
                print("Subscribed to news topic")
            } else {
                
            }
        }
    }
    
    func saveImage() {
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
                    self.student.pictureUrl = url.absoluteString
                    self.ref.child("Students").child(user!.uid).child("pictureUrl").setValue(url.absoluteString)

                    
                }
            })
        })
        uploadTask.resume()
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
                self.uni_sub_array.sort(by:{ $0.title! < $1.title! } )
                self.allColleges = self.uni_sub_array
                self.listOfColleges.reloadAllComponents()
            }
        })
    }
    
    func fetchClassesInUni(allClasses:[FetchObject], uid:String) {
        let ref = Database.database().reference()
        self.allClassesArr.removeAll()
        ref.child("Universities").child(uid).child("Classes").queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                // you get a dictionary. get
                
                let classes = response.value as! [String:AnyObject]
                for (a,b) in classes {
                    if let index = allClasses.index(where: {$0.uid == a}) {
                        var university = FetchObject()
                        university.title = allClasses[index].title
                        university.subjectID = allClasses[index].subjectID
                        university.subName = allClasses[index].subName
                        university.uid = allClasses[index].uid
                        university.uniID = allClasses[index].uniID
                        university.uniName = allClasses[index].uniName
                        self.allClassesArr.append(university)
                    }
                }
                self.allClassesArr.sort(by:{ $0.title! < $1.title! } )
                self.classInUniSearch.reloadData()
            }
        })
    }
    
    func fetchAllClasses() {
        let ref = Database.database().reference()
        ref.child("Classes").queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                // you get a dictionary. get
                self.uni_sub_array.removeAll()
                let classes = response.value as! [String:AnyObject]
                for (_,b) in classes {
                    var university = FetchObject()
                    university.title = b["name"] as? String
                    university.subjectID = b["subjectID"] as? String
                    university.subName = b["subjectName"] as? String
                    university.uid = b["uid"] as? String
                    university.uniID = b["uniId"] as? String
                    university.uniName = b["uniName"] as? String
                    self.uniClasses.append(university)
                }
                // after you get all the classes compare and contrast the one you have to show based on the university.
                self.fetchClassesInUni(allClasses: self.uniClasses, uid: "-LJH2y7HOmoOfNHnRxVR")
            }
        })
    }
 
    
    
    func fetchStudentInfo() {
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        handle2 = ref.child("Students").child(uid!).queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                self.myClassesArr.removeAll()
                let myclass = response.value as! [String:AnyObject]
                var name = " "
                if let dict = myclass["Classes"] as? [String : AnyObject] {
                    for (x,y) in dict {
                        var fetch = FetchObject()
                        fetch.title = y["className"] as? String
                        fetch.uid = y["uid"] as? String
                        self.myClassesArr.append(fetch)
                    }
                }
                if let fname = myclass["full_name"] as? String {
                    UserDefaults.standard.set(fname, forKey: "full_name")
                    self.student.full_name = fname
                    ProfileVC.full_name = fname 
                }
                if let fname = myclass["fName"] as? String {
                    UserDefaults.standard.set(fname, forKey: "fName")
                    name = fname
                    
                    self.student.fName = fname
                }
                if let phone = myclass["phoneNumber"] as? String {
                    UserDefaults.standard.set(phone, forKey: "phoneNumber")
                    self.phoneNumber.text = phone
                    self.student.phoneNumebr = phone
                } //isTutorApproved paymentSource
                if let email = myclass["email"] as? String {
                    UserDefaults.standard.set(email, forKey: "email")
                    self.student.email = email
                } //status meetUpLocations
                if let status = myclass["status"] as? String {
                    self.student.tutorStatus = status
                }
                if let status = myclass["paymentSource"] as? [ String] {
                    self.student.paymentSource = status
                    ProfileVC.paymentSurce = status 
                    
                } //fromDevice
                if let fromDevice = myclass["fromDevice"] as? String {
                    self.student.deviceId = fromDevice
                    ProfileVC.DEVICEID = fromDevice
                }
                if let hasCard = myclass["hasCard"] {
                    print(hasCard)
                    self.student.hasCard = hasCard as! Bool
                    ProfileVC.hasCard = hasCard as! Bool
                }
                if let meetUpLocations = myclass["meetUpLocations"] as? [String:[String]] {
                    self.student.meetUpLocation = meetUpLocations
                }
                if let lname = myclass["lName"] as? String {
                    UserDefaults.standard.set(lname, forKey: "lName")
                    name += " " + lname + "\n " + (Auth.auth().currentUser?.email)!
                    self.student.lName = lname
                }
                if let id = myclass["uid"] as? String {
                    UserDefaults.standard.set(id, forKey: "userId")
                    self.student.uid = id
                } //TutorProfile
                if let customer = myclass["customerId"] as? String {
                    UserDefaults.standard.set(customer, forKey: "customerId")
                    self.student.customerId = customer
                    ProfileVC.senderCustomerId = customer
                }
                self.userName.text = name
                if let pictureURl = myclass["pictureUrl"] as? String {
                    self.student.pictureUrl = pictureURl
                    UserDefaults.standard.set(pictureURl, forKey: "pictureUrl")
                    self.storageRef.reference(forURL: pictureURl).getData(maxSize: 1 * 1024 * 1024, completion: { (imgData, error) in
                    if error == nil {
                        if let data = imgData{
                            UserDefaults.standard.set(data, forKey: "pictureData")
                            self.profilePic.image = UIImage(data: data)
                            self.preveiwPic.image = UIImage(data: data)
                        }
                    }
                    else {
                        print(error?.localizedDescription)
                    }
                })
              }
            }
        })
    }
    
    
    fileprivate func addToGrpMessg( keyName:String, notificationKey:String)
    {
        let newString = keyName.replacingOccurrences(of: " ", with: "_")
        ref = Database.database().reference()
        var headers:HTTPHeaders = HTTPHeaders()
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)","project_id":"81643141779"]
        let notification = ["operation": "add","notification_key":notificationKey,"notification_key_name": newString,"registration_ids":[ProfileVC.DEVICEID]] as [String:Any]
        
        Alamofire.request("https://fcm.googleapis.com/fcm/notification" as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            do {
                guard let json = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as? JSON else {return}
                let par = ["notification_key\(json["notification_key"] ?? "")": json["notification_key"] ?? ""] as [String: Any]
                self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(par)
            } catch {
                
            }
        }
    }
    
    fileprivate func rmFrmGrpMessg( keyName:String, notificationKey:String)
    {
        let newString = keyName.replacingOccurrences(of: " ", with: "_")
        ref = Database.database().reference()
        var headers:HTTPHeaders = HTTPHeaders()
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)","project_id":"81643141779"]
        let notification = ["operation": "remove","notification_key_name":newString,"notification_key":notificationKey,"registration_ids":[ProfileVC.DEVICEID]] as [String:Any]
        
        Alamofire.request("https://fcm.googleapis.com/fcm/notification" as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            do {
                guard let json = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as? JSON else {return}
                //                let par = ["notification_key": json["notification_key"]] as [String: Any]
                // self.ref.child("Classes").child(self.selClassId).updateChildValues(par)
            } catch {
                
            }
        }
    }
    
    // search implementation
 
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        allClassesArrFilterd = allClassesArr.filter({( classe : FetchObject) -> Bool in
            return classe.title!.lowercased().contains(searchText.lowercased())
        })
        
        classInUniSearch.reloadData()
    }
 
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profileToClasses" {
            let vc = segue.destination as? MyClassRoomVC
            let indexPath = myClassesTableView.indexPathForSelectedRow
            vc?.fetchObject = myClassesArr[(indexPath?.row)!]
            vc?.student = student
        }
    }
}

extension ProfileVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         if tableView == myClassesTableView{
                self.performSegue(withIdentifier: "profileToClasses", sender: self)
        }
        
        if tableView == classInUniSearch {
            if inSearching {
                selectedClasses.append(allClassesArrFilterd[indexPath.row])
            } else {
                selectedClasses.append(allClassesArr[indexPath.row])
            }
            selectedClassesTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == myClassesTableView {
            if (editingStyle == UITableViewCellEditingStyle.delete) {
                deletValue(indexPathRow: indexPath.row)
                
                myClassesArr.remove(at: indexPath.row)
                myClassesTableView.deleteRows(at: [indexPath], with: .fade)

            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         if tableView == myClassesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myClasses", for: indexPath)
            if !myClassesArr.isEmpty {
                cell.textLabel?.text = myClassesArr[indexPath.row].title
                cell.textLabel?.numberOfLines = 0 
            }
            return cell
        } else if tableView == classInUniSearch {
            let cell = tableView.dequeueReusableCell(withIdentifier: "classUniSearch", for: indexPath)
            if inSearching {
                cell.textLabel?.text = allClassesArrFilterd[indexPath.row].title
            } else {
                cell.textLabel?.text = allClassesArr[indexPath.row].title
            }
            return cell
         } else if tableView == selectedClassesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "selectedClassCell", for: indexPath)
            cell.textLabel?.text = selectedClasses[indexPath.row].title
            return cell
         }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myClasses", for: indexPath)
            cell.textLabel!.text = myClassesArr[indexPath.row].title
            return cell
        }
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == myClassesTableView {
            return myClassesArr.count
        }  else if tableView == classInUniSearch {
            if inSearching {
                return allClassesArrFilterd.count
            } else {
                return allClassesArr.count
            }
        } else if tableView == selectedClassesTableView {
            return selectedClasses.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == myClassesTableView {
            return "My Classes"
        } else if tableView == classInUniSearch {
            return "classes"
        } else if tableView == selectedClassesTableView {
            return "my classes"
        } else {
            return ""
        }
    }
    
    
}

extension ProfileVC: STPAddCardViewControllerDelegate {
    
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        dismiss(animated: true)
    }
    
    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {
        
        
        StripeClient.shared.addCard(with: token, amount: 000) { result in
            switch result.result {
            // 1
            case .success:
                completion(nil)
                
                let userInfo: [String: Any] = ["hasCard": true]
                self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(userInfo) { (err, resp) in
                    if err != nil {
                        ProfileVC.hasCard = true 
                    }
                }
                self.dismiss(animated: true)
            // 2
            case .failure(let error):
                completion(error)
            }
        }
        
    }
}


extension ProfileVC: PaperOnboardingDataSource, PaperOnboardingDelegate {
    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        let bkGroundColor1 = UIColor(red: 217/255, green: 17/258, blue: 89/255, alpha: 1)
        let bkGroundColor2 = UIColor(red: 106/255, green: 166/258, blue: 211/255, alpha: 1)
        let bkGroundColor3 = UIColor(red: 168/255, green: 200/258, blue: 78/255, alpha: 1)
        
        let title = UIFont(name: "AvenirNext-Bold", size: 24)
        let description = UIFont(name: "AvenirNext-Regular", size: 14) // iOS fonts .com
        let obod = OnboardingItemInfo(informationImage: UIImage(named: "selectUni")!, title: "University", description: "First, select your university.", pageIcon:  UIImage(named: "homeworkMeLogo")!, color: bkGroundColor1, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        let obod2 = OnboardingItemInfo(informationImage: UIImage(named: "selectSub")!, title: "Subject", description: "Next, select your subject or degree.", pageIcon:  UIImage(named: "homeworkMeLogo")!, color: bkGroundColor2, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        let obod3 = OnboardingItemInfo(informationImage: UIImage(named: "selectClass")!, title: "Classes", description: "Then, add the classes you are taking in that subject or degree.", pageIcon:  UIImage(named: "homeworkMeLogo")!, color: bkGroundColor3, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        let obod4 = OnboardingItemInfo(informationImage: UIImage(named: "selectSubBtn")!, title: "Subject", description: "To select another subject or school, press the Subject button.", pageIcon:  UIImage(named: "homeworkMeLogo")!, color: bkGroundColor1, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        let obod5 = OnboardingItemInfo(informationImage: UIImage(named: "addPlaces")!, title: "Places To Meet", description: "Add public places you wouldn't mind meeting up with a classmate for your session.", pageIcon:  UIImage(named: "homeworkMeLogo")!, color: bkGroundColor2, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        let obod6 = OnboardingItemInfo(informationImage: UIImage(named: "add_save")!, title: "Save", description: "Lastly, add a picture and tap save.", pageIcon:  UIImage(named: "homeworkMeLogo")!, color: bkGroundColor3, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        return [obod, obod2, obod3, obod4, obod5, obod6][index]
    }
    
    func onboardingConfigurationItem(_: OnboardingContentViewItem, index _: Int) {
        //
    }
    
    func onboardingWillTransitonToIndex(_ index: Int) {
        if index == 4 {
            UIView.animate(withDuration: 0.2) {
                self.getStarted.alpha = 0
            }
        }
    }
    
    func onboardingDidTransitonToIndex(_ index: Int) {
        if index == 5 {
            UIView.animate(withDuration: 0.4) {
                self.getStarted.alpha = 1
            }
        }
    }
    
    func onboardingItemsCount() -> Int {
        return 6
    }
}


extension ProfileVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return allColleges.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return allColleges[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectSchoolBtn.setTitle(allColleges[row].title, for: .normal)
        listOfColleges.isHidden = true
        fetchClassesInUni(allClasses: self.uniClasses, uid: allColleges[row].uid!)
    }
}

extension ProfileVC: UISearchResultsUpdating {
    
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
}
