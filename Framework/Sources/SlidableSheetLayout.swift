import UIKit

public protocol SlidableSheetLayout: class {
    /// Returns the initial position of a floating panel.
    var initialPosition: SlidableSheetPosition { get }

    /// Returns a set of SlidableSheetPosition objects to tell the applicable positions of the floating panel controller. Default is all of them.
    var supportedPositions: Set<SlidableSheetPosition> { get }

    /// Return the interaction buffer to the top from the top position. Default is 6.0.
    var topInteractionBuffer: CGFloat { get }

    /// Return the interaction buffer to the bottom from the bottom position. Default is 6.0.
    var bottomInteractionBuffer: CGFloat { get }

    /// Returns a CGFloat value to determine a floating panel height for each position(full, half and tip).
    /// A value for full position indicates a top inset from a safe area.
    /// On the other hand, values for half and tip positions indicate bottom insets from a safe area.
    /// If a position doesn't contain the supported positions, return nil.
    func insetFor(position: SlidableSheetPosition) -> CGFloat?

    /// Returns X-axis and width layout constraints of the surface view of a floating panel.
    /// You must not include any Y-axis and height layout constraints of the surface view
    /// because their constraints will be configured by the floating panel controller.
    /// By default, the width of a surface view fits a safe area.
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint]

    /// Returns a CGFloat value to determine the backdrop view's alpha for a position.
    ///
    /// Default is 0.3 at full position, otherwise 0.0.
    func backdropAlphaFor(position: SlidableSheetPosition) -> CGFloat
}

public extension SlidableSheetLayout {
    var topInteractionBuffer: CGFloat { return 6.0 }
    var bottomInteractionBuffer: CGFloat { return 6.0 }

    var supportedPositions: Set<SlidableSheetPosition> {
        return Set(SlidableSheetPosition.allCases)
    }

    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.sideLayoutGuide.leftAnchor, constant: 0.0),
            surfaceView.rightAnchor.constraint(equalTo: view.sideLayoutGuide.rightAnchor, constant: 0.0),
        ]
    }

    func backdropAlphaFor(position: SlidableSheetPosition) -> CGFloat {
        return position == .full ? 0.3 : 0.0
    }
}

public class SlidableSheetDefaultLayout: SlidableSheetLayout {
    public var initialPosition: SlidableSheetPosition {
        return .half
    }

    public func insetFor(position: SlidableSheetPosition) -> CGFloat? {
        switch position {
        case .full: return 18.0
        case .half: return 262.0
        case .tip: return 69.0
        }
    }
}

public class SlidableSheetDefaultLandscapeLayout: SlidableSheetLayout {
    public var initialPosition: SlidableSheetPosition {
        return .tip
    }
    public var supportedPositions: Set<SlidableSheetPosition> {
        return [.full, .tip]
    }

    public func insetFor(position: SlidableSheetPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .tip: return 69.0
        default: return nil
        }
    }

    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.sideLayoutGuide.leftAnchor, constant: 0.0),
            surfaceView.rightAnchor.constraint(equalTo: view.sideLayoutGuide.rightAnchor, constant: 0.0),
        ]
    }
}


class SlidableSheetLayoutAdapter {
    private weak var surfaceView: SlidableSheetSurfaceView!
    private weak var backdropVIew: SlidableSheetBackdropView!

    var layout: SlidableSheetLayout {
        didSet { checkConsistance(of: layout) }
    }

