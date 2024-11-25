//
//  MKImageView.swift
//  main
//
//  Created by Lakr Aream on 2022/5/14.
//

import SDWebImage
import UIKit

class MKImageView: UIView {
    struct Request: Equatable, Hashable {
        let url: String?
        let blurHash: String?
        let sensitive: Bool

        init(url: String? = nil, blurHash: String? = nil, sensitive: Bool = false) {
            self.url = url
            self.blurHash = blurHash
            self.sensitive = sensitive
        }

        init(url: URL? = nil, blurHash: String? = nil, sensitive: Bool = false) {
            self.init(
                url: url?.absoluteString,
                blurHash: blurHash,
                sensitive: sensitive
            )
        }
    }

    private var currentRequest: Request?
    private var nextRequest: Request?

    struct Option: Equatable {
        var previewEnabled: Bool
        init(previewEnabled: Bool = false) {
            self.previewEnabled = previewEnabled
        }
    }

    var option: Option {
        didSet { updateOptionBehavior() }
    }

    let renderView: MKImageRenderView = .init()

    init(option: Option = .init()) {
        self.option = option
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(renderView)

        updateOptionBehavior()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        renderView.frame = bounds
        updateRequestIfNeeded()
    }

    func updateRequestIfNeeded() {
        assert(Thread.isMainThread)
        defer { nextRequest = nil }
        guard let nextRequest, nextRequest != currentRequest else {
            return
        }
        currentRequest = nextRequest
        renderView.loadImage(with: nextRequest)
    }

    func clear() {
        nextRequest = nil
        setNeedsLayout()
    }

    func loadImage(with request: Request?) {
        nextRequest = request
        setNeedsLayout()
    }

    func updateOptionBehavior() {
        if option.previewEnabled {
            renderView.previewButton.addTarget(renderView, action: #selector(MKImageRenderView.preview), for: .touchUpInside)
        } else {
            renderView.previewButton.removeTarget(nil, action: nil, for: .allEvents)
        }
    }
}

class MKImageRenderView: UIView {
    let blurView = BlurHashView()
    let imageView: SDAnimatedImageView = {
        let view = SDAnimatedImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    private var ticket: UUID = .init()
    private var interactionButton: UIButton?

    var imageData: Data?
    let previewButton = UIButton()
    let sensitiveButton = SpoilerView()

    init() {
        super.init(frame: CGRect())
        clipsToBounds = true
        addSubviews([blurView, imageView, previewButton, sensitiveButton])
        sensitiveButton.hide()
        UIView.performWithoutAnimation { clear() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = bounds
        for view in subviews {
            view.frame = bounds
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    @discardableResult
    func clear() -> UUID {
        let ticket = UUID()
        self.ticket = ticket

        assert(Thread.isMainThread)

        imageView.sd_cancelCurrentImageLoad()
        blurView.setImage(withBlurHash: nil)
        imageView.image = nil
        backgroundColor = .systemGray6
        imageData = nil

        return ticket
    }

    func loadImage(with request: MKImageView.Request?) {
        assert(Thread.isMainThread)
        let ticket = clear()
        guard let str = request?.url, let url = URL(string: str) else {
            return
        }

        if request?.sensitive ?? false {
            sensitiveButton.show()
        } else {
            sensitiveButton.hide()
        }

        if let cache = SDImageCache.shared.imageFromMemoryCache(forKey: str) {
            imageView.image = cache
            DispatchQueue.global().async {
                let imageData = cache.sd_imageData()
                withMainActor {
                    guard let data = imageData, self.ticket == ticket else { return }
                    self.imageData = data
                }
            }
            return
        }

        blurView.setImage(withBlurHash: request?.blurHash)

        imageView.sd_setImage(
            with: url,
            placeholderImage: nil,
            options: [.retryFailed, .continueInBackground, .avoidAutoSetImage],
            context: [.imageForceDecodePolicy: SDImageForceDecodePolicy.never.rawValue as NSNumber]
        ) { _, _, _ in } completed: { [weak self] image, _, _, _ in
            guard let self, let image else { return }
            finalizeImageRequst(withImage: image, ticket: ticket)
        }
    }

    private func finalizeImageRequst(withImage image: UIImage?, ticket: UUID) {
        DispatchQueue.global().async { [weak self] in
            let imageData: Data? = image?.sd_imageData() // because it may decode
            let thumbnail: UIImage? = image?.decodeForDisplay()
            withMainActor { [weak self] in
                assert(Thread.isMainThread)
                if let self, ticket == self.ticket, let thumbnail {
                    imageView.image = thumbnail
                    self.imageData = imageData
                    blurView.setImage(withBlurHash: nil)
                }
            }
        }
    }

    @objc func preview() {
        guard let data = imageData else { return }
        interactionButton?.backgroundColor = .gray.withAlphaComponent(0.5)
        withUIKitAnimation { self.interactionButton?.backgroundColor = .clear }
        let preview = ImagePreviewController()
        preview.imageData = data
        parentViewController?.present(preview, animated: true)
    }
}
