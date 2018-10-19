//
//  MyClassRoomVC.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/7/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Alamofire
import MessageUI
import paper_onboarding


class MyClassRoomVC: UIViewController {

    @IBOutlet weak var addPostBtn: UIButton!
    @IBOutlet weak var classRoomLbl: UILabel!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var categoryBtn: UISegmentedControl!
    @IBOutlet weak var postsTableView: UITableView!
    @IBOutlet weak var requestsTableView: UITableView!
    @IBOutlet weak var priceSlider: UISlider!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var postPresetView: UIView!
    @IBOutlet weak var newPostView1: UIStackView!
    @IBOutlet weak var newPostView2: UIStackView!
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var teacherName: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inClassSwitch: UISwitch!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var homeWorkTitleLbl: UILabel!
    @IBOutlet weak var switchView: UIBarButtonItem!
    @IBOutlet weak var onBoardingView: OnboardingView!
    @IBOutlet weak var getStarted: UIButton!
    
    var fetchObject = FetchObject()
    var postTitle:String?; var price:Int = 5; var category:String!
    var handle: DatabaseHandle?; var handle2: DatabaseHandle?
    var myPostArr = [Post](); var hmwrkArr = [Post](); var testArr = [Post](); var notesArr = [Post](); var otherArr = [Post](); var tutorArr = [Post](); var allPostHolder = [Post]()
    
    var myPostArrReq = [Post](); var hmwrkArrReq = [Post](); var testArrReq = [Post](); var notesArrReq = [Post](); var otherArrReq = [Post](); var tutorArrReq = [Post](); var allPostHolderReq = [Post]()
    var tableViewSections = ["All","Homework", "Test","Notes","Tutoring","Other"]
    let seg = "classRoomToPostSegue" //classroom to post view
    var postObject = Post() // variable to hold transfered data to PostView
    var functions = CommonFunctions()
    var schedules = [String]()
    var schedule = String()
    var userStorage: StorageReference!
    let ref = Database.database().reference()
    var student = Student()
    var isGiveHelp = false
    var isRequest = false
    var notificationKey: String!
    var notificationKeyName: String!
    var devicNotes = [String]()
    var isOffering: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let currentDate: Date = Date()
        dismissKeyboard()
        postsTableView.estimatedRowHeight = 45
        postsTableView.rowHeight = UITableViewAutomaticDimension
        requestsTableView.estimatedRowHeight = 45
        requestsTableView.rowHeight = UITableViewAutomaticDimension
        classRoomLbl.text = fetchObject.title
        fetchMyPostsKey()
        priceLbl.text = "$5"
        onBoardingView.dataSource = self
        onBoardingView.delegate = self
        
