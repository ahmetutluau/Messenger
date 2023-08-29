//
//  Location.swift
//  Messenger
//
//  Created by Ahmet Utlu on 28.08.2023.
//

import CoreLocation
import MessageKit

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}
