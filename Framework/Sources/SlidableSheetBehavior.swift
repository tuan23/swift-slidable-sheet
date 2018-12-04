import UIKit

public protocol SlidableSheetBehavior {
    func interactionAnimator(_ fpc: SlidableSheetController, to targetPosition: SlidableSheetPosition, with velocity: CGVector) -> UIViewPropertyAnimator

    func addAnimator(_ fpc: SlidableSheetController, to: SlidableSheetPosition) -> UIViewPropertyAnimator

    func removeAnimator(_ fpc: SlidableSheetController, from: SlidableSheetPosition) -> UIViewPropertyAnimator

    func moveAnimator(_ fpc: SlidableSheetController, from: SlidableSheetPosition, to: SlidableSheetPosition) -> UIViewPropertyAnimator

    var removalVelocityThreshold: CGFloat { get }

    func removalInteractionAnimator(_ fpc: SlidableSheetController, with velocity: CGVector) -> UIViewPropertyAnimator
}

public extension SlidableSheetBehavior {
    func addAnimator(_ fpc: SlidableSheetController, to: SlidableSheetPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }

    func removeAnimator(_ fpc: SlidableSheetController, from: SlidableSheetPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }

    func moveAnimator(_ fpc: SlidableSheetController, from: SlidableSheetPosition, to: SlidableSheetPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }

    var removalVelocityThreshold: CGFloat {
        return 10.0
    }

    func removalInteractionAnimator(_ fpc: SlidableSheetController, with velocity: CGVector) -> UIViewPropertyAnimator {
        log.debug("velocity", velocity)
        let timing = UISpringTimingParameters(dampingRatio: 1.0,
                                        frequencyResponse: 0.3,
                                        initialVelocity: velocity)
        return UIViewPropertyAnimator(duration: 0, timingParameters: timing)
    }
}

class SlidableSheetDefaultBehavior: SlidableSheetBehavior {
    func interactionAnimator(_ fpc: SlidableSheetController, to targetPosition: SlidableSheetPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let timing = timeingCurve(with: velocity)
        return UIViewPropertyAnimator(duration: 0, timingParameters: timing)
    }

    private func timeingCurve(with velocity: CGVector) -> UITimingCurveProvider {
        log.debug("velocity", velocity)
        let damping = self.getDamping(with: velocity)
        return UISpringTimingParameters(dampingRatio: damping,
                                        frequencyResponse: 0.3,
                                        initialVelocity: velocity)
    }

    private let velocityThreshold: CGFloat = 8.0
    private func getDamping(with velocity: CGVector) -> CGFloat {
        let dy = abs(velocity.dy)
        if dy > velocityThreshold {
            return 0.7
        } else {
            return 1.0
        }
    }
}
