//
//  ProfileVC.swift
//  Messenger
//
//  Created by Ahmet Utlu on 18.05.2023.
//

import UIKit
import FirebaseAuth

final class ProfileVC: UIViewController {
    let viewModel = ProfileVM()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        setupTableView()
    }
        
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTVCell.self,
                           forCellReuseIdentifier: ProfileTVCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.setupModel()
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 300))
        headerView.backgroundColor = .link
        
        lazy var profileImageView: UIImageView = {
            let imageView = UIImageView(frame: CGRect(x: (headerView.width-150) / 2,
                                                      y: 70,
                                                      width: 150,
                                                      height: 150))
            imageView.contentMode = .scaleToFill
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 3
            imageView.layer.masksToBounds = true
            imageView.backgroundColor = .white
            imageView.layer.cornerRadius = imageView.width / 2
            return imageView
        }()
        
        headerView.addSubview(profileImageView)
        
        viewModel.downloadUrl(path: path) { url in
            profileImageView.sd_setImage(with: url)
        }
        
        return headerView
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = viewModel.data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTVCell.identifier, for: indexPath) as! ProfileTVCell
        cell.setup(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.data[indexPath.row].handler?()
    }
}

// MARK: - Subcsribe logic
extension ProfileVC: ProfileVMProtocol {
    func showAlert() {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel   ))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            do {
                try Auth.auth().signOut()
                if Auth.auth().currentUser == nil {
                    let vc = LoginVC()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: false)
                }
            } catch {
                print(error)
            }
        }))
        self.present(alert, animated: true)
    }
    
    func reloadData() {
        tableView.reloadData()
    }
}
