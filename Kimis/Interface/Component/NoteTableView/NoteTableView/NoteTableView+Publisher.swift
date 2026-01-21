//
//  NoteTableView+Publisher.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/22.
//

import Combine
import Foundation

extension NoteTableView {
    func preparePublisher() {
        Publishers.CombineLatest3(
            updatedSource
                .removeDuplicates(),
            $layoutWidth
                .filter { $0 > 0 }
                .removeDuplicates()
                .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global()),
            refreshCaller
                .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global()),
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] value in
            guard let self, option.useBuiltinRender else { return }
            let ticket = UUID()
            renderTicket = ticket
            renderQueue.async {
                self.requestRenderUpdateReload(
                    target: value.0,
                    width: value.1,
                    ticket: ticket,
                )
            }
        }
        .store(in: &cancellable)

        source?.notesChange
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshCaller.send(true)
            }
            .store(in: &cancellable)

        $footerProgressWorkingJobs
            .removeDuplicates()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if value > 0 {
                    self?.progressIndicator.animate()
                } else {
                    self?.progressIndicator.stopAnimate()
                }
            }
            .store(in: &cancellable)
    }
}
