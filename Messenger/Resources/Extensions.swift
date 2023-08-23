//
//  Extensions.swift
//  Messenger
//
//  Created by Ahmet Utlu on 15.05.2023.
//

import UIKit

extension UIView {
    public var width: CGFloat {
        self.frame.size.width
    }
    
    public var height: CGFloat {
        self.frame.size.height
    }
    
    public var bottom: CGFloat {
        self.frame.size.height + self.frame.origin.y
    }
    
    public var top: CGFloat {
        self.frame.origin.y
    }
    
    public var left: CGFloat {
        self.frame.origin.x
    }
    
    public var right: CGFloat {
        self.frame.size.width + self.frame.origin.x
    }
}
