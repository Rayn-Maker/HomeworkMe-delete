//
//  PosView.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/13/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import Stripe
import SquarePointOfSaleSDK
import MessageUI
import Alamofire


class PostView: UIViewController,  MFMessageComposeViewControllerDelegate  {
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var firstAndLastName: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var classAndRatingsLable: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var locationsTableView: UITableView! //notesTableView
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    
    var postObject = Post() 
    var functions = CommonFunctions() 
    var userStorage: StorageReference!
    var studentInClass: Bool!
    var schedules = [String](); var locationsArray = [String]()
    var disLikers = [String](); var likers = [String]()
    var authorFname = "" ; var authorLname = " " 
    let ref = Database.database().reference()
    let settingsVC = SettingsViewController()
    var meetUpLocation: Place!
    var price: Int?
    var tutor = Student()
    var sentReq = false
    let postss = Post()
    var phoneNumber = ""
    // stripe payment setup
     

    override func viewDidLoad() {
        super.viewDidLoad()
        let storage = Storage.storage().reference(forURL: "gs://hmwrkme.appspot.com")
        userStorage = storage.child("Students")
        
        postTitle.text = postObject.title
        editImage()
        fetchTutor()
        fetchPost()
    }
 
    @IBAction func backPrsd(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
  
    
    @IBAction func leavACommentPrsd(_ sender: Any) {
        let userId = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        let dateString = String(describing: Date())
        if let fname = UserDefaults.standard.object(forKey: "fName") as? String {
            authorFname = fname
        }
        if let lname = UserDefaults.standard.object(forKey: "lName") as? String {
            authorLname = lname
        }
        let alert = UIAlertController(title: "Comment", message: "leave a comment", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter comment here..."
        }
        let ok = UIAlertAction(title: "Ok", style: .default) { (resp) in
            let name = self.authorFname + " " + self.authorLname
            let tt = alert.textFields?.first?.text
            let parameters: [String:String] = ["note":tt!,
                                               "time":dateString,
                                               "author":name,
                                               "key":userId!]
            
            ref.child("Posts").child(self.postObject.uid!).child("comments").child(userId!).updateChildValues(parameters)
            
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(ok); alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func call(_ sender: Any) {
        
        self.phoneNumber = self.phoneNumber.replacingOccurrences(of: "-", with: "")
        self.phoneNumber = self.phoneNumber.replacingOccurrences(of: " ", with: "")
        self.phoneNumber = self.phoneNumber.replacingOccurrences(of: ")", with: "")
        self.phoneNumber = self.phoneNumber.replacingOccurrences(of: "(", with: "")
        self.phoneNumber = self.phoneNumber.replacingOccurrences(of: "+", with: "")
        
        if self.phoneNumber.count > 10 {
            self.phoneNumber.remove(at: self.phoneNumber.startIndex)
        }
        if self.phoneNumber.count > 10 {
            self.phoneNumber.remove(at: self.phoneNumber.startIndex)
        }
        
        if self.phoneNumber.count > 10 {
            String(self.phoneNumber.characters.dropLast())
        }
        let dd =  (self.phoneNumber as NSString).integerValue
        
        guard let number = URL(string: "tel://" + "\(dd ?? 8888888888)") else {
            
            
            return }
        UIApplication.shared.open(number)
    }
    
    
    @IBAction func text(_ sender: Any) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = ""
            controller.recipients = [self.phoneNumber]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        } 
    }
    
    @IBAction func purchesPrsd(_ sender: Any) {
// before purchase happens check tutors status
        // if tutor is hot you'll have to go meet him where he's at
        // if tutor is off you will have to schedule an appointment via text.
        if meetUpLocation != nil {
            let alert2 = UIAlertController(title: "Pay with", message: "", preferredStyle: .alert)
            let square = UIAlertAction(title: "Credit Card", style: .default) { (response) in
                self.addCard()
            }
            let newCC = UIAlertAction(title: "Add new credit card", style: .default) { (resp) in
                self.addCard()
            }
            alert2.addAction(newCC)
            alert2.addAction(square)
            present(alert2, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Missing Schedule", message: "Please select a date to meet up", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true , completion: nil)
        }
    }
    
//    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
//        //... handle sms screen actions
//        self.dismiss(animated: true, completion: nil)
//    }
    
    func tutorStatus(){
        if tutor.tutorStatus == "hot" {
            
        } else if tutor.tutorStatus == "live" {
            
        } else if tutor.tutorStatus == "off" {
            
        }
    }
    
    var storageRef: Storage {
        return Storage.storage()
    }
    
 // stripe implementation functions
    func addCard() {
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self
        
        // Present add card view controller
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        present(navigationController, animated: true)
    }
    
    // end of stripe payment implementation 
    func editImage(){
        profilePic.layer.borderWidth = 1
        profilePic.layer.masksToBounds = false
        profilePic.layer.borderColor = UIColor.black.cgColor
        profilePic.layer.cornerRadius = profilePic.frame.height/2
        profilePic.clipsToBounds = true
    }
    
    func fetchTutor(){
        let ref = Database.database().reference()
        ref.child("Students").child(postObject.authorID ?? " ").queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
            if response.value is NSNull { 
            } else {
                let tutDict = response.value as! [String:AnyObject]
                
                if let mtuplcatns = tutDict["meetUpLocations"] as? [String:[String]] {
                    self.tutor.meetUpLocation = mtuplcatns
                    
                }
                if let fullname = tutDict["full_name"] as? String {
                    self.tutor.full_name = fullname
                    self.firstAndLastName.text = fullname
                }
                if let paymentSource = tutDict["paymentSource"] as? [String] {
                    self.tutor.paymentSource = paymentSource
                }
                if let email = tutDict["email"] as? String {
                    self.tutor.email = email
                    self.email.text = email
                }
                if let phn = tutDict["phoneNumber"] as? String {
                    self.tutor.phoneNumebr = phn
                    self.phoneNumber = phn 
                }
                if let phn = tutDict["pictureUrl"] as? String {
                    self.tutor.pictureUrl = phn
                    self.tutor.profilepic = self.downloadImage(url: phn as! String)
                }
                if let phn = tutDict["uid"] as? String {
                    self.tutor.uid = phn
                }
                if let fromDevice = tutDict["fromDevice"] as? String {
                    self.tutor.deviceId = fromDevice
                }
                if let currLoc = tutDict["currLoc"] as? [String]{
                    self.tutor.currLoc.lat = currLoc[0]
                    self.tutor.currLoc.long = currLoc[1]
                    self.tutor.currLoc.name = currLoc[2]
                    self.tutor.currLoc.address = currLoc[3]
                }
                if let reqs = tutDict["received"] as? [String:AnyObject] {
                    self.tutor.receivedObject = reqs
                    self.checkIfBookedTutor()
                }
                if let posts = tutDict["Posts"] as? [String:AnyObject] {
                    self.tutor.posts2 = posts
                }
                if let did = tutDict["customerId"] as? String {
                    self.tutor.customerId = did
                }
               
                if let status = tutDict["status"] as? String {
                    self.tutor.tutorStatus = status
                    self.getLocations()
                    if self.sentReq {
                        self.statusLbl.text = status + " :Request Pending"
                    } else {
                        self.statusLbl.text = status
                    }
                }
            }
        })
    }
    
