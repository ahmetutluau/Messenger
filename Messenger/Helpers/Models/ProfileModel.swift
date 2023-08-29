//
//  ProfileModel.swift
//  Messenger
//
//  Created by Ahmet Utlu on 28.08.2023.
//

import Foundation

struct ProfileModel {
    let viewModelType: ProfileModelType
    let title: String
    let handler: (() -> Void)?
}
