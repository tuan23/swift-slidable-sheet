import UIKit

public protocol SlidableSheetControllerDelegate: class {
    // if it returns nil, SlidableSheetController uses the default layout
    func slidableSheet(_ vc: SlidableSheetController, layoutFor newCollection: UITraitCollection) -> SlidableSheetLayout?

    // if it returns nil, SlidableSheetController uses the default behavior
    func slidableSheet(_ vc: SlidableSheetController, behaviorFor newCollection: UITraitCollection) -> SlidableSheetBehavior?

    func slidableSheetDidMove(_ vc: SlidableSheetController) // any offset changes

    // called on start of dragging (may require some time and or distance to move)
    func slidableSheetWillBeginDragging(_ vc: SlidableSheetController)
    // called on finger up if the user dragged. velocity is in points/second.
    func slidableSheetDidEndDragging(_ vc: SlidableSheetController, withVelocity velocity: CGPoint, targetPosition: SlidableSheetPosition)
    func slidableSheetWillBeginDecelerating(_ vc: SlidableSheetController) // called on finger up as we are moving
    func slidableSheetDidEndDecelerating(_ vc: SlidableSheetController) // called when scroll view grinds to a halt

    // called on start of dragging to remove its views from a parent view controller
    func slidableSheetDidEndDraggingToRemove(_ vc: SlidableSheetController, withVelocity velocity: CGPoint)
    // called when its views are removed from a parent view controller
    func slidableSheetDidEndRemove(_ vc: SlidableSheetController)
}

public extension SlidableSheetControllerDelegate {
    func slidableSheet(_ vc: SlidableSheetController, layoutFor newCollection: UITraitCollection) -> SlidableSheetLayout? {
        return nil
    }
    func slidableSheet(_ vc: SlidableSheetController, behaviorFor newCollection: UITraitCollection) -> SlidableSheetBehavior? {
        return nil
    }
    func slidableSheetDidMove(_ vc: SlidableSheetController) {}
    func slidableSheetWillBeginDragging(_ vc: SlidableSheetController) {}
    func slidableSheetDidEndDragging(_ vc: SlidableSheetController, withVelocity velocity: CGPoint, targetPosition: SlidableSheetPosition) {}
    func slidableSheetWillBeginDecelerating(_ vc: SlidableSheetController) {}
    func slidableSheetDidEndDecelerating(_ vc: SlidableSheetController) {}

    func slidableSheetDidEndDraggingToRemove(_ vc: SlidableSheetController, withVelocity velocity: CGPoint) {}
    func slidableSheetDidEndRemove(_ vc: SlidableSheetController) {}
}

public enum SlidableSheetPosition: Int, CaseIterable {
    case full
    case half
    case tip
}

