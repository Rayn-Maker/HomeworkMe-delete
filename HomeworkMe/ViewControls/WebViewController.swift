//
//  WebViewController.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 10/3/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: WKWebView!
    let urlStr = Constants.stripOauthUrl
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        if let url = NSURL(string: Constants.stripOauthUrl) {
//            let settingsUrl = url
//            UIApplication.shared.open(settingsUrl as URL, options: [:], completionHandler: nil)
//        }
        
//        let url = URL(string:Constants.stripOauthUrl)
//        let request = URLRequest(url: url!)
//        webView.load(request)
        
        assert(urlStr != "", "You must set your stripe callback url at the top of ViewController.swift to run this app.")
        
        setupViews()
    }
    
    func setupViews(){
        
        view.addSubview(connectBtn)
        view.addSubview(webview)
        
        connectBtn.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        connectBtn.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        connectBtn.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        connectBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        
        webview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webview.delegate = self
        webview.isHidden = true
        
        connectBtn.addTarget(self, action: #selector(onConnect), for: .touchUpInside)
        
    }
    
//    override func loadView() {
//        webView.navigationDelegate = self
//        view = webView
//    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //
    }
    
//    func webViewDidFinishLoad(webView: UIWebView) {
//        if let request = webView.request {
//            if let resp = URLCache.shared.cachedResponse(for: request) {
//                if let response = resp.response as? HTTPURLResponse {
//                    print(response.allHeaderFields)
//                }
//            }
//        }
//        let headers = webView.request?.allHTTPHeaderFields
//        for (key,value) in headers! {
//            print("key \(key) value \(value)")
//        }
//    }
    
    
    let webview:UIWebView = {
        let wbv = UIWebView()
        wbv.translatesAutoresizingMaskIntoConstraints = false
        wbv.backgroundColor = .white
        return wbv
    }()
    
    let connectBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Connect Stripe", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    func webViewDidFinishLoad(_ webView: UIWebView) { //document.body.outerHTML   //document.getElementById('json').innerHTML
//        progressHUD.dismiss()
        if let response = webView.stringByEvaluatingJavaScript(from: "document.body.outerHTML"){
            print("JSON Response: \(response)")
            
            do {
                
                if let data = response.data(using: .utf8), let json = try( JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: AnyObject] {
                    
                    if let error = json["error"] as? String, let errorDiscription =  json["error_description"] as? String{
                        print("\(errorDiscription)")
                        closeWebView()
                        
                        let alert = UIAlertController(title: error, message: errorDiscription, preferredStyle: .alert)
                        
                        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(okAction)
                        
                        present(alert, animated: true, completion: nil)
                        return
                    }
                    if let stripe_user_id = json["stripe_user_id"]{
                        print("\(stripe_user_id)")
                        closeWebView()
                        storeAccountDetail(json)
                        return
                    }
                }
                
                
            } catch(let ex) {
                print("\(ex)")
            }
            
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
//        progressHUD.show(in: view)
    }
    
    func closeWebView(){
        webview.isHidden = true
    }
    
    func storeAccountDetail(_ json: [String: AnyObject]) {
        // Write down your code here to store stripe_user_id and and access token to server
        
        if let stripe_user_id = json["stripe_user_id"] as? String{
            print("\(stripe_user_id)")
            let alert = UIAlertController(title: "Success", message: "Stripe Account Id \(stripe_user_id)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            
            
            return
        }
        
        
    }
    
    @objc func onConnect(_ sender: Any){
        webview.isHidden = false
        if let url = URL(string: urlStr) {
            let request = URLRequest(url: url)
            webview.loadRequest(request)
        }
    }

}