        if let ob = UserDefaults.standard.object(forKey: "hasSeenOS2") as? Bool {
            if ob {
                onBoardingView.isHidden = true
            }
        }

    }
    
    @IBAction func addPostPrsd(_ sender: Any) {
        let ref = Database.database().reference()
        if student.paymentSource != nil {
            let alert4 = UIAlertController(title: "Give or Get help", message: "", preferredStyle: .alert)
            let giveHelp = UIAlertAction(title: "Give Help", style: .default) { (_) in
                self.isGiveHelp = true
                self.postPresetView.isHidden = false
                self.newPostView1.isHidden = false
                self.newPostView2.isHidden = true
               
            }
            let getHelp = UIAlertAction(title: "Get Help", style: .default) { (_) in
                self.isGiveHelp = false
                self.postPresetView.isHidden = false
                self.newPostView1.isHidden = false
                self.newPostView2.isHidden = true
                
            }
            alert4.addAction(giveHelp); alert4.addAction(getHelp)
            present(alert4, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Missing Information", message: "Kindly register your account for tutoring by selecting a method in which your students can pay you. Then tap to add an assignment again.", preferredStyle: .alert)
            let zelle = UIAlertAction(title: "Zelle", style: .default) { (resp) in
                let alert1 = UIAlertController(title: "Zelle", message: "what's your Zelle email or phone number", preferredStyle: .alert)
                alert1.addTextField { (textField) in
                    textField.placeholder = "zelle email or phone"
                }
                alert1.addTextField { (textField2) in
                    textField2.placeholder = "zelle email or phone confirmation"
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let Add = UIAlertAction(title: "Add", style: .default) { _ in
                    guard let text = alert1.textFields?.first?.text else { return }
                    guard let text2 = alert1.textFields?.first?.text else { return }
                    if text != "" && text2 != "" && text2 == text {
                        let ar = ["Zelle",text]
                        let par = ["paymentSource":ar] as [String:[String]]
                        ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(par)
                        self.student.paymentSource = ar
                    }
                }
                alert1.addAction(Add); alert1.addAction(cancel)
                self.present(alert1, animated: true, completion: nil)
            }
            let cash = UIAlertAction(title: "Cash App", style: .default) { (resp) in
                let alert2 = UIAlertController(title: "Cash App", message: "what's your Cash App $cash_tag (e.x. $Raycorp)", preferredStyle: .alert)
                alert2.addTextField { (textField) in
                    textField.placeholder = "$cash_tag"
                }
                alert2.addTextField { (textField2) in
                    textField2.placeholder = "Cash App confirmation"
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let Add = UIAlertAction(title: "Add", style: .default) { _ in
                    guard let text = alert2.textFields?.first?.text else { return }
                    guard let text2 = alert2.textFields?.first?.text else { return }
                    if text != "" && text2 != "" && text2 == text {
                        let ar = ["Zelle",text]
                        let par = ["paymentSource":ar] as [String:[String]]
                        ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(par)
                        self.student.paymentSource = ar
                    }
                }
                alert2.addAction(Add); alert2.addAction(cancel)
                self.present(alert2, animated: true, completion: nil)
            }
            let venmo = UIAlertAction(title: "Venmo", style: .default) { (resp) in
                let alert3 = UIAlertController(title: "Cash App", message: "what's your Venmo @username (e.x. @Raycorp)", preferredStyle: .alert)
                alert3.addTextField { (textField) in
                    textField.placeholder = "Venmo @username"
                }
                alert3.addTextField { (textField2) in
                    textField2.placeholder = "Venmo @username confirmation"
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let Add = UIAlertAction(title: "Add", style: .default) { _ in
                    guard let text = alert3.textFields?.first?.text else { return }
                    guard let text2 = alert3.textFields?.first?.text else { return }
                    if text != "" && text2 != "" && text2 == text {
                        let ar = ["Zelle",text]
                         let par = ["paymentSource":ar] as [String:[String]]
                        ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(par)
                        self.student.paymentSource = ar
                    }
                }
                alert3.addAction(Add); alert3.addAction(cancel)
                self.present(alert3, animated: true, completion: nil)
            }
            alert.addAction(zelle); alert.addAction(cash); alert.addAction(venmo)
            present(alert, animated: true, completion: nil)
        }
    }
    
    let step: Float = 5
    @IBAction func priceSlider(_ sender: UISlider) {
//        priceLbl.text = "$\(Int(sender.value) )"
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        priceLbl.text = "$\(Int(sender.value))"
        price = Int(sender.value)
        // Do something else with the value
    }
    
    @IBAction func backPrsd(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func creatPostPrsd(_ sender: Any) {
        creatPost()
    }
    
    @IBAction func getStarted(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.onBoardingView.isHidden = true
            self.getStarted.isHidden = true
            UserDefaults.standard.set(true, forKey: "hasSeenOS2")
        }
    }
    
    @IBAction func cancelPrsd(_ sender: Any) {
        postPresetView.isHidden = true
        newPostView1.isHidden = true
        newPostView2.isHidden = true
    }
    
    @IBAction func switchView(_ sender: Any) {
        if requestsTableView.isHidden {
            requestsTableView.isHidden = false
            switchView.title = "View Offers"
            isRequest = true
        } else {
             requestsTableView.isHidden = true
            switchView.title = " View Requests"
            isRequest = true
        }
    }
    
    @IBAction func filterOptions(_ sender: UISegmentedControl) {
        if isRequest {
            if sender.selectedSegmentIndex == 0 {
                if !hmwrkArrReq.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 1)
                    self.requestsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            if sender.selectedSegmentIndex == 1 {
                if !testArrReq.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 2)
                    self.requestsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            if sender.selectedSegmentIndex == 2 {
                if !notesArrReq.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 3)
                    self.requestsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            if sender.selectedSegmentIndex == 3 {
                if !tutorArrReq.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 4)
                    self.requestsTableView.scrollToRow(at: indexPath, at: .top, animated: true)

                }
            }
            if sender.selectedSegmentIndex == 4 {
                if !otherArrReq.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 5)
                    self.requestsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
        } else {
            if sender.selectedSegmentIndex == 0 {
                if !hmwrkArr.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 1)
                    self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            if sender.selectedSegmentIndex == 1 {
                if !testArr.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 2)
                    self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            if sender.selectedSegmentIndex == 2 {
                if !notesArr.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 3)
                    self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            if sender.selectedSegmentIndex == 3 {
                if !tutorArr.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 4)
                    self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            if sender.selectedSegmentIndex == 4 {
                if !otherArr.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 5)
                    self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
        }
        
    }
    
    @IBAction func categoryPrsd(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            category = "Homework"
            titleText.placeholder = "#"
            homeWorkTitleLbl.text = "Homework number or title"
            
            titleLabel.text = priceLbl.text! + " " + fetchObject.title! + " Homework"
            newPostView1.isHidden = true
            newPostView2.isHidden = false
//            postPresetView.isHidden = true
        }
        if sender.selectedSegmentIndex == 1 {
            category = "Test"
            postTitle = fetchObject.title! + " Test "
            newPostView1.isHidden = true
            newPostView2.isHidden = false
            homeWorkTitleLbl.text = "Test number"
            titleText.placeholder = "# "
            titleLabel.text = priceLbl.text! + " " + fetchObject.title! + " Test"
        }
        if sender.selectedSegmentIndex == 2 {
            category = "Notes"
            newPostView1.isHidden = true
            newPostView2.isHidden = false
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E MMM dd"
            let dateString = dateFormatter.string(from: Date())
            homeWorkTitleLbl.text = ""
            titleText.text = "Notes for \(dateString)"
            titleLabel.text = priceLbl.text! + " " + fetchObject.title!
        }
        if sender.selectedSegmentIndex == 3 {
            category = "Tutoring"
            newPostView1.isHidden = true
            newPostView2.isHidden = false
            homeWorkTitleLbl.text = ""
            titleText.text = "0"
            titleLabel.text = priceLbl.text! + " " + fetchObject.title! + " Tutoring"
        }
        if sender.selectedSegmentIndex == 4 {
            category = "Other"
            newPostView1.isHidden = true
            newPostView2.isHidden = false
            homeWorkTitleLbl.text = ""
            titleText.text = "0"
            titleLabel.text = priceLbl.text! + " " + fetchObject.title! + " Other"
        }
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: sender.date)
        if let day = components.day, let month = components.month, let year = components.year {
            let strn = String(describing: sender.date)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E MMM dd hh:mm a"
            schedule = dateFormatter.string(from: sender.date)
        }
    }
    
    func dismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    var storageRef: Storage {
        return Storage.storage()
    }
    
    func creatPost(){
        let ref = Database.database().reference()
        let authrName = Auth.auth().currentUser?.email
        let postKey = ref.child("Posts").childByAutoId().key
        let dateString = String(describing: Date())
        var picUrl:String!
        var authorFname: String!
        var authorLname: String!
        var phoneNumber: String?
        if let picurl = UserDefaults.standard.object(forKey: "pictureUrl") as? String {
           picUrl = picurl
        } //UserDefaults.standard.set(lname, forKey: "lName")
        if let fname = UserDefaults.standard.object(forKey: "fName") as? String {
            authorFname = fname
        }
        if let lname = UserDefaults.standard.object(forKey: "lName") as? String {
            authorLname = lname
        } // UserDefaults.standard.set(phone, forKey: "phoneNumber")
        if let phone = UserDefaults.standard.object(forKey: "phoneNumber") as? String {
            phoneNumber = phone
        }
        if titleText.text != "" || titleText.text != nil {
            let name = titleLabel.text! + " " + titleText.text! + " " + teacherName.text!
            
            let parameters = ["uid":postKey,
                              "name": name,
                              "authorID":Auth.auth().currentUser?.uid ?? " ",
                              "authorEmail": authrName ?? " ",
                              "authorName": authorFname + " " + authorLname,
                              "timeStamp":dateString,
                              "category":self.category,
                              "price": self.price,
                              //                              "schedule": self.schedules,
                "studentInClass":self.inClassSwitch.isOn,
                "postPic": picUrl,
                "classId": self.fetchObject.uid ?? "",
                "className":self.fetchObject.title ?? "",
                "phoneNumber":phoneNumber as Any] as? [String : Any]
            
            let parameters2 = ["uid":postKey,
                               "name": name,
                               "authorID":Auth.auth().currentUser?.uid ?? " ",
                               "authorName": authorFname + " " + authorLname,
                               "timeStamp":dateString,
                               "category":self.category,
                               "price": self.price ] as? [String : Any]
            
            let postParam = [postKey : parameters2]
            
            if isGiveHelp {
                ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").child("Myposts").updateChildValues(postParam ?? [:])
                ref.child("Posts").child(postKey).updateChildValues(parameters!)
                ref.child("Classes").child(self.fetchObject.uid!).child("Posts").child("GiveHelp").updateChildValues(postParam)
                self.callForHelp(title: "HomeworkMe Assignement Offer", body: "Your classmate in \(self.fetchObject.title ?? ""), under Offers posted: \(name ?? "")")
            } else {
                ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").child("Myposts").updateChildValues(postParam ?? [:])
                ref.child("Posts").child(postKey).updateChildValues(parameters!)
                ref.child("Classes").child(self.fetchObject.uid!).child("Posts").child("GetHelp").updateChildValues(postParam)
                self.callForHelp(title: "HomeworkMe Help Request", body: "Your classmate in \(self.fetchObject.title ?? ""), under Requests posted: \(name )")
            }
            self.postPresetView.isHidden = true
            categoryBtn.isSelected = false
            
        } else {
            // shake text
        }
        
        
    }
    
    func fetchMyPostsKey() {
        let ref = Database.database().reference()
        handle = ref.child("Classes").child(fetchObject.uid!).queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                /// dont do anything
            } else {
                let posts = response.value as! [String:AnyObject]
                if let dict = posts["Posts"] as? [String : AnyObject] {
                    self.fetchPostInfo(dictCheck: dict)
                }
                if let notificationKey = posts["notificationKey"] as? String {
                        self.notificationKey = notificationKey
                }
                if let notificationKeyName = posts["notificationKeyName"] as? String {
                    self.notificationKeyName = notificationKeyName
                }
                if let Notification_Devices = posts["Notification_Devices"] as? [String] {
                    self.devicNotes = Notification_Devices
                }
            }
        })
    }
    
    func fetchPostInfo(dictCheck: [String:AnyObject]){
        hmwrkArr.removeAll(); hmwrkArrReq.removeAll(); notesArr.removeAll(); notesArrReq.removeAll(); tutorArr.removeAll(); tutorArrReq.removeAll(); testArrReq.removeAll(); testArr.removeAll(); otherArr.removeAll(); otherArrReq.removeAll(); myPostArrReq.removeAll(); myPostArr.removeAll()
        for (x,d) in dictCheck {
            for (_,b) in d as! [String:AnyObject] {
                let postss = Post()
                if let fname = b["authorName"] as? String {
                    postss.authorName = fname
                } else {
                    postss.authorName = " "
                }
                if let uid = b["uid"] {
                    postss.uid = uid as? String
                }
                if let title = b["name"] {
                    postss.title = title as? String
                }
                if let authId = b["authorID"] {
                    postss.authorID = authId as? String
                }
                if let authEmal = b["authorEmail"] {
                    postss.authorEmail = authEmal as? String
                }
                if let tmStmp = b["timeStamp"] {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
                    guard let dat = dateFormatter.date(from: tmStmp as! String) else {break}
                    postss.timeStamp = dat
                }
                if let catgry = b["category"] {
                    postss.category = catgry as? String
                }
                if let price = b["price"] {
                    postss.price = price as! Int
                } else {
                    postss.price = 0
                }
                if x == "GetHelp" {
                    self.myPostArrReq.append(postss)
                    if postss.category == "Homework" {
                        self.hmwrkArrReq.append(postss)
                    } else if postss.category == "Notes" {
                        self.notesArrReq.append(postss)
                    }else if postss.category == "Tutoring" {
                        self.tutorArrReq.append(postss)
                    }else  if postss.category == "Test" {
                        self.testArrReq.append(postss)
                    }else if postss.category == "Other" {
                        self.otherArrReq.append(postss)
                    }
                } else {
                    self.myPostArr.append(postss)
                    if postss.category == "Homework" {
                        self.hmwrkArr.append(postss)
                    } else if postss.category == "Notes" {
                        self.notesArr.append(postss)
                    }else if postss.category == "Tutoring" {
                        self.tutorArr.append(postss)
                    }else  if postss.category == "Test" {
                        self.testArr.append(postss)
                    }else if postss.category == "Other" {
                        self.otherArr.append(postss)
                    }
                }
            }
            
        }
        if !self.myPostArr.isEmpty {
            self.myPostArr.sort(by: { $0.timeStamp?.compare(($1.timeStamp)!) == ComparisonResult.orderedDescending})
        }
        if !self.myPostArrReq.isEmpty {
            self.myPostArrReq.sort(by: { $0.timeStamp?.compare(($1.timeStamp)!) == ComparisonResult.orderedDescending})
        }
        self.allPostHolder = self.myPostArr
        self.postsTableView.reloadData()
        self.requestsTableView.reloadData()
        self.activitySpinner.stopAnimating()
        self.activitySpinner.isHidden = true

    }
    

    func imageWithImage(image:UIImage,scaledToSize newSize:CGSize)-> UIImage {
        
        UIGraphicsBeginImageContext( newSize )
        image.draw(in: CGRect(x: 0,y: 0,width: newSize.width,height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!.withRenderingMode(.alwaysTemplate)
    }
    
    func downloadImage(url:String) -> Data {
        var datas = Data()
        let storage = Storage.storage().reference(forURL: "gs://hmwrkme.appspot.com")
        userStorage = storage.child("Students")
        
        storageRef.reference(forURL: url).getData(maxSize: 1 * 1024 * 1024, completion: { (imgData, error) in
            if error == nil {
                if let data = imgData{
                   datas = data
                }
            }
            else {
                print(error?.localizedDescription)
            }
        })
         return datas
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == seg {
            let vc = segue.destination as? PostView
             vc?.postObject = self.postObject
            vc?.isOffering = self.isOffering
            vc?.classObject = self.fetchObject
        }
    }
    
   
    func callForHelp(title:String, body:String){
        for x in 0...devicNotes.count - 1 {
            checkNotif(fromDevice: devicNotes[x], title: title, body: body)
//            print("call for help ran \(x) times")
        }
    }
    
    fileprivate func checkNotif(fromDevice:String, title:String, body:String)
    {
        //        guard let message = "text.text" else {return}
        let toDeviceID = fromDevice
        var headers:HTTPHeaders = HTTPHeaders()
        
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)" ]
        
        let notification = ["to": fromDevice,
                            "notification":[
                                "body":body,
                                "title":title,
                                "badge":1,
                                "sound":"default"]
            ] as [String:Any]
        
        Alamofire.request("https://fcm.googleapis.com/fcm/send" as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
        }
    }
    
    fileprivate func setupPushNotification(fromDevice:String, title:String, body:String)
    {
        //        guard let message = "text.text" else {return}
        let toDeviceID = fromDevice
        var headers:HTTPHeaders = HTTPHeaders()
        
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)"
            
        ]
        let notification = ["to":"cXerwI8NeS4:APA91bE8AyQGyvQ3UAg4OpIpLrjlNFE6iV39dXWoq3EknYeHwtTTDbdEvhldhRX6SVCQqOktADc2tciBe46QrHQF_dtnMMt4wqBM-Xg4erVAE3j1DnkLvVwn5JaJneT8fjsLNkxNHJfb","notification":["body":body,"title":title,"badge":1,"sound":"default"]] as [String:Any]
        
        Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
        }
        
    }
}

