//
//  ChatVC.swift
//  Messenger
//
//  Created by Ahmet Utlu on 22.05.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit
import CoreLocation

final class ChatVC: MessagesViewController {
    let viewModel = ChatVM()
    
    init(with email: String, id: String?) {
        viewModel.otherUserEmail = email
        viewModel.conversationId = id
        super.init(nibName: nil, bundle: nil)
        if let id = viewModel.conversationId {
            viewModel.listenForMessages(id: id)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
        viewModel.delegate = self
    }
    
    private func setupInputButton () {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet ()
        }
    
        messageInputBar.setLeftStackViewWidthConstant(to:36, animated:false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default,handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default,handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default,handler: { _ in
            self.presentLocationVC()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationVC() {
        let vc = LocationPickerVC(coordinates: nil)
        vc.title = "Pick Location"
        vc.completion = { [weak self] selectedCoordinates in
            guard let self else { return }
            guard let messageId = viewModel.createMessageId(),
                  let name = self.title,
                  let conversationId = viewModel.conversationId,
                  let sender = viewModel.selfSender else { return }
            
            let latitude = selectedCoordinates.latitude
            let longitude = selectedCoordinates.longitude
            
            print("latitude:\(latitude),longitude:\(longitude)")
            
            let location = Location(location: CLLocation(latitude: latitude,longitude: longitude), size: .zero)
            
            let message = Message(sender: sender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            guard let otherUserEmail = viewModel.otherUserEmail else { return }
            
            viewModel.sendMessage(id: conversationId, otherUserEmail: otherUserEmail, name: name, message: message)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach photo from",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default,handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach video from",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default,handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatVC: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { return }
        print(text)
        
        viewModel.sendMessage(text: text, title: self.title ?? "User")
    }
    
    
}

// MARK: - MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate
extension ChatVC: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
    var currentSender: SenderType {
        if let selfSender = viewModel.selfSender {
            return selfSender
        }
        fatalError("selfSender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        viewModel.messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        viewModel.messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }

    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = viewModel.messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            let vc = PhotoViewerVC(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else { return }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = viewModel.messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinate = locationData.location.coordinate
            let vc = LocationPickerVC(coordinates: coordinate)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        viewModel.configureAvatar(message: message) { url in
            avatarView.sd_setImage(with: url)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let selectedImage = info[.editedImage] as? UIImage,
           let imageData = selectedImage.pngData() {
            
            viewModel.uploadImage(data: imageData,title: title)
            
        } else if let videoUrl = info[.mediaURL] as? URL {
            viewModel.uploadVideo(url: videoUrl, title: title)
        }
    }
    
}

// MARK: - Subcsribe logic
extension ChatVC: ChatVMProtocol {
    func reloadData() {
        DispatchQueue.main.async {
            self.messagesCollectionView.reloadDataAndKeepOffset()
            self.messagesCollectionView.scrollToLastItem()
        }
    }
    
    func sendMessageSuccess() {
        messageInputBar.inputTextView.text = nil
    }
}
