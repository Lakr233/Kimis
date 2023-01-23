//
//  AttachmentDrivePicker.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/9.
//

import Combine
import Source
import UIKit

class AttachmentDrivePicker: ViewController {
    let post: Post

    enum Section { case main }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, Attachment>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Attachment>
    var dataSource: DataSource?
    var attachmentsList: [Attachment] = [] {
        didSet {
            print("[*] AttachmentDrivePicker applying \(attachmentsList.count) items")
            applySnapshot()
        }
    }

    var selection: Set<Attachment> = [] {
        didSet { updateTitle() }
    }

    @Published var loading = false
    let collectionView: UICollectionView
    let refreshControl = UIRefreshControl()
    let indicator: UIActivityIndicatorView = .init(frame: .zero)

    init(post: Post) {
        self.post = post

        let layout = AlignedCollectionViewFlowLayout(
            horizontalAlignment: .justified,
            verticalAlignment: .center
        )
        collectionView = .init(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)

        dataSource = makeDataSource()
        applySnapshot()
        collectionView.register(AttachmentCell.self, forCellWithReuseIdentifier: AttachmentCell.cellId)
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshControllerTrigged), for: .valueChanged)
        collectionView.register(
            LoadMoreFooterButton.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadMoreFooterButton.cellId
        )

        $loading
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                if output {
                    self?.indicator.startAnimating()
                } else {
                    self?.indicator.stopAnimating()
                }
            }
            .store(in: &cancellable)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTitle()

        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        navigationItem.leftBarButtonItems = [
            .init(
                title: "Cancel",
                style: .plain,
                target: self,
                action: #selector(cancelButtonTapped)
            ),
        ]
        navigationItem.rightBarButtonItems = [
            .init(
                title: "Done",
                style: .done,
                target: self,
                action: #selector(doneButtonTapped)
            ),
            .init(customView: indicator),
        ]
    }

    func updateTitle() {
        if selection.isEmpty {
            title = "Drive File"
        } else {
            title = "Drive File - (\(selection.count))"
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadMore()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let bounds = view.bounds
        let padding = IH.preferredPadding(usingWidth: bounds.width)
        collectionView.contentInset = .init(horizontal: padding, vertical: padding)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc func cancelButtonTapped() {
        if selection.isEmpty {
            dismiss()
            return
        }
        let alert = UIAlertController(title: "⚠️", message: "Are you sure you want to go back?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go Back", style: .destructive, handler: { _ in
            self.dismiss()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func doneButtonTapped() {
        if !selection.isEmpty {
            post.attachments.append(contentsOf: selection)
        }
        dismiss()
    }

    func dismiss() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc func refreshControllerTrigged() {
        withMainActor(delay: 1) {
            self.refreshControl.endRefreshing()
        }
        withMainActor(delay: 1.5) {
            guard !self.loading else { return }
            self.attachmentsList = []
            self.loadMore()
        }
    }

    @objc func loadMore() {
        guard let source, !loading else { return }
        let until = attachmentsList.last?.attachId
        let current = attachmentsList
        loading = true
        DispatchQueue.global().async { [weak self] in
            defer { withMainActor { self?.loading = false } }
            let fetchResult = source.req.requestDriveFiles(untilId: until)
            var build = (current + fetchResult)
            build.removeDuplicates()
            guard let self else { return }
            withMainActor { self.attachmentsList = build }
        }
    }
}
