//
//  NewConversationsVM.swift
//  Messenger
//
//  Created by Ahmet Utlu on 8.09.2023.
//

import Foundation

protocol NewConversationsVMProtocol: AnyObject {
    func dismissSpinner()
    func updateUI()
}

class NewConversationsVM {
    weak var delegate: NewConversationsVMProtocol?
    var users: [[String: String]] = []
    var results: [SearchResult] = []
    var hasFetched = false
    
    func searchUsers (query: String) {
        // check if array has firebase results
        if hasFetched {
            //if it does: filter
            self.filterUsers(with: query)
        }
        else {
            // if not, fetch then filter
            DatabaseManager.shared.getAllUsers { result in
                switch result {
                case .success(let userCollection):
                    self.hasFetched = true
                    self.users = userCollection
                    self.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            }
        }
    }
    
    func filterUsers (with term: String) {
        // update the UI: either show results or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        delegate?.dismissSpinner()
        
        let results: [SearchResult] = self.users.filter({
            guard safeEmail != $0["email"],
                  let name = $0[ "name"]?.lowercased() else { return false }
            return name.hasPrefix(term.lowercased())
        }).compactMap {
            guard let email = $0["email"],
                  let name = $0["name"] else { return nil }
            return SearchResult(name: name, email: email)
        }
        
        self.results = results
        delegate?.updateUI()
    }
}


