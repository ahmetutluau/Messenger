//
//  ChatVM.swift
//  Messenger
//
//  Created by Ahmet Utlu on 7.09.2023.
//

import UIKit
import MessageKit

protocol ChatVMProtocol: AnyObject {
    func reloadData()
    func sendMessageSuccess()
}

class ChatVM {
    weak var delegate: ChatVMProtocol?
    var conversations: [Conversation] = []
    var senderUserPhotoUrl: URL?
    var otherUserPhotoUrl: URL?
    
    var otherUserEmail: String?
    var isNewConversation = false
    var conversationId: String?
    var messages: [Message] = []
    
    var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return nil }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        return Sender(photoUrl: "",
                      senderId: safeEmail,
                      displayName: "me")
    }
    
    func sendMessage(id: String, otherUserEmail: String, name: String, message: Message) {
        DatabaseManager.shared.sendMessage(to: id, otherUserEmail: otherUserEmail, name: name, newMessage: message) { succes in
            if succes {
                print("sent location message")
            } else {
                print("failed to send location message")
            }
        }
    }

    func listenForMessages(id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else { return }
                self?.messages = messages
                self?.delegate?.reloadData()
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
    }
    
    func createMessageId() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let otherUserEmail = self.otherUserEmail else {
            return nil
        }

        let safeCurrentEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let dateString = DatabaseManager.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("created messageId: \(newIdentifier)")

        return newIdentifier
    }
    
    ///send message
    func sendMessage(text: String, title: String) {
        guard let selfSender,
              let messageId = createMessageId() else {return}
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        if isNewConversation {
            guard let otherUserEmail else { return }

            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: title, firstMessage: message) { [weak self] success in
                guard let self else { return }
                
                if success {
                    delegate?.sendMessageSuccess()
                    print("sent message")
                    self.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self.conversationId = newConversationId
                    if let conversationId {
                        self.listenForMessages(id: conversationId)
                    }
                } else {
                    print("failed to send")
                }
            }
        } else {
            guard let conversationId,
                  let otherUserEmail = self.otherUserEmail else { return }
            
            // append existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: title, newMessage: message) { [weak self] success in
                guard let self else { return }
                
                if success {
                    delegate?.sendMessageSuccess()
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
        }
    }
    
    func configureAvatar(message: MessageType, completion: @escaping (URL) -> Void) {
        if message.sender.senderId == selfSender?.senderId {
            // my image
            if let senderUserPhotoUrl {
                completion(senderUserPhotoUrl)
            } else {
                // fetch url
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
                let safeEmail = DatabaseManager.safeEmail(email: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    guard let self else { return }
                    
                    switch result {
                    case .success(let url):
                        self.senderUserPhotoUrl = url
                        DispatchQueue.main.async {
                            completion(url)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        } else {
            // other image
            if let otherUserPhotoUrl {
                completion(otherUserPhotoUrl)
            } else {
                // fetch url
                guard let email = otherUserEmail else { return }
                let safeEmail = DatabaseManager.safeEmail(email: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoUrl = url
                        DispatchQueue.main.async {
                            completion(url)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    
    /// upload ımage
    func uploadImage(data: Data, title: String?) {
        guard let messageId = createMessageId(),
              let name = title,
              let conversationId = conversationId,
              let sender = selfSender else { return }
        
        let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
        
        StorageManager.shared.uploadMessagePhoto(with: data, fileName: fileName) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let urlString):
                // ready to send message
                print("uploaded message photo: \(urlString)")
                
                guard let placeHolder = UIImage(systemName: "plus"),
                      let url = URL(string: urlString) else { return }
                
                let media = Media(url: url,
                                  placeholderImage: placeHolder,
                                  size: .zero)
                
                let message = Message(sender: sender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .photo(media))
                
                guard let otherUserEmail = self.otherUserEmail else { return }
                
                DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { succes in
                    if succes {
                        print("sent photo message")
                    } else {
                        print("failed to send photo message")
                    }
                }
                break
            case .failure(let error):
                print("message photo upload error: \(error)")
            }
        }
    }
    
    /// upload video
    func uploadVideo(url: URL, title: String?) {
        guard let messageId = createMessageId(),
              let name = title,
              let conversationId = conversationId,
              let sender = selfSender else { return }
        
        let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
        
        StorageManager.shared.uploadMessageVideo(with: url, fileName: fileName) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let urlString):
                // ready to send message
                print("uploaded message video: \(urlString)")
                
                guard let placeHolder = UIImage(systemName: "plus"),
                      let url = URL(string: urlString) else { return }
                
                let media = Media(url: url,
                                  placeholderImage: placeHolder,
                                  size: .zero)
                
                let message = Message(sender: sender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .video(media))
                
                guard let otherUserEmail = self.otherUserEmail else { return }
                DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { succes in
                    if succes {
                        print("sent photo message")
                    } else {
                        print("failed to send photo message")
                    }
                }
                break
            case .failure(let error):
                print("message photo upload error: \(error)")
            }
        }
    }
}
