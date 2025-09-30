//
//  TrendingTableView.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/27.
//

import Combine
import Module
import UIKit

class TrendingTableView: TableView {
    private(set) var _source: [Trending] = []
    let progressView = ProgressFooterView()

    override init() {
        super.init()

        delegate = self
        dataSource = self

        register(ItemCell.self, forCellReuseIdentifier: ItemCell.identifier)
        register(FooterCountView.self, forHeaderFooterViewReuseIdentifier: FooterCountView.identifier)

        tableFooterView = progressView
        tableFooterView?.frame.size.height = progressView.intrinsicContentSize.height

        source?.trending.$dataSource
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?._source = value
                self?.reloadData()
            }
            .store(in: &cancellable)

        source?.trending.$updating
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if value {
                    self?.progressView.animate()
                } else {
                    self?.progressView.stopAnimate()
                }
            }
            .store(in: &cancellable)
    }
}
