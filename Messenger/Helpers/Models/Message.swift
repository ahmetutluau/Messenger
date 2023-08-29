//
//  Message.swift
//  Messenger
//
//  Created by Ahmet Utlu on 28.08.2023.
//

import Foundation
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}
