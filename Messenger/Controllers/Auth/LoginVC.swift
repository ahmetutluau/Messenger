//
//  LoginVC.swift
//  Messenger
//
//  Created by Ahmet Utlu on 15.05.2023.
//

import UIKit
import JGProgressHUD

final class LoginVC: UIViewController {
    let viewModel = LoginVM()
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Email Address..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.backgroundColor = .secondarySystemBackground
        textField.leftViewMode = .always
        textField.delegate = self
        
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Password..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.isSecureTextEntry = true
        textField.backgroundColor = .secondarySystemBackground
        textField.delegate = self
        
        return textField
    }()
        
    
    private lazy var loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        viewModel.delegate = self
        setNavBar()
        addSubviews()
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)

        emailTextField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        passwordTextField.frame = CGRect(x: 30, y: emailTextField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordTextField.bottom + 10, width: scrollView.width - 60, height: 52)
        
    }
    
    private func setNavBar() {
        title = "Login"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(didTappedRegister))
    }
    
    @objc private func didTappedRegister() {
        let vc = RegisterVC()
        vc.title = "Register"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        viewModel.login(email: email, password: password)
    }
    
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "please enter all information to log in.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dissmiss", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.becomeFirstResponder()
        } else if textField == passwordTextField {
            loginButtonTapped()
        }
        return true
    }
}

// MARK: - Subcsribe logic
extension LoginVC: LoginVMProtocol {
    func dismissController() {
        self.navigationController?.dismiss(animated: true)
    }
    
    func presentAlert(text: String) {
        let alert = UIAlertController(title: "Warning", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dissmiss", style: .cancel))
        present(alert, animated: true)
    }
    
    func dismissSpinner() {
        DispatchQueue.main.async {
            self.spinner.dismiss(animated: true)
        }
    }
}
