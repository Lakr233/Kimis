//
//  LLSplitController.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/2.
//

import UIKit

private let kSeparatorWidth: CGFloat = 1

class LLSplitController: ViewController {
    let leftController: UIViewController
    let leftControllerMinWidth: CGFloat
    let rightController: UIViewController
    let rightControllerWidth: CGFloat

    let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    var showSeparator: Bool = true {
        didSet { updateViewConstraints() }
    }

    init(left: UIViewController, right: UIViewController, leftMinWidth: CGFloat = 550, rightWidth: CGFloat = 350) {
        leftController = left
        leftControllerMinWidth = leftMinWidth
        rightController = right
        rightControllerWidth = rightWidth
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(leftController, toContainerView: view)
        title = leftController.title
        view.addSubview(separator)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupConstraints()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupConstraints()
    }

    func setupConstraints() {
        if view.size.width > leftControllerMinWidth + rightControllerWidth {
            setupLargeLayout()
        } else {
            setupCompactLayout()
        }
    }

    private func setupLargeLayout() {
        addChildViewController(rightController, toContainerView: view)
        rightController.view.snp.remakeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.width.equalTo(rightControllerWidth)
        }
        separator.isHidden = !showSeparator
        separator.snp.remakeConstraints { make in
            make.width.equalTo(showSeparator ? kSeparatorWidth : 0)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(rightController.view.snp.left)
        }
        leftController.view.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(separator.snp.left)
        }
    }

    private func setupCompactLayout() {
        rightController.view.snp.removeConstraints()
        rightController.removeViewAndControllerFromParentViewController()
        leftController.view.snp.remakeConstraints { make in
            make.edges.equalTo(self.view)
        }
        separator.snp.removeConstraints()
        separator.isHidden = true
    }
}
