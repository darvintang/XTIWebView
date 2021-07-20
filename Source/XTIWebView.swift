//
//  XTIWebView.swift
//
//  Created by xtinput on 2021/4/20.
//

import UIKit
import WebKit

@objc public protocol XTIWebViewDelegate: NSObjectProtocol {
    @objc optional func userContentController(_ message: WKScriptMessage)
    @objc optional func titleChanged(_ title: String?)
    @objc optional func canGoBack(_ canGoBack: Bool)
}

public class XTIWebView: UIView {
    public lazy var configuration: WKWebViewConfiguration = {
        let tempConfiguration = WKWebViewConfiguration()
        return tempConfiguration
    }()

    public lazy var webView: WKWebView = {
        let tempWebView = WKWebView(frame: .zero, configuration: configuration)
        return tempWebView
    }()

    public lazy var progressView: XTIProgressView = {
        let tempProgressView = XTIProgressView()
        tempProgressView.isHidden = true
        return tempProgressView
    }()

    weak var delegate: XTIWebViewDelegate?

    public func add(_ scriptName: String) {
        self.configuration.userContentController.add(XTIScriptMessageHandler(self), name: scriptName)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.customizeInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.customizeInit()
    }

    fileprivate func customizeInit() {
        self.backgroundColor = .clear
        self.addSubview(self.webView)
        self.webView.translatesAutoresizingMaskIntoConstraints = false

        self.addConstraint(NSLayoutConstraint(item: self.webView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.webView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.webView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.webView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))

        self.configuration.userContentController.add(XTIScriptMessageHandler(self), name: "NativeBaseService")

        self.webView.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "loading", options: [.new, .old], context: nil)
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)

        self.addSubview(self.progressView)
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 2))
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "canGoBack")
        webView.removeObserver(self, forKeyPath: "title")
        webView.removeObserver(self, forKeyPath: "loading")
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            if self.webView.isLoading {
                self.progressView.isHidden = false
            } else {
                self.progressView.isHidden = true
            }
        } else if keyPath == "estimatedProgress" {
            self.progressView.setProgress((change?[.newKey] as? CGFloat) ?? 1.0, animated: true)
        } else if keyPath == "title" {
            self.delegate?.titleChanged?(change?[.newKey] as? String)
        } else if keyPath == "canGoBack" {
            self.delegate?.canGoBack?((change?[.newKey] as? Bool) ?? false)
        }
    }
}

fileprivate extension XTIWebView {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController?(message)
    }
}

class XTIScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var webView: XTIWebView?

    init(_ webView: XTIWebView) {
        super.init()
        self.webView = webView
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.webView?.userContentController(userContentController, didReceive: message)
    }
}
