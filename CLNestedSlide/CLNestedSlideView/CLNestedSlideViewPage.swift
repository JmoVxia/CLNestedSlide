//
//  NestedSlideViewPage.swift
//  NestedSlideView
//
//  Created by Chen JmoVxia on 2024/7/1.
//  Copyright © 2024 JmoVxia. All rights reserved.
//

import Foundation
import UIKit

// MARK: - CLScrollViewDelegateProxy

/// 内部代理拦截器，用于拦截和转发滚动视图代理方法
fileprivate class CLScrollViewDelegateProxy: NSObject, UIScrollViewDelegate {
    weak var externalDelegate: UIScrollViewDelegate?
    weak var nestedTarget: CLNestedSlideViewPage?
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) {
            return self
        } else if let externalDelegate = externalDelegate, externalDelegate.responds(to: aSelector) {
            return externalDelegate
        }
        return self
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if let externalDelegate = externalDelegate {
            return super.responds(to: aSelector) || externalDelegate.responds(to: aSelector)
        }
        return super.responds(to: aSelector)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 1. 处理内部嵌套滚动逻辑
        nestedTarget?.handleScrollViewDidScroll(scrollView)
        // 2. 转发给外部代理
        externalDelegate?.scrollViewDidScroll?(scrollView)
    }
}

// MARK: - CLScrollViewWrapper

/// 内部包装器，用于监听和拦截滚动视图代理变化
fileprivate class CLScrollViewWrapper: NSObject {
    weak var scrollView: UIScrollView?
    weak var nestedTarget: CLNestedSlideViewPage?
    private var proxy: CLScrollViewDelegateProxy?
    
    init(scrollView: UIScrollView, nestedTarget: CLNestedSlideViewPage) {
        self.scrollView = scrollView
        self.nestedTarget = nestedTarget
        super.init()
        
        scrollView.addObserver(self, forKeyPath: "delegate", options: [.new], context: nil)
        handleDelegateChange(scrollView.delegate)
    }
    
    deinit {
        scrollView?.removeObserver(self, forKeyPath: "delegate")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "delegate", let newDelegate = change?[.newKey] as? UIScrollViewDelegate {
            handleDelegateChange(newDelegate)
        }
    }
    
    private func handleDelegateChange(_ newDelegate: UIScrollViewDelegate?) {
        guard let scrollView = scrollView, let nestedTarget = nestedTarget else { return }
        
        // 如果已经是我们的代理则忽略
        if newDelegate is CLScrollViewDelegateProxy { return }
        
        // 创建或重用代理
        if proxy == nil {
            proxy = CLScrollViewDelegateProxy()
            proxy?.nestedTarget = nestedTarget
        }
        
        proxy?.externalDelegate = newDelegate
        scrollView.delegate = proxy
    }
}

// MARK: - Associated Object Keys

/// 运行时存储关联对象的键
fileprivate struct AssociatedKeys {
    static var isSwipeEnabledKey: Void?
    static var superScrollEnabledHandlerKey: Void?
    static var scrollViewWrapperKey: Void?
}

// MARK: - CLNestedSlideViewPage Protocol

/// 定义嵌套滑动视图页面要求的协议
public protocol CLNestedSlideViewPage: AnyObject where Self: UIView {
    /// 参与嵌套滚动的滚动视图
    var scrollView: UIScrollView { get }
}

// MARK: - CLNestedSlideViewPage 默认实现

public extension CLNestedSlideViewPage {
    
    // MARK: - 内部属性
    
    /// 指示页面是否可以滑动
    var isSwipeEnabled: Bool {
        get { 
            objc_getAssociatedObject(self, &AssociatedKeys.isSwipeEnabledKey) as? Bool ?? false 
        }
        set { 
            objc_setAssociatedObject(self, &AssociatedKeys.isSwipeEnabledKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) 
        }
    }
    
    /// 检查父滚动视图是否应启用时调用的处理器
    var superScrollEnabledHandler: ((Bool) -> Bool)? {
        get { 
            objc_getAssociatedObject(self, &AssociatedKeys.superScrollEnabledHandlerKey) as? ((Bool) -> Bool) 
        }
        set { 
            objc_setAssociatedObject(self, &AssociatedKeys.superScrollEnabledHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) 
        }
    }
    
    // MARK: - 公共方法
    
    /// 如果需要，设置滚动视图代理拦截
    /// 此方法应由 NestedSlideView 自动调用
    func setupScrollViewDelegateIfNeeded() {
        // 避免重复设置
        guard objc_getAssociatedObject(self, &AssociatedKeys.scrollViewWrapperKey) == nil else { return }
        
        let wrapper = CLScrollViewWrapper(scrollView: scrollView, nestedTarget: self)
        objc_setAssociatedObject(self, &AssociatedKeys.scrollViewWrapperKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - 私有辅助方法

fileprivate extension CLNestedSlideViewPage {
    
    /// 处理滚动视图滚动事件以协调嵌套滚动
    /// - Parameter scrollView: 滚动视图
    func handleScrollViewDidScroll(_ scrollView: UIScrollView) {
        // 不再需要通知代理，嵌套滚动逻辑已简化
        
        guard isSwipeEnabled else {
            scrollView.contentOffset.y = 0
            return
        }
        
        guard scrollView.contentOffset.y <= 0 else { return }
        guard let superScrollEnabledHandler = superScrollEnabledHandler, 
              !superScrollEnabledHandler(true) else { return }
        
        isSwipeEnabled = false
    }
}
