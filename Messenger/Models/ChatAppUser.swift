//
//  ChatAppUser.swift
//  Messenger
//
//  Created by Ahmet Utlu on 14.06.2023.
//

import Foundation

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let email: String
    
    var safeEmail: String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        "\(safeEmail)_profile_picture.png"
    }
}
