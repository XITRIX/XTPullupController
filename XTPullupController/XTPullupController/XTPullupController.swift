//
//  XTPullupController.swift
//  XTPullupController
//
//  Created by Даниил Виноградов on 12.04.2021.
//

import UIKit

open class XTPullupController: UIViewController {
    public enum State {
        case uninstalled
        case hidden
        case collapsed
        case halfState
        case expanded
    }
    
    open var topOffset: CGFloat { 64 }
    open var collapsedHeight: CGFloat { 44 }
    open var middleState: CGFloat { 0.4 }
    
    open var cornerRadius: CGFloat { 16 }
    open var respectContentViewHeight: Bool { false }
    
    open var contentView: UIView?
    
    private(set) var currentState: State = .uninstalled
    private(set) var panGesture = UIPanGestureRecognizer()
    
    private var constraints: [NSLayoutConstraint] = []
    private var embeddedScrollOffset: CGPoint = .zero
    private var bottomConstraint: NSLayoutConstraint!
    private var embaddedScrollView: UIScrollView?
    private var lastTranslation: CGPoint = .zero
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        panGesture.addTarget(self, action: #selector(handlePanGesture))
        view.addGestureRecognizer(panGesture)
        
        if let scroll = view.subviews.first as? UIScrollView {
            embaddedScrollView = scroll
            scroll.panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture))
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layer.addObserver(self, forKeyPath: "position", options: .new, context: nil)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.layer.removeObserver(self, forKeyPath: "position")
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.layer.cornerRadius = cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
        
        // shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 6.0
        
        view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
        
        setState(currentState, animated: false)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            positionDidChange()
        }
    }
    
    open func positionDidChange() {
        guard let parent = parent
        else { return }
        
        let bottomOffset = parent.view.frame.height - view.frame.minY - parent.view.safeAreaInsets.bottom - collapsedHeight
        let alpha = min(1, max(0, bottomOffset / 44))
        contentView?.alpha = alpha
    }
    
    open func setState(_ state: State, animated: Bool = true) {
        var target: CGFloat = 0
        switch state {
        case .collapsed:
            target = clampOffset(CGFloat.greatestFiniteMagnitude)
        case .halfState:
            target = view.frame.height * (1 - middleState)
        case .expanded:
            target = 0
        case .hidden:
            target = view.frame.height
        default:
            break
        }
        
        if state != .hidden {
            view.isHidden = false
        }
        
        currentState = state
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
                self.bottomConstraint.constant = target
                self.parent?.view.layoutIfNeeded()
            } completion: { _ in
                self.view.isHidden = state == .hidden
            }
        } else {
            self.view.isHidden = state == .hidden
            self.bottomConstraint.constant = target
            self.parent?.view.layoutIfNeeded()
        }
    }
    
    open func applyTo(_ viewController: UIViewController, in state: State = .halfState, order: Int? = nil) {
        currentState = state
        
        viewController.addChild(self)
        
        if let order = order {
            viewController.view.insertSubview(view, at: order)
        } else {
            viewController.view.addSubview(view)
        }
        
        didMove(toParent: viewController)
        
        setupConstraints()
        setState(state, animated: false)
    }
    
    open func remove() {
        guard parent != nil
        else { return }
        
        constraints.forEach{ $0.isActive = false }
        constraints.removeAll()
        
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        
        currentState = .uninstalled
    }
    
    @objc private func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        var translation = panGesture.translation(in: parent?.view)
        translation.x = 0
        
        defer {
            lastTranslation = translation
        }
        
        if panGesture.state == .began {
            lastTranslation = translation
        }
        
        let delta = translation - lastTranslation
        
        if self.panGesture !== panGesture {
            if let embeddedScroll = embaddedScrollView {
                defer {
                    embeddedScrollOffset = embeddedScroll.contentOffset
                }
                
                if panGesture.state == .began {
                    lastTranslation = translation
                    embeddedScrollOffset = embeddedScroll.contentOffset
                }
                
                if bottomConstraint.constant > 0 && (delta.y <= 0 || embeddedScrollOffset.y <= 0)
                {
                    embeddedScrollOffset.y = max (0, embeddedScrollOffset.y)
                    embeddedScroll.setContentOffset(embeddedScrollOffset, animated: false)
                } else {
                    if embeddedScroll.contentOffset.y > 0 {
                        return
                    }
                }
            }
        }
        
        switch panGesture.state {
        case .began:
            break
        case .changed:
            bottomConstraint.constant = clampOffset(bottomConstraint.constant + delta.y)
            break
        case .ended:
            let velocity = panGesture.velocity(in: parent?.view)
            startDeceleration(with: velocity)
            break
        default:
            break
        }
        
    }
    
    private func startDeceleration(with velocity: CGPoint) {
        let decelerationRate: CGFloat = 0.991
        let threshold = 0.5 / UIScreen.main.scale
        let parameters = DecelerationTimingParameters(initialValue: CGPoint(x: 0, y: bottomConstraint.constant),
                                                      initialVelocity: velocity,
                                                      decelerationRate: decelerationRate,
                                                      threshold: threshold)
        
        let target = self.targetPosition(parameters.destination.y)
        currentState = target.state
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.bottomConstraint.constant = target.pos
            self.parent?.view.layoutIfNeeded()
        }
    }
    
    private func targetPosition(_ pos: CGFloat) -> (pos: CGFloat, state: State) {
        let available = [(0, State.expanded), ((view.frame.height * (1 - middleState)), State.halfState), (clampOffset(CGFloat.greatestFiniteMagnitude), State.collapsed)]
        return available.sorted(by: { abs(pos - $0.0) < abs(pos - $1.0) }).first!
    }
    
    private func clampOffset(_ offset: CGFloat) -> CGFloat {
        let safe = parent?.view.safeAreaInsets.bottom ?? 0
        return max(0, min(self.view.frame.height - self.collapsedHeight - safe, offset))
    }
    
    private func setupConstraints() {
        guard let parent = parent
        else { return }
        
        bottomConstraint = view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor)
        
        constraints.append(bottomConstraint)
        constraints.append(view.widthAnchor.constraint(equalTo: parent.view.widthAnchor))
        
        if respectContentViewHeight {
            constraints.append(view.heightAnchor.constraint(lessThanOrEqualTo: parent.view.heightAnchor, constant: -topOffset))
            constraints.append(view.topAnchor.constraint(greaterThanOrEqualTo: parent.view.topAnchor, constant: topOffset))
        } else {
            constraints.append(view.heightAnchor.constraint(equalTo: parent.view.heightAnchor, constant: -topOffset))
        }
        
        constraints.forEach { $0.isActive = true }
    }
}
