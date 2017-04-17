//
//  ImageGenerator.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/18/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import Foundation
import UIKit
import os.log

class ImageGenerator: Operation {
    static let ig_log = OSLog(subsystem: "com.salesforce.WikiDrips", category: "ImageGenerator")
    let initials: String
    var image: UIImage?
    
    init(initials: String) {
        self.initials = initials
    }
    
    override func main() {
        if isCancelled {
            os_log("Image generation cancelled.", log: ImageGenerator.ig_log, type: .debug)
            return
        }
        image = UIImage.image(withInitials: initials, size: CGSize(width:32, height:32))
    }
}
