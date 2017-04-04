//
//  WikiDoc.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/3/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import Foundation

public class WikiDoc
{
    public let title = "Test Title String"
    public let pubDate = Date.init()
    public var imageInitials: String {
        get {
            let nameArray = self.title.components(separatedBy: " ")
            return "\(nameArray.first?.characters.first!)\(nameArray.last?.characters.first!)"
        }
    }
    
    public func editedDate() -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("h:mm a., EEEE, MMMM dd, yyyy")
        return formatter.string(from: pubDate)
    }
}

