//
//  TrendingSource.swift
//
//
//  Created by Lakr Aream on 2022/11/30.
//

import Foundation
import Network

public class TrendingSource: ObservableObject {
    weak var ctx: Source?

    @Published public private(set) var updating: Bool = false
    @Published public private(set) var dataSource = [Trending]()

    init(context: Source) {
        ctx = context
    }

    public func populateTrending() {
        guard !updating, let ctx else { return }
        print("[*] requesting trending data...")
        updating = true
        DispatchQueue.global().async { [weak self] in
            defer { self?.updating = false }
            guard let req = ctx.req.requestHashtagTrending() else {
                return
            }
            let out = req
                .filter { !ctx.isTextMuted(text: $0.tag) }
            guard !out.isEmpty else { return }
            self?.dataSource = out
            print("[*] requesting trending data result \(req.count) raw items")
        }
    }
}
