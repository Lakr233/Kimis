//
//  ChidoriMenu.swift
//  Chidori
//
//  Created by Christian Selig on 2021-02-15.
//

import UIKit

class ChidoriMenu: UIViewController {
    let tableView: UITableView = .init(frame: .zero, style: .plain)
    private lazy var dataSource = makeDataSource()
    private static let cellReuseIdentifier = "MenuCell"

    /// The backing object that acts as the basis for the basis for the menu
    let menu: UIMenu

    /// Where in the window the menu is being summond from
    let summonPoint: CGPoint

    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight))
    private let shadowLayer = CALayer()

    /// Used to power the "drag to select" functionality like the iOS version
    let panGestureRecognizer: UIPanGestureRecognizer = .init()

    weak var delegate: ChidoriDelegate?

    /// Stores a reference to the current tranisiton controller to share between animation and interaction roles
    var transitionController: ChidoriAnimationController?

    // Constants that match the iOS version
    static let width: CGFloat = 250.0
    static let cornerRadius: CGFloat = 13.0
    static let shadowRadius: CGFloat = 25.0

    init(menu: UIMenu, summonPoint: CGPoint) {
        self.menu = menu
        self.summonPoint = summonPoint

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("\(#file) does not implement coder.") }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Can't have masksToBounds = true for corner radius on the layer *and* have a drop shadow, so some extra steps are required
        setUpShadowLayer()

        view.layer.masksToBounds = false
        view.backgroundColor = .clear

        visualEffectView.layer.masksToBounds = true
        visualEffectView.layer.cornerRadius = ChidoriMenu.cornerRadius

        tableView.register(ChidoriMenuTableViewCell.self, forCellReuseIdentifier: ChidoriMenu.cellReuseIdentifier)
        tableView.dataSource = dataSource
        tableView.separatorInset = .zero
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: ChidoriMenu.cornerRadius, left: 0.0, bottom: ChidoriMenu.cornerRadius, right: 0.0)
        visualEffectView.contentView.addSubview(tableView)

        view.addSubview(visualEffectView)

        // Required to not get whacky spacing
        tableView.estimatedSectionHeaderHeight = 0.0
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0

        // This hack still seems to be the best way to hide the last separator in a UITableView
        let fauxTableFooterView = UIView()
        fauxTableFooterView.frame = CGRect(x: 0.0, y: 0.0, width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
        tableView.tableFooterView = fauxTableFooterView

        panGestureRecognizer.addTarget(self, action: #selector(panned(panGestureRecognizer:)))
        panGestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(panGestureRecognizer)

        addInitialData()
    }

    override func viewDidAppear(_: Bool) {
        // Once the transition is over, we can nil out the transition controller
        // and simply dismiss this view controller as normal
        transitionController = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        visualEffectView.frame = view.bounds
        tableView.frame = visualEffectView.contentView.bounds

        // Set shadow path for better performance (note that bezier path uses continuous corner curve so no need to manually set)
        shadowLayer.frame = view.bounds
        shadowLayer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: ChidoriMenu.cornerRadius).cgPath
        setShadowMask()

        let isTableViewNotFullyVisible = tableView.contentSize.height > view.bounds.height
        tableView.isScrollEnabled = isTableViewNotFullyVisible
        panGestureRecognizer.isEnabled = !isTableViewNotFullyVisible
    }

    private func setUpShadowLayer() {
        shadowLayer.masksToBounds = false
        shadowLayer.cornerRadius = ChidoriMenu.cornerRadius
        shadowLayer.cornerCurve = .continuous
        shadowLayer.shadowColor = UIColor.black.cgColor
        shadowLayer.shadowOffset = .zero
        shadowLayer.shadowOpacity = 0.15
        shadowLayer.shadowRadius = ChidoriMenu.shadowRadius
        shadowLayer.shouldRasterize = true
        shadowLayer.rasterizationScale = UIScreen.main.scale
        view.layer.addSublayer(shadowLayer)
    }

    private func setShadowMask() {
        // We need to do this (and jump through a lot of hoops) because UIVisualEffectView is partially tranparent, and since iOS draws the shadow underneath the view as well it would be visible if we didn't mask out the portion under the view
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds

        // Set fillRule so that the maskOutPath will actually remove from the center
        maskLayer.fillRule = .evenOdd

        // We want this mask to be larger than the shadow layer because the shadow layer draws outside its bounds. Make it suitably large enough to cover the shadow radius, which anecdotally seems approximately double the radius.
        let mainPath = UIBezierPath(roundedRect: CGRect(x: -ChidoriMenu.shadowRadius * 2.0, y: -ChidoriMenu.shadowRadius * 2.0, width: view.bounds.width + ChidoriMenu.shadowRadius * 4.0, height: view.bounds.height + ChidoriMenu.shadowRadius * 4.0), cornerRadius: ChidoriMenu.cornerRadius)

        let maskOutPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: ChidoriMenu.cornerRadius)
        mainPath.append(maskOutPath)
        maskLayer.path = mainPath.cgPath

        shadowLayer.mask = maskLayer
    }

    private func addInitialData() {
        var snapshot = NSDiffableDataSourceSnapshot<UIMenu, UIAction>()

        if let actionChildren = menu.children as? [UIAction] {
            // To keep a consistent data structure, wrap actions in a UIMenu so we can still have menus at the top level to have support for secttions
            let wrapperMenu = UIMenu(title: "", image: nil, identifier: nil, options: [.displayInline], children: actionChildren)

            let menuChildren: [UIMenu] = [wrapperMenu]
            snapshot.appendSections(menuChildren)

            menuChildren.forEach {
                snapshot.appendItems($0.children as! [UIAction], toSection: $0)
            }
        } else if let menuChildren = menu.children as? [UIMenu] {
            snapshot.appendSections(menuChildren)

            menuChildren.forEach {
                snapshot.appendItems($0.children as! [UIAction], toSection: $0)
            }
        } else {
            preconditionFailure("Incorrect format. Do not mix UIAction and UIMenu in menu children for ChidoriMenu use.")
        }

        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }

    func height() -> CGFloat {
        let tableHeight = tableView.sizeThatFits(CGSize(width: ChidoriMenu.width, height: CGFloat.greatestFiniteMagnitude)).height.rounded()
        return tableHeight
    }
}

