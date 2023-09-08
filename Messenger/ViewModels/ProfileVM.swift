//
//  ProfileVM.swift
//  Messenger
//
//  Created by Ahmet Utlu on 6.09.2023.
//

import Foundation

protocol ProfileVMProtocol: AnyObject {
    func reloadData()
    func showAlert()
}

class ProfileVM {
    weak var delegate: ProfileVMProtocol?
    var data = [ProfileModel]()
    
    func setupModel() {
        data = [ProfileModel(viewModelType: .info,
                             title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                             handler: nil),
                ProfileModel(viewModelType: .info,
                             title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")",
                             handler: nil),
                ProfileModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            guard let self else { return }
            delegate?.showAlert()
        })
        ]
        delegate?.reloadData()
    }
    
    func downloadUrl(path: String, completion: @escaping (URL) -> Void) {
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success (let url):
                completion(url)
            case .failure (let error):
                print("Failed to get download url: \(error)")
            }
        })
    }
}
