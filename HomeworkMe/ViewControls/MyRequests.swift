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
    
    
    var tutor = Student()
    var student = Student()
    var functions = CommonFunctions()
    var userStorage: StorageReference!
    var request: Request!
    let ref = Database.database().reference()
    var displayingTutReqview = true
    var handle: DatabaseHandle?
    var handle2: DatabaseHandle?
    var isTutor = true
    var locationGoingTo = Place()
    var notificationRepeats = true
    private var notTimer = Timer()
    
// google map setup
    var place = Place()
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    var seconds = 1200
    var timer = Timer()
    var isTimerRunning = false
    var isGrantedAccess = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let istutor = UserDefaults.standard.bool(forKey: "isTutorApproved") as? Bool {
            isTutor = istutor
        } else {
            isTutor = false
        }
        if isTutor {
            displayingTutReqview = true
            tutorReqView.isHidden = true
        }
        tutorReqTable.estimatedRowHeight = 45
        tutorReqTable.rowHeight = UITableViewAutomaticDimension
        myRequestsTable.estimatedRowHeight = 45
        myRequestsTable.rowHeight = UITableViewAutomaticDimension
        let storage = Storage.storage().reference(forURL: "gs://hmwrkme.appspot.com")
        userStorage = storage.child("Students")
        googleMapsetup()
        fetchStudent()
        editImage()
        startTimer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        isTimerRunning = false
//        stopTimer()
        let parameter2: [String:AnyObject] = ["newNotice":false as AnyObject]
        
        self.ref.child("Students").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(parameter2)
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
        // remove profile from request cup and put it in jobs cup
        // check status of tutor
        // start timer for 20 mins
        let dateString = String(describing: Date())
        
//        let fdate = Date()/
        var calendar = Calendar.current

//
//        TimeZone.ReferenceType.default = TimeZone(abbreviation: "CDT")!
        let formatter = DateFormatter()
