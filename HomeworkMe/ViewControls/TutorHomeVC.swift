//
//  TutorHomeVC.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 11/8/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit

import GooglePlaces

class TutorHomeVC: UIViewController {
    
    
    
    var dayArray = [String](); var hourArr = [String](); var minArr = [String](); var amArr = [String]()
    
    var schedule = String()
    var chosenLocationsArr = [String]() ; var day = "Sunday"; var hour = "12"; var min = "00"; var am = "Am"
    var place = Place()
    var placeArr = [Place](); var placeesDict = [String:[String]]()
    var schedules = [String]()
    var student = Student()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func FirstDrag(_ sender: UIScreenEdgePanGestureRecognizer) {
        let card = sender.view!
        let point = sender.translation(in: view)
        card.center = CGPoint(x: view.center.x + point.x, y: view.center.y + point.y)
//        if sender.state == UIGestureRecognizerState.ended {
            UIView.animate(withDuration: 0.2) {
//                card.center = self.view.center
                card.frame = CGRect(x: 0, y: 0, width: card.frame.width - 15, height: card.frame.height)
            }
//        }
    }
    
    @IBAction func secondDrag(_ sender: UIScreenEdgePanGestureRecognizer) {
        let card = sender.view!
        let point = sender.translation(in: view)
        // check whether you are draggin left or right
//        let xFromCenter = card.center.x - view.center.x
        
        card.center = CGPoint(x: view.center.x + point.x, y: view.center.y + point.y)
        UIView.animate(withDuration: 0.2) {
            //                card.center = self.view.center
            card.frame = CGRect(x: 0, y: 0, width: card.frame.width - 25, height: card.frame.height)
        }
    }
    
    func setUpSchdArr(){
        schedule = "Sundays 12:00 am"
        dayArray = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        hourArr = ["12","1","2","3","4","5","6","7","8","9","10","11"]
        minArr = ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59"]
        amArr = ["Am","Pm"]
    }
}


extension TutorHomeVC: GMSAutocompleteViewControllerDelegate {
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        self.place.name = place.name
        self.place.long = "\(place.coordinate.longitude)"
        self.place.lat = "\(place.coordinate.latitude)"
        self.placeArr.append(self.place)
        let arr = ["\(place.coordinate.latitude)", "\(place.coordinate.longitude)", place.name, "\(place.formattedAddress ?? "")"]
        placeesDict["\(place.placeID)"] = arr
        
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
