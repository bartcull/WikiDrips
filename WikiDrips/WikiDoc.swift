//
//  WikiDoc.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/3/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import Foundation

public struct WikiDoc
{
    public let title: String
    public let pubDate: String?
    public var imageInitials: String? {
        get {
            let nameArray = self.title.components(separatedBy: " ")
            var initials: String = ""
            
            if let first = nameArray.first?.characters.first {
                initials.append(first)
            }
            
            if let last = nameArray.last?.characters.first, nameArray.count > 1 {
                initials.append(last)
            }
            
            guard initials.isEmpty == false else {
                return nil
            }
            
            return initials.uppercased()
        }
    }
    
    init? (data: [String: Any]?) {
        guard let title = data?["title"] as? String else { return nil }
        guard let date = data?["timestamp"] as? String else { return nil }

        self.title = title
        self.pubDate = date
    }
    
}

