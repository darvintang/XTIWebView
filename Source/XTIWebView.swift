//
//  XTIWebView.swift
//
//  Created by xtinput on 2021/4/20.
//

import UIKit
import WebKit
import XTILoger

let webLoger = XTILoger(logerName: "XTIWebView")

@objc public protocol XTIWebViewDelegate: NSObjectProtocol {
    @objc optional func titleChanged(_ title: String?)
    @objc optional func canGoBack(_ canGoBack: Bool)

    @objc optional func userContentController(_ message: WKScriptMessage)
    @objc optional func synJSToNative(_ message: String) -> String?

    @objc optional func showAlert(_ message: String, completion: @escaping () -> Void)
    @objc optional func showConfirm(_ message: String, completion: @escaping (Bool) -> Void)

    @objc optional func decidePolicy(_ navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
}

open class XTIWebView: UIView {
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

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.customizeInit()
    }

    public required init?(coder: NSCoder) {
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

        self.addSubview(self.progressView)
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 2))
        self.addConstraint(NSLayoutConstraint(item: self.progressView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))

        self.configuration.userContentController.add(XTIScriptMessageHandler(self), name: "NativeBaseService")

        self.webView.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "loading", options: [.new, .old], context: nil)
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)

        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self

        self.webView.scrollView.showsVerticalScrollIndicator = false
        self.webView.scrollView.showsHorizontalScrollIndicator = false
        self.webView.scrollView.backgroundColor = .clear
    }

    deinit {
        webLoger.info("deinit")
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

extension XTIWebView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if self.delegate?.responds(to: Selector("decidePolicy(_:decisionHandler:)")) ?? false {
            self.delegate?.decidePolicy?(navigationAction, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension XTIWebView: WKUIDelegate {
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        if self.delegate?.responds(to: Selector("showAlert(_:completion:)")) ?? false {
            self.delegate?.showAlert?(message, completion: completionHandler)
        } else {
            let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
                completionHandler()
            }))
            self.selfVC?.present(alertController, animated: true, completion: nil)
        }
    }

    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        if self.delegate?.responds(to: Selector("showConfirm(_:completion:)")) ?? false {
            self.delegate?.showConfirm?(message, completion: completionHandler)
        } else {
            let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .default, handler: { _ in
                completionHandler(false)
            }))
            alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
                completionHandler(true)
            }))
            self.selfVC?.present(alertController, animated: true, completion: nil)
        }
    }

    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let value = self.delegate?.synJSToNative?(prompt)
        completionHandler(value)
    }
}

fileprivate extension XTIWebView {
    var selfVC: UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if responder?.isKind(of: UIViewController.classForCoder()) ?? false {
                return responder as? UIViewController
            }
            responder = responder?.next
        }
        return nil
    }
}

extension XTIWebView {
    public func addJSToNative(_ scriptName: String) {
        self.configuration.userContentController.add(XTIScriptMessageHandler(self), name: scriptName)
    }

    /// 原生调用JS的方法，只支持一个参数，多参数请封装
    /// - Parameters:
    ///   - funcName: 方法名，不需要()
    ///   - value: 参数，如果函数没有参数就不传递
    ///   - completion: 调用结果
    public func nativeToJS(_ funcName: String, value: String? = nil, completion: ((Any?, Error?) -> Void)? = nil) {
        webLoger.info("原生调用JS方法：", funcName, value)
        self.webView.evaluateJavaScript(funcName + (value == nil ? "()" : "('\(value!)')"), completionHandler: completion)
    }
}

public extension XTIWebView {
    /// 重写该方法可以拦截并处理JS调用原生的功能
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
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
