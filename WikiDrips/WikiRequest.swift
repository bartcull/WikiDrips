//
//  WikiRequest.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/3/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import Foundation

public class WikiRequest
{
    let session = URLSession.shared
    let searchText: String
    
    init?(searchText: String) {
        self.searchText = searchText
    }
    
    public func fetchWikiDocs(successHandler: @escaping ([WikiDoc]) -> Void) -> URLSessionDataTask? {
        guard let urlRequest = urlRequest(searchText: searchText) else {
            return nil
        }
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on \(urlRequest)")
                print(error!)
                return
            }
            // make sure we got data
            guard let data = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON
            do {
                guard let response = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    print("error trying to convert data to JSON")
                    return
                }
                
                guard let dictionary = response as? [String: Any],
                    let query = dictionary["query"] as? [String: Any],
                    let results = query["search"] as? [Any] else {
                    return
                }

                let isoDateFormatter = ISO8601DateFormatter()

                let wikiDocs: [WikiDoc] = results.flatMap {
                    guard let item = $0 as? [String: Any],
                        let title = item["title"] as? String,
                        let isoDate = item["timestamp"] as? String,
                        let date = isoDateFormatter.date(from: isoDate) else {
                        return nil
                    }
                    return WikiDoc(title: title, date: date, image: nil)
                }
                
                successHandler(wikiDocs)
            }
        }
        return task
    }
    
    private func urlRequest(searchText: String, offset: Int = 0) -> URLRequest? {
        var endpoint = URLComponents()
        endpoint.scheme = "http"
        endpoint.host = "en.wikipedia.org"
        endpoint.path = "/w/api.php"
        endpoint.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "srwhat", value: "text"),
            URLQueryItem(name: "sroffset", value: "\(offset)"),
            URLQueryItem(name: "srsearch", value: searchText),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = endpoint.url else {
            print("Error: cannot create URL")
            return nil
        }

        return URLRequest(url: url)
    }
}
