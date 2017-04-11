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
    let baseEndpoint: String = "http://en.wikipedia.org/w/api.php?action=query&list=search&srwhat=text&sroffset=0&format=json"
    var wikiDocs = [[WikiDoc]]()
    let searchText: String
    
    init?(searchText: String) {
        self.searchText = searchText
    }
    
    public func fetchWikiDocs(handler: @escaping ([[WikiDoc]]) -> Void) {
        guard let urlRequest = urlRequest(searchText: searchText) else {
            return
        }
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on \(self.baseEndpoint)")
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
                if let dictionary = response as? [String: Any] {
                    if let query = dictionary["query"] as? [String: Any] {
                        if let results = query["search"] as? [Any] {
                            for item in results {
                                guard let item = item as? [String: Any] else {
                                    break
                                }
                                if let wikiDoc = WikiDoc(data: item) {
                                    self.wikiDocs.insert([wikiDoc], at: 0)
                                }
                            }
                        }
                    }
                }
                handler(self.wikiDocs)
            }
        }
        task.resume()
    }
    
    private func urlRequest(searchText: String) -> URLRequest? {
        let endpoint: String = "\(baseEndpoint)&srsearch=\(searchText)"
        guard let url = URL(string: endpoint) else {
            print("Error: cannot create URL")
            return nil
        }
        return URLRequest(url: url)
    }
}
