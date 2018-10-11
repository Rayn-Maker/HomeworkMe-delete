/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE. \\\

import Foundation

typealias JSON = [String: Any]

enum Constants {
  static let publishableKey = "pk_live_zElKyvWz0R0pJiEmf42HAcii"
  static let baseURLString = "https://fierce-gorge-75882.herokuapp.com/"
  static let defaultCurrency = "usd"
  static let defaultDescription = "Purchase from Homeworkme iOS"
//  static let stripOauthUrl = "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=ca_DiiKriN3m4MSCxufEyxmo3GY1Mjm9ex1=read_write"
    //https://connect.stripe.com/oauth/authorize?response_type=code&client_id=ca_DiiKx0f3Mun33KUO4P6RJ6evqTHPWWHn&scope=read_write
    //"https://connect.stripe.com/express/oauth/authorize?redirect_uri=https://fierce-gorge-75882.herokuapp.com&client_id=ca_DiiKx0f3Mun33KUO4P6RJ6evqTHPWWHn&state=Texas"
  static let stripOauthUrl = "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=ca_DiiKx0f3Mun33KUO4P6RJ6evqTHPWWHn&scope=read_write"
      
//    let customerId = UserDefaults.standard.string(forKey: "customerId")
}
