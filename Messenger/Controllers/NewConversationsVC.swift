//
//  NewConversationsVC.swift
//  Messenger
//
//  Created by Ahmet Utlu on 22.05.2023.
//

import UIKit
import JGProgressHUD

final class NewConversationsVC: UIViewController {
    public var completion: ((SearchResult) -> Void) = {_ in }
    private let spinner = JGProgressHUD()
    
    private var users: [[String: String]] = []
    private var results: [SearchResult] = []
    private var hasFetched = false
    
    private lazy var searchBar: UISearchBar = {
       let bar = UISearchBar()
        bar.delegate = self
        bar.placeholder = "Search for users.."
        bar.becomeFirstResponder()
        return bar
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(NewConversationTVCell.self, forCellReuseIdentifier: NewConversationTVCell.identifier)
        table.isHidden = true
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private let noResultsLabel: UILabel = {
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
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didTapCancelButton))
        
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews () {
        super.viewDidLayoutSubviews ()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y: (view.height-200)/2,
                                      width: view.width/2,
                                      height: 200)
    }
    
    @objc private func didTapCancelButton() {
        self.dismiss(animated: true)
    }
}

extension NewConversationsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationTVCell.identifier, for: indexPath) as! NewConversationTVCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //start conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion(targetUserData)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }
}

extension NewConversationsVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text,
              !text.replacingOccurrences (of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers (query: text)
    }
    
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
        self.spinner.dismiss(animated: true)
        
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
        updateUI()
    }
    
    func updateUI () {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }
        else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

struct SearchResult {
    let name: String
    let email: String
}
