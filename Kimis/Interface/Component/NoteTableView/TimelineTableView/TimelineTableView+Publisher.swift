//
//  TimelineTableView+Publisher.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/7.
//

import Combine
import Foundation

extension TimelineTableView {
    func createPublishers() {
        guard let source else { return }

        // 不再监听 dataSoruce
        // 由 timeline source publish change 出来
        // 拿到就处理

        Publishers.CombineLatest3(
            source.timeline.updateAvailable,
            $layoutWidth
                .filter { $0 > 0 }
                .removeDuplicates(),
            refreshCaller,
        )
        .debounce(for: .seconds(0.1), scheduler: _dataBuildQueue)
        .receive(on: _dataBuildQueue)
        .sink { [weak self] _ in
            print("[*] sink called TimelineTableView.CombineLatest3")
            self?.preparePatchesIfNeededAndRenderUpdate()
        }
        .store(in: &cancellable)

        source.timeline.$updating
            .removeDuplicates()
            .sink { [weak self] value in
                if value {
                    self?.footerProgressWorkingJobs += 1
                } else {
                    self?.footerProgressWorkingJobs -= 1
                }
            }
            .store(in: &cancellable)

        $scrollLocation
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.global())
            .filter { $0.y > 100 } // remeber user focus
            .receive(on: RunLoop.main)
            .compactMap { [weak self] _ in
                self?.indexPathsForVisibleRows?.middle
            }
            .compactMap { [weak self] value in
                self?.retainContext(atIndexPath: value)
            }
            .compactMap(\.noteId)
            .removeDuplicates()
            .sink { [weak self] value in
                print("[*] setting uesr focus to note \(value) \(self?.source?.notes.retain(value)?.text.components(separatedBy: "\n").first ?? "")")
                self?.source?.timeline.pointOfInterest = value
            }
            .store(in: &cancellable)

        $scrollLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateGuiderCount()
            }
            .store(in: &cancellable)

        updateFetchRequest
            .throttle(for: .seconds(10), scheduler: DispatchQueue.global(), latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.source?.timeline.updating ?? true { return }
                if self?.contentOffset.y ?? 0 > 100 { return }
                print("[*] timeline table view $updateFetchRequest called")
                self?.source?.timeline.requestUpdate(direction: .newer)
            }
            .store(in: &cancellable)
    }
}
