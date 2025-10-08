//
//  EmojiPicker+Data.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/5.
//

import UIKit

extension EmojiPickerView {
    struct EmojiElement: Hashable, Equatable {
        let emoji: EmojiProvider.Emoji
    }

    struct EmojiSection: Hashable, Equatable {
        var sectionTitle: String
        var emojis: [EmojiElement]
    }

    func prepareDataSource() {
        let recentUsed = provider.obtainRecentUsed()
        let instanceEmojis = provider.retainInstanceEmojis()
        let staticEmojis = provider.retainStaticEmojis()

        var dataSource = [EmojiSection]()

        var recent = [EmojiElement]()
        for emoji in recentUsed {
            if emoji.hasPrefix(":"),
               emoji.hasSuffix(":"),
               emoji.count > 2
            {
                // grab from instance // TODO: PERFORMANCE
                inner: for lookup in instanceEmojis {
                    if lookup.emoji == emoji {
                        recent.append(.init(emoji: lookup))
                        break inner
                    }
                }
            } else {
                // grab from static
                outter: for (_, value) in staticEmojis {
                    for lookup in value {
                        if lookup.emoji == emoji {
                            recent.append(.init(emoji: lookup))
                            break outter
                        }
                    }
                }
            }
        }
        if !recent.isEmpty {
            let section = EmojiSection(sectionTitle: L10n.text("Recent Used"), emojis: recent)
            dataSource.append(section)
        }

        if !instanceEmojis.isEmpty {
            var build: [String: [EmojiElement]] = [:]
            for instanceEmoji in instanceEmojis {
                build[instanceEmoji.category, default: []].append(.init(emoji: instanceEmoji))
            }
            for key in build.keys.sorted() {
                guard let section = build[key] else { continue }
                dataSource.append(.init(
                    sectionTitle: key.isEmpty ? L10n.text("Instance Emoji") : key,
                    emojis: section.sorted { a, b in a.emoji.emoji < b.emoji.emoji }
                ))
            }
        }

        let keys = staticEmojis.keys.sorted()
        for key in keys {
            guard let emojis = staticEmojis[key], !emojis.isEmpty else {
                continue
            }
            let elements = emojis
                .sorted(by: \.emoji)
                .map { EmojiElement(emoji: $0) }
            let section = EmojiSection(
                sectionTitle: key.isEmpty ? L10n.text("Ungrouped") : key,
                emojis: elements
            )
            dataSource.append(section)
        }

        rawDataSource = dataSource
        self.dataSource = dataSource
        collectionView.reloadData()
    }

    func buildSearchResultAndReload(for searchText: String) {
        let newDataSource: [EmojiSection] = if searchText.isEmpty {
            rawDataSource
        } else {
            searchFiltering(text: searchText)
        }
        reloadWithAnimation(with: newDataSource)
    }

    func reloadWithAnimation(with target: [EmojiSection]) {
        withMainActor { [self] in
            dataSource = target
            collectionView.reloadData()
        }
    }

    func searchFiltering(text: String) -> [EmojiSection] {
        let text = text.lowercased()
        return rawDataSource.compactMap { section -> EmojiSection? in
            let emojis = section.emojis.filter { emoji in
                if emoji.emoji.emoji.lowercased().contains(text) {
                    return true
                }
                // which is emoji's category
                if section.sectionTitle.lowercased().contains(text) {
                    return true
                }
                if !emoji.emoji.emoji.hasPrefix(":"),
                   emoji.emoji.description.lowercased().contains(text)
                {
                    return true
                }
                let alias = emoji.emoji.aliases.contains { str in
                    str.lowercased().contains(text)
                }
                if alias { return true }
                let tags = emoji.emoji.tags.contains { str in
                    str.lowercased().contains(text)
                }
                if tags { return true }
                return false
            }
            if emojis.isEmpty { return nil }
            return .init(sectionTitle: section.sectionTitle, emojis: emojis)
        }
    }
}

extension EmojiPickerView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in _: UICollectionView) -> Int {
        dataSource.count
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource[safe: section]?.emojis.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(
                withReuseIdentifier: EmojiPickerCell.cellId,
                for: indexPath
            ) as? EmojiPickerCell
            ?? .init()

        if let data = dataSource[safe: indexPath.section]?.emojis[safe: indexPath.row] {
            cell.apply(item: data)
        }

        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        CGSize(width: 44, height: 44)
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let data = dataSource[safe: indexPath.section]?.emojis[safe: indexPath.row] {
            selectingEmoji?(data.emoji)
            provider.insertRecentUsed(emoji: data.emoji.emoji)
        }
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
        CGSize(width: 200, height: 20)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: EmojiPickerSectionHeader.headerId,
            for: indexPath
        ) as? EmojiPickerSectionHeader
            ?? EmojiPickerSectionHeader()

        if let data = dataSource[safe: indexPath.section] {
            cell.label.text = data.sectionTitle
        }

        return cell
    }
}
