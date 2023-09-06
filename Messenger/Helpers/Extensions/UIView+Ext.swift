//
//  Extensions.swift
//  Messenger
//
//  Created by Ahmet Utlu on 15.05.2023.
//

import UIKit

extension UIView {
    var width: CGFloat {
        self.frame.size.width
    }
    
    var height: CGFloat {
        self.frame.size.height
    }
    
    var bottom: CGFloat {
        self.frame.size.height + self.frame.origin.y
    }
    
    var top: CGFloat {
        self.frame.origin.y
    }
    
    var left: CGFloat {
        self.frame.origin.x
    }
    
    var right: CGFloat {
        self.frame.size.width + self.frame.origin.x
    }
}
