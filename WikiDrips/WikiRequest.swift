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
    case dataNotReturned
    case jsonConversionError
    case malformedData
}

extension WikiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .dataNotReturned:
            return NSLocalizedString("Did not receive data.", comment: "Error message when API response returns no data.")
        case .jsonConversionError:
            return NSLocalizedString("Error trying to convert data to JSON.", comment: "Error message when API response can't be converted to JSON.")
        case .malformedData:
            return NSLocalizedString("Response is malformed.", comment: "Error message when API response is missing elements.")
        }
    }
}

public class WikiRequest {

    static let searchLimit = 100
    static let log = OSLog(subsystem: "com.salesforce.WikiDrips", category: "WikiRequest")

    let session = URLSession.shared
    let searchText: String
    let offset: Int
    var task: URLSessionDataTask?
    var isCancelled = false
    
    init?(searchText: String, pageIndex: Int = 0) {
        self.searchText = searchText
        self.offset = (pageIndex * WikiRequest.searchLimit)
    }
    
    public func fetchWikiDocs(handler: @escaping ([WikiDoc]?, Error?) -> Void) {
        guard let urlRequest = urlRequest(searchText: searchText) else { return }
        task = session.dataTask(with: urlRequest) {
            (data, response, error) in

            // make sure request wasn't cancelled
            guard self.isCancelled == false else { return }

            // check for any errors
            guard error == nil else {
                guard let error = error as NSError? else { return }
                var logType = (code: OSLogType.error, description: "Error")
                if error.code == NSURLErrorCancelled {
                    self.isCancelled = true
                    logType.code = .debug
                    logType.description = "Debug"
                }
                os_log("%@: %@", log: WikiRequest.log, type: logType.code, logType.description, error)
                return handler(nil, error)
            }
            // make sure we got data
            guard let data = data else {
                let dataError = WikiError.dataNotReturned as NSError
                os_log("Error: %@", log: WikiRequest.log, type: .error, dataError)
                return handler(nil, dataError)
            }
            // parse the result as JSON
            guard let response = try? JSONSerialization.jsonObject(with: data, options: []) else {
                let conversionError = WikiError.jsonConversionError as NSError
                os_log("Error: %@", log: WikiRequest.log, type: .error, conversionError)
                return handler(nil, conversionError)
            }

            guard let dictionary = response as? [String: Any],
                let query = dictionary["query"] as? [String: Any],
                let results = query["search"] as? [Any] else {
                    let malformedDataError = WikiError.malformedData as NSError
                    os_log("Error: %@", log: WikiRequest.log, type: .error, malformedDataError)
                    return handler(nil, malformedDataError)
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

            handler(wikiDocs, nil)
        }
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
            os_log("Error: cannot create URL for searchText %@.", log: WikiRequest.log, type: .error, searchText)
            return nil
        }

        return URLRequest(url: url)
    }
}
