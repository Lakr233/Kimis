//
//  AttachmentDrivePicker+Delegate.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/9.
//

import Combine
import Source
import UIKit

private let kDefaultCellSize: CGFloat = 100

extension AttachmentDrivePicker: UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { [weak self] collectionView, indexPath, attach ->
                UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: AttachmentCell.cellId,
                    for: indexPath
                ) as! AttachmentCell
                cell.load(attach)
                cell.setSelection(self?.selection.contains(attach) ?? false)
                return cell
            }
        )
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter else {
                return nil
            }
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LoadMoreFooterButton.cellId,
                for: indexPath
            ) as? LoadMoreFooterButton
            view?.picker = self
            return view
        }
        return dataSource
    }

    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(attachmentsList)
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset

        if scrollView.contentSize.height > scrollView.frame.height,
           offset.y + scrollView.frame.height > scrollView.contentSize.height + 50
        {
            loadMore()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let width = collectionView.frame.width - collectionView.contentInset.horizontal
        guard width > kDefaultCellSize * 2 else {
            return .init(width: kDefaultCellSize, height: kDefaultCellSize)
        }
        let items = Int(width / kDefaultCellSize)
//        let padding = IH.preferredPadding(usingWidth: width)
        let padding: CGFloat = 10
        // resolve function
        // -> cellSize * items + padding * (items - 1) = width
        let cellSize = (width - padding * CGFloat(items - 1)) / CGFloat(items)
        return CGSize(width: cellSize, height: cellSize)
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection _: Int) -> CGSize {
        if collectionView.numberOfSections != 1 || collectionView.numberOfItems(inSection: 0) == 0 {
            return .zero
        }
        var size = LoadMoreFooterButton.buttonSize
        size.height += 10 * 2 // layout padding for each cell: 10pt
        return size
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticGenerator.make(.selectionChanged)
        guard let attachment = attachmentsList[safe: indexPath.row],
              let cell = collectionView.cellForItem(at: indexPath) as? AttachmentCell
        else {
            assertionFailure()
            return
        }
        print("[*] selecting attachment \(attachment.attachId)")
        if selection.contains(attachment) {
            cell.setSelection(false)
            selection.remove(attachment)
        } else {
            cell.setSelection(true)
            selection.insert(attachment)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        withUIKitAnimation {
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.transform = .init(scaleX: 0.95, y: 0.95)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        withUIKitAnimation {
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.transform = .identity
            }
        }
    }

//    TODO: 不想写了 不是硬需求 以后再说吧
//    func collectionView(_: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point _: CGPoint) -> UIContextMenuConfiguration? {
//        guard indexPaths.count == 1,
//              let indexPath = indexPaths.first,
//              let attach = attachmentsList[safe: indexPath.row]
//        else {
//            return nil
//        }
//
//        return .init(identifier: nil, previewProvider: nil) { _ in
//            var menuActions: [[UIAction]] = []
//            menuActions.append([
//                .init(
//                    title: "Rename",
//                    image: .init(systemName: "pencil")
//                ) { _ in
//
//                },
//                .init(
//                    title: attach.isSensitive ? ,
//                    image: .init(systemName: "pencil")
//                ) { _ in
//
//                },
//                .init(
//                    title: "Delete",
//                    image: .init(systemName: "trash"),
//                    attributes: .destructive
//                ) { _ in
//
//                },
//            ])
//            return UIMenu(children: menuActions.map { UIMenu(children: $0) })
//        }
//    }
}
