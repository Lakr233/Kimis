//
//  UserCell.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/12/30.
//

import Combine
import Source
import UIKit

extension UserSimpleBannerCell {
    class Context: Identifiable, Equatable, Hashable {
        var id: Int { hashValue }

        var cellHeight: CGFloat = 0
        let profile: UserProfile?
        var snapshot: (any AnySnapshot)?

        init(user: UserProfile) {
            profile = user
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(profile)
        }

        static func == (lhs: UserSimpleBannerCell.Context, rhs: UserSimpleBannerCell.Context) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}