public class SlidableSheetController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    /// Constants indicating how safe area insets are added to the adjusted content inset.
    public enum ContentInsetAdjustmentBehavior: Int {
        case always
        case never
    }

    /// The delegate of the floating panel controller object.
    public weak var delegate: SlidableSheetControllerDelegate?

    /// Returns the surface view managed by the controller object. It's the same as `self.view`.
    public var surfaceView: SlidableSheetSurfaceView! {
        return view as? SlidableSheetSurfaceView
    }

    /// Returns the backdrop view managed by the controller object.
    public var backdropView: SlidableSheetBackdropView! {
        return slidableSheet.backdropView
    }

    /// Returns the scroll view that the controller tracks.
    public weak var scrollView: UIScrollView? {
        return slidableSheet.scrollView
    }

    // The underlying gesture recognizer for pan gestures
    public var panGestureRecognizer: UIPanGestureRecognizer {
        return slidableSheet.panGesture
    }

    /// The current position of the floating panel controller's contents.
    public var position: SlidableSheetPosition {
        return slidableSheet.state
    }

    /// The content insets of the tracking scroll view derived from the safe area of the parent view
    public var adjustedContentInsets: UIEdgeInsets {
        return slidableSheet.layoutAdapter.adjustedContentInsets
    }

    /// The behavior for determining the adjusted content offsets.
    ///
    /// This property specifies how the content area of the tracking scroll view is modified using `adjustedContentInsets`. The default value of this property is SlidableSheetController.ContentInsetAdjustmentBehavior.always.
    public var contentInsetAdjustmentBehavior: ContentInsetAdjustmentBehavior = .always

    /// A Boolean value that determines whether the removal interaction is enabled.
    public var isRemovalInteractionEnabled: Bool {
        set { slidableSheet.isRemovalInteractionEnabled = newValue }
        get { return slidableSheet.isRemovalInteractionEnabled }
    }

    /// The view controller responsible for the content portion of the floating panel.
    public var contentViewController: UIViewController? {
        set { set(contentViewController: newValue) }
        get { return _contentViewController }
    }
    private var _contentViewController: UIViewController?

    private var slidableSheet: SlidableSheet!
    private var layoutInsetsObservations: [NSKeyValueObservation] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        slidableSheet = SlidableSheet(self,
                                      layout: fetchLayout(for: self.traitCollection),
                                      behavior: fetchBehavior(for: self.traitCollection))
    }

    /// Initialize a newly created floating panel controller.
    public init() {
        super.init(nibName: nil, bundle: nil)

        slidableSheet = SlidableSheet(self,
                                      layout: fetchLayout(for: self.traitCollection),
                                      behavior: fetchBehavior(for: self.traitCollection))
    }

    /// Creates the view that the controller manages.
    override public func loadView() {
        assert(self.storyboard == nil, "Storyboard isn't supported")

        let view = SlidableSheetSurfaceView()
        view.backgroundColor = .white

        self.view = view as UIView
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        // Change layout for a new trait collection
        slidableSheet.layoutAdapter.layout = fetchLayout(for: newCollection)
        slidableSheet.behavior = fetchBehavior(for: newCollection)

        guard let parent = parent else { fatalError() }

        slidableSheet.layoutAdapter.prepareLayout(toParent: parent)
        slidableSheet.layoutAdapter.activateLayout(of: slidableSheet.state)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection != traitCollection else { return }

        if let parent = parent {
            self.update(safeAreaInsets: parent.layoutInsets)
        }
        slidableSheet.backdropView.isHidden = (traitCollection.verticalSizeClass == .compact)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Need to update safeAreaInsets here to ensure that the `adjustedContentInsets` has a correct value.
        // Because the parent VC does not call viewSafeAreaInsetsDidChange() expectedly and
        // `view.safeAreaInsets` has a correct value of the bottom inset here.
        if let parent = parent {
            self.update(safeAreaInsets: parent.layoutInsets)
        }
    }

    private func fetchLayout(for traitCollection: UITraitCollection) -> SlidableSheetLayout {
        switch traitCollection.verticalSizeClass {
        case .compact:
            return self.delegate?.slidableSheet(self, layoutFor: traitCollection) ?? SlidableSheetDefaultLandscapeLayout()
        default:
            return self.delegate?.slidableSheet(self, layoutFor: traitCollection) ?? SlidableSheetDefaultLayout()
        }
    }

    private func fetchBehavior(for traitCollection: UITraitCollection) -> SlidableSheetBehavior {
        return self.delegate?.slidableSheet(self, behaviorFor: traitCollection) ?? SlidableSheetDefaultBehavior()
    }

    private func update(safeAreaInsets: UIEdgeInsets) {
        slidableSheet.safeAreaInsets = safeAreaInsets
        switch contentInsetAdjustmentBehavior {
        case .always:
            scrollView?.contentInset = adjustedContentInsets
            scrollView?.scrollIndicatorInsets = adjustedContentInsets
        default:
            break
        }
    }

    /// Adds the view managed by the controller as a child of the specified view controller.
    /// - Parameters:
    ///     - parent: A parent view controller object that displays SlidableSheetController's view. A container view controller object isn't applicable.
    ///     - belowView: Insert the surface view managed by the controller below the specified view. By default, the surface view will be added to the end of the parent list of subviews.
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    public func addPanel(toParent parent: UIViewController, belowView: UIView? = nil, animated: Bool = false) {
        guard self.parent == nil else {
            log.warning("Already added to a parent(\(parent))")
            return
        }
        precondition((parent is UINavigationController) == false, "UINavigationController displays only one child view controller at a time.")
        precondition((parent is UITabBarController) == false, "UITabBarController displays child view controllers with a radio-style selection interface")
        precondition((parent is UISplitViewController) == false, "UISplitViewController manages two child view controllers in a master-detail interface")
        precondition((parent is UITableViewController) == false, "UITableViewController should not be the parent because the view is a table view so that a floating panel doens't work well")
        precondition((parent is UICollectionViewController) == false, "UICollectionViewController should not be the parent because the view is a collection view so that a floating panel doens't work well")

        view.frame = parent.view.bounds
        if let belowView = belowView {
            parent.view.insertSubview(self.view, belowSubview: belowView)
        } else {
            parent.view.addSubview(self.view)
        }

        layoutInsetsObservations.removeAll()

        // Must track safeAreaInsets/{top,bottom}LayoutGuide of the `parent.view` to update slidableSheet.safeAreaInsets`.
        // Because the parent VC does not call viewSafeAreaInsetsDidChange() expectedly on the bottom inset's update.
        // So I needs to observe them. It ensures that the `adjustedContentInsets` has a correct value.
        if #available(iOS 11.0, *) {
            let observaion = parent.observe(\.view.safeAreaInsets) { [weak self] (vc, chaneg) in
                guard let self = self else { return }
                self.update(safeAreaInsets: vc.layoutInsets)
            }
            layoutInsetsObservations.append(observaion)
        } else {
            // KVOs for topLayoutGuide & bottomLayoutGuide are not effective. Instead, safeAreaInsets will be updated in viewDidAppear()
        }

        parent.addChild(self)

        // Must set a layout again here because `self.traitCollection` is applied correctly once it's added to a parent VC
        slidableSheet.layoutAdapter.layout = fetchLayout(for: traitCollection)
        slidableSheet.layoutViews(in: parent)

        slidableSheet.behavior = fetchBehavior(for: traitCollection)

        slidableSheet.present(animated: animated) { [weak self] in
            guard let self = self else { return }
            self.didMove(toParent: parent)
        }
    }

    /// Removes the controller and the managed view from its parent view controller
    /// - Parameters:
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may specify nil for this parameter.
    public func removePanelFromParent(animated: Bool, completion: (() -> Void)? = nil) {
        guard self.parent != nil else {
            completion?()
            return
        }

        layoutInsetsObservations.removeAll()

        slidableSheet.dismiss(animated: animated) { [weak self] in
            guard let self = self else { return }

            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            completion?()
        }
    }

    /// Moves the position to the specified position.
    /// - Parameters:
    ///     - to: Pass a SlidableSheetPosition value to move the surface view to the position.
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the view controller has finished moving. This block has no return value and takes no parameters. You may specify nil for this parameter.
    public func move(to: SlidableSheetPosition, animated: Bool, completion: (() -> Void)? = nil) {
        slidableSheet.move(to: to, animated: animated, completion: completion)
    }

    /// Sets the view controller responsible for the content portion of the floating panel..
    public func set(contentViewController: UIViewController?) {
        if let vc = _contentViewController {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        if let vc = contentViewController {
            let surfaceView = self.view as! SlidableSheetSurfaceView
            surfaceView.add(childView: vc.view)
            addChild(vc)
            vc.didMove(toParent: self)
        }

        _contentViewController = contentViewController
    }

    @available(*, unavailable, renamed: "set(contentViewController:)")
    public override func show(_ vc: UIViewController, sender: Any?) {
        if let target = self.parent?.targetViewController(forAction: #selector(UIViewController.show(_:sender:)), sender: sender) {
            target.show(vc, sender: sender)
        }
    }

    @available(*, unavailable, renamed: "set(contentViewController:)")
    public override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        if let target = self.parent?.targetViewController(forAction: #selector(UIViewController.showDetailViewController(_:sender:)), sender: sender) {
            target.showDetailViewController(vc, sender: sender)
        }
    }

    /// Tracks the specified scroll view to correspond with the scroll.
    ///
    /// - Attention:
    ///     The specified scroll view must be already assigned to the delegate property because the controller intermediates between the various delegate methods.
    ///
    public func track(scrollView: UIScrollView) {
        slidableSheet.scrollView = scrollView
        slidableSheet.userScrollViewDelegate = scrollView.delegate
        scrollView.delegate = slidableSheet
        switch contentInsetAdjustmentBehavior {
        case .always:
            if #available(iOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            } else {
                children.forEach { (vc) in
                    vc.automaticallyAdjustsScrollViewInsets = false
                }
            }
        default:
            break
        }
    }

    /// Returns the y-coordinate of the point at the origin of the surface view
    public func originYOfSurface(for pos: SlidableSheetPosition) -> CGFloat {
        switch pos {
        case .full:
            return slidableSheet.layoutAdapter.topY
        case .half:
            return slidableSheet.layoutAdapter.middleY
        case .tip:
            return slidableSheet.layoutAdapter.bottomY
        }
    }
}
