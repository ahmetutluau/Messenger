//
//  ProfileVC.swift
//  Messenger
//
//  Created by Ahmet Utlu on 18.05.2023.
//

import UIKit
import FirebaseAuth

final class ProfileVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var data = [ProfileModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupViewModel() {
        data = [ProfileModel(viewModelType: .info,
                                 title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                                 handler: nil),
                ProfileModel(viewModelType: .info,
                                 title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")",
                                 handler: nil),
                ProfileModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
                    guard let self else { return }
                    
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
                })
        ]
        
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTVCell.self,
                           forCellReuseIdentifier: ProfileTVCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupViewModel()
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
        
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success (let url):
                profileImageView.sd_setImage(with: url)
            case .failure (let error):
                print("Failed to get download url: \(error)")
            }
        })
        return headerView
    }
}

extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTVCell.identifier, for: indexPath) as! ProfileTVCell
        cell.setup(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}
