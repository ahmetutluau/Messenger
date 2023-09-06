//
//  StorageManager.swift
//  Messenger
//
//  Created by Ahmet Utlu on 22.05.2023.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    private init() {}
    
    typealias UploadPictureCompletion = (Result<String, StorageErrors>) -> Void
    
    /// upload picture to firebase storage and returns completion with url string to download
    func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metaData, error in
            guard error == nil else {
                print("fail to upload data to firebase for picture")
                completion(.failure(.failToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("fail to get download url")
                    completion(.failure(.failToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url return \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    /// upload image that will be sent in a conversation message
    func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] metaData, error in
            guard error == nil else {
                print("fail to upload data to firebase for picture")
                completion(.failure(.failToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("fail to get download url")
                    completion(.failure(.failToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url return \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    /// upload video that will be sent in a conversation message
    func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] metaData, error in
            guard error == nil else {
                print("fail to upload data to firebase for video")
                completion(.failure(.failToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("fail to get download url")
                    completion(.failure(.failToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url return \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    func downloadURL(for path: String, completion: @escaping (Result<URL, StorageErrors>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL (completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure (.failToGetDownloadUrl))
                return
            }
            completion(.success (url))
        })
    }
}
