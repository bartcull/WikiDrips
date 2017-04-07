//
//  TitleImageView.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/6/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import UIKit

class TitleImageView: UIImageView {
    
    func drawImageWith(initials: String?) -> UIImage {
        let scale = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return #imageLiteral(resourceName: "PlaceHolderImage")
        }
        
        let circlePath = CGPath(ellipseIn: self.bounds, transform: nil)
        context.addPath(circlePath)
        context.clip()
        
        UIColor.black.setFill()
        context.fill(self.bounds)
        
        
        let textAttrs: [String : AnyObject] = [NSForegroundColorAttributeName : UIColor.white]
        if let _initials = initials {
            let textRectSize = _initials.size(attributes: textAttrs)
            let textRect = CGRect(x: bounds.size.width / 2 - textRectSize.width / 2,
                                  y: bounds.size.height / 2 - textRectSize.height / 2,
                                  width: textRectSize.width,
                                  height: textRectSize.height)
            _initials.draw(in: textRect, withAttributes: textAttrs)
        }
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return image
        } else {
            return #imageLiteral(resourceName: "PlaceHolderImage")
        }
    }

}