    func checkIfBookedTutor(){
        for (x,y) in tutor.receivedObject {
            if x == Auth.auth().currentUser!.uid {
                sentReq = true
            }
        }
    }
    
    
    func fetchPost(){
        let ref = Database.database().reference()
        ref.child("Posts").child(postObject.uid ?? "").queryOrderedByKey().observeSingleEvent(of: .value,  with: { response in
            if response.value is NSNull {
                /// dont do anything \\\
            } else {
                let posts = response.value as! [String:AnyObject]
                if let fname = posts["authorName"] as? String {
                    self.postss.authorName = fname
//                    self.firstAndLastName.text = fname
                } else {
                    self.postss.authorName = " "
                }
                if let uid = posts["uid"] {
                    self.postss.uid = uid as? String
                }
                if let title = posts["name"] {
                    self.postss.title = title as? String
                }
                if let authId = posts["authorID"] {
                    self.postss.authorID = authId as? String
                }
                if let authEmal = posts["authorEmail"] {
                    self.postss.authorEmail = authEmal as? String
                    self.email.text = authEmal as! String
                }
                if let tmStmp = posts["timeStamp"] {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
                    let dat = dateFormatter.date(from: tmStmp as! String)
                    self.postss.timeStamp = dat
                }
                if let catgry = posts["category"] {
                    self.postss.category = catgry as? String
                } //postPic studentInClass schedule
                if let postic = posts["postPic"] {
                    if postic != nil {
                        self.postss.postPic = postic as? String
                    }
                }
                if let stIn = posts["studentInClass"] {
                    self.postss.studentInClas = stIn as? Bool
                    if stIn as? Bool ?? false {
                        self.classAndRatingsLable.text = "Student in class"
                    } else {
                        self.classAndRatingsLable.text = "Tutor of class"
                    }
                }
                if let comments = posts["comments"] as? [String:Any] {
                    
                }
                if let phone = posts["phoneNumber"] as? String {
                    self.postss.phoneNumber = phone
                }
                if let price = posts["price"] {
                    self.postss.price = price as! Int
                } else {
                    self.postss.price = 0
                }
             }
                self.activitySpinner.stopAnimating()
                self.activitySpinner.isHidden = true
            })
    }

func downloadImage(url:String) -> Data {
    var datas = Data()
    
    self.storageRef.reference(forURL: url).getData(maxSize: 1 * 1024 * 1024, completion: { (imgData, error) in
        if error == nil {
            if let data = imgData{
                self.profilePic.image = UIImage(data: data)
                self.activitySpinner.stopAnimating()
            }
        }
        else {
            print(error?.localizedDescription)
            self.activitySpinner.stopAnimating()
        }
    })
   
    return datas
}
    
