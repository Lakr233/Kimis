//
//  NotificationTableView+Publisher.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/30.
//

import Combine
import UIKit

extension NotificationTableView {
    func preparePublisher() {
        guard let source else { return }

        Publishers.CombineLatest4(
            source.notifications.$dataSource,
            source.notifications.$readDate,
            $layoutWidth
                .filter { $0 > 0 }
                .removeDuplicates()
                .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global()),
            refreshCaller
                .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] value in
            guard let self else { return }
            let ticket = UUID()
            renderTicket = ticket
            renderQueue.async {
                self.requestRenderUpdate(
                    target: value.0,
                    readAllBefore: value.1,
                    width: value.2,
                    ticket: ticket
                )
            }
        }
        .store(in: &cancellable)

        source.notifications.$updating
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if value {
                    self?.progressIndicator.animate()
                } else {
                    self?.progressIndicator.stopAnimate()
                }
            }
            .store(in: &cancellable)
    }
}
