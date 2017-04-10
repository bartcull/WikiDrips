//
//  TitleImageView.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/6/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import UIKit

extension UIImage {
    
    static func image(withInitials initials: String?, in bounds: CGRect) -> UIImage {
        let scale = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, scale)
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let initials = initials, let context = UIGraphicsGetCurrentContext() else {
            return #imageLiteral(resourceName: "PlaceHolderImage")
        }

        let circlePath = CGPath(ellipseIn: bounds, transform: nil)
        context.addPath(circlePath)
        context.clip()
        
        UIColor.black.setFill()
        context.fill(bounds)
        
        let textAttrs: [String : AnyObject] = [NSForegroundColorAttributeName : UIColor.white]
        let textRectSize = initials.size(attributes: textAttrs)
        let textRect = CGRect(x: bounds.midX - textRectSize.width / 2,
                              y: bounds.midY - textRectSize.height / 2,
                              width: textRectSize.width,
                              height: textRectSize.height).integral
        initials.draw(in: textRect, withAttributes: textAttrs)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return #imageLiteral(resourceName: "PlaceHolderImage")
        }
        
        return image
    }

}
