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
import GooglePlaces
import GoogleSignIn
import UserNotifications
import paper_onboarding
import Alamofire


class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GIDSignInUIDelegate, UNUserNotificationCenterDelegate  {
    //// Edit School pluggings
    @IBOutlet weak var universityBtn: UIButton!
    @IBOutlet weak var degreeSubjectBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var classRoomTableView: UITableView!
    @IBOutlet weak var myClassesTableView: UITableView!
    /// finish edit school pluggins
    
    // Onboarding stuff
    @IBOutlet weak var onBoardingView: OnboardingView!
    @IBOutlet weak var getStarted: UIButton!
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var editViewBtn: UIButton!
    @IBOutlet weak var changePicBtn: UIButton!
    @IBOutlet weak var classSearchView: UITableView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var schoolInstructionsLabel: UILabel!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var tutorEdit: UIView!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var goLiveSwitch: UISwitch!

    @IBOutlet weak var goLiveLable: UILabel!
    @IBOutlet weak var goliveView: UIStackView!
    @IBOutlet weak var meetUpLocationsTable: UITableView!
    
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
    var editIntChecker = 0
    let picker = UIImagePickerController()
    var userStorage: StorageReference!
    var functions = CommonFunctions()
    var ref: DatabaseReference!
    var imageChangeCheck = false
    var Id: String?
    var classView = Bool()
    var schedules = [String]()
    var schedule = String()
    var dayArray = [String](); var hourArr = [String](); var minArr = [String](); var amArr = [String]()
    var chosenLocationsArr = [String]() ; var day = "Sunday"; var hour = "12"; var min = "00"; var am = "Am"
    var place = Place()
    var placeArr = [Place](); var placeesDict = [String:[String]]()
    var student = Student()
    var phoneNumberString = String()
    static var DEVICEID = String()
    static var hasCard = false
    static var senderCustomerId = ""
    static var full_name = ""
    static var paymentSurce = [String]()
    var devicNotes = [String]()
    var window: UIWindow?
    
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
        // Show registration completion
        if classView {
            editView.isHidden = false
        } else {
            editView.isHidden = true
        }
        
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
        let currentDate: Date = Date()
        tutorEdit.isHidden = true
        setUpSchdArr()
        dismissKeyboard()
        ref = Database.database().reference()
        myClassesTableView.estimatedRowHeight = 35
        myClassesTableView.rowHeight = UITableViewAutomaticDimension
        classRoomTableView.estimatedRowHeight = 35
        classRoomTableView.rowHeight = UITableViewAutomaticDimension
        degreeSubjectBtn.isEnabled = false
        degreeSubjectBtn.setTitleColor(UIColor.gray, for: .normal)
        activitySpinner.startAnimating()
        universityBtn.isEnabled = false ; universityBtn.setTitleColor(UIColor.gray, for: .normal)
        fetchMyClassKey()
        fetchUni()
        if let pictureDat = UserDefaults.standard.object(forKey: "pictureData") as? Data {
            profilePic.image = UIImage(data: pictureDat)
        }
        editImage()
        dismissKeyboard()
        
    }
 
     
    @IBAction func selectUniPrsd(_ sender: Any) {
        tableViewTitleCounter = 0
        headerTitle = "Select University"
        degreeSubjectBtn.isEnabled = false
        degreeSubjectBtn.setTitleColor(UIColor.gray, for: .normal); degreeSubjectBtn.setTitle("List Subject", for: .normal)
        universityBtn.isEnabled = false ; universityBtn.setTitleColor(UIColor.gray, for: .normal); universityBtn.setTitle("List University", for: .normal)
        uni_sub_array = uniArray
        classRoomTableView.reloadData()
        uniBtnOn = true; subBtnOn = false
    }
    
    @IBAction func selectSubPrsd(_ sender: Any) {
        headerTitle = "Select Subject"
        tableViewTitleCounter = 1
        degreeSubjectBtn.setTitleColor(UIColor.gray, for: .normal); degreeSubjectBtn.setTitle("Subject", for: .normal); degreeSubjectBtn.isEnabled = false
        uni_sub_array = subjectArray
        classRoomTableView.reloadData()
        uniBtnOn = false; subBtnOn = true
    }
    
    
    @IBAction func editViewPrsd(_ sender: Any) {
        // first time pressed
        editIntChecker += 1
        if editIntChecker % 2 == 0 {
            if self.student.pictureUrl != nil {
//                if editViewBtn.titleLabel?.text != "Edit" {
//
//                }
                editViewBtn.setTitle("Edit", for: .normal)
                changePicBtn.isHidden = true
                classSearchView.isHidden = true
                
                
                cancelBtn.isEnabled = false
                cancelBtn.setTitleColor(.gray, for: .normal)
                if imageChangeCheck {
                    saveImage()
                }
            } else {
                let alert = UIAlertController(title: "Missing Information", message: "Please add a photo", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(ok)
                present(alert, animated: true, completion: nil)
                editIntChecker = 1
            }
            view.endEditing(true)
//            addClassBtn.isHidden = true
            
        } else {
            /// second time pressed
            editView.isHidden = false
            editViewBtn.setTitle("Save", for: .normal)
            changePicBtn.isHidden = false
            classSearchView.isHidden = false
            cancelBtn.isEnabled = true
            cancelBtn.setTitleColor(.black, for: .normal)
//            addClassBtn.isHidden = true
        }
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
        classSearchView.isHidden = true
        cancelBtn.isEnabled = false
        cancelBtn.setTitleColor(.gray, for: .normal)
        view.endEditing(true)
        editIntChecker = 0
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
    
    @IBAction func tutorRegistration(_ sender: Any) {
        editView.isHidden = true
        tutorEdit.isHidden = false
    }
    
    // Done button for editView pressed
    
    @IBAction func backToEditView(_ sender: Any) {
        editView.isHidden = false
        tutorEdit.isHidden = true
    }
    
    
    @IBAction func saveTutor(_ sender: Any) {
        if changePicBtn.isHidden {
            editIntChecker = 1
            editViewBtn.setTitle("Save", for: .normal)
            changePicBtn.isHidden = false
            
            cancelBtn.isEnabled = true
            cancelBtn.setTitleColor(.black, for: .normal)
        }
        
        if phoneNumber.text != nil && phoneNumber.text != "" && !placeesDict.isEmpty {
         
            let userInfo: [String: Any] = ["meetUpLocations":placeesDict,
                                           "status":"live",
                                           "phoneNumber": self.phoneNumber.text ?? ""]
            
            ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(userInfo) { (err, resp) in
                if err != nil {
                    
                }
            }
             tutorEdit.isHidden = true
        } else if phoneNumber.text != nil && phoneNumber.text != "" && !student.meetUpLocation.isEmpty {
            
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
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "ClassesEditVC") as! ClassesEditVC
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
    
    @IBAction func getStarted(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.onBoardingView.isHidden = true
            self.getStarted.isHidden = true
            UserDefaults.standard.set(true, forKey: "hasSeenOS1")
        }
    }
    
    
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
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
    
    func setUpSchdArr(){
        schedule = "Sundays 12:00 am"
        dayArray = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        hourArr = ["12","1","2","3","4","5","6","7","8","9","10","11"]
        minArr = ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59"]
        amArr = ["Am","Pm"]
    }
    
    func dismissKeyboard() { 
        let tap = UITapGestureRecognizer(target: self.view, action: Selector("endEditing:"))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profilePic.image = image
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
    
    func editImage(){
        profilePic.layer.borderWidth = 1
        profilePic.layer.masksToBounds = false
        profilePic.layer.borderColor = UIColor.black.cgColor
        profilePic.layer.cornerRadius = profilePic.frame.height/2
        profilePic.clipsToBounds = true
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
//                self.uni_sub_array.removeAll()
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
                var name = " "
                if let dict = myclass["Classes"] as? [String : AnyObject] {
                    self.fetchMyClass(dictCheck: dict)
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
                    self.Id = id
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
    
    func fetchMyClass(dictCheck: [String:AnyObject]){
        var fetchObject = FetchObject()
        for (_,y) in dictCheck {
            fetchObject.title = y["className"] as? String
            fetchObject.uid = y["uid"] as? String
            if let notificationKey  = y["notificationKey"] as? String {
                fetchObject.notificationKey = notificationKey
            }
            self.myClassesArr.append(fetchObject)
        }
        self.activitySpinner.stopAnimating()
        self.activitySpinner.isHidden = true
        self.myClassesTableView.reloadData()

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
                self.uni_sub_array.sort(by:{ $0.title! < $1.title! } )
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
                                }
                                if let notificationKey = b["notificationKey"] {
                                    subject.notificationKey = notificationKey as? String
                                }
                                if let notificationName = b["notificationKeyName"] {
                                    subject.notificationKeyName = notificationName as? String
                                }//Notification_Devices
                                if let notificationName = b["Notification_Devices"] {
                                    subject.Notification_Devices = notificationName as? [String] ?? []
                                }
                                self.uni_sub_array.append(subject)
                            }
                        }
                    }
                    self.uni_sub_array.sort(by:{ $0.title! < $1.title! } )
                    self.uniBtnOn = false; self.subBtnOn = false; self.classBtnOn = true
                    self.classRoomTableView.reloadData()
                }
            })
        }
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
                //                self.ref.child("Classes").child(self.selClassId).updateChildValues(par)
            } catch {
                
            }
        }
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
        if tableView == classRoomTableView {
        if uniBtnOn {
            tableViewTitleCounter = 1
            uniID = uni_sub_array[indexPath.row].uid
            uniArray = uni_sub_array
            self.fetchSub(uniKey: uniID!, dictCheck: uni_sub_array[indexPath.row].dict!)
            uniBtnOn = false ; subBtnOn = true; classBtnOn = false
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
            let cell = classRoomTableView.cellForRow(at: indexPath)
            classArray = uni_sub_array
            let ref = Database.database().reference()
            let key = uni_sub_array[indexPath.row].uid
            let className = uni_sub_array[indexPath.row].title
            let uid = Auth.auth().currentUser?.uid
            let parameters: [String:String] = ["uid" : key!,
                                               "className":className ?? "",
                                               "notificationKey":uni_sub_array[indexPath.row].notificationKey]
            let parameters2: [String:String] = ["uid" : uid!,
                                                "studentName":self.student.full_name ?? ""]
            if myClassesArr.contains(where: { $0.uid == key }) {
                cell?.accessoryType = .checkmark
            } else {
                cell?.accessoryType = .checkmark
                ref.child("Students").child(uid!).child("Classes").child(key!).updateChildValues(parameters)
                ref.child("Classes").child(key!).child("Students").child(uid!).updateChildValues(parameters2)
                
                devicNotes = uni_sub_array[indexPath.row].Notification_Devices
                if devicNotes.contains(ProfileVC.DEVICEID) {
                    
                } else {
                    devicNotes.append(ProfileVC.DEVICEID)
                }
                ref.child("Classes").child(key!).child("Notification_Devices").setValue(devicNotes)
                self.addToGrpMessg(keyName: uni_sub_array[indexPath.row].title!, notificationKey: uni_sub_array[indexPath.row].notificationKey)

            }
            
         }
        } else if tableView == myClassesTableView{
                self.performSegue(withIdentifier: "profileToClasses", sender: self)
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
       
        
        if tableView == meetUpLocationsTable {
            if (editingStyle == UITableViewCellEditingStyle.delete) {
                placeArr.remove(at: indexPath.row)
                meetUpLocationsTable.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == classRoomTableView {
             let cell = tableView.dequeueReusableCell(withIdentifier: "classRoomCells", for: indexPath)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "myClasses", for: indexPath)
            if !myClassesArr.isEmpty {
                cell.textLabel?.text = myClassesArr[indexPath.row].title
                cell.textLabel?.numberOfLines = 0 
            }
            return cell
        } else if tableView == meetUpLocationsTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "meetUpLocation", for: indexPath)
            cell.textLabel!.text = placeArr[indexPath.row].name
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
        if tableView == classRoomTableView {
            return uni_sub_array.count
        } else if tableView == myClassesTableView {
            return myClassesArr.count
        } else if tableView == meetUpLocationsTable {
            return placeArr.count
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
        if tableView == meetUpLocationsTable {
            return "Meet up locations"
        }
        if tableView == myClassesTableView {
            return "My Classes"
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

extension ProfileVC: GMSAutocompleteViewControllerDelegate {
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        self.place.name = place.name
        self.place.long = "\(place.coordinate.longitude)"
        self.place.lat = "\(place.coordinate.latitude)"
        self.placeArr.append(self.place)
        let arr = ["\(place.coordinate.latitude)", "\(place.coordinate.longitude)", place.name, "\(place.formattedAddress ?? "")"]
        placeesDict["\(place.placeID)"] = arr
        meetUpLocationsTable.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