    func getLocations() {
        if tutor.tutorStatus == "live" {
            var places = Place()
            for (_,y) in tutor.meetUpLocation {
                places.lat = y[0]
                places.long = y[1]
                places.name = y[2]
                places.address = y[3]
                tutor.places.append(places)
            }
            locationsTableView.reloadData()
        } else if tutor.tutorStatus == "hot" {
            var places2 = Place()
            if tutor.places.count > 0 {
                tutor.places.removeAll()
            }
            if tutor.currLoc != nil {
                 tutor.places.append(tutor.currLoc)
                locationsTableView.reloadData()
            }
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    func sendTextMesg() {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = ""
            controller.recipients = [self.tutor.phoneNumebr] as! [String]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func call() {
        
        self.tutor.phoneNumebr = self.tutor.phoneNumebr?.replacingOccurrences(of: "-", with: "")
        self.tutor.phoneNumebr = self.tutor.phoneNumebr?.replacingOccurrences(of: " ", with: "")
        self.tutor.phoneNumebr = self.tutor.phoneNumebr?.replacingOccurrences(of: ")", with: "")
        self.tutor.phoneNumebr = self.tutor.phoneNumebr?.replacingOccurrences(of: "(", with: "")
        self.tutor.phoneNumebr = self.tutor.phoneNumebr?.replacingOccurrences(of: "+", with: "")
        
        if self.tutor.phoneNumebr?.count ?? 0 > 10 {
            self.tutor.phoneNumebr?.remove(at: (self.tutor.phoneNumebr?.startIndex)!)
        }
        if (self.tutor.phoneNumebr?.count)! > 10 {
//            self.tutor.phoneNumebr.remove(at: self.tutor.phoneNumebr.startIndex)
        }
        
        if self.tutor.phoneNumebr!.count > 10 {
            String(self.tutor.phoneNumebr!.characters.dropLast())
        }
        let dd =  (self.tutor.phoneNumebr as! NSString).integerValue
        
        guard let number = URL(string: "tel://" + "\(dd ?? 8888888888)") else {
            
            
            return }
        UIApplication.shared.open(number)
    }
    
    func sendRequest(){
        // send a request to the author of the post, under his tutor tree in a request bucket
        // post should have time stamp, sender id, chosen location if live
        // post should have time stamp, sender id, and preset location if tutor is hot, request id
        // post should have time stamp, sender id, and chosen appointment sent.
        // put the request in a bucket under student who sent the request.
        // one new screen. show pending requests, show sent requests.
        // show waiting for response after they send a request on the post page 
        let ref = Database.database().reference()
        let postKey = ref.child("Requests").childByAutoId().key
        let dateString = String(describing: Date())
        let senderId = Auth.auth().currentUser!.uid
        var senderName: String?
        var phoneNumber: String? //phoneNumber
        var picUrl: String? //pictureUrl
        var senderCustomerId:String?
        if let nam = UserDefaults.standard.string(forKey: "full_name") {
            senderName = nam
        } else {
            senderName = "Full name missing"
        }
        if let phon = UserDefaults.standard.string(forKey: "phoneNumber") {
            phoneNumber = phon
        } else {
            phoneNumber = "0000000000"
        }
        if let phon = UserDefaults.standard.string(forKey: "pictureUrl") {
            picUrl = phon
        } else {
            picUrl = " "
        }//customerId
        if let phon = UserDefaults.standard.string(forKey: "customerId") {
            senderCustomerId = phon
        } else {
            
        }
        
        if tutor.uid != senderId {
            let place: [String:String] = ["address":meetUpLocation.address ?? "",
                                          "long":meetUpLocation.long ?? "",
                                          "lat":meetUpLocation.lat ?? "",
                                          "name":meetUpLocation.name ?? ""]
            
            let parameters: [String:AnyObject] = ["senderId":senderId as AnyObject,
                                                  "receiverId":self.tutor.uid as AnyObject,
                                                  "time":dateString as AnyObject,
                                                  "senderName":senderName as AnyObject,
                                                  "receiverName":postss.authorName as AnyObject,
                                                  "reqId":postKey as AnyObject,
                                                  "place":place as AnyObject,
                                                  "postTitle":self.postss.title as AnyObject,
                                                  "senderPhone":phoneNumber as AnyObject,
                                                  "receiverPhone":self.tutor.phoneNumebr as AnyObject,
                                                  "receiverPic":self.tutor.pictureUrl as AnyObject,
                                                  "senderPic":picUrl as AnyObject,
                                                  "status":"pending" as AnyObject,
                                                  "senderCustomerId":ProfileVC.senderCustomerId as AnyObject,
                                                  "receiverCustomerId":tutor.customerId as AnyObject,
                                                  "price":self.postss.price as AnyObject,
                                                  "senderDevice":ProfileVC.DEVICEID as AnyObject,
                                                  "receiverDevice":tutor.deviceId as AnyObject,
                                                  "receiverPayment":tutor.paymentSource as AnyObject]
            let par = [postKey : parameters] as [String: Any]
            self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").child("sent").updateChildValues(par)
            self.ref.child("Students").child(postss.authorID ?? "").child("received").updateChildValues(par)
            self.ref.child("Students").child(postss.authorID ?? "").child("currentLocation").updateChildValues(place)
            //        self.ref.child("Students").child(postss.authorID ?? "").updateChildValues(parameter2)
            self.setupPushNotification(fromDevice: tutor.deviceId, title: "HomeworkMe", body: "Tutor request from \(senderName ?? "")")
        } else {
            // you cant send a request to yourself.
            let alert = UIAlertController(title: "This is your session", message: "You can't book a session with yourself.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    fileprivate func setupPushNotification(fromDevice:String, title:String, body:String)
    {
//        guard let message = "text.text" else {return}
        let toDeviceID = fromDevice
        var headers:HTTPHeaders = HTTPHeaders()
        
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)"
            
        ]
        let notification = ["to":"\(toDeviceID)","notification":["body":body,"title":title,"badge":1,"sound":"default"]] as [String:Any]
        
        Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
        }
        
    }
    
}

extension PostView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // check to make sure this post id is not in my sent posts or else say you already requested this
        if indexPath.section == 0 {
            if !sentReq {
                meetUpLocation = tutor.places[indexPath.row]
               sendRequest()
            } else {
                let alert = UIAlertController(title: "Request Previously Sent", message: "This tutor is yet to respond to your request try texting or calling.", preferredStyle: .alert)
                let text = UIAlertAction(title: "Text", style: .default) { (res) in
                    //
                    self.sendTextMesg()
                }
                let call = UIAlertAction(title: "call", style: .default) { (res) in
                    //
                    self.call()
                }
                let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
                alert.addAction(call); alert.addAction(call); alert.addAction(cancel)
                present(alert, animated: true, completion: nil)
            }
        } else if indexPath.section == 1 {
            
        }
        if tableView == locationsTableView {
            
        }
    }
  
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "selecScheduleCell", for: indexPath)
            cell.textLabel!.text = tutor.places[indexPath.row].name
            cell.textLabel?.numberOfLines = 0
            return cell
        } else if indexPath.section == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell", for: indexPath)
            cell.textLabel?.text = postObject.notes[indexPath.row].note + "\n" + postObject.notes[indexPath.row].author
            cell.textLabel?.numberOfLines = 0
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell", for: indexPath)
            cell.textLabel?.text = postObject.notes[indexPath.row].note + "\n" + postObject.notes[indexPath.row].author
            cell.textLabel?.numberOfLines = 0
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == locationsTableView {
            switch (section) { 
            case 0:
                return tutor.places.count
            case 1:
                return postObject.notes.count
            default:
                return 0
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Select Meet Up Location"
        } else if section == 1 {
            return "Notes"
        }
        return ""
    }
 
}

extension PostView: STPAddCardViewControllerDelegate {
    
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