    var safeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            updateHeight()
        }
    }

    private var parentHeight: CGFloat = 0.0
    private var heightBuffer: CGFloat = 88.0 // For bounce
    private var fixedConstraints: [NSLayoutConstraint] = []
    private var fullConstraints: [NSLayoutConstraint] = []
    private var halfConstraints: [NSLayoutConstraint] = []
    private var tipConstraints: [NSLayoutConstraint] = []
    private var offConstraints: [NSLayoutConstraint] = []
    private var heightConstraints: [NSLayoutConstraint] = []

    private var fullInset: CGFloat {
        return layout.insetFor(position: .full) ?? 0.0
    }
    private var halfInset: CGFloat {
        return layout.insetFor(position: .half) ?? 0.0
    }
    private var tipInset: CGFloat {
        return layout.insetFor(position: .tip) ?? 0.0
    }

    var topY: CGFloat {
        if layout.supportedPositions.contains(.full) {
            return (safeAreaInsets.top + fullInset)
        } else {
            return middleY
        }
    }

    var middleY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + halfInset)
    }

    var bottomY: CGFloat {
        if layout.supportedPositions.contains(.tip) {
            return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + tipInset)
        } else {
            return middleY
        }
    }

    var safeAreaBottomY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom)
    }

    var adjustedContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0.0,
                            left: 0.0,
                            bottom: safeAreaInsets.bottom,
                            right: 0.0)
    }

    func positionY(for pos: SlidableSheetPosition) -> CGFloat {
        switch pos {
        case .full:
            return topY
        case .half:
            return middleY
        case .tip:
            return bottomY
        }
    }

    init(surfaceView: SlidableSheetSurfaceView, backdropView: SlidableSheetBackdropView, layout: SlidableSheetLayout) {
        self.layout = layout
        self.surfaceView = surfaceView
        self.backdropVIew = backdropView
    }

    func prepareLayout(toParent parent: UIViewController) {
        parentHeight = parent.view.frame.height

        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        backdropVIew.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.deactivate(fixedConstraints + fullConstraints + halfConstraints + tipConstraints + offConstraints)

        // Fixed constraints of surface and backdrop views
        let surfaceConstraints = layout.prepareLayout(surfaceView: surfaceView, in: parent.view!)
        let backdroptConstraints = [
            backdropVIew.topAnchor.constraint(equalTo: parent.view.topAnchor,
                                              constant: 0.0),
            backdropVIew.leftAnchor.constraint(equalTo: parent.view.leftAnchor,
                                               constant: 0.0),
            backdropVIew.rightAnchor.constraint(equalTo: parent.view.rightAnchor,
                                                constant: 0.0),
            backdropVIew.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor,
                                                 constant: 0.0),
            ]
        fixedConstraints = surfaceConstraints + backdroptConstraints

        // Flexible surface constarints for full, half, tip and off
        fullConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.topAnchor,
                                             constant: fullInset),
        ]
        halfConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.bottomAnchor,
                                             constant: -halfInset),
        ]
        tipConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.bottomAnchor,
                                             constant: -tipInset),
        ]
        offConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: 0.0),
        ]
    }

    // The method is separated from prepareLayout(to:) for the rotation support
    // It must be called in SlidableSheetController.traitCollectionDidChange(_:)
    func updateHeight() {
        defer {
            UIView.performWithoutAnimation {
                surfaceView.superview!.layoutIfNeeded()
            }
        }

        NSLayoutConstraint.deactivate(heightConstraints)
        let height = parentHeight - (safeAreaInsets.top + fullInset)
        heightConstraints = [
            surfaceView.heightAnchor.constraint(equalToConstant: height)
        ]
        NSLayoutConstraint.activate(heightConstraints)
        surfaceView.set(bottomOverflow: heightBuffer)
    }

    func activateLayout(of state: SlidableSheetPosition?) {
        defer {
            surfaceView.superview!.layoutIfNeeded()
        }

        NSLayoutConstraint.activate(fixedConstraints)

        guard var state = state else {
            NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints)
            NSLayoutConstraint.activate(offConstraints)
            return
        }

        if layout.supportedPositions.contains(state) == false {
            state = layout.initialPosition
        }

        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)
        switch state {
        case .full:
            NSLayoutConstraint.deactivate(halfConstraints + tipConstraints + offConstraints)
            NSLayoutConstraint.activate(fullConstraints)
        case .half:
            NSLayoutConstraint.deactivate(fullConstraints + tipConstraints + offConstraints)
            NSLayoutConstraint.activate(halfConstraints)
        case .tip:
            NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + offConstraints)
            NSLayoutConstraint.activate(tipConstraints)
        }
    }

    private func checkConsistance(of layout: SlidableSheetLayout) {
        // Verify layout configurations
        let supportedPositions = layout.supportedPositions

        assert(supportedPositions.count > 0)
        assert(supportedPositions.contains(layout.initialPosition),
               "Does not include an initial potision(\(layout.initialPosition)) in supportedPositions(\(supportedPositions))")

        supportedPositions.forEach { pos in
            assert(layout.insetFor(position: pos) != nil,
                   "Undefined an inset for a pos(\(pos))")
        }

        if halfInset > 0 {
            assert(halfInset > tipInset, "Invalid half and tip insets")
        }
        if fullInset > 0 {
            assert(middleY > topY, "Invalid insets")
            assert(bottomY > topY, "Invalid insets")
        }
    }
}
