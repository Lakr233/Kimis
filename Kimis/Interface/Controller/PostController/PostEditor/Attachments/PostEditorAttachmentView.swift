//
//  PostEditorView+Attachments.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/12.
//

import Combine
import Source
import UIKit

class PostEditorAttachmentView: UIView {
    let post: Post
    let spacing: CGFloat
    let collectionView: UICollectionView

    var contentSize: CGSize {
        if post.attachments.isEmpty {
            return .zero
        }
        return collectionView.contentSize
    }

    init(post: Post, spacing: CGFloat) {
        self.post = post

        let layout = AlignedCollectionViewFlowLayout(
            horizontalAlignment: .left,
            verticalAlignment: .center
        )
        self.spacing = spacing
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)

        addSubview(collectionView)
        collectionView.clipsToBounds = false
        collectionView.dragInteractionEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.register(AttachmentCell.self, forCellWithReuseIdentifier: AttachmentCell.cellId)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }

    var previousData: [Attachment] = []

    func reloadAndPrepareForNewFrame() {
        if post.attachments != previousData {
            collectionView.reloadData()
            previousData = post.attachments
        }
        collectionView.collectionViewLayout.invalidateLayout()
        layoutIfNeeded()
    }
}
