//
//  NewConversationsVC.swift
//  Messenger
//
//  Created by Ahmet Utlu on 22.05.2023.
//

import UIKit
import JGProgressHUD

final class NewConversationsVC: UIViewController {
    let viewModel = NewConversationsVM()
    var completion: ((SearchResult) -> Void) = {_ in }
    private let spinner = JGProgressHUD()
        
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
        setNavBar()
        viewModel.delegate = self
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
    
    private func setNavBar() {
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didTapCancelButton))
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension NewConversationsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationTVCell.identifier, for: indexPath) as! NewConversationTVCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation
        let targetUserData = viewModel.results[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion(targetUserData)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }
}

// MARK: - UISearchBarDelegate
extension NewConversationsVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text,
              !text.replacingOccurrences (of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        
        viewModel.results.removeAll()
        spinner.show(in: view)
        viewModel.searchUsers (query: text)
    }
}


// MARK: - Subcsribe logic
extension NewConversationsVC: NewConversationsVMProtocol {
    func updateUI() {
        if viewModel.results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
    func dismissSpinner() {
        spinner.dismiss(animated: true)
    }

}
