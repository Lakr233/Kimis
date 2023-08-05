//
//  TextParser+User.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/10.
//

import Foundation
import IDNA
import UIKit

extension TextParser {
    func compileUserHeader(with user: User, lineBreak: Bool) -> NSMutableAttributedString {
        let strings: [NSMutableAttributedString] = [
            NSMutableAttributedString(
                string: user.name,
                attributes: [
                    .font: getFont(size: size.title, weight: weight.title),
                    .link: "username://\(user.absoluteUsername.base64Encoded ?? "")",
                ]
            ),
            NSMutableAttributedString(
                string: user.absoluteUsername,
                attributes: [
                    .foregroundColor: color.secondary,
                    .font: getFont(size: size.base, weight: weight.base),
                    .link: "username://\(user.absoluteUsername.base64Encoded ?? "")",
                ]
            ),
        ]
        let ans = connect(strings: strings, separator: lineBreak ? "\n" : " ")
        if lineBreak, let para = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            para.paragraphSpacing = para.lineSpacing
            ans.addAttributes([.paragraphStyle: para], range: ans.full)
        }
        decodingIDNAIfNeeded(modifyingStringInPlace: ans)
        return finalize(ans, defaultHost: user.host)
    }

    func compileRenoteUserHeader(with user: User, lineBreak: Bool = false) -> NSMutableAttributedString {
        let strings: [NSMutableAttributedString] = [
            NSMutableAttributedString(
                string: user.name,
                attributes: [
                    .font: getFont(size: size.title, weight: weight.title),
                    .link: "username://\(user.absoluteUsername.base64Encoded ?? "")",
                ]
            ),
            NSMutableAttributedString(
                string: user.absoluteUsername,
                attributes: [
                    .font: getFont(size: size.title, weight: weight.base),
                    .link: "username://\(user.absoluteUsername.base64Encoded ?? "")",
                    .foregroundColor: color.secondary,
                ]
            ),
        ]
        let ans = connect(strings: strings, separator: lineBreak ? "\n" : " ")
        decodingIDNAIfNeeded(modifyingStringInPlace: ans)
        return finalize(ans, defaultHost: user.host)
    }

    func compileUserProfileHeader(with profile: UserProfile) -> NSMutableAttributedString {
        let largeOffset: CGFloat = 4
        let strings: [[NSMutableAttributedString]] = [
            [
                NSMutableAttributedString(
                    string: profile.name,
                    attributes: [
                        .font: getFont(size: size.title + largeOffset, weight: weight.title),
                        .link: "username://\(profile.absoluteUsername.base64Encoded ?? "")",
                    ]
                ),
                !profile.publiclyVisible || profile.isLocked ? createRestrictedVisibilityHint(size: size.title + largeOffset) : .init(),
                profile.isAdmin || profile.isModerator ? createAdminHint(size: size.title + largeOffset) : .init(),
            ],
            [
                NSMutableAttributedString(
                    string: profile.absoluteUsername,
                    attributes: [
                        .foregroundColor: color.secondary,
                        .font: getFont(size: size.base, weight: weight.base),
                        .link: "username://\(profile.absoluteUsername.base64Encoded ?? "")",
                    ]
                ),
                profile.isFollowed ? NSMutableAttributedString(
                    string: "『 Follows You 』".noLineBreak(),
                    attributes: [
                        .foregroundColor: color.secondary,
                        .font: getFont(size: size.base, weight: weight.base),
                    ]
                ) : .init(),
            ],
        ]

        let ans = connect(strings: strings.map {
            connect(strings: $0, separator: " ")
        }, separator: "\n")

        let smallerPadding = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle ?? .init()
        smallerPadding.lineSpacing = 1
        smallerPadding.paragraphSpacing = 0
        ans.addAttributes([
            .paragraphStyle: smallerPadding,
        ], range: ans.full)

        decodingIDNAIfNeeded(modifyingStringInPlace: ans)
        return finalize(ans, defaultHost: profile.host)
    }

    func compileUserDescriptionSimple(with profile: UserProfile) -> NSMutableAttributedString {
        var desc = profile.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
//        while desc.contains("\n\n") {
//            desc = desc.replacingOccurrences(of: "\n\n", with: "\n")
//        }
        if desc.isEmpty { desc = "This user did not provide a self introduction." }
        let items: [NSMutableAttributedString] = [
            NSMutableAttributedString(string: "\(desc)"),
        ]
        let preflight = connect(strings: items, separator: "\n")
        decodingIDNAIfNeeded(modifyingStringInPlace: preflight)
        return finalize(preflight, defaultHost: profile.host)
    }

    func compileUserDescription(with profile: UserProfile) -> NSMutableAttributedString {
        // in this function, we extract and compile user description with all useful info
        // description, birthday, join date (first seen), and user fields

        // Description
        var desc = profile.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
//        while desc.contains("\n\n") {
//            desc = desc.replacingOccurrences(of: "\n\n", with: "\n")
//        }
        if desc.isEmpty, profile.fields.isEmpty {
            desc = "This user did not provide a self introduction."
        }
        var items: [NSMutableAttributedString] = [
            NSMutableAttributedString(string: "\(desc)"),
        ]

        // user fields
        items += profile.fields.map {
            NSMutableAttributedString(string: "\($0.name): \($0.value)")
        }

        // captions
        var captions = [NSMutableAttributedString]()
        captions += [
            NSMutableAttributedString(string: "First Seen: \(compile(date: profile.createdAt))"),
        ]
        if let birth = profile.birthday {
            captions += [
                NSMutableAttributedString(string: "Born: \(birth)"),
            ]
        }
        if let location = profile.location {
            captions += [
                NSMutableAttributedString(string: "Location: \(location)"),
            ]
        }
        let captionPreflight = connect(strings: captions, separator: "\n")
        let captionPs = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle ?? .init()
        captionPs.lineSpacing = 1
        captionPs.paragraphSpacing = 0
        captionPreflight.addAttributes([
            .font: getFont(size: size.foot, weight: weight.foot),
            .foregroundColor: color.secondary,
            .paragraphStyle: captionPs,
        ], range: captionPreflight.full)
        items.append(captionPreflight)

        let preflight = connect(strings: items, separator: "\n")
        decodingIDNAIfNeeded(modifyingStringInPlace: preflight)
        return finalize(preflight, defaultHost: profile.host)
    }

    func compilePreviewReasonForRenote(withUser user: User) -> NSMutableAttributedString {
        let strings: [NSMutableAttributedString] = [
            NSMutableAttributedString(string: "Renote By"),
            NSMutableAttributedString(string: user.name),
        ]
        let ans = connect(strings: strings, separator: " ")
        ans.addAttributes([
            .font: getFont(size: size.hint, weight: weight.hint),
            .foregroundColor: color.secondary,
            .link: "username://\(user.absoluteUsername.base64Encoded ?? "")",
        ], range: ans.full)
        decodingIDNAIfNeeded(modifyingStringInPlace: ans)
        return finalize(ans, defaultHost: user.host)
    }

    func compilePreviewReasonForInstanceName(withUser user: User) -> NSMutableAttributedString? {
        guard let instanceName = user.instance?.name else { return nil }
        let string = "From \(instanceName)".capitalized
        let ans = NSMutableAttributedString(string: string)
        ans.addAttributes([
            .font: getFont(size: size.hint, weight: weight.hint),
            .foregroundColor: color.secondary,
        ], range: ans.full)
        decodingIDNAIfNeeded(modifyingStringInPlace: ans)
        return finalize(ans, defaultHost: user.host)
    }

    func compileUserBanner(withUser user: User) -> NSMutableAttributedString {
        var strings: [NSMutableAttributedString] = []
        if let url = URL(string: user.avatarUrl) {
            strings.append(
                NSMutableAttributedString(
                    attachment: RemoteImageAttachment(url: url, size: CGSize(width: size.base, height: size.base), cornerRadius: 8)
                )
            )
        }
        strings.append(
            NSMutableAttributedString(
                string: user.name,
                attributes: [
                    .font: getFont(size: size.base, weight: weight.base),
                    .link: "username://\(user.absoluteUsername.base64Encoded ?? "")",
                ]
            )
        )
        let ans = connect(strings: strings, separator: " ")
        decodingIDNAIfNeeded(modifyingStringInPlace: ans)
        return finalize(ans, defaultHost: user.host)
    }
}
