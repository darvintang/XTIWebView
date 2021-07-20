//
//  XTIProgressView.swift
//  XTIWebView
//
//  Created by xtinput on 2021/7/20.
//

import UIKit

public class XTIProgressView: UIView {
    // 进度条完成部分的渐变颜色，设置单个为纯色，设置多个为渐变色
    public var progressColors: [UIColor] = [.systemBlue] {
        didSet {
            if self.progressColors.count == 0 {
                self.gradientLayer.colors = nil
            } else if self.progressColors.count == 1 {
                let color = self.progressColors[0]
                self.gradientLayer.colors = [color, color].map { $0.cgColor }
            } else {
                self.gradientLayer.colors = self.progressColors.map { $0.cgColor }
            }
        }
    }

    // 进度条完成部分的圆角半径
    public var progressCornerRadius: CGFloat = 0 {
        didSet {
            self.maskLayer.cornerRadius = self.progressCornerRadius
        }
    }

    // 进度完成部分的内间距
    public var progressEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }

    // 当前进度
    public var progress: CGFloat {
        get {
            return self.privateProgress
        }
        set {
            self.setProgress(newValue, animated: false)
        }
    }

    // 渐变Layer
    public let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.anchorPoint = .zero
        layer.startPoint = .zero
        layer.endPoint = CGPoint(x: 1.0, y: 0.0)

        return layer
    }()

    // 动画持续时间
    public var animationDuration: TimeInterval = 0.3

    // 动画时间函数
    public var timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .default)

    // 进度更新动画过程中的回调，在这里可以拿到当前进度及进度条的frame
    public var progressUpdating: ((CGFloat, CGRect) -> Void)?

    private var privateProgress: CGFloat = 0
    private let maskLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.white.cgColor

        return layer
    }()

    // MARK: - Lifecycle

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.commonInit()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInit()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        self.gradientLayer.frame = bounds.inset(by: self.progressEdgeInsets)
        var bounds = self.gradientLayer.bounds
        bounds.size.width *= CGFloat(self.progress)
        self.maskLayer.frame = bounds
    }

    // MARK: - Private

    private func commonInit() {
        let color = self.progressColors[0]
        self.gradientLayer.colors = [color, color].map { $0.cgColor }
        self.gradientLayer.mask = self.maskLayer
        layer.insertSublayer(self.gradientLayer, at: 0)
    }

    @objc private func displayLinkAction() {
        guard let frame = maskLayer.presentation()?.frame else { return }
        let progress = frame.size.width / self.gradientLayer.frame.size.width
        self.progressUpdating?(progress, frame)
    }

    // MARK: - Public

    public func setProgress(_ progress: CGFloat, animated: Bool) {
        let validProgress = min(1.0, max(0.0, progress))
        if self.privateProgress == validProgress {
            return
        }
        self.privateProgress = validProgress

        // 动画时长
        var duration = animated ? self.animationDuration : 0
        if duration < 0 {
            duration = 0
        }

        var displayLink: CADisplayLink?
        if duration > 0 {
            // 开启CADisplayLink
            displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkAction))
            // 使用common模式，使其在UIScrollView滑动时依然能得到回调
            displayLink?.add(to: .main, forMode: .common)
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(self.timingFunction)
        CATransaction.setCompletionBlock {
            // 停止CADisplayLink
            displayLink?.invalidate()
            if duration == 0 {
                // 更新回调
                self.progressUpdating?(validProgress, self.maskLayer.frame)
            } else {
                if let _ = self.maskLayer.presentation() {
                    self.displayLinkAction()
                } else {
                    self.progressUpdating?(validProgress, self.maskLayer.frame)
                }
            }
        }

        // 更新maskLayer的frame
        var bounds = self.gradientLayer.bounds
        bounds.size.width *= CGFloat(validProgress)
        self.maskLayer.frame = bounds

        CATransaction.commit()
    }
}