// MARK: - UITableViewDelegate

extension ChidoriMenu: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section != tableView.numberOfSections - 1 else { return nil }

        let footerView = UIView()
        footerView.backgroundColor = UIColor(white: 0.0, alpha: 0.1)
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionDividerHeight: CGFloat = 8.0

        // If it's the last section, don't show a divider, otherwise do
        return section == tableView.numberOfSections - 1 ? 0.0 : sectionDividerHeight
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectActionAtIndexPath(indexPath)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Target Action

extension ChidoriMenu {
    @objc private func panned(panGestureRecognizer: UIPanGestureRecognizer) {
        let offsetInTableView = panGestureRecognizer.location(in: tableView)

        guard let indexPath = tableView.indexPathForRow(at: offsetInTableView) else {
            // If we pan outside the table and there's a cell selected, unselect it
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
            tableView.deselectRow(at: selectedIndexPath, animated: false)
            return
        }

        if panGestureRecognizer.state == .ended {
            // Treat is as a tap
            didSelectActionAtIndexPath(indexPath)
            dismiss(animated: true, completion: nil)
        } else {
            // This API always confuses me, it does not *select* the cell in a way that would call `didSelectRowAtIndexPath`, this just visually highlights it!
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
}

// MARK: - Helpers

extension ChidoriMenu {
    private func makeDataSource() -> UITableViewDiffableDataSource<UIMenu, UIAction> {
        let dataSource = UITableViewDiffableDataSource<UIMenu, UIAction>(tableView: tableView) { tableView, indexPath, action -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: ChidoriMenu.cellReuseIdentifier, for: indexPath) as! ChidoriMenuTableViewCell
            cell.menuTitle = action.title
            cell.iconImage = action.image
            cell.isDestructive = action.attributes.contains(.destructive)
            return cell
        }

        return dataSource
    }

    private func didSelectActionAtIndexPath(_ indexPath: IndexPath) {
        guard let action = dataSource.itemIdentifier(for: indexPath) else {
            preconditionFailure("Should have corresponding action")
        }

        delegate?.didSelectAction(action)
    }
}

// MARK: - Custom View Controller Presentation

extension ChidoriMenu: UIViewControllerTransitioningDelegate {
    func animationController(forPresented _: UIViewController, presenting _: UIViewController, source _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionController = ChidoriAnimationController(type: .presentation)
        return transitionController
    }

    func interactionControllerForPresentation(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        transitionController
    }

    func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        ChidoriAnimationController(type: .dismissal)
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source _: UIViewController) -> UIPresentationController? {
        let controller = ChidoriPresentationController(presentedViewController: presented, presenting: presenting)
        controller.transitionDelegate = self
        return controller
    }
}

// MARK: - Presentation Controller Interactive Delegate

extension ChidoriMenu: ChidoriPresentationControllerDelegate {
    func didTapOverlayView(_: ChidoriPresentationController) {
        transitionController?.cancelTransition()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Action Protocol

protocol ChidoriDelegate: AnyObject {
    func didSelectAction(_ action: UIAction)
}
