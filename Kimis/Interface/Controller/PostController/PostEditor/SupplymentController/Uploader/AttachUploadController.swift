//
//  AttachUploadController.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/7.
//

import Combine
import GlyphixTextFx
import Source
import UIKit

class AttachUploadController: ViewController {
    let tableView = TableView()

    let post: Post
    var requests: [UploadRequest]
    var canceled: Bool = false
    var isQuerying: Bool = false {
        didSet { if !isQuerying { checkAndPopWhenComplete() }}
    }

    convenience init(post: Post, files: [URL]) {
        self.init(post: post, requests: files.map { .init(assetFile: $0) })
    }

    init(post: Post, requests: [UploadRequest]) {
        self.post = post
        self.requests = requests

        super.init(nibName: nil, bundle: nil)

        title = "Upload"
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(UploadCell.self, forCellReuseIdentifier: UploadCell.cellId)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.reloadData()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelUpload))

        for request in requests {
            request.updated
                .sink { [weak self] _ in
                    self?.checkAndPopWhenComplete()
                }
                .store(in: &cancellable)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global().async {
            let sem = DispatchSemaphore(value: 5)
            for req in self.requests {
                req.startUploading(sem: sem)
            }
        }
    }

    @objc func cancelUpload() {
        isQuerying = true
        let alert = UIAlertController(title: "⚠️", message: "Are you sure you want to cancel upload?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel Upload", style: .destructive, handler: { _ in
            self.canceled = true
            self.cleanUp()
            self.dismiss(animated: true)
            self.isQuerying = false
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
            self.isQuerying = false
        }))
        present(alert, animated: true)
    }

    func cleanUp() {
        requests.forEach { $0.cancelUpload() }
        cancellable.forEach { $0.cancel() }
        cancellable = []
    }

    func checkAndPopWhenComplete() {
        guard !canceled, !isQuerying else { return }
        var completed = true
        for item in requests where !item.completed {
            completed = false
        }
        guard completed else { return }
        cleanUp()
        let orig = post.attachments
        var build = orig
        for item in requests {
            if let attach = item.attachment {
                build.append(attach)
            }
        }
        build.removeDuplicates()
        print("[*] setting post with \(build.count) attachments")
        post.attachments = build
        dismiss(animated: true)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let nav = navigationController {
            nav.popViewController(animated: true, completion)
        } else {
            super.dismiss(animated: flag, completion: completion)
        }
    }
}

extension AttachUploadController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        requests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UploadCell.cellId, for: indexPath) as? UploadCell else {
            assertionFailure()
            return .init()
        }
        if let req = requests[safe: indexPath.row] {
            cell.set(req)
        }
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        60
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let req = requests[safe: indexPath.row] {
            req.startUploading()
        }
    }
}
