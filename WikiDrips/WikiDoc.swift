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
    public let title: String
    public let pubDate: Date
    public var imageInitials: String {
        get {
            let nameArray = self.title.components(separatedBy: " ")
            var initials = ""
            
            if let firstWord = nameArray.first {
                if let firstInitial = firstWord.characters.first {
                    initials = "\(firstInitial)"
                }
            }
            
            if nameArray.count > 1 {
                if let lastWord = nameArray.last {
                    if let lastInitial = lastWord.characters.first {
                        initials += "\(lastInitial)"
                    }
                }
            }
            
            return initials
        }
    }
    
    init? (data: NSDictionary?) {
        
//      Make sure properties are set
        title = "defaultTitle".localized
        pubDate = Date()
    }
    
}

