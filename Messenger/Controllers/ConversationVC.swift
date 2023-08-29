//
//  ViewController.swift
//  Messenger
//
//  Created by Ahmet Utlu on 15.05.2023.
//

import UIKit
import FirebaseAuth

final class ConversationVC: UIViewController {
    private var conversations: [Conversation] = []
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(ConversationTVCell.self, forCellReuseIdentifier: ConversationTVCell.identifier)
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningforConversations()
    }
    
    private func startListeningforConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                    return
                }
                self?.tableView.isHidden = false
                self?.noConversationLabel.isHidden = true
                self?.conversations = conversations.reversed()
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationLabel.isHidden = false
                print("failed to get conversations \(error)")
            }
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationsVC()
        vc.completion = { [weak self] result in
            print(result)
            
            if let targetConversation = self?.conversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.email)
            }) {
                let vc = ChatVC(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                self?.createNewConversation(result: result)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func createNewConversation(result: SearchResult) {
        let email = result.email
        let name = DatabaseManager.safeEmail(email: result.name)
        
        // check in  database if conversation exist with this two user
        // if it does, reuse conversation id
        // otherwise use existing code
        
        DatabaseManager.shared.conversationExist(with: email) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let conversationId):
                let vc = ChatVC(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatVC(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationLabel.frame = CGRect(x: 10,
                                           y: (Int(view.height) - 100)/2,
                                           width: Int(view.width)-20,
                                           height: 100)
    }
    
    private func validateAuth() {
        if Auth.auth().currentUser == nil {
            let vc = LoginVC()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
}

extension ConversationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTVCell.identifier, for: indexPath) as! ConversationTVCell
        let model = conversations[indexPath.row]
        
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatVC(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // start deleting
            tableView.beginUpdates()
            
            let id = conversations[indexPath.row].id
            let removedConversation = conversations[indexPath.row]
            tableView.deleteRows(at: [indexPath], with: .left)
            self.conversations.remove(at: indexPath.row)
            
            DatabaseManager.shared.deleteConversation(conversationId: id) { [weak self] success in
                if !success {
                    self?.conversations.insert(removedConversation, at: indexPath.row)
                    tableView.insertRows(at: [indexPath], with: .left)
                }
            }
            
            tableView.endUpdates()
        }
    }
}
