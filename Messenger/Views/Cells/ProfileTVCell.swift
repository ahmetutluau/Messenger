//
//  ProfileTVCell.swift
//  Messenger
//
//  Created by Ahmet Utlu on 15.06.2023.
//

import UIKit

class ProfileTVCell: UITableViewCell {
    static let identifier = "ProfileTVCell"
    
    func setup(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        
        switch viewModel.viewModelType {
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
            self.textLabel?.textColor = .label
        case .logout:
            self.textLabel?.textAlignment = .center
            self.textLabel?.textColor = .red
        }
    }
}
