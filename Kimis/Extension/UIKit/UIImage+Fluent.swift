//
//  UIImage+Fluent.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/1.
//

import SDWebImage
import UIKit

private var fluentCache: [String: UIImage] = [:]
private var fluentAccess = NSLock()

extension UIImage {
    enum FluentIcon: String, CaseIterable {
        // MARK: REGULAR

        case comment_arrow_left = "ic_fluent_comment_arrow_left_24_regular"
        case emoji_add = "ic_fluent_emoji_add_24_regular"
        case square_arrow_forward = "ic_fluent_square_arrow_forward_24_regular"
        case more_horizontal = "ic_fluent_more_horizontal_24_regular"
        case share_ios = "ic_fluent_share_ios_24_regular"
        case subtract_square = "ic_fluent_subtract_square_24_regular"

        // MARK: FILLED

        case home_filled = "ic_fluent_home_24_filled"
        case city_filled = "ic_fluent_city_24_filled"
        case alert_filled = "ic_fluent_alert_24_filled"
        case chat_filled = "ic_fluent_chat_24_filled"
        case search_filled = "ic_fluent_search_24_filled"
        case settings_filled = "ic_fluent_settings_24_filled"
        case add_filled = "ic_fluent_add_24_filled"
        case arrow_reply_filled = "ic_fluent_arrow_reply_24_filled"
        case arrow_repeat_filled = "ic_fluent_arrow_repeat_all_24_filled"
        case more_horizontal_filled = "ic_fluent_more_horizontal_24_filled"
        case share_ios_filled = "ic_fluent_share_ios_24_filled"
        case emoji_add_filled = "ic_fluent_emoji_add_24_filled"
        case squre_arrow_forward_filled = "ic_fluent_square_arrow_forward_24_filled"
        case comment_arrow_left_filled = "ic_fluent_comment_arrow_left_24_filled"
        case subtract_square_filled = "ic_fluent_subtract_square_24_filled"
        case bookmark_filled = "ic_fluent_bookmark_24_filled"
        case arrow_left_filled = "ic_fluent_arrow_left_24_regular"
        case arrow_collapse_all_filled = "ic_fluent_arrow_collapse_all_20_filled"
        case arrow_counterclockwise_filled = "ic_fluent_arrow_counterclockwise_24_filled"
        case cloud_swap_filled = "ic_fluent_cloud_swap_24_filled"
        case gantt_chart_filled = "ic_fluent_gantt_chart_24_filled"
        case reading_list_filled = "ic_fluent_reading_list_24_filled"
        case tag_lock_filled = "ic_fluent_tag_lock_24_filled"
        case lock_open_filled = "ic_fluent_lock_open_24_filled"
        case shield_checkmark_filled = "ic_fluent_shield_checkmark_24_filled"
        case pin_filled = "ic_fluent_pin_24_filled"
        case arrow_maximize_vertical_filled = "ic_fluent_arrow_maximize_vertical_24_filled"
        case calligraphy_pen_filled = "ic_fluent_calligraphy_pen_24_filled"
        case filter_filled = "ic_fluent_filter_24_filled"
        case data_trending_filled = "ic_fluent_data_trending_24_filled"
        case checkmark_filled = "ic_fluent_checkmark_24_filled"
        case checkmark_circle_filled = "ic_fluent_checkmark_circle_24_filled"
        case camera_add_filled = "ic_fluent_camera_add_24_filled"
        case task_list_add_filled = "ic_fluent_task_list_add_24_filled"
        case task_list_square_add_filled = "ic_fluent_task_list_square_add_24_filled"
        case folder_add_filled = "ic_fluent_folder_add_24_filled"
        case person_add_filled = "ic_fluent_person_add_24_filled"
        case checkbox_person_filled = "ic_fluent_checkbox_person_24_filled"
        case globe_person_filled = "ic_fluent_globe_person_24_filled"
        case home_person_filled = "ic_fluent_home_person_24_filled"
        case person_mail_filled = "ic_fluent_person_mail_24_filled"
        case text_grammar_dismiss = "ic_fluent_text_grammar_dismiss_24_filled"
        case map_drive_filled = "ic_fluent_map_drive_24_filled"
        case cloud_checkmark_filled = "ic_fluent_cloud_checkmark_24_filled"
        case person_filled = "ic_fluent_person_24_filled"
    }

    private
    convenience init?(fluent: FluentIcon) {
        self.init(named: fluent.rawValue)
    }

    #if DEBUG
        static var checked = false
    #endif

    static func fluent(_ item: FluentIcon, size: CGSize = .init(width: 24, height: 24)) -> UIImage {
        fluentAccess.lock()
        defer { fluentAccess.unlock() }

        #if DEBUG
            if !checked {
                let items = FluentIcon.allCases.map(\.rawValue)
                for item in items {
                    assert(UIImage(named: item) != nil)
                }
                checked = true
                print("[*] FluentIcon Resources Checked!")
            }
        #endif

        let key = "\(item):\(size)"
        if let image = fluentCache[key] {
            return image
        }
        guard let ret = UIImage(fluent: item) else {
            assertionFailure("broken resource")
            return .init()
        }
        guard let final = ret
            .sd_resizedImage(with: size, scaleMode: .aspectFit)? // check before call
            .withRenderingMode(.alwaysTemplate)
        else {
            assertionFailure("broken resource")
            return .init()
        }
        fluentCache[key] = final
        return final
    }
}