//        formatter.timeZone = TimeZone.ReferenceType.default
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
        formatter.calendar.date(byAdding: .minute, value: 20, to: Date())
        let strDate = formatter.string(from: Date())
        let datesss = calendar.date(byAdding: .minute, value: 20, to: formatter.date(from: strDate)!)
        let y = formatter.string(from: datesss!)
        let parameter2: [String:String] = ["newNotice":"true" ,
                                              "endTime": y ?? ""]
        
        if self.tutor.tutorStatus == "live" {
            let par = ["time": dateString as AnyObject,
                       "status":"approved",
                       "currLocationCoord": "\(self.request.place.lat ?? "") \(self.request.place.long ?? "")",
                "currLocationName":self.request.place.name] as! [String: Any]
            
        self.ref.child("Students").child(request.senderId ?? "").updateChildValues(parameter2)
        self.ref.child("Students").child(request.receiverId ?? "").updateChildValues(parameter2)
        self.ref.child("Students").child(request.senderId ?? "").child("sent").child(request.reqID).updateChildValues(par)
        self.ref.child("Students").child(request.receiverId ?? "").child("received").child(request.reqID).updateChildValues(par)
            
        let para = ["status":"hot"] as! [String: Any]
            
//            requestersView.isHidden = true
//            drawPath(start: currentLocation!, end: request.place)
//            mapViewDisplay.isHidden = false
            setupPushNotification(fromDevice: request.senderDevice)
        } else if self.tutor.tutorStatus == "hot" {
            let par = ["time": dateString as AnyObject,
                       "status":"approved"] as [String : Any]
            
            self.ref.child("Students").child(request.senderId ?? "").updateChildValues(parameter2)
            self.ref.child("Students").child(request.senderId ?? "").child("sent").child(request.reqID).updateChildValues(par)
            setupPushNotification(fromDevice: request.senderDevice)
        } else if self.tutor.tutorStatus == "off" {
            // a callendar should be shown when cell is clicked on.
            setupPushNotification(fromDevice: request.senderDevice)
        }
    }
    
    @IBAction func callPrsd(_ sender: Any) {
        
       self.request.phoneNumber = self.request.phoneNumber.replacingOccurrences(of: "-", with: "")
       self.request.phoneNumber = self.request.phoneNumber.replacingOccurrences(of: " ", with: "")
       self.request.phoneNumber = self.request.phoneNumber.replacingOccurrences(of: ")", with: "")
       self.request.phoneNumber = self.request.phoneNumber.replacingOccurrences(of: "(", with: "")
       self.request.phoneNumber = self.request.phoneNumber.replacingOccurrences(of: "+", with: "")
        
        if self.request.phoneNumber.count > 10 {
            self.request.phoneNumber.remove(at: self.request.phoneNumber.startIndex)
        }
        if self.request.phoneNumber.count > 10 {
           self.request.phoneNumber.remove(at: self.request.phoneNumber.startIndex)
        }
        
        if self.request.phoneNumber.count > 10 {
            String(self.request.phoneNumber.characters.dropLast())
        }
        let dd =  (self.request.phoneNumber as NSString).integerValue
        
        guard let number = URL(string: "tel://" + "\(dd ?? 8888888888)") else {
            
        
            return }
        UIApplication.shared.open(number)
    }
    
    @IBAction func txtMsg(_ sender: Any) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = ""
            controller.recipients = [self.request.phoneNumber]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
     @IBAction func cancelTutor(_ sender: Any) {
        //change the tag with an api call.
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MyRequests.updateTimer)), userInfo: nil, repeats: true)
        isTimerRunning = true
    }
    
    @objc func updateTimer() {
        if seconds < 1 {
            timer.invalidate()
            //Send alert to indicate "time's up!"
        } else {
            seconds -= 1     //This will decrement(count down)the seconds.
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }
        
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
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
                    self.tutor = self.setUpReqArr(tableArr: self.tutor, object: json, table: self.myRequestsTable)
                }
                if let json = tutDict["sent"] as? [String:AnyObject] {
//                    self.student.receivedObject = json
                    self.student = self.setUpReqArr(tableArr: self.student, object: json, table: self.tutorReqTable)
                }
                if let scdul = tutDict["appointMents"] as? [String] {
                    self.tutor.schedule = scdul
                }
                if let posts = tutDict["Posts"] as? [String:AnyObject] {
                    self.tutor.posts2 = posts
                } //endTime:
                if let tmStmp = tutDict["endTime"] as? String {
//
//                    let dateFormatter = DateFormatter()
//                    var calendar = Calendar.current
//                    calendar.timeZone = TimeZone.ReferenceType.default
//                    dateFormatter.timeZone = TimeZone(abbreviation: "CDT")
//                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//
//                    let dat = dateFormatter.date(from: tmStmp )
//                    let x = calendar.dateComponents(in: TimeZone.current, from: dat!)
//                    let k = self.UTCToLocal(date: tmStmp)
//                    calendar.date(from: x)
//                    self.tutor.endTime = dat ?? Date()
//                    let date = Date()
//
//                    print("\(date.timeIntervalSince(dat ?? Date()))")
                    
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
                            self.runTimer()
                        }
                    } else {
                        print(k); print(dat!)
                        self.isTimerRunning = false
                        self.timer.invalidate()
                    }
                }
                if let newNotice = tutDict["newNotice"] as? Bool {
                    if newNotice {
                        self.startTimer()
                    }
                }
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
//
//    func UTCToLocal(date:String) -> Date {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//
//        let dt = dateFormatter.date(from: date)
////        dateFormatter.timeZone = TimeZone.current
////        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//
//        return  dt!
//    }
    
    func connectProfile(req: Request, tutStat:String, isRequest:Bool, meetUplocationMesg:String) {
        if !isRequest{
            cancelTutor.isHidden = false
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
            cancelTutor.isHidden = true
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
    
    func editImage(){
        image.layer.borderWidth = 1
        image.layer.masksToBounds = false
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.cornerRadius = image.frame.height/2
        image.clipsToBounds = true
    }
    
    func setUpReqArr (tableArr: Student, object:[String : AnyObject], table:UITableView) -> Student {
        var req = Request()
        tableArr.requestsArrRejected.removeAll()
        tableArr.requestsArrAccepted.removeAll()
        tableArr.requestsArrPending.removeAll()
        for (_,b) in object {
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
            req.receiverPicUrl = b["receiverPic"] as? String
            req.reqStatus = b["status"] as? String
            if let place = b["place"] as? [String:AnyObject] {
                 req.place.address = place["address"] as? String
                req.place.lat = place["lat"] as? String
                req.place.long = place["long"] as? String
                req.place.name = place["name"] as? String
            }
            if req.reqStatus == "pending" {
                tableArr.requestsArrPending.append(req)
            } else if req.reqStatus == "approved" {
                tableArr.requestsArrAccepted.append(req)
                self.notificationRepeats = true
            } else if req.reqStatus == "rejected"{
                tableArr.requestsArrRejected.append(req)
            }
            
        }
        table.reloadData()
        return tableArr
    }
    
    fileprivate func setupPushNotification(fromDevice:String)
    {
        //        guard let message = "text.text" else {return}
        let title = "tech build dreams"
        let body = "message"
        let toDeviceID = fromDevice
        var headers:HTTPHeaders = HTTPHeaders()
        
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.SERVERKEY)"
            
        ]
        let notification = ["to":"\(toDeviceID)","notification":["body":body,"title":title,"badge":1,"sound":"default"]] as [String:Any]
        
        Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
        }
        
    }
    
    func notify() {
        if isGrantedAccess{
            let content = UNMutableNotificationContent()
            content.title = "HmwkMe"
            content.subtitle = ""
            content.body = ""
            content.badge = 1
//            content.sound = UNNotificationSound.default()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.001, repeats: false)
            
            let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (err) in
                //
                self.notificationRepeats = false
//                self.stopTimer()
            }
            
            let systemSoundId: SystemSoundID = 1016
            AudioServicesPlaySystemSound(systemSoundId)
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //
    }
  
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func startTimer(){
        let timeInterval = 2.0
        if isGrantedAccess && !timer.isValid { //allowed notification and timer off
            timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (timer) in
                self.notify()
            })
        }
    }
    
    func stopTimer(){
        //shut down timer
        timer.invalidate()
        //clear out any pending and delivered notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func downlaodPic(url:String) {
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
                cell.textLabel?.text = "\( tutor.requestsArrPending[indexPath.row].senderName ?? "")\n\(tutor.requestsArrPending[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = tutor.requestsArrPending[indexPath.row].postTite
                return cell
            } else if indexPath.section == 1 {
                
                cell.textLabel?.text = "\( tutor.requestsArrAccepted[indexPath.row].senderName ?? "")\n\(tutor.requestsArrAccepted[indexPath.row].postTite ?? "")"
                cell.detailTextLabel?.text = tutor.requestsArrAccepted[indexPath.row].postTite
                return cell
            } else if indexPath.section == 2 {
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Pending Requests"
        } else if section == 1 {
            return "Accepted Requests"
        } else if section == 2 {
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
            if indexPath.section == 0 {
                request = student.requestsArrPending[indexPath.row]
                connectProfile(req: student.requestsArrPending[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: false, meetUplocationMesg: "Tutor's yet to respond")
                
            } else if indexPath.section == 1 {
                request = student.requestsArrAccepted[indexPath.row]
                connectProfile(req: student.requestsArrAccepted[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: false, meetUplocationMesg:  request.place.name)
                self.place = student.requestsArrAccepted[indexPath.row].place
                self.acceptRejView.isHidden = true
                self.cancelTutor.isHidden = false
            } else if indexPath.section == 2 {
                request = student.requestsArrRejected[indexPath.row]
                connectProfile(req: student.requestsArrRejected[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: false, meetUplocationMesg: "Tutor request was rejected kinldy find another.")
            }
        } else if tableView == myRequestsTable {
            if indexPath.section == 0 {
                request = tutor.requestsArrPending[indexPath.row]
                connectProfile(req: tutor.requestsArrPending[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: true, meetUplocationMesg: "\(request.place.name ?? "")" + "\n" + "\(request.place.address ?? "")")
            } else if indexPath.section == 1 {
                request = tutor.requestsArrAccepted[indexPath.row]
                connectProfile(req: tutor.requestsArrAccepted[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: true, meetUplocationMesg: "\(request.place.name ?? "")" + "\n" + "\(request.place.address ?? "")")
                self.acceptRejView.isHidden = true
                self.cancelTutor.isHidden = false
            } else if indexPath.section == 2 {
                request = tutor.requestsArrRejected[indexPath.row]
                connectProfile(req: tutor.requestsArrRejected[indexPath.row], tutStat: tutor.tutorStatus ?? "", isRequest: true, meetUplocationMesg: "You rejected the request")
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
