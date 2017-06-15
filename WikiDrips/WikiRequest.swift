//
//  WikiRequest.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/3/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import Foundation
import os.log

enum WikiError: Error {
    case networkError
    case dataNotReturned
    case jsonConversionError
}

extension WikiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .dataNotReturned:
            return NSLocalizedString("Did not receive data.", comment: "Error message when API response returns no data.")
        case .jsonConversionError:
            return NSLocalizedString("Error trying to convert data to JSON.", comment: "Error message when API response can't be converted to JSON.")
        default:
            return NSLocalizedString("An unknown error occurred.", comment: "Default error message.")
        }
    }
}

public class WikiRequest {

    static let searchLimit = 100
    static let rq_log = OSLog(subsystem: "com.salesforce.WikiDrips", category: "WikiRequest")

    let session = URLSession.shared
    let searchText: String
    let offset: Int
    var task: URLSessionDataTask?
    var isCancelled = false
    
    init?(searchText: String, pageIndex: Int = 0) {
        self.searchText = searchText
        self.offset = (pageIndex * WikiRequest.searchLimit)
    }
    
    public func fetchWikiDocs(handlerForDocsOrError: @escaping ([WikiDoc], Error?) -> Void) {
        guard let urlRequest = urlRequest(searchText: searchText) else { return }
        var wikiDocs = [WikiDoc]()
        var request_error: Error?
        task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // make sure request wasn't cancelled
            guard self.isCancelled == false else { return }
            
            // check for any errors
            guard error == nil else {
                request_error = error
                guard let error = error as NSError? else { return }
                var log_type = (code: OSLogType.error, description: "Error")
                if error.code == NSURLErrorCancelled {
                    self.isCancelled = true
                    log_type.code = .debug
                    log_type.description = "Debug"
                }
                os_log("%@: %@", log: WikiRequest.rq_log, type: log_type.code, log_type.description, error)
                handlerForDocsOrError(wikiDocs, request_error)
                return
            }
            // make sure we got data
            guard let data = data else {
                request_error = WikiError.dataNotReturned
                guard let error = request_error as NSError? else { return }
                os_log("Error: %@", log: WikiRequest.rq_log, type: .error, error)
                handlerForDocsOrError(wikiDocs, request_error)
                return
            }
            // parse the result as JSON
            do {
                guard let response = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    request_error = WikiError.jsonConversionError
                    guard let error = request_error as NSError? else { return }
                    os_log("Error: %@", log: WikiRequest.rq_log, type: .error, error)
                    handlerForDocsOrError(wikiDocs, request_error)
                    return
                }
                
                guard let dictionary = response as? [String: Any],
                    let query = dictionary["query"] as? [String: Any],
                    let results = query["search"] as? [Any] else {
                    return
                }

                let isoDateFormatter = ISO8601DateFormatter()

                wikiDocs = results.flatMap {
                    guard let item = $0 as? [String: Any],
                        let title = item["title"] as? String,
                        let isoDate = item["timestamp"] as? String,
                        let date = isoDateFormatter.date(from: isoDate) else {
                        return nil
                    }
                    return WikiDoc(title: title, date: date, image: nil)
                }
                handlerForDocsOrError(wikiDocs, request_error)
            }
        }
//        return (wikiDocs, request_error)
    }
    
    public func cancel() {
        task?.cancel()
        isCancelled = true
    }
    
    private func urlRequest(searchText: String) -> URLRequest? {
        var endpoint = URLComponents()
        endpoint.scheme = "http"
        endpoint.host = "en.wikipedia.org"
        endpoint.path = "/w/api.php"
        endpoint.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "srwhat", value: "text"),
            URLQueryItem(name: "srlimit", value: "\(WikiRequest.searchLimit)"),
            URLQueryItem(name: "sroffset", value: "\(offset)"),
            URLQueryItem(name: "srsearch", value: searchText),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = endpoint.url else {
            os_log("Error: cannot create URL for searchText %@.", log: WikiRequest.rq_log, type: .error, searchText)
            return nil
        }

        return URLRequest(url: url)
    }
}
