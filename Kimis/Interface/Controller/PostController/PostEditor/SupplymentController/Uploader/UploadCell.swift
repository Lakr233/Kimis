//
//  UploadCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/11.
//

import Combine
import GlyphixTextFx
import QuickLook
import UIKit

extension AttachUploadController {
    class UploadCell: TableViewCell {
        static let cellId = "UploadCell"

        let activityIndicator = UIActivityIndicatorView()
        let iconView = UIImageView()
        let previewHolder = UIView()
        let previewIcon = UIImageView()
        let previewThumbnail = UIImageView()
        let titleView = UILabel()
        let subtitleView = UILabel()
        let progressLabel = GlyphixTextLabel()
        let progressBackground = UIView()

        var request: UploadRequest?

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            contentView.addSubviews([
                activityIndicator, iconView,
                progressBackground,
                previewHolder, previewIcon, previewThumbnail,
                titleView, subtitleView,
                progressLabel,
            ])

            progressBackground.backgroundColor = .accent.withAlphaComponent(0.05)

            let horizontalEdge: CGFloat = 16
            let padding: CGFloat = 8

            iconView.contentMode = .scaleAspectFit
            iconView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(horizontalEdge)
                make.top.bottom.equalToSuperview().inset(UIEdgeInsets(inset: padding))
                make.width.equalTo(24)
            }
            activityIndicator.snp.makeConstraints { make in
                make.center.equalTo(iconView)
            }

            previewHolder.clipsToBounds = true
            previewHolder.layer.cornerRadius = 4
            previewHolder.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(UIEdgeInsets(inset: padding))
                make.left.equalTo(iconView.snp.right).offset(padding)
                make.width.equalTo(80)
            }
            previewIcon.image = UIImage(systemName: "doc.fill")
            previewIcon.contentMode = .scaleAspectFit
            previewIcon.tintColor = .accent
            previewHolder.addSubview(previewIcon)
            previewIcon.snp.makeConstraints { make in
                make.width.equalTo(24)
                make.height.equalTo(24)
                make.center.equalToSuperview()
            }

            previewThumbnail.clipsToBounds = true
            previewThumbnail.layer.cornerRadius = 4
            previewThumbnail.contentMode = .scaleAspectFit
            previewThumbnail.snp.makeConstraints { make in
                make.edges.equalTo(previewHolder)
            }

            progressLabel.textAlignment = .leading
            progressLabel.textColor = .accent
            progressLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
            progressLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(UIEdgeInsets(inset: padding))
                make.right.equalToSuperview().offset(-horizontalEdge)
                make.width.equalTo(50)
            }
            titleView.font = .systemFont(ofSize: 16)
            titleView.snp.makeConstraints { make in
                make.bottom.equalTo(contentView.snp.centerY)
                make.left.equalTo(previewThumbnail.snp.right).offset(padding)
                make.right.equalTo(progressLabel.snp.left).offset(-padding)
            }
            subtitleView.font = .systemFont(ofSize: 14)
            subtitleView.alpha = 0.5
            subtitleView.snp.makeConstraints { make in
                make.top.equalTo(titleView.snp.bottom).offset(4)
                make.left.right.equalTo(titleView)
            }
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            UIView.performWithoutAnimation {
                iconView.image = nil
                iconView.tintColor = nil
                activityIndicator.stopAnimating()
                request = nil
                cancellable.forEach { $0.cancel() }
                cancellable = []
                previewIcon.alpha = 1
                previewThumbnail.image = nil
                titleView.text = ""
                subtitleView.text = ""
                progressLabel.text = ""
                setNeedsLayout()
            }
        }

        func set(_ request: UploadRequest) {
            self.request = request
            UIView.performWithoutAnimation {
                updateValue()
            }
            request.updated
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateValue(animated: true)
                }
                .store(in: &cancellable)
        }

        func updateValue(animated: Bool = false) {
            guard let request else {
                prepareForReuse()
                return
            }
            let status = request.status
            var title = status.title
            if case let .failed(error) = status {
                title += " \(error)"
            }
            switch status {
            case .pending, .uploading: activityIndicator.startAnimating()
            case .done, .failed: activityIndicator.stopAnimating()
            }
            iconView.image = status.icon
            iconView.tintColor = status.iconColor
            titleView.text = title
            titleView.textColor = status.color
            let attr = try? FileManager.default.attributesOfItem(atPath: request.assetFile.path)
            let size = attr?[FileAttributeKey.size] as? UInt64 ?? 0
            subtitleView.text = "\(ByteCountFormatter().string(fromByteCount: Int64(size))), \(decodeFileName(url: request.assetFile))"
            progressLabel.text = "\(Int(request.progress * 100))%"
            preparerThumbnail(for: request)
            if animated {
                withUIKitAnimation { self.layoutSubviews() }
            } else {
                setNeedsLayout()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            progressBackground.frame = contentView.bounds
            progressBackground.frame.size.width *= request?.progress ?? 0
        }

        func decodeFileName(url: URL) -> String {
            var lastCompos = url.lastPathComponent
            if lastCompos.contains("="), lastCompos.contains("&") {
                for item in lastCompos.components(separatedBy: "&") {
                    if item.lowercased().hasPrefix("noloc=") {
                        lastCompos = String(item.dropFirst("noloc=".count))
                        break
                    }
                }
            }
            return lastCompos
        }

        func preparerThumbnail(
            for request: UploadRequest,
            size: CGSize = .init(width: 256, height: 256),
            scale: CGFloat = 1.0
        ) {
            let previewRequest = QLThumbnailGenerator.Request(
                fileAt: request.assetFile,
                size: size,
                scale: scale,
                representationTypes: .thumbnail
            )
            QLThumbnailGenerator.shared.generateRepresentations(for: previewRequest) { thumbnail, _, error in
                withMainActor { [weak self] in
                    if let error { print("[E] QLThumbnailGenerator", error) }
                    guard let thumbnail else { return }
                    guard request == self?.request else { return }
                    self?.previewThumbnail.image = thumbnail.uiImage
                    self?.previewIcon.alpha = 0
                }
            }
        }
    }
}
