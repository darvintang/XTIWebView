//
//  XTIWebErrorView.swift
//  XTIWebView
//
//  Created by xtinput on 2021/7/21.
//

import UIKit

open class XTIWebErrorView: UIView {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .red
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var reloadBlock: (() -> Void)?
}

extension XTIWebErrorView {
    public func show(_ error: Error) {
        self.superview?.bringSubviewToFront(self)
        UIView.animate(withDuration: 0.25) {
            self.isHidden = false
        }
    }
}
