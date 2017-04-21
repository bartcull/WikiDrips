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

    var webView: WKWebView?
    var searchText: String?

    // MARK: - View Controller Lifecycle
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView?.uiDelegate = self
        view = webView
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
