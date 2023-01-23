//
//  LoadingController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/8.
//

import SnapKit
import UIKit

class LoadingController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let indicator = UIActivityIndicatorView()
        indicator.startAnimating()
        view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
