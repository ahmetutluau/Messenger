//
//  ViewController.swift
//  Messenger
//
//  Created by Ahmet Utlu on 15.05.2023.
//

import UIKit
import FirebaseAuth

final class ConversationVC: UIViewController {
    let viewModel = ConversationVM()
        
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
        
        viewModel.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startListeningforConversations()
    }
    
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationsVC()
        vc.completion = { [weak self] result in
            print(result)
            
            if let targetConversation = self?.viewModel.conversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.email)
            }) {
                let vc = ChatVC(with: targetConversation.otherUserEmail,
                                id: targetConversation.id)
                vc.viewModel.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                self?.viewModel.createNewConversation(result: result)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
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
    
    private func openConversation(_ model: Conversation) {
        let vc = ChatVC(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ConversationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTVCell.identifier, for: indexPath) as! ConversationTVCell
        let model = viewModel.conversations[indexPath.row]
        
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = viewModel.conversations[indexPath.row]
        openConversation(model)
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
            
            let id = viewModel.conversations[indexPath.row].id
            let removedConversation = viewModel.conversations[indexPath.row]
            tableView.deleteRows(at: [indexPath], with: .left)
            viewModel.conversations.remove(at: indexPath.row)
            
            viewModel.deleteConversation(id: id) {
                self.viewModel.conversations.insert(removedConversation, at: indexPath.row)
                tableView.insertRows(at: [indexPath], with: .left)
            }
            
            tableView.endUpdates()
        }
    }
}

// MARK: - Subcsribe logic
extension ConversationVC: ConversationVMProtocol {
    func pushVC(vc: UIViewController) {
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func isConversationExist(isExist: Bool) {
        tableView.isHidden = !isExist
        noConversationLabel.isHidden = isExist
    }
}
