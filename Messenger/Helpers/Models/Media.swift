//
//  Media.swift
//  Messenger
//
//  Created by Ahmet Utlu on 28.08.2023.
//

import UIKit
import MessageKit

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
