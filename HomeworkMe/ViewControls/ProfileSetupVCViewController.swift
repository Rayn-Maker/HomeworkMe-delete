//
//  ProfileSetupVCViewController.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 11/7/18.
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

class ProfileSetupVCViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GIDSignInUIDelegate, UNUserNotificationCenterDelegate   {
    
    //// have three table views one for university, SUbjects then Classes.
    @IBOutlet weak var classRoomTableView: UITableView!
    @IBOutlet weak var universityTableView: UITableView!
    @IBOutlet weak var subjectsTableView: UITableView!
    
    
    //have three buttons to switch from page to page
     @IBOutlet weak var button1: UIButton!
     @IBOutlet weak var button2: UIButton!
     @IBOutlet weak var button3: UIButton!
    
    
    // objects
    var universityArray = [FetchObject](); var subArray = [FetchObject](); var classArray = [FetchObject]()
    
    // screen number
    var screen = 0

    override func viewDidLoad() {
        super.viewDidLoad()
//        swipeGesture()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func uniPanGest(_ sender: UIPanGestureRecognizer) {
        let card = sender.view!
        let point = sender.translation(in: view)
        // check whether you are draggin left or right
        let xFromCenter = card.center.x - view.center.x
        
        card.center = CGPoint(x: view.center.x + point.x, y: view.center.y + point.y)
//
//        if xFromCenter > 0 {
//            // card is being dragged to the right.
//        } else {
//            // card is being dragged to the left.
//        }
//
////        universityTableView.alpha = abs(xFromCenter) / view.center.x
//
//        if sender.state == UIGestureRecognizerState.ended {
//
//            if card.center.x < 75 {
//                // move off to the left side
//                UIView.animate(withDuration: 0.3) {
////                    card.center = CGPoint(x: card.center.x - 37, y: card.center.y)
//                    card.frame = CGRect(x: 0, y: 0, width: card.frame.width, height: card.frame.height)
//                }
//                return
//            } else if card.center.x > (view.frame.width - 75) {
//                //move off to the rigth side.
//                UIView.animate(withDuration: 0.3) {
//                    card.frame = CGRect(x: 0, y: 0, width: card.frame.width, height: card.frame.height)
//
////                    card.center = CGPoint(x: card.center.x + 37, y: card.center.y)
//                }
//                return
//            }
//
//            UIView.animate(withDuration: 0.2) {
//                card.center = self.view.center
//                self.universityTableView.alpha = 1
//            }
//        }
    }
    
    @IBAction func subPanGest(_ sender: UIPanGestureRecognizer) {
        let card = sender.view!
        let point = sender.translation(in: view)
        card.center = CGPoint(x: view.center.x + point.x, y: view.center.y + point.y)
        if sender.state == UIGestureRecognizerState.ended {
            UIView.animate(withDuration: 0.2) {
                card.center = self.view.center
            }
        }
    }
    
    @IBAction func classPanGest(_ sender: UIPanGestureRecognizer) {
        let card = sender.view!
        let point = sender.translation(in: view)
        card.center = CGPoint(x: view.center.x + point.x, y: view.center.y + point.y)
        
        if sender.state == UIGestureRecognizerState.ended {
            UIView.animate(withDuration: 0.2) {
                card.center = self.view.center
            }
        }
    }

    
    func showDiffView(bool:Bool){
        self.universityTableView.isHidden = bool
        self.subjectsTableView.isHidden = bool
        self.classRoomTableView.isHidden = bool
    }
    
    func swipeGesture(){
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == UISwipeGestureRecognizerDirection.right {
            if screen >= 1 && screen < 3{
                UIView.animate(withDuration: 0.5) {
                    print("Swipe Right")
                    self.screen -= 1
                    self.displayToView(index: self.screen)
                }
            }
        }
        else if gesture.direction == UISwipeGestureRecognizerDirection.left {
            
            if screen >= 0 && screen < 2{
                UIView.animate(withDuration: 0.5) {
                    print("Swipe Left")
                    self.screen += 1
                    self.displayToView(index: self.screen)
                }
            }
        }
        else if gesture.direction == UISwipeGestureRecognizerDirection.up {
            print("Swipe Up")
        }
        else if gesture.direction == UISwipeGestureRecognizerDirection.down {
            print("Swipe Down")
        }
    }
    
    func displayToView(index:Int){
        if index == 0 {
            UIView.animate(withDuration: 0.5) {
                self.universityTableView.isHidden = false
                self.subjectsTableView.isHidden = true
                self.classRoomTableView.isHidden = true
            }
        }
        if index == 1 {
            UIView.animate(withDuration: 0.5) {
                self.universityTableView.isHidden = true
                self.subjectsTableView.isHidden = false
                self.classRoomTableView.isHidden = true
            }
        }
        if index == 2 {
            UIView.animate(withDuration: 0.5) {
                self.universityTableView.isHidden = true
                self.subjectsTableView.isHidden = true
                self.classRoomTableView.isHidden = false
            }
        }
    }
}

extension ProfileSetupVCViewController: PaperOnboardingDataSource, PaperOnboardingDelegate {
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
        if index == 0 {
            UIView.animate(withDuration: 0.02) {
                self.universityTableView.isHidden = false
                self.subjectsTableView.isHidden = true
                self.classRoomTableView.isHidden = true
            }
        }
        if index == 1 {
            UIView.animate(withDuration: 0.02) {
                self.universityTableView.isHidden = true
                self.subjectsTableView.isHidden = false
                self.classRoomTableView.isHidden = true
            }
        }
        if index == 2 {
            UIView.animate(withDuration: 0.02) {
                self.universityTableView.isHidden = true
                self.subjectsTableView.isHidden = true
                self.classRoomTableView.isHidden = false
            }
        }
    }
    
    func onboardingDidTransitonToIndex(_ index: Int) {
        if index == 5 {
            UIView.animate(withDuration: 0.4) {
//                self.getStarted.alpha = 1
            }
        }
    }
    
    func onboardingItemsCount() -> Int {
        return 6
    }
}


extension ProfileSetupVCViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == classRoomTableView {
           
        } else if tableView == subjectsTableView{
            
        } else if tableView == universityTableView {
            
        }
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if tableView == myClassesTableView {
//            if (editingStyle == UITableViewCellEditingStyle.delete) {
//                deletValue(indexPathRow: indexPath.row)
//
//                myClassesArr.remove(at: indexPath.row)
//                myClassesTableView.deleteRows(at: [indexPath], with: .fade)
//
//            }
//        }
//
//
//        if tableView == meetUpLocationsTable {
//            if (editingStyle == UITableViewCellEditingStyle.delete) {
//                placeArr.remove(at: indexPath.row)
//                meetUpLocationsTable.deleteRows(at: [indexPath], with: .fade)
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == classRoomTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "classRoomCells", for: indexPath)
            cell.textLabel!.text = universityArray[indexPath.row].title
            cell.textLabel?.numberOfLines = 0
            if universityArray.contains(where: { $0.uid == universityArray[indexPath.row].uid }) {
                // print a statement saying class already added
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        }  else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myClasses", for: indexPath)
            cell.textLabel!.text = universityArray[indexPath.row].title
            return cell
        }
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == classRoomTableView {
            return universityArray.count
        } else if tableView == subjectsTableView {
            return universityArray.count
        } else if tableView == universityTableView {
            return universityArray.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == classRoomTableView {
           return "Select All Classes"
        }
        if tableView == subjectsTableView {
            return "Select All Subjects"
        }
        if tableView == universityTableView {
            return "Select All Universities"
        } else {
            return ""
        }
    }
    
    
}
