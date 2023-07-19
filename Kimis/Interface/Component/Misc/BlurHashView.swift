//
//  MKImageView+AsyncBlur.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/24.
//

import UIKit

class BlurHashView: UIView {
    let imageView = UIImageView()

    init() {
        super.init(frame: .zero)
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var session: UUID = .init()
    func setImage(withBlurHash hash: String?) {
        assert(Thread.isMainThread)
        guard let hash else {
            imageView.image = nil
            session = .init()
            return
        }
        assert(Thread.isMainThread)
        let builderSession = UUID()
        session = builderSession
        loadImage(forHash: hash) { [weak self] image in
            assert(Thread.isMainThread)
            guard let self, session == builderSession else {
                return
            }
            imageView.image = image
        }
    }

    private func loadImage(forHash: String, completion: @escaping (UIImage?) -> Void, onQueue: DispatchQueue = .main) {
        DispatchQueue.global().async {
            let image = UIImage(blurHash: forHash, size: CGSize(width: 50, height: 50))?
                .decodeForDisplay()
            onQueue.async { completion(image) }
        }
    }
}
