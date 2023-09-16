//
//  PostEditorAttachmentView+Delegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/12.
//

import Combine
import Source
import UIKit

private let kDefaultCellSize: CGFloat = 100

extension PostEditorAttachmentView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        post.attachments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AttachmentCell.cellId,
            for: indexPath
        ) as! AttachmentCell
        if let attach = post.attachments[safe: indexPath.row] {
            cell.load(attach, atIndexPath: indexPath, editOnPost: post)
        } else {
            cell.prepareForReuse()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let width = collectionView.frame.width - collectionView.contentInset.horizontal
        guard width > kDefaultCellSize * 2 else {
            return .init(width: kDefaultCellSize, height: kDefaultCellSize)
        }
        let items = width > 450 ? 4 : 3
        let padding: CGFloat = spacing
        let cellSize = (width - padding * CGFloat(items - 1)) / CGFloat(items)
        return CGSize(width: cellSize, height: cellSize)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point _: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPaths.count == 1,
              let indexPath = indexPaths.first,
              let cell = collectionView.cellForItem(at: indexPath) as? AttachmentCell
        else {
            return nil
        }
        return cell.createContextMenuConfig()
    }
}

extension PostEditorAttachmentView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_: UICollectionView, itemsForBeginning _: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let attach = post.attachments[safe: indexPath.row] else {
            return []
        }
        let itemProvider = NSItemProvider(object: attach.attachId as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = dragItem
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parm = UIDragPreviewParameters()
        parm.backgroundColor = .clear
        let size = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
        parm.visiblePath = .init(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: IH.contentCornerRadius)
        return parm
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate _: UIDropSession, withDestinationIndexPath _: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return .init(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return .init(operation: .forbidden)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard coordinator.proposal.operation == .move else {
            return
        }

        var destIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destIndexPath = indexPath
        } else {
            let row = collectionView.numberOfItems(inSection: 0)
            destIndexPath = .init(item: row - 1, section: 0)
        }

        reorderItems(collectionView: collectionView, coordinator: coordinator, destIndexPath: destIndexPath)
    }

    func reorderItems(collectionView: UICollectionView, coordinator: UICollectionViewDropCoordinator, destIndexPath: IndexPath) {
        guard coordinator.items.count == 1,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath,
              let attach = post.attachments[safe: sourceIndexPath.row]
        else {
            return
        }
        collectionView.performBatchUpdates {
            self.post.attachments.remove(at: sourceIndexPath.row)
            self.post.attachments.insert(attach, at: destIndexPath.row)
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destIndexPath])
        }
        coordinator.drop(item.dragItem, toItemAt: destIndexPath)
    }
}
