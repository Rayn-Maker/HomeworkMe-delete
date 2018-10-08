//
//  MyClassMates.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/13/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import MessageUI
import GoogleMaps
import GooglePlaces
import Alamofire
import UserNotifications
import AudioToolbox


class MyRequests: UIViewController, MFMessageComposeViewControllerDelegate, UNUserNotificationCenterDelegate  {

    @IBOutlet weak var navBat: UINavigationBar!
    @IBOutlet weak var requestersView: UIView!
    @IBOutlet weak var myRequestsTable: UITableView!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var callBtn: UIButton!
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var timeSincePstLable: UILabel!
    @IBOutlet weak var bioLable: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var meetUpLocation: UITextView!
    @IBOutlet weak var switchView: UIBarButtonItem!
    @IBOutlet weak var tutorReqView: UIView!
    @IBOutlet weak var tutorReqTable: UITableView!
    @IBOutlet weak var mapViewDisplay: UIView!
    @IBOutlet weak var cancelTutor: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var acceptRejView: UIStackView! 
    
    @IBOutlet weak var startSessionBtn: UIButton!
    
    @IBOutlet weak var sessionBtnView: UIStackView!
    
    
    var tutor = Student()
    var student = Student()
    var functions = CommonFunctions()
    var userStorage: StorageReference!
    var request: Request!
    let ref = Database.database().reference()
    var displayingTutReqview = false
    var handle: DatabaseHandle?
    var handle2: DatabaseHandle?
    var isTutor = true
    var locationGoingTo = Place()
    var notificationRepeats = true
    private var notTimer = Timer()
    var toMeetUp = "to meet up"
    var window: UIWindow?
    
// google map setup
    var place = Place()
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    // An array to hold the list of likely places.
    var isSender = false
    var timerMessage = "timer message"
    
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    var seconds = 1200
    var timer = Timer()
    var isTimerRunning = false
    var timer2 = Timer()
    var isTimerRunning2 = false
    var isGrantedAccess = false
    var phoneNumber = String()
    var placeesDict = [String:[String]]()
    var earnings = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tutorReqTable.estimatedRowHeight = 45
        tutorReqTable.rowHeight = UITableViewAutomaticDimension
        myRequestsTable.estimatedRowHeight = 45
        myRequestsTable.rowHeight = UITableViewAutomaticDimension
        let storage = Storage.storage().reference(forURL: "gs://hmwrkme.appspot.com")
        userStorage = storage.child("Students")
        googleMapsetup()
        fetchStudent()
        editImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        isTimerRunning = false
//        stopTimer()
    }
    
    @IBAction func rejectReq(_ sender: Any) {
        let dateString = String(describing: Date())
        let parameter2: [String:AnyObject] = ["newNotice":true as AnyObject]
        
        let par = ["time": dateString as AnyObject,
                   "status":"rejected"] as! [String: Any]
        
        self.ref.child("Students").child(request.receiverId ?? "").child("received").child(request.reqID).updateChildValues(par)
        self.ref.child("Students").child(request.senderId ?? "").child("sent").child(request.reqID).updateChildValues(par)
        self.ref.child("Students").child(request.senderId ?? "").updateChildValues(parameter2)
        
        requestersView.isHidden = true
    }
    
    @IBAction func switchView(_ sender: Any) {
        if displayingTutReqview {
            tutorReqView.isHidden = true
            displayingTutReqview = false
//            navBat.topItem?.title = "Sent"
            switchView.title = "View Sent"
        } else {
            tutorReqView.isHidden = false
            displayingTutReqview = true
            switchView.title = "View Received"
        }
    }
    
    @IBAction func acceptReq(_ sender: Any) {
        if self.tutor.tutorStatus == "live" {
            let alert1 = UIAlertController(title: "Congratulations", message: "You have 20 minutes to meet at the location to start the session", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
                self.acceptRequest()
            }
            alert1.addAction(ok)
            present(alert1, animated: true, completion: nil)
        } else if self.tutor.tutorStatus == "hot" {
            let alert1 = UIAlertController(title: "Congratulations", message: "Student has 20 minutes to meet you at the location to start the session", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
                self.acceptRequest()
            }
            alert1.addAction(ok)
            present(alert1, animated: true, completion: nil)
     
        } else if self.tutor.tutorStatus == "off" {
            let alert = UIAlertController(title: "You are Off", message: "1) Make sure to communicate with the student on what time and location to meet. 2) When you have the location and time from the student turn on your live switch on you profile page and tap this session again.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok", style: .default) { (_) in
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile") as! ProfileVC
                self.window?.rootViewController = vc
            }
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func callPrsd(_ sender: Any) {
        
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
    
    @IBAction func txtMsg(_ sender: Any) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = ""
            controller.recipients = [self.phoneNumber]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
     @IBAction func cancelTutor(_ sender: Any) {
        //change the tag with an api call.
    }
    
    @IBAction func dismissView(_ sender: Any) {
        requestersView.isHidden = true
    }
    
    @IBAction func startSession(_ sender: Any) {
        //change the tag with an api call.
        if !self.request.sessionDidStart {
            startSessionBtn.setTitle("Finish Session", for: .normal)
            startSession()
            self.request.sessionDidStart = true
        }else {
            if startSessionBtn.titleLabel?.text == "Finish Session" {
                startSessionBtn.setTitle("Start Session", for: .normal)
                stopSession()
                requestersView.isHidden = true
            }
        }
    }
    
    func acceptRequest() {
        let dateString = String(describing: Date())
        var calendar = Calendar.current
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
        formatter.calendar.date(byAdding: .minute, value: 20, to: Date())
        let strDate = formatter.string(from: Date())
        let datesss = calendar.date(byAdding: .minute, value: 20, to: formatter.date(from: strDate)!)
        let y = formatter.string(from: datesss!)
        var payOut: [Int]
        let title = "HomeworkMe"
        payOut = convMony(price: request.sessionPrice)
        let desc = "Description: Payment to: \(request.receiverName ?? "") from: \(request.senderName ?? "") for \(request.postTite ?? "") total paid \(payOut[1])"
        let statsParam: [String:String] = ["status":"hot"]
        let receiptParam = ["tutor":request.receiverName,
                            "tutorPhone":request.receiverPhone,
                            "tutorPay":request.receiverPayment,
                            "studentPhon":request.senderPhone,
                            "studentCust":request.senderCustomerId,
                            "student":request.senderName,
                            "price":request.sessionPrice,
                            "date":payOut,
                            "description":desc] as! [String:AnyObject]
        
        let locParam = ["time": dateString as AnyObject,
                        "status":"approved",
                        "currLocationCoord": "\(self.request.place.lat ?? "") \(self.request.place.long ?? "")",
            "endTimeToMeet": y ?? "",
            "currLocationName":self.request.place.name] as! [String: Any]
        
        let priceParam = ["price":payOut[1]] as! [String: Any]
        
        self.ref.child("Students").child(request.senderId ?? "").updateChildValues(statsParam)
        self.ref.child("Students").child(request.receiverId ?? "").updateChildValues(statsParam)
        
        self.ref.child("Students").child(request.receiverId ?? "").updateChildValues(placeesDict)
        
        self.ref.child("Students").child(request.senderId ?? "").child("sent").child(request.reqID).updateChildValues(locParam)
        self.ref.child("Students").child(request.receiverId ?? "").child("received").child(request.reqID).updateChildValues(locParam)
        
        self.ref.child("Students").child(request.senderId ?? "").child("sent").child(request.reqID).updateChildValues(priceParam)
        self.ref.child("Students").child(request.receiverId ?? "").child("received").child(request.reqID).updateChildValues(priceParam)
        
        self.ref.child("Receipt").child(request.reqID).updateChildValues(receiptParam)
        self.ref.child("Students").child(request.senderId ?? "").child("receipt").child(request.reqID).updateChildValues(receiptParam)
        self.ref.child("Students").child(request.receiverId ?? "").child("receipt").child(request.reqID).updateChildValues(receiptParam)
        requestersView.isHidden = true
        chargeCard( price: payOut[0], description: desc, customerSender: request.senderCustomerId)
        setupPushNotification(fromDevice: request.senderDevice, title: title, body: "\(request.receiverName ?? "") Has accepted your tutor session")
        //            drawPath(start: currentLocation!, end: request.place)
        //            mapViewDisplay.isHidden = false
    }
    
    func convMony(price:Int) -> [Int] {
        let total = price * 100
        let payOut = Int(floor(Double(total) * 0.25))
        let pay = [total, total - payOut]
        return pay
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    func chargeCard( price:Int, description:String, customerSender:String){
        StripeClient.shared.completeCharge(amount:price, description: description, customerSender: customerSender) { (result) in
            //
        }
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MyRequests.updateTimer)), userInfo: nil, repeats: true)
        isTimerRunning = true
    }
    
    @objc func updateTimer() {
        print("")
        if seconds < 1 {
            timer.invalidate()
            let parameter2: [String:String] = ["newNotice":"true",
                                               "status":"live"]
            
            let alert = UIAlertController(title: "Time's Up", message: self.timerMessage, preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default) { (resp) in
                self.ref.child("Students").child(self.request.receiverId ?? "").updateChildValues(parameter2)
                self.ref.child("Students").child(self.request.senderId ?? "").updateChildValues(parameter2)
            }
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        } else {
            seconds -= 1     //This will decrement(count down)the seconds.
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }
        
    }
    
    func runTimer2() {
        timer2 = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MyRequests.updateTimer2)), userInfo: nil, repeats: true)
        isTimerRunning = true
    }
    
    @objc func updateTimer2() {
        if seconds < 1 {
            timer2.invalidate()
            let parameter2: [String:String] = ["newNotice":"true",
                                               "status":"live"]
            
            let alert = UIAlertController(title: "Time's Up", message: self.timerMessage, preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default) { (resp) in
                self.ref.child("Students").child(self.request.receiverId ?? "").updateChildValues(parameter2)
                self.ref.child("Students").child(self.request.senderId ?? "").updateChildValues(parameter2)
            }
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        } else {
            seconds -= 1     //This will decrement(count down)the seconds.
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }
        
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i \(toMeetUp)", hours, minutes, seconds)
    }
    
    var storageRef: Storage {
        return Storage.storage()
    }
    
    func fetchStudent() {
        let ref = Database.database().reference()
          handle = ref.child("Students").child(Auth.auth().currentUser?.uid ?? " ").queryOrderedByKey().observe( .value, with: { response in
            if response.value is NSNull {
            } else {
                let tutDict = response.value as! [String:AnyObject]

                if let json = tutDict["received"] as? [String:AnyObject] {
//                    self.tutor.receivedObject = json
                    self.tutor = self.setUpReqArr(tableArr: self.tutor, object: json, table: self.myRequestsTable, isSender: false)
                }
                if let json = tutDict["sent"] as? [String:AnyObject] {
//                    self.student.receivedObject = json
                    self.student = self.setUpReqArr(tableArr: self.student, object: json, table: self.tutorReqTable, isSender: true)
                }
                if let scdul = tutDict["appointMents"] as? [String] {
                    self.tutor.schedule = scdul
                }
                if let posts = tutDict["Posts"] as? [String:AnyObject] {
                    self.tutor.posts2 = posts
                } //endTime:
                if let tmStmp = tutDict["endTime"] as? String {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
                    let dat = dateFormatter.date(from: tmStmp as String)
                    self.tutor.endTime = dat!
                    let k = Date()
                    if k < dat! {
                        // call timer and give it the set minute
                        let m = dat!.timeIntervalSince(k)
                        let minutes = floor(m/60)
                        self.seconds = Int(round(m))
                        if !self.isTimerRunning {
                            self.timerMessage = "You've let the time run out without starting the session, this session has been cancelled"
                           // self.runTimer()
                        }
                    } else {
                        print(k); print(dat!)
                        self.isTimerRunning = false
                        self.timer.invalidate()
                    }
                }
//                if let newNotice = tutDict["newNotice"] as? Bool {
//                    if newNotice {
//                        self.startTimer()
//                    }
//                }
                self.tutor.customerId = tutDict["customerId"] as? String
                self.tutor.phoneNumebr = tutDict["phoneNumber"] as? String
                self.tutor.full_name = tutDict["full_name"] as? String
                self.tutor.email = tutDict["email"] as? String
                if let status = tutDict["status"] as? String {
                    self.tutor.tutorStatus = status 
                }
            }
        })
    }

    
    func connectProfile(req: Request, tutStat:String, isRequest:Bool, meetUplocationMesg:String) {
        if !isRequest{
            
            if tutor.tutorStatus == "hot"{
                downlaodPic(url: req.receiverPicUrl)
                postTitle.text = req.postTite
                timeSincePstLable.text = req.timeString
                bioLable.text = req.receiverName
                meetUpLocation.text = meetUplocationMesg
                
            } else if tutor.tutorStatus == "live"{
                downlaodPic(url: req.receiverPicUrl)
                postTitle.text = req.postTite
                timeSincePstLable.text = req.timeString
                bioLable.text = req.receiverName
                meetUpLocation.text = meetUplocationMesg
                
            } else if tutor.tutorStatus  == "off"{
                downlaodPic(url: req.receiverPicUrl)
                postTitle.text = req.postTite
                timeSincePstLable.text = req.timeString
                bioLable.text = req.receiverName
                meetUpLocation.text = meetUplocationMesg
            }
        } else {
            
            if tutor.tutorStatus  == "hot"{
                downlaodPic(url: req.senderPicUrl)
                postTitle.text = req.postTite
                timeSincePstLable.text = req.timeString
                bioLable.text = req.senderName
                meetUpLocation.text = meetUplocationMesg
            } else if tutor.tutorStatus  == "live"{
                downlaodPic(url: req.senderPicUrl)
                postTitle.text = req.postTite
                timeSincePstLable.text = req.timeString
                bioLable.text = req.senderName
                meetUpLocation.text = meetUplocationMesg
            } else if tutor.tutorStatus  == "off"{
                downlaodPic(url: req.senderPicUrl)
                postTitle.text = req.postTite
                timeSincePstLable.text = req.timeString
                bioLable.text = req.senderName
                meetUpLocation.text = meetUplocationMesg
            }
        }
    }
    
    func startSession(){
        var calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
        formatter.calendar.date(byAdding: .minute, value: 30, to: Date())
        let strDate = formatter.string(from: Date())
        let datesss = calendar.date(byAdding: .minute, value: 30, to: formatter.date(from: strDate)!)
        let y = formatter.string(from: datesss!)
        let par: [String:AnyObject] = ["sessionDidStart":true as AnyObject,
                                       "endTime": "\(y ?? "")" as AnyObject]
        
        if !request.sessionDidStart {
            self.ref.child("Students").child(request.senderId ?? "").child("sent").child(request.reqID).updateChildValues(par)
            self.ref.child("Students").child(request.receiverId ?? "").child("received").child(request.reqID).updateChildValues(par)
            self.setupPushNotification(fromDevice: request.senderDevice, title: "HomeworkMe" ?? "", body: "\(request.receiverName ?? "") Has started your tutor session")
            if self.isTimerRunning2 {
                self.isTimerRunning2 = false
                self.timer2.invalidate()
            } else {
                
            }
            connectTimer(req: self.request, startSess: true)
            
        } else {
            let alert = UIAlertController(title: "Session already started", message: "This session has already been started.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func stopSession() {
        if tutor.requestsArrAccepted.count < 2 {
            // change status to live.
            let par: [String:AnyObject] = ["status":"live" as AnyObject]
            self.ref.child("Students").child(request.receiverId ?? "").updateChildValues(par)
        }
        
        let par: [String:AnyObject] = ["sessionFinished":true as AnyObject,
                                       "status":"finished" as AnyObject]
        self.setupPushNotification(fromDevice: request.senderDevice, title: "HomeworkMe", body: "\(request.receiverName ?? "") Has ended your session.")
        self.ref.child("Students").child(request.receiverId ?? "").child("received").child(request.reqID).updateChildValues(par)
        self.ref.child("Students").child(request.senderId ?? "").child("sent").child(request.reqID).updateChildValues(par)
    }
    
    func editImage(){
        image.layer.borderWidth = 1
        image.layer.masksToBounds = false
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.cornerRadius = image.frame.height/2
        image.clipsToBounds = true
    }
    
    func setUpReqArr (tableArr: Student, object:[String : AnyObject], table:UITableView, isSender:Bool) -> Student {
        tableArr.requestsArrRejected.removeAll()
        tableArr.requestsArrAccepted.removeAll()
        tableArr.requestsArrPending.removeAll()
        for (_,b) in object {
            var req = Request()
            req.senderName = b["senderName"] as? String
            req.receiverName = b["receiverName"] as? String
            req.senderId = b["senderId"] as? String
            req.receiverId = b["receiverId"] as? String
            let ts = b["time"] as? String
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
            let dat = dateFormatter.date(from: ts as! String)
            req.timeString = functions.getTimeSince(date: dat ?? Date())
            req.reqID = b["reqId"] as? String
            req.senderDevice = b["senderDevice"] as? String
            req.recieverDevice = b["receiverDevice"] as? String
            req.postTite = b["postTitle"] as? String
            req.senderPhone = b["senderPhone"] as? String
            req.senderPicUrl = b["senderPic"] as? String
            req.receiverCustomerId = b["receiverCustomerId"] as? String
            req.senderCustomerId = b["senderCustomerId"] as? String
            req.sessionPrice = b["price"] as? Int
            self.earnings += req.sessionPrice
            req.receiverPicUrl = b["receiverPic"] as? String
            req.receiverPayment = b["receiverPayment"] as? [String]
            if let et = b["endTimeToMeet"] as? String {
                req.endTimeToMeet = et
//                connectTimer(req: req, timeToMeet: true)
            }
            req.sessionDidStart = b["sessionDidStart"] as? Bool ?? false
            if req.sessionDidStart {
                req.endTimeStrn = b["endTime"] as! String
//                connectTimer(req: req, timeToMeet: false)
            }
            
            req.reqStatus = b["status"] as? String
            if let place = b["place"] as? [String:AnyObject] {
                 req.place.address = place["address"] as? String
                req.place.lat = place["lat"] as? String
                req.place.long = place["long"] as? String
                req.place.name = place["name"] as? String
                let arr = ["\(req.place.lat ?? "")", "\(req.place.long ?? "")", req.place.name , "\(req.place.address ?? "")"]
                placeesDict["currLoc"] = arr as! [String]
            }
            if req.reqStatus == "pending" {
                tableArr.requestsArrPending.append(req)
            } else if req.reqStatus == "approved" {
                tableArr.requestsArrAccepted.append(req)
                self.notificationRepeats = true
            } else if req.reqStatus == "rejected" {
                tableArr.requestsArrRejected.append(req)
            } else if req.reqStatus == "finished" {
                 tableArr.requestsArrHistory.append(req)
            }
        }
        table.reloadData()
        return tableArr
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
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //
    }
  
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
//    func startTimer(){
//        let timeInterval = 2.0
//        if isGrantedAccess && !timer.isValid { //allowed notification and timer off
//            timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (timer) in
//
//            })
//        }
//    }
    
    func connectTimer(req:Request, startSess:Bool = false){
        timerLabel.text = "00:00:00"
        timer2.invalidate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
        var dat: Date?
        if req.sessionDidStart {
            dat = dateFormatter.date(from: req.endTimeStrn as String)
            toMeetUp = "till session ends"
        } else {
            dat = dateFormatter.date(from: req.endTimeToMeet as String)
            toMeetUp = "to start session"
        }
        let k = Date()
        if k < dat! {
            // call timer and give it the set minute
            let m = dat!.timeIntervalSince(k)
            let minutes = floor(m/60)
            if startSess{
                self.seconds = 1800
                self.timerMessage = "session is over"
            } else {
                self.seconds = Int(round(m))
            }
            self.timerMessage = "session is over"
            self.runTimer2()
        } else {
            print(k); print(dat!)
            self.isTimerRunning2 = false
            self.timer2.invalidate()
        }
    }
    
//    func stopTimer(){
//        //shut down timer
//        timer.invalidate()
//        //clear out any pending and delivered notifications
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//    }
    
    func downlaodPic(url:String) {
        if url != nil && url != "" && url != " " {
            self.storageRef.reference(forURL:url).getData(maxSize: 1 * 1024 * 1024, completion: { (imgData, error) in
                if error == nil {
                    if let data = imgData{
                        self.image.image = UIImage(data: data)
                        self.activitySpinner.stopAnimating()
                    }
                }
                else {
                    print(error?.localizedDescription)
                    self.activitySpinner.stopAnimating()
                }
            })
        } else {
            self.image.image = UIImage(named: "engineering")
        }
    }
    
    func drawPath(start:CLLocation, end:Place){
        let origin = "\(start.coordinate.latitude ),\(start.coordinate.longitude)"
        let destination = "\(end.lat ?? ""),\(end.long ?? "")"
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyDV7NWQ25BT5pISVM5b9vkRFJrK8TjXypY"
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: {
            (data, response, error) in
            if(error != nil){
                print("error")
            }else{
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                    let routes = json["routes"] as! NSArray
                    self.mapView.clear()
                    
                    OperationQueue.main.addOperation({
                        for route in routes
                        {
                            let routeOverviewPolyline:NSDictionary = (route as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
                            let points = routeOverviewPolyline.object(forKey: "points")
                            let path = GMSPath.init(fromEncodedPath: points! as! String)
                            let polyline = GMSPolyline.init(path: path)
                            polyline.strokeWidth = 3
                            
                            let bounds = GMSCoordinateBounds(path: path!)
                            self.mapView!.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 30.0))
                            
                            polyline.map = self.mapView
                            
                        }
                    })
                }catch let error as NSError{
                    print("error:\(error)")
                }
            }
        }).resume()
    }
    
    /// Google maps implementation
    func googleMapsetup() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRequester" {
            let vc = segue.destination as? Request
            
        }
    }
}


