//
//  Localizer.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/4/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//


import Foundation

private class Localizer {
    
    static let sharedInstance = Localizer()
    
    lazy var localizableDictionary: NSDictionary! = {
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "plist") {
            return NSDictionary(contentsOfFile: path)
        }
        fatalError("Localizable file NOT found")
    }()
    
    func localize(string: String) -> String {
        guard let localizedString = (localizableDictionary.value(forKey: string) as AnyObject).value(forKey: "value") as? String else {
            assertionFailure("Missing translation for: \(string)")
            return ""
        }
        return localizedString
    }
}

extension String {
    var localized: String {
        return Localizer.sharedInstance.localize(string: self)
    }
}
