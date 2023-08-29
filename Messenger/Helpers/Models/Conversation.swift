//
//  Conversation.swift
//  Messenger
//
//  Created by Ahmet Utlu on 28.08.2023.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
