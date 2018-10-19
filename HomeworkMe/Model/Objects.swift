//
//  Objects.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/1/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseDatabase

class Student {
    var fName: String?
    var lName: String?
    var email: String?
    var password: String?
    var confPassword: String? 
    var school: [String]?
    var classroom: [Classroom]?
    var posts: [Post]?
    var profilepic: Data?
    var billing: Billing?
    var postedPosts: [Post]?
    var uid: String?
    var phoneNumebr: String?
    var posts2: [String: AnyObject]?
    var studentProfile: [String: AnyObject]?
    var full_name: String?
    var tutorApproved: Bool?
    var customerId: String?
    var tutorStatus: String?
    var ratings: String?
    var comments: Note?
    var pictureUrl: String!
    var classification: String!
    var meetUpLocation = [String:[String]]()
    var schedule: [String]!
    var major: String!
    var schoolEmail:String!
    var places = [Place]()
    var requestsArrPending = [Request]()
    var requestsArrAccepted = [Request]()
    var requestsArrRejected = [Request]()
    var requestsArrHistory = [Request]()
    var requestsSentPending = [Request]()
    var requestsSentApprd = [Request]()
    var requestsSentReject = [Request]()
    var request = Request()
    var sentObject = [String:AnyObject]()
    var receivedObject = [String:AnyObject]()
    var coorLocCoord = String()
    var coorLocName = String()
    var deviceId = String()
    var endTime = Date()
    var paymentSource: [String]?
    var hasCard = Bool()
    var currLoc = Place()
}

enum Location {
    case startLocation
    case destinationLocation
}

class Classroom {
    var university: String?
    var subject: Subject?
    var students: [Student]?
    var teacher: String?
    var title: String?
    var createdBy: String?
    var uid: String?
}

class Request {
    var place = Place()
    var reqID: String!
    var senderName: String!
    var receiverName: String!
    var senderId: String!
    var receiverId: String!
    var time: Date!
    var timeString: String!
    var postTite: String!
    var senderPhone: String!
    var receiverPhone: String!
    var senderPicUrl: String!
    var receiverPicUrl: String!
    var reqStatus: String!
    var phoneNumber: String!
    var senderDevice: String!
    var recieverDevice: String!
    var sessionDidStart = false
    var endTimeStrn: String!
    var endTimeDte: Date!
    var endTimeToMeet: String!
    var endTimeToMeetDate: Date!
    var senderCustomerId:String!
    var receiverCustomerId:String!
    var sessionPrice:Int!
    var receiverPayment: [String]!
}

class Post {
    var classs: Classroom?
    var publisher: Student?
    var subject: Subject?
    var title: String?
    var seller: Student?
    var buyer: Student?
    var file: File?
    var timeStamp: Date?
    var uid: String?
    var category:String?
    var authorName: String?
    var authorEmail: String!
    var authorID: String?
    var price: Int!
    var data: Data!
    var postPic: String!
    var studentInClas: Bool!
    var schedule = [String]()
    var likers = [String]()
    var disLikers = [String]()
    var notes = [Note]()
    var noteDict = [String:String]()
    var phoneNumber = String()
}

struct Place {
    var name: String!
    var long: String!
    var lat: String!
    var address: String!
}


struct File {
    var title: String?
    var data: Data?
    var post: Post?
    
}

struct Note {
    var note: String!
    var time: String!
    var author: String!
    var key: String!
}

struct Billing {
    var creditCardNumber: Int?
    var creditCardExpr: Date?
    var creditCardPin: Int?
    var nameOnCreditCard: String?
    var zip: Int?
    var cash_zelle: String?
}

struct Subject {
    var title:String? 
    var classrooms: [Classroom]?
    var uid: String?
}

struct University {
    var title:String?
    var subjects: [Subject]?
    var uid: String?
}

struct FetchObject {
    var title: String?
    var uid: String?
    var dict: [String:AnyObject]?
    var subjectID: String?
    var subName:String!
    var uniID: String?
    var uniName: String?
    var notificationKey: String!
    var notificationKeyName: String!
}

struct Reciept {
    var post: Post?
    var billing: Billing?
    var date: Date?
    var uid: String?
    var buyer: Student?
    var seller: Student?
    var zelle_cash: String?
}

class CommonFunctions {
    var ref: DatabaseReference?
    var handle: DatabaseHandle?
    var handle2: DatabaseHandle?
    
    func alertWithOk(errorMessagTitle:String, errorMessage:String) ->UIAlertController {
        let alert = UIAlertController(title: errorMessagTitle, message: errorMessage, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        return alert
    }
    
    func addToDirecotory(key:String, title:String, message:String, subKey:String, uniName:String, foldername:String, universityKey:String = " ", subjectKey:String = " " ) -> UIAlertController {
        let ref = Database.database().reference()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter name here"
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let post = UIAlertAction(title: "Create", style: .default) { _ in
            guard let text = alert.textFields?.first?.text else { return }
            if text != "" {
                print(text)
                
                if foldername == "Universities" {
                let parameters = ["uid" : key,
                                  "name" : text]
                
                let university = ["\(key)" : parameters]
                ref.child(foldername).updateChildValues(university)
                }
                if foldername == "Subjects" {
                    let parameters = ["uid": key,
                                      "name" : text,
                                      "uniName":uniName,
                                      "uniId":universityKey]
                    let subject = ["\(key)": parameters]
                    let uniSection = [key:key]
                    ref.child(foldername).updateChildValues(subject)
                    ref.child("Universities").child(universityKey).child("Subjects").updateChildValues(uniSection)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(post)
        return alert
    }
    
    func fetch(folderName:String, success successBlock: @escaping () -> ([University])) {
        var universitiesArray  = [University]() 
        let ref = Database.database().reference()
        ref.child(folderName).queryOrderedByKey().observeSingleEvent(of: .value, with: { response in
            if response.value is NSNull {
                
                /// dont do anything
            } else {
                let universities = response.value as! [String:AnyObject]
                for (_,b) in universities {
                    var university = University()
                    if let uid = b["uid"] {
                        university.uid = uid as? String
                    }
                    if let title = b["name"] {
                        university.title = title as? String
                    }
                    universitiesArray.append(university)
                }
            }
        })
    }
    
    func getTimeSince(date:Date) -> String {
        var calendar = NSCalendar.autoupdatingCurrent
        calendar.timeZone = NSTimeZone.system
        let components = calendar.dateComponents([ .month, .day, .minute, .hour, .second ], from: date, to: Date())
        //        let months = components.month
        let days = components.day
        let hours = components.hour
        let minutes = components.minute
        let secs = components.second
        var time:Int = days!; var measur:String = "Days ago"
        
        if days == 1 {
            measur = "Day ago"
        } else if days! < 1 {
            measur = "hours ago"
            time = hours!
           if hours == 1 {
                measur = "hour ago"
           } else if hours! < 1 {
            measur = "minutes ago"
            time = minutes!
           if minutes == 1 {
            measur = "minute ago"
           } else if minutes! < 1 {
            measur = "seconds ago"
            time = secs!
        }
      }
    }
        return "\(time)\(measur)"
    }
}

extension UIImageView {
    
    func downloadImage(from imgURL: String!) {
        
        let url = URLRequest(url: URL(string: imgURL)!)
        
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                self.image = UIImage(data: data!)
            }
            
        }
        
        task.resume()
    }
}

