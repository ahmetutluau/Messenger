//
//  RegisterVM.swift
//  Messenger
//
//  Created by Ahmet Utlu on 6.09.2023.
//

import Foundation
import FirebaseAuth

protocol RegisterVMProtocol: AnyObject {
    func dismissSpinner()
    func presentAlert(text: String)
    func dismissController()
}

class RegisterVM {
    weak var delegate: RegisterVMProtocol?
    var imageData: Data?
    
    // firebase register
    func register(email: String, password: String, firstName: String, lastName: String) {
        DatabaseManager.shared.userExist(with: email) { [weak self] exists in
            guard let self else { return }
            
            delegate?.dismissSpinner()
            
            guard !exists else {
                delegate?.presentAlert(text: "looks like this email already exists")
                return
            }
            
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
                guard let self else { return }
                
                guard authResult != nil,
                      error == nil else {
                    self.delegate?.presentAlert(text: "\(error?.localizedDescription)")
                    return
                }
                
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                
                let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           email: email)
                DatabaseManager.shared.insertUser(with: chatUser) { succes in
                    if succes {
                        guard let data = self.imageData else {
                            return
                        }
                        let fileName = chatUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("storage manager error: \(error)")
                            }
                        }
                    }
                    
                }
                self.delegate?.dismissController()
            }
        }
    }
}
