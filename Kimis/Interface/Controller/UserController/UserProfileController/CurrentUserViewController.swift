//
//  CurrentUserViewController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/25.
//

import UIKit

class CurrentUserViewController: UserViewController {
    override var associatedData: Any? {
        get { source?.user.absoluteUsername }
        set { print("[*] inject route data value to \(String(describing: self)) is not allowed, ignored") }
    }

    override init() {
        super.init()
        source?.$user
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[*] user profile reload called")
                withMainActor { self?.performReload() }
            }
            .store(in: &cancellable)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func determineLocalProfileIfPossible() -> UserProfile? {
        source?.user
    }
}
