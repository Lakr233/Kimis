//
//  ViewController.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/18.
//

import Combine
import Source
import UIKit

class ViewController: UIViewController {
    weak var source: Source? = Account.shared.source
    var cancellable: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        platformSetup()
    }
}