extension MyClassRoomVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == postsTableView {
            switch (section) { //["All","Homework", "Test","Notes","Tutoring","Other"]
            case 0:
                return myPostArr.count
            case 1:
                return hmwrkArr.count
            case 2:
                return testArr.count
            case 3:
                return notesArr.count
            case 4:
                return tutorArr.count
            case 5:
                return otherArr.count
            default:
                return 0
            }
        } else if tableView == requestsTableView {
            switch (section) { //["All","Homework", "Test","Notes","Tutoring","Other"]
            case 0:
                return myPostArrReq.count
            case 1:
                return hmwrkArrReq.count
            case 2:
                return testArrReq.count
            case 3:
                return notesArrReq.count
            case 4:
                return tutorArrReq.count
            case 5:
                return otherArrReq.count
            default:
                return 0
            }
        }
       return 0
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == postsTableView {
             return tableViewSections.count
        } else if tableView == requestsTableView {
            return tableViewSections.count
        } else {
            return 0
        }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == postsTableView {
            return self.tableViewSections[section]
        
        } else if tableView == requestsTableView {
            return self.tableViewSections[section]
        }
        return ""
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == postsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postsCell", for: indexPath)
            var cellTxt = " "
            var urlString = ""
            var data = Data()
            switch (indexPath.section) {
            case 0:
                cellTxt = " " +  myPostArr[indexPath.row].title! + "\n" + myPostArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: myPostArr[indexPath.row].timeStamp!))"
                if myPostArr[indexPath.row].postPic != nil {
                    urlString = myPostArr[indexPath.row].postPic
                    data = myPostArr[indexPath.row].data
                }
            case 1:
                cellTxt = " " +  hmwrkArr[indexPath.row].title! + "\n" + hmwrkArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: hmwrkArr[indexPath.row].timeStamp!))"
                if hmwrkArr[indexPath.row].postPic != nil {
                    urlString = hmwrkArr[indexPath.row].postPic
                    data = hmwrkArr[indexPath.row].data
                }
            case 2:
                cellTxt = " " +  testArr[indexPath.row].title! + "\n" + testArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: testArr[indexPath.row].timeStamp!))"
                
                if testArr[indexPath.row].postPic != nil {
                    urlString = testArr[indexPath.row].postPic
                    data = testArr[indexPath.row].data
                }
            case 3:
                cellTxt = " " +  notesArr[indexPath.row].title! + "\n" + notesArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: notesArr[indexPath.row].timeStamp!))"
                if notesArr[indexPath.row].postPic != nil {
                    urlString = notesArr[indexPath.row].postPic
                    data = notesArr[indexPath.row].data
                }
            case 4:
                cellTxt = " " +  tutorArr[indexPath.row].title! + "\n" + tutorArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: tutorArr[indexPath.row].timeStamp!))"
                
                if tutorArr[indexPath.row].postPic != nil {
                    urlString = tutorArr[indexPath.row].postPic
                    data = tutorArr[indexPath.row].data
                }
            case 5:
                cellTxt = otherArr[indexPath.row].title! + "\n" + otherArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: otherArr[indexPath.row].timeStamp!))"
                if otherArr[indexPath.row].postPic != nil {
                    data = otherArr[indexPath.row].data
                    urlString = otherArr[indexPath.row].postPic
                }
            default:
                cellTxt = " "
            }
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = cellTxt
//                    cell.imageView?.image = #imageLiteral(resourceName: "manInWater")

            cell.imageView?.image = imageWithImage(image: UIImage(named: "manInWater")!, scaledToSize: CGSize(width: 30, height: 30))
            return cell
      
        } else if tableView == requestsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath)
            
            var cellTxt = " "
            var urlString = ""
            var data = Data()
            switch (indexPath.section) {
            case 0:
                cellTxt = " " +  myPostArrReq[indexPath.row].title! + "\n" + myPostArrReq[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: myPostArrReq[indexPath.row].timeStamp!))"
                if myPostArrReq[indexPath.row].postPic != nil {
                    urlString = myPostArrReq[indexPath.row].postPic
                    data = myPostArrReq[indexPath.row].data
                }
            case 1:
                cellTxt = " " +  hmwrkArrReq[indexPath.row].title! + "\n" + hmwrkArrReq[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: hmwrkArrReq[indexPath.row].timeStamp!))"
                if hmwrkArrReq[indexPath.row].postPic != nil {
                    urlString = hmwrkArrReq[indexPath.row].postPic
                    data = hmwrkArrReq[indexPath.row].data
                }
            case 2:
                cellTxt = " " +  testArrReq[indexPath.row].title! + "\n" + testArrReq[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: testArrReq[indexPath.row].timeStamp!))"
                
                if testArrReq[indexPath.row].postPic != nil {
                    urlString = testArrReq[indexPath.row].postPic
                    data = testArrReq[indexPath.row].data
                }
            case 3:
                cellTxt = " " +  notesArrReq[indexPath.row].title! + "\n" + notesArrReq[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: notesArrReq[indexPath.row].timeStamp!))"
                if notesArrReq[indexPath.row].postPic != nil {
                    urlString = notesArrReq[indexPath.row].postPic
                    data = notesArrReq[indexPath.row].data
                }
            case 4:
                cellTxt = " " +  tutorArrReq[indexPath.row].title! + "\n" + tutorArrReq[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: tutorArrReq[indexPath.row].timeStamp!))"
                
                if tutorArrReq[indexPath.row].postPic != nil {
                    urlString = tutorArrReq[indexPath.row].postPic
                    data = tutorArrReq[indexPath.row].data
                }
            case 5:
                cellTxt = otherArrReq[indexPath.row].title! + "\n" + otherArrReq[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: otherArrReq[indexPath.row].timeStamp!))"
                if otherArrReq[indexPath.row].postPic != nil {
                    data = otherArrReq[indexPath.row].data
                    urlString = otherArrReq[indexPath.row].postPic
                }
            default:
                cellTxt = " "
            }
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = cellTxt
            //                    cell.imageView?.image = #imageLiteral(resourceName: "manInWater")
            
            cell.imageView?.image = imageWithImage(image: UIImage(named: "manInWater")!, scaledToSize: CGSize(width: 30, height: 30))
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "postsCell", for: indexPath)
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == postsTableView {
            self.isOffering = true 
            switch (indexPath.section) { //["All","Homework", "Test","Notes","Tutoring","Other"]
            case 0:
                postObject = myPostArr[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 1:
                postObject = hmwrkArr[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 2:
                postObject = testArr[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 3:
                postObject = notesArr[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 4:
                postObject = tutorArr[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 5:
                postObject = otherArr[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            default:
                print(seg)
            }
        } else if tableView == requestsTableView {
            self.isOffering = false
            switch (indexPath.section) { //["All","Homework", "Test","Notes","Tutoring","Other"]
            case 0:
                postObject = myPostArrReq[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 1:
                postObject = hmwrkArrReq[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 2:
                postObject = testArrReq[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 3:
                postObject = notesArrReq[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 4:
                postObject = tutorArrReq[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            case 5:
                postObject = otherArrReq[indexPath.row]
                self.performSegue(withIdentifier: seg, sender: self)
            default:
                print(seg)
            }
        }
       
    }
    
}


extension MyClassRoomVC: PaperOnboardingDataSource, PaperOnboardingDelegate {
    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        let bkGroundColor1 = UIColor(red: 217/255, green: 17/258, blue: 89/255, alpha: 1)
        let bkGroundColor2 = UIColor(red: 106/255, green: 166/258, blue: 211/255, alpha: 1)
        let bkGroundColor3 = UIColor(red: 168/255, green: 200/258, blue: 78/255, alpha: 1)
        
        let title = UIFont(name: "AvenirNext-Bold", size: 24)
        let description = UIFont(name: "AvenirNext-Regular", size: 14) // iOS fonts .com
        let obod = OnboardingItemInfo(informationImage: UIImage(named: "addHelpSess")!, title: "Add Session", description: "Click  ➕ to give or get help.", pageIcon:  UIImage(named: "addSessFull")!, color: bkGroundColor1, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        let obod2 = OnboardingItemInfo(informationImage: UIImage(named: "const")!, title: "Set Price and Select Category", description: "Slide to set your price, then select a category. If you are in the class, leave the green button on, otherwise, switch it off.", pageIcon:  UIImage(named: "defineHelpCOnstFUll")!, color: bkGroundColor2, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        let obod3 = OnboardingItemInfo(informationImage: UIImage(named: "postIt")!, title: "Post it!", description: "Add resource number or description and professor's name, then tap Post.", pageIcon:  UIImage(named: "defineHelpCOnstFUll")!, color: bkGroundColor3, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: title!, descriptionFont: description!)
        
        
        return [obod, obod2, obod3 ][index]
    }
    
    func onboardingConfigurationItem(_: OnboardingContentViewItem, index _: Int) {
        //
    }
    
    func onboardingWillTransitonToIndex(_ index: Int) {
        if index == 1 {
            UIView.animate(withDuration: 0.2) {
                self.getStarted.alpha = 0
            }
        }
    }
    
    func onboardingDidTransitonToIndex(_ index: Int) {
        if index == 2 {
            UIView.animate(withDuration: 0.4) {
                self.getStarted.alpha = 1
            }
        }
    }
    
    func onboardingItemsCount() -> Int {
        return 3
    }
}