extension MyRequests: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == myRequestsTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myRequests", for: indexPath)
            if indexPath.section == 0 {
//                timerLabel.isHidden = true
                cell.textLabel?.text = "\( tutor.requestsArrPending[indexPath.row].senderName ?? "")\n\(tutor.requestsArrPending[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = tutor.requestsArrPending[indexPath.row].postTite
                return cell
            } else if indexPath.section == 1 {
                cell.textLabel?.text = "\( tutor.requestsArrAccepted[indexPath.row].senderName ?? "")\n\(tutor.requestsArrAccepted[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = tutor.requestsArrAccepted[indexPath.row].postTite
                return cell
            } else if indexPath.section == 2 {
                cell.textLabel?.text = "\( tutor.requestsArrHistory[indexPath.row].senderName ?? "")\n\(tutor.requestsArrHistory[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = tutor.requestsArrHistory[indexPath.row].postTite
                return cell
            } else if indexPath.section == 3 {
                cell.textLabel?.text = "\( tutor.requestsArrRejected[indexPath.row].senderName ?? "")\n\(tutor.requestsArrRejected[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = tutor.requestsArrRejected[indexPath.row].postTite
                return cell
            }
        } else if tableView == tutorReqTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myTutorRequests", for: indexPath)
            if indexPath.section == 0 {
                cell.textLabel?.text = "\( student.requestsArrPending[indexPath.row].receiverName ?? "")\n\(student.requestsArrPending[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = student.requestsArrPending[indexPath.row].postTite
                return cell
            } else if indexPath.section == 1 {


                cell.textLabel?.text = "\( student.requestsArrAccepted[indexPath.row].receiverName ?? "")\n\(student.requestsArrAccepted[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = student.requestsArrAccepted[indexPath.row].postTite
                return cell
            } else if indexPath.section == 2 {
                cell.textLabel?.text = "\( student.requestsArrHistory[indexPath.row].receiverName ?? "")\n\(student.requestsArrHistory[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = student.requestsArrHistory[indexPath.row].postTite
                return cell
            } else if indexPath.section == 3 {
                cell.textLabel?.text = "\( student.requestsArrRejected[indexPath.row].receiverName ?? "")\n\(student.requestsArrRejected[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = student.requestsArrRejected[indexPath.row].postTite
                return cell
            }

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myRequests", for: indexPath)
            cell.textLabel?.text = "\( tutor.requestsArrRejected[indexPath.row].receiverName ?? "")\n\(tutor.requestsArrRejected[indexPath.row].postTite ?? "")"
            cell.detailTextLabel?.text = tutor.requestsArrRejected[indexPath.row].postTite
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "myRequests", for: indexPath)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Pending Requests"
        } else if section == 1 {
            return "Accepted Requests"
        } else if section == 2 {
            return "Requests History"
        } else if section == 3 {
            return "Rejected Requests"
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == myRequestsTable {
            switch (section) {
            case 0:
                return tutor.requestsArrPending.count
            case 1:
                return tutor.requestsArrAccepted.count
            case 2:
                return  tutor.requestsArrHistory.count
            case 3:
                return tutor.requestsArrRejected.count
            default:
                return 0
            }
        } else if tableView == tutorReqTable {
            switch (section) {
            case 0:
                return student.requestsArrPending.count
            case 1:
                return student.requestsArrAccepted.count
            case 2:
                return student.requestsArrHistory.count
            case 3:
                return student.requestsArrRejected.count
            default:
                return 0
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activitySpinner.startAnimating()
        requestersView.isHidden = false
        if tableView == tutorReqTable {
            isSender = true
            if indexPath.section == 0 {
                self.acceptRejView.isHidden = false
                self.sessionBtnView.isHidden = true
                self.timeSincePstLable.isHidden = false
                acceptRejView.isHidden = true
//                timerLabel.isHidden = true
                if student.requestsArrPending[indexPath.row].receiverPhone != nil {
                    self.phoneNumber = student.requestsArrPending[indexPath.row].receiverPhone
                }
                request = student.requestsArrPending[indexPath.row]
                connectProfile(req: student.requestsArrPending[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: false, meetUplocationMesg: "Tutor's yet to respond")
                
            } else if indexPath.section == 1 {
                if student.requestsArrAccepted[indexPath.row].receiverPhone != nil {
                    self.phoneNumber = student.requestsArrAccepted[indexPath.row].receiverPhone
                }
                self.sessionBtnView.isHidden = true
                request = student.requestsArrAccepted[indexPath.row]
                connectTimer(req: request)
                if !self.request.sessionDidStart {
                    startSessionBtn.setTitle("Start Session", for: .normal)
                }else {
                    startSessionBtn.setTitle("Finish Session", for: .normal)
                }
                connectProfile(req: student.requestsArrAccepted[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: false, meetUplocationMesg: "\(request.place.name ?? "")" + "\n" + "\(request.place.address ?? "")")
                self.place = student.requestsArrAccepted[indexPath.row].place
                self.acceptRejView.isHidden = true
                self.sessionBtnView.isHidden = false
                self.timeSincePstLable.isHidden = true
                cancelTutor.setTitleColor(.black, for: .normal); cancelTutor.isEnabled = true
                startSessionBtn.setTitleColor(.black, for: .normal); startSessionBtn.isEnabled = true
//                timerLabel.isHidden = false
            } else if indexPath.section == 2 {
                acceptRejView.isHidden = true
                cancelTutor.setTitleColor(.gray, for: .normal); cancelTutor.isEnabled = false
                startSessionBtn.setTitleColor(.gray, for: .normal); startSessionBtn.isEnabled = false
                if student.requestsArrHistory[indexPath.row].receiverPhone != nil { self.phoneNumber = student.requestsArrHistory[indexPath.row].receiverPhone
                }
                self.sessionBtnView.isHidden = false
                request = student.requestsArrHistory[indexPath.row]
                connectProfile(req: student.requestsArrHistory[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: false, meetUplocationMesg: "Hope you had a great time with this tutor")
                self.isTimerRunning2 = false
                self.timer2.invalidate()
                timerLabel.text = "00:00:00"
            } else if indexPath.section == 3 {
                acceptRejView.isHidden = true
                cancelTutor.setTitleColor(.gray, for: .normal); cancelTutor.isEnabled = false
                startSessionBtn.setTitleColor(.gray, for: .normal); startSessionBtn.isEnabled = false
                self.phoneNumber = student.requestsArrRejected[indexPath.row].receiverPhone
                self.sessionBtnView.isHidden = false
                request = student.requestsArrRejected[indexPath.row]
                connectProfile(req: student.requestsArrRejected[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: false, meetUplocationMesg: "Tutor request was rejected kinldy find another. or session is over")
                self.isTimerRunning2 = false
                self.timer2.invalidate()
                timerLabel.text = "00:00:00"
            }
        } else if tableView == myRequestsTable {
            isSender = false
            if indexPath.section == 0 {
                self.acceptRejView.isHidden = false
                self.sessionBtnView.isHidden = true
                self.timeSincePstLable.isHidden = false
//                timerLabel.isHidden = true
                self.phoneNumber = tutor.requestsArrPending[indexPath.row].senderPhone
                self.sessionBtnView.isHidden = true
                request = tutor.requestsArrPending[indexPath.row]
                connectProfile(req: tutor.requestsArrPending[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: true, meetUplocationMesg: "\(request.place.name ?? "")" + "\n" + "\(request.place.address ?? "")")
            } else if indexPath.section == 1 {
                self.phoneNumber = tutor.requestsArrAccepted[indexPath.row].senderPhone
                request = tutor.requestsArrAccepted[indexPath.row]
                connectTimer(req: request)
                cancelTutor.setTitleColor(.black, for: .normal); cancelTutor.isEnabled = true
                startSessionBtn.setTitleColor(.black, for: .normal); startSessionBtn.isEnabled = true
                connectProfile(req: tutor.requestsArrAccepted[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: true, meetUplocationMesg: "\(request.place.name ?? "")" + "\n" + "\(request.place.address ?? "")")
                if !self.request.sessionDidStart {
                    startSessionBtn.setTitle("Start Session", for: .normal)
                }else {
                    startSessionBtn.setTitle("Finish Session", for: .normal)
                }
                self.acceptRejView.isHidden = true
                self.sessionBtnView.isHidden = false
                self.timeSincePstLable.isHidden = true
//                timerLabel.isHidden = false
            } else if indexPath.section == 2 {
                acceptRejView.isHidden = true
                cancelTutor.setTitleColor(.gray, for: .normal); cancelTutor.isEnabled = false
                startSessionBtn.setTitleColor(.gray, for: .normal); startSessionBtn.isEnabled = false
                self.phoneNumber = tutor.requestsArrHistory[indexPath.row].senderPhone
                request = tutor.requestsArrHistory[indexPath.row]
                connectProfile(req: tutor.requestsArrHistory[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: true, meetUplocationMesg: "Session over hope you had a great time with this Student. you've made $\(String(format: "%.2f", Double(self.earnings) - Double(self.earnings) * 0.25)) so far.")
                self.isTimerRunning2 = false
                self.timer2.invalidate()
                timerLabel.text = "00:00:00"
            } else if indexPath.section == 3 {
                acceptRejView.isHidden = true
                cancelTutor.setTitleColor(.gray, for: .normal); cancelTutor.isEnabled = false
                startSessionBtn.setTitleColor(.gray, for: .normal); startSessionBtn.isEnabled = false
                self.phoneNumber = tutor.requestsArrRejected[indexPath.row].senderPhone
                request = tutor.requestsArrRejected[indexPath.row]
                connectProfile(req: tutor.requestsArrRejected[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: true, meetUplocationMesg: "You rejected the request ")
                timerLabel.text = "00:00:00"
                self.isTimerRunning2 = false
                self.timer2.invalidate()
            }
        }
    }
}


extension MyRequests: CLLocationManagerDelegate, GMSMapViewDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        currentLocation = locations.last
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        
        
        
        // Add the map to the view, hide it until we've got a location update.
        self.mapView.camera = camera
        self.mapView.delegate = self
        self.mapView?.isMyLocationEnabled = true
        self.mapView.settings.myLocationButton = true
        self.mapView.settings.compassButton = true
        self.mapView.settings.zoomGestures = true

    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.mapView.isMyLocationEnabled = true
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        self.mapView.isMyLocationEnabled = true
        
        if (gesture) {
            mapView.selectedMarker = nil
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.mapView.isMyLocationEnabled = true
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("COORDINATE \(coordinate)") // when you tapped coordinate
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        self.mapView.isMyLocationEnabled = true
        self.mapView.selectedMarker = nil
        return false
    }
}
