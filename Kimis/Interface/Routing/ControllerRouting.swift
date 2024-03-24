//
//  ControllerRouting.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/5/7.
//

import SafariServices
import UIKit

enum ControllerRouting {
    enum RoutingTag {
        case post
        case user
        case me
        case note
        case hashtag
        case search

        func constructController() -> UIViewController {
            switch self {
            case .post: PostController()
            case .user: UserViewController()
            case .me: CurrentUserViewController()
            case .note: NoteViewController()
            case .hashtag: HashtagNoteController()
            case .search: SearchController()
//            @unknown default:
//                let cont = UIViewController()
//                cont.
//                return cont
            }
        }
    }

    static func pushing(tag: RoutingTag, referencer: UIView?, associatedData: Any? = nil) {
        ControllerRouting.pushing(
            tag: tag,
            referencer: referencer?.parentViewController,
            associatedData: associatedData
        )
    }

    static func pushing(tag: RoutingTag, referencer: UIViewController?, associatedData: Any? = nil) {
        guard let controller = prepareViewController(tag: tag, data: associatedData),
              let into = findPushTarget(referencer: referencer)
        else {
            assertionFailure()
            return
        }
        into.present(next: controller)
    }

    private static func prepareViewControllerHook(tag: RoutingTag, data: inout Any?) -> UIViewController? {
        if tag == .user,
           let data = data as? String,
           let user = Account.shared.source?.user,
           user.userId == data || user.absoluteUsername == data
        {
            return CurrentUserViewController()
        }
        if tag == .note,
           let noteId = data as? NoteID,
           let origin = Account.shared.source?.notes.retain(noteId),
           let renoteId = origin.renoteId,
           origin.justRenote
        {
            data = renoteId
        }
        return nil
    }

    private static func prepareViewController(tag: RoutingTag, data: Any? = nil) -> UIViewController? {
        var controller: UIViewController?
        var modifiableData = data
        if let hook = prepareViewControllerHook(tag: tag, data: &modifiableData) {
            controller = hook
        } else {
            controller = tag.constructController()
        }
        assert(controller != nil)
        if let controller = controller as? RouterDatable {
            controller.associatedData = modifiableData
        } else {
            assert(modifiableData == nil, "[?] inject data into non RouterDatable does not make scene \(String(describing: controller))")
        }
        return controller
    }

    private static func findPushTarget(referencer: UIViewController?) -> UIViewController? {
        guard var from = referencer ?? UIWindow.mainWindow?.topController else {
            return nil
        }
        while let pop = from.popoverPresentationController {
            pop.presentedViewController.dismiss(animated: true)
            from = pop.presentingViewController
        }
        var splitLookup: UIViewController? = from
        while let parent = splitLookup?.parent {
            if let split = parent as? LLSplitController {
                return split.leftController
            }
            splitLookup = splitLookup?.parent
        }
        return from
    }

    static func pushing(deepLink: String, referencer: UIView?) {
        if deepLink.hasPrefix("http") || deepLink.hasPrefix("https://"),
           let url = URL(string: deepLink)
        {
            let safari = SFSafariViewController(url: url)
            referencer?.window?.topController?.present(safari, animated: true)
            return
        }

        if let url = URL(string: deepLink),
           UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url)
            return
        }

        var comps = deepLink.components(separatedBy: "://")
        guard comps.count >= 2 else {
            assertionFailure()
            return
        }

        let scheme = comps.removeFirst()
        let data = comps.joined(separator: "://")
        guard let actualData = Data(base64Encoded: data),
              let actual = String(data: actualData, encoding: .utf8)
        else {
            assertionFailure()
            return
        }

        print("[*] deep link \(scheme)://\(actual)")

        switch scheme {
        case "note":
            pushing(tag: .note, referencer: referencer, associatedData: actual)
        case "username":
            pushing(tag: .user, referencer: referencer, associatedData: actual)
        case "hashtag":
            pushing(tag: .hashtag, referencer: referencer, associatedData: actual)
        default:
            assertionFailure()
        }
    }
}
