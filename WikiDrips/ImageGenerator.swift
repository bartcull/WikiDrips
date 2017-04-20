//
//  ImageGenerator.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/18/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import Foundation
import UIKit

class ImageGenerator: Operation{
    let initials: String
    var image: UIImage?
    
    init(initials: String) {
        self.initials = initials
    }
    
    override func main() {
        if isCancelled { print("Cancelled"); return }
        image = UIImage.image(withInitials: initials)
    }
}
