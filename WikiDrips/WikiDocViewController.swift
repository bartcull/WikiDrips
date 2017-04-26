//
//  WikiDocViewController.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/21/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import UIKit
import WebKit

class WikiDocViewController: UIViewController, WKUIDelegate {

    fileprivate var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private var webView: WKWebView?
    var searchText: String?

    // MARK: - View Controller Lifecycle
    
    override func loadView() {
        super.loadView()
        
        webView = WKWebView(frame: view.frame, configuration: WKWebViewConfiguration())
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
        if let webview = webView {
            view.addSubview(webview)
        }
        
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let searchText = searchText, let request = docRequest(title: searchText) {
            webView?.load(request)
        }
    }
    
    // MARK: - Prep Request
    
    private func docRequest(title: String) -> URLRequest? {
        var endpoint = URLComponents()
        endpoint.scheme = "http"
        endpoint.host = "en.wikipedia.org"
        endpoint.path = "/wiki/\(title)"

        guard let url = endpoint.url else {
            print("Error: cannot create document URL")
            return nil
        }
        
        return URLRequest(url: url)
    }


}

extension WikiDocViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Log an error for didFail")
        activityIndicator.stopAnimating()
    }
}
