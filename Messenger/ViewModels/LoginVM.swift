//
//  LoginVM.swift
//  Messenger
//
//  Created by Ahmet Utlu on 6.09.2023.
//

import Foundation
import FirebaseAuth

protocol LoginVMProtocol: AnyObject {
    func dismissSpinner()
    func presentAlert(text: String)
    func dismissController()
}

class LoginVM {
    weak var delegate: LoginVMProtocol?
    
    // Firebase login
    func login(email: String, password: String) {
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self else { return }
            
            delegate?.dismissSpinner()
            
            guard let user = authResult?.user,
                  error == nil else {
                guard let error else { return }
                delegate?.presentAlert(text: "\(error.localizedDescription)")
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(email: email)
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                defer {
                    dispatchGroup.leave()
                }
                
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else { return }
                    
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("failed to read data with error: \(error)")
                }
            }
            dispatchGroup.notify(queue: .main) {
                 UserDefaults.standard.set(email, forKey: "email")
                print("log in user: \(user)")
                self.delegate?.dismissController()
            }
        }
    }
}
