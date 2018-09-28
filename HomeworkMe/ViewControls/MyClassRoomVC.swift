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

class MyClassRoomVC: UIViewController {

    @IBOutlet weak var addPostBtn: UIButton!
    @IBOutlet weak var classRoomLbl: UILabel!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var categoryBtn: UISegmentedControl!
    @IBOutlet weak var postsTableView: UITableView!
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
    
    var fetchObject = FetchObject()
    var postTitle:String?; var price:Int = 5; var category:String!
    var handle: DatabaseHandle?; var handle2: DatabaseHandle?
    var myPostArr = [Post](); var hmwrkArr = [Post](); var testArr = [Post](); var notesArr = [Post](); var otherArr = [Post](); var tutorArr = [Post](); var allPostHolder = [Post]()
    var tableViewSections = ["All","Homework", "Test","Notes","Tutoring","Other"]
    let seg = "classRoomToPostSegue" //classroom to post view
    var postObject = Post() // variable to hold transfered data to PostView
    var functions = CommonFunctions()
    var schedules = [String]()
    var schedule = String()
    var userStorage: StorageReference!
    let ref = Database.database().reference()
    var isTutor = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let currentDate: Date = Date()
        dismissKeyboard()
        postsTableView.estimatedRowHeight = 45
        postsTableView.rowHeight = UITableViewAutomaticDimension
        classRoomLbl.text = fetchObject.title
        fetchMyPostsKey()
        priceLbl.text = "$5"
       
       
        if isTutor {
            addPostBtn.isHidden = false
        } else {
            addPostBtn.isHidden = true 
        }
    }
    
    @IBAction func addPostPrsd(_ sender: Any) {
        postPresetView.isHidden = false
        newPostView1.isHidden = false
        newPostView2.isHidden = true
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
    
    @IBAction func cancelPrsd(_ sender: Any) {
        postPresetView.isHidden = true
        newPostView1.isHidden = true
        newPostView2.isHidden = true
    }
    
    @IBAction func filterOptions(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            let indexPath = IndexPath(item: 0, section: 1)
            self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        if sender.selectedSegmentIndex == 1 {
 
            let indexPath = IndexPath(item: 0, section: 2)
            self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        if sender.selectedSegmentIndex == 2 {
 
            let indexPath = IndexPath(item: 0, section: 3)
            self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        if sender.selectedSegmentIndex == 3 {
 
            let indexPath = IndexPath(item: 0, section: 4)
            self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        if sender.selectedSegmentIndex == 4 {
 
            let indexPath = IndexPath(item: 0, section: 5)
            self.postsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
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
        if let picurl = UserDefaults.standard.object(forKey: "pictureUrl") as? String {
           picUrl = picurl
        } //UserDefaults.standard.set(lname, forKey: "lName")
        if let fname = UserDefaults.standard.object(forKey: "fName") as? String {
            authorFname = fname
        }
        if let lname = UserDefaults.standard.object(forKey: "lName") as? String {
            authorLname = lname
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
                              "schedule": self.schedules,
                              "studentInClass":self.inClassSwitch.isOn,
                              "postPic": picUrl,
                              "classId": self.fetchObject.uid ?? "",
                              "className":self.fetchObject.title ?? ""] as? [String : Any]
            let postParam = [postKey : parameters]
            
            
        ref.child("Tutors").child((Auth.auth().currentUser?.uid)!).child("Posts").setValue(parameters)
            ref.child("Posts").updateChildValues(postParam)
            ref.child("Classes").child(self.fetchObject.uid!).child("Posts").updateChildValues(postParam)
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
                    self.fetchMyClass(dictCheck: dict)
                }
            }
        })
    }
    
    func fetchMyClass(dictCheck: [String:AnyObject]){
        let ref = Database.database().reference()
        handle2 = ref.child("Posts").queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
                /// dont do anything \\\
            } else {
                self.myPostArr.removeAll()
                self.hmwrkArr.removeAll()
                self.notesArr.removeAll()
                self.tutorArr.removeAll()
                self.testArr.removeAll()
                self.otherArr.removeAll()
                let posts = response.value as! [String:AnyObject]
                for (a,_) in dictCheck {
                    for (c,b) in posts {
                        if a == c {
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
                                let dat = dateFormatter.date(from: tmStmp as! String)
                                postss.timeStamp = dat
                            }
                            if let catgry = b["category"] {
                                postss.category = catgry as? String
                            } //postPic studentInClass schedule
                            if let postic = b["postPic"] {
                                if postic != nil {
                                    postss.postPic = postic as? String
                                    postss.data = self.downloadImage(url: postic as! String) 
                                }
                              }
                            if let stIn = b["studentInClass"] {
                                postss.studentInClas = stIn as? Bool
                            }
                            if let skedl = b["schedule"] {
                                if skedl != nil  {
                                    postss.schedule = skedl as! [String]
                                }
                            }
                            if let comments = b["comments"] as? [String:Any] {
                                
                            }
                            if let price = b["price"] {
                                postss.price = price as! Int
                            } else {
                                postss.price = 0
                            }
                            if let dlikers = b["disLikers"] as? [String:String] {
                                if dlikers != nil {
                                   postss.disLikers = [""]//dlikers.values as! [String]
                                }
                            }
                            if let liker = b["likers"] as? [String:Any] {
                                if liker != nil {
                                    postss.likers = Array(liker.values) as! [String]
                                }
                            }
                            self.myPostArr.append(postss)
                            
                            if postss.category == "Homework" {
                                self.hmwrkArr.append(postss)
                            }
                            if postss.category == "Notes" {
                                self.notesArr.append(postss)
                            }
                            if postss.category == "Tutoring" {
                                self.tutorArr.append(postss)
                            }
                            if postss.category == "Test" {
                                self.testArr.append(postss)
                            }
                            if postss.category == "Other" {
                                self.otherArr.append(postss)
                            }
                        }
                    }
                }
                self.myPostArr.sort(by: { $0.timeStamp?.compare(($1.timeStamp)!) == ComparisonResult.orderedDescending})
                self.allPostHolder = self.myPostArr
                self.postsTableView.reloadData()
                self.activitySpinner.stopAnimating()
                self.activitySpinner.isHidden = true
            }
        })
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
        } else{
            return 0
        }
       return 0
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == postsTableView {
             return tableViewSections.count
        } else {
            return 0
        }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == postsTableView {
            return self.tableViewSections[section]
        
        } else {
            return ""
        }
        return ""
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == postsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postsCell", for: indexPath)
            var cellTxt = " "
            var urlString = ""
            var data = Data()
            switch (indexPath.section) { //["All","Homework", "Test","Notes","Tutoring","Other"]
            case 0:
                cellTxt = " " +  myPostArr[indexPath.row].title! + "\n" + myPostArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: myPostArr[indexPath.row].timeStamp!))"
                if myPostArr[indexPath.row].postPic != nil {
                    urlString = myPostArr[indexPath.row].postPic
                    data = myPostArr[indexPath.row].data
                }
            case 1:
                cellTxt = " " +  hmwrkArr[indexPath.row].title! + "\n~" + hmwrkArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: hmwrkArr[indexPath.row].timeStamp!))"
                if hmwrkArr[indexPath.row].postPic != nil {
                    urlString = hmwrkArr[indexPath.row].postPic
                    data = hmwrkArr[indexPath.row].data
                }
            case 2:
                cellTxt = " " +  testArr[indexPath.row].title! + "\n~" + testArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: testArr[indexPath.row].timeStamp!))"
                
                if testArr[indexPath.row].postPic != nil {
                    urlString = testArr[indexPath.row].postPic
                    data = testArr[indexPath.row].data
                }
            case 3:
                cellTxt = " " +  notesArr[indexPath.row].title! + "\n~" + notesArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: notesArr[indexPath.row].timeStamp!))"
                if notesArr[indexPath.row].postPic != nil {
                    urlString = notesArr[indexPath.row].postPic
                    data = notesArr[indexPath.row].data
                }
            case 4:
                cellTxt = " " +  tutorArr[indexPath.row].title! + "\n~" + tutorArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: tutorArr[indexPath.row].timeStamp!))"
                
                if tutorArr[indexPath.row].postPic != nil {
                    urlString = tutorArr[indexPath.row].postPic
                    data = tutorArr[indexPath.row].data
                }
            case 5:
                cellTxt = otherArr[indexPath.row].title! + "\n~" + otherArr[indexPath.row].authorName! + "\n \(functions.getTimeSince(date: otherArr[indexPath.row].timeStamp!))"
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
      
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postsCell", for: indexPath)
            
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "postsCell", for: indexPath)
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == postsTableView {
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
        }
       
    }
    
}
