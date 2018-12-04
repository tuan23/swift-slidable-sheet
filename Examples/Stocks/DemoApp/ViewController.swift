import UIKit
import SlidableSheet

class ViewController: UIViewController, SlidableSheetControllerDelegate {
    @IBOutlet var topBannerView: UIImageView!
    @IBOutlet weak var labelStackView: UIStackView!
    @IBOutlet weak var bottomToolView: UIView!

    var fpc: SlidableSheetController!
    var newsVC: NewsViewController!

    var initialColor: UIColor = .black
    override func viewDidLoad() {
        super.viewDidLoad()
        initialColor = view.backgroundColor!
        // Initialize SlidableSheetController
        fpc = SlidableSheetController()
        fpc.delegate = self

        // Initialize SlidableSheetController and add the view
        fpc.surfaceView.backgroundColor = UIColor(displayP3Red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
        fpc.surfaceView.cornerRadius = 24.0
        fpc.surfaceView.shadowHidden = true
        fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
        fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)

        newsVC = storyboard?.instantiateViewController(withIdentifier: "News") as? NewsViewController

        // Set a content view controller
        fpc.set(contentViewController: newsVC)
        fpc.track(scrollView: newsVC.scrollView)

        fpc.addPanel(toParent: self, belowView: bottomToolView, animated: false)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: SlidableSheetControllerDelegate

    func slidableSheet(_ vc: SlidableSheetController, layoutFor newCollection: UITraitCollection) -> SlidableSheetLayout? {
        return SlidableSheetStocksLayout()
    }

    func slidableSheet(_ vc: SlidableSheetController, behaviorFor newCollection: UITraitCollection) -> SlidableSheetBehavior? {
        return SlidableSheetStocksBehavior()
    }

    func slidableSheetWillBeginDragging(_ vc: SlidableSheetController) {
        if vc.position == .full {
            // Dimiss top bar with dissolve animation
            UIView.animate(withDuration: 0.25) {
                self.labelStackView.alpha = 1.0
                self.view.backgroundColor = self.initialColor
            }
        }
    }
    func slidableSheetDidEndDragging(_ vc: SlidableSheetController, withVelocity velocity: CGPoint, targetPosition: SlidableSheetPosition) {
        if targetPosition == .full {
            // Present top bar with dissolve animation
            UIView.animate(withDuration: 0.25) {
                self.labelStackView.alpha = 0.5
                self.view.backgroundColor = .black
            }
        }
    }
}

class NewsViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
}


// MARK: My custom layout

class SlidableSheetStocksLayout: SlidableSheetLayout {
    var initialPosition: SlidableSheetPosition {
        return .tip
    }

    var topInteractionBuffer: CGFloat { return 0.0 }
    var bottomInteractionBuffer: CGFloat { return 0.0 }

    func insetFor(position: SlidableSheetPosition) -> CGFloat? {
        switch position {
        case .full: return 56.0
        case .half: return 262.0
        case .tip: return 85.0 + 44.0 // Visible + ToolView
        }
    }

    func backdropAlphaFor(position: SlidableSheetPosition) -> CGFloat {
        return 0.0
    }
}

// MARK: My custom behavior

class SlidableSheetStocksBehavior: SlidableSheetBehavior {
    var velocityThreshold: CGFloat {
        return 15.0
    }

    func interactionAnimator(_ fpc: SlidableSheetController, to targetPosition: SlidableSheetPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let timing = timeingCurve(to: targetPosition, with: velocity)
        return UIViewPropertyAnimator(duration: 0, timingParameters: timing)
    }

    private func timeingCurve(to: SlidableSheetPosition, with velocity: CGVector) -> UITimingCurveProvider {
        let damping = self.damping(with: velocity)
        return UISpringTimingParameters(dampingRatio: damping,
                                        frequencyResponse: 0.4,
                                        initialVelocity: velocity)
    }

    private func damping(with velocity: CGVector) -> CGFloat {
        switch velocity.dy {
        case ...(-velocityThreshold):
            return 0.7
        case velocityThreshold...:
            return 0.7
        default:
            return 1.0
        }
    }
}
