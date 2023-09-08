//
//  ConversationVM.swift
//  Messenger
//
//  Created by Ahmet Utlu on 6.09.2023.
//

import UIKit

protocol ConversationVMProtocol: AnyObject {
    func isConversationExist(isExist: Bool)
    func reloadTableView()
    func pushVC(vc: UIViewController)
}
class ConversationVM {
    weak var delegate: ConversationVMProtocol?
    var conversations: [Conversation] = []

    func startListeningforConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    delegate?.isConversationExist(isExist: false)
                    return
                }
                
                delegate?.isConversationExist(isExist: true)

                self.conversations = conversations.reversed()
                delegate?.reloadTableView()
                
            case .failure(let error):
                delegate?.isConversationExist(isExist: false)
                print("failed to get conversations \(error)")
            }
        }
    }
    
    // check in  database if conversation exist with this two user
    // if it does, reuse conversation id
    // otherwise use existing code
    func createNewConversation(result: SearchResult) {
        let email = result.email
        let name = DatabaseManager.safeEmail(email: result.name)
                
        DatabaseManager.shared.conversationExist(with: email) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let conversationId):
                let vc = ChatVC(with: email, id: conversationId)
                vc.viewModel.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                delegate?.pushVC(vc: vc)
            case .failure(_):
                let vc = ChatVC(with: email, id: nil)
                vc.viewModel.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                delegate?.pushVC(vc: vc)
            }
        }
    }
    
    func deleteConversation(id: String, completion: @escaping () -> Void) {
        DatabaseManager.shared.deleteConversation(conversationId: id) { success in
            if !success {
                completion()
            }
        }
    }
}
