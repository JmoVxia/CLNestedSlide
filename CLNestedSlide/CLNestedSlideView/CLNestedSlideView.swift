//
//  NestedSlideView.swift
//  NestedSlideView
//
//  Created by Chen JmoVxia on 2024/7/1.
//  Copyright © 2024 JmoVxia. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - CLMultiGestureScrollView

/// 支持多手势同时识别的滚动视图
/// 仅在 CLNestedSlideView 框架内部使用
fileprivate class CLMultiGestureScrollView: UIScrollView {
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIGestureRecognizerDelegate

extension CLMultiGestureScrollView: UIGestureRecognizerDelegate {
    /// 允许与其他手势识别器同时识别
    /// - Parameters:
    ///   - gestureRecognizer: 当前手势识别器
    ///   - otherGestureRecognizer: 其他手势识别器
    /// - Returns: 始终返回 true 以允许同时识别
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - CLObservingScrollView

/// 支持 contentSize 变化监听的滚动视图，仅在 CLNestedSlideView 内部使用
fileprivate class CLObservingScrollView: UIScrollView {
    var onContentSizeChanged: ((CGSize) -> Void)?
    override var contentSize: CGSize {
        didSet {
            guard oldValue != contentSize else { return }
            onContentSizeChanged?(contentSize)
        }
    }
}

// MARK: - CLNestedSlideViewDataSource

/// 嵌套滑动视图数据源协议
public protocol CLNestedSlideViewDataSource: AnyObject {
    /// 返回嵌套滑动视图中的页面数量
    /// - Parameter nestedSlideView: 嵌套滑动视图实例
    /// - Returns: 页面数量
    func numberOfPages(in nestedSlideView: CLNestedSlideView) -> Int
    
    /// 返回指定索引的页面视图
    /// - Parameters:
    ///   - nestedSlideView: 嵌套滑动视图实例
    ///   - index: 页面索引
    /// - Returns: 符合 NestedSlideViewPage 协议的视图
    func nestedSlideView(_ nestedSlideView: CLNestedSlideView, pageFor index: Int) -> CLNestedSlideViewPage
}

// MARK: - CLNestedSlideViewDelegate

/// 嵌套滑动视图代理协议
public protocol CLNestedSlideViewDelegate: AnyObject {
    /// 页面滑动过程中调用（实时回调）
    /// - Parameters:
    ///   - nestedSlideView: 嵌套滑动视图实例
    ///   - scrollView: 内容滚动视图
    ///   - progress: 滑动进度（0.0 到 页面数-1）
    func contentScrollViewDidScroll(_ nestedSlideView: CLNestedSlideView, scrollView: UIScrollView, progress: CGFloat)
    
    /// 当内容滚动到指定页面时调用
    /// - Parameter index: 当前页面索引
    func contentScrollViewDidScrollToPage(at index: Int)
}

// MARK: - CLNestedSlideViewDelegate 默认实现

public extension CLNestedSlideViewDelegate {
    /// 页面滑动过程中的默认实现（可选）
    func contentScrollViewDidScroll(_ nestedSlideView: CLNestedSlideView, scrollView: UIScrollView, progress: CGFloat) {
        // 默认空实现，子类可选择实现
    }
    
    func contentScrollViewDidScrollToPage(at index: Int) {}
}

// MARK: - CLNestedSlideView

/// 提供嵌套滚动功能的视图，包含头部视图、悬停视图和分页内容
public class CLNestedSlideView: UIView {
    
    // MARK: - 公共属性
    
    /// 顶部头部视图
    public var headerView: UIView? {
        didSet {
            guard headerView != oldValue else { return }
            updateStackView(headStackView, with: headerView, oldValue: oldValue, at: 0)
        }
    }
    
    /// 滚动时保持可见的悬停视图
    public var hoverView: UIView? {
        didSet {
            guard hoverView != oldValue else { return }
            updateStackView(bottomStackView, with: hoverView, oldValue: oldValue, at: 0)
        }
    }
    
    /// 嵌套滑动视图的数据源
    public weak var dataSource: CLNestedSlideViewDataSource?
    
    /// 嵌套滑动视图的代理
    public weak var delegate: CLNestedSlideViewDelegate?
    
    /// 当前是否启用懒加载模式（只读）
    public var isLazyLoadingEnabled: Bool { isLazyLoading }
    
    /// 当前页面索引
    public var currentPageIndex: Int {
        get { currentIndex }
        set {
            let targetIndex = min(max(newValue, 0), pageCount - 1)
            if targetIndex != currentIndex { scrollToPage(at: targetIndex, animated: false) }
        }
    }
    
    /// 总页数
    public var numberOfPages: Int { pageCount }
    
    /// 当前可见页面
    public var currentPage: CLNestedSlideViewPage? { visiblePage }
    
        /// 是否允许横向滑动
    public var isHorizontalScrollEnabled: Bool {
        get { contentScrollView.isScrollEnabled }
        set { contentScrollView.isScrollEnabled = newValue }
    }
    
    // MARK: - 私有属性
    
    /// 主滚动视图，支持垂直滚动
    private lazy var mainScrollView: CLMultiGestureScrollView = {
        let scrollView = CLMultiGestureScrollView()
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    /// 内容滚动视图，支持水平分页滚动
    private lazy var contentScrollView: CLObservingScrollView = {
        let scrollView = CLObservingScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.onContentSizeChanged = { [weak self] _ in
            guard let self = self else { return }
            self.scrollToPage(at: self.currentPageIndex, animated: false)
        }
        return scrollView
    }()
    
    /// 主堆栈视图，包含顶部和底部堆栈
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    /// 头部堆栈视图
    private lazy var headStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    /// 底部堆栈视图
    private lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    /// 水平堆栈视图，管理页面布局和自动撑开 contentSize
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    /// 当前页面索引
    private var currentIndex = 0 {
        didSet {
            guard currentIndex != oldValue else { return }
            loadPage(at: currentIndex)
            delegate?.contentScrollViewDidScrollToPage(at: currentIndex)
        }
    }
    
    /// 当前可见的页面
    private var visiblePage: CLNestedSlideViewPage?
    /// 页面缓存
    private var pageCache = [Int: CLNestedSlideViewPage]()
    /// 占位 UIView 数组，用于未加载的页面
    private var placeholderViews = [UIView]()
    /// 页面总数
    private var pageCount = 0
    /// 是否允许滑动
    private var isSwipeEnabled = true
    /// 是否启用懒加载模式（初始化后不可修改）
    private let isLazyLoading: Bool
    
    // MARK: - 初始化
    
    public init(frame: CGRect = .zero, isLazyLoading: Bool = true) {
        self.isLazyLoading = isLazyLoading
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    public override init(frame: CGRect) {
        self.isLazyLoading = true
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        self.isLazyLoading = true
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - 公共方法
    
    /// 重新加载所有页面并刷新视图
    public func reload() {
        guard let dataSource = dataSource else { return }
        guard pageCount != dataSource.numberOfPages(in: self) || pageCache.isEmpty else { return }
        pageCount = dataSource.numberOfPages(in: self)
        if !isLazyLoading { pageCache.removeAll() }
        setupPlaceholderViews()
        guard pageCount > 0 else { return }
        currentIndex = min(currentIndex, pageCount - 1)
        loadPage(at: currentIndex)
    }
    
    /// 滚动到指定页面
    /// - Parameters:
    ///   - index: 目标页面索引
    ///   - animated: 是否使用动画过渡
    public func scrollToPage(at index: Int, animated: Bool) {
        let targetIndex = min(max(index, 0), pageCount - 1)
        guard targetIndex < placeholderViews.count else { return }
        if isLazyLoading { loadPage(at: targetIndex) }
        let targetOffset = CGPoint(x: CGFloat(targetIndex) * bounds.width, y: 0)
        contentScrollView.setContentOffset(targetOffset, animated: animated)
    }
    
    /// 获取指定索引的页面（懒加载模式下可能返回 nil）
    public func page(at index: Int) -> CLNestedSlideViewPage? {
        guard index >= 0, index < pageCount, index < placeholderViews.count else { return nil }
        return isLazyLoading ? pageCache[index] : (placeholderViews[index] as? CLNestedSlideViewPage)
    }
}

// MARK: - 私有设置方法

private extension CLNestedSlideView {
    /// 设置用户界面
    func setupUI() {
        addSubview(mainScrollView)
        mainScrollView.addSubview(mainStackView)
        mainStackView.addArrangedSubview(headStackView)
        mainStackView.addArrangedSubview(bottomStackView)
        bottomStackView.addArrangedSubview(contentScrollView)
        contentScrollView.addSubview(contentStackView)
    }
    
    /// 设置约束
    func setupConstraints() {
        mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mainStackView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        bottomStackView.snp.makeConstraints { make in
           make.height.equalTo(self)
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.height.equalToSuperview()
        }
    }
}

// MARK: - 私有辅助方法

private extension CLNestedSlideView {
    func setupPlaceholderViews() {
        guard let dataSource = dataSource else { return }
        
        placeholderViews.forEach { view in
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        placeholderViews.removeAll()
        
        if isLazyLoading {
            setupLazyLoadingViews()
        } else {
            setupEagerLoadingViews(dataSource: dataSource)
        }
    }
    
    private func setupLazyLoadingViews() {
        for _ in 0..<pageCount {
            let placeholder = UIView()
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            placeholder.backgroundColor = .clear
            
            contentStackView.addArrangedSubview(placeholder)
            placeholderViews.append(placeholder)
            
            placeholder.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
    }
    
    private func setupEagerLoadingViews(dataSource: CLNestedSlideViewDataSource) {
        for index in 0..<pageCount {
            let page = dataSource.nestedSlideView(self, pageFor: index)
            page.translatesAutoresizingMaskIntoConstraints = false
            page.isSwipeEnabled = headStackView.arrangedSubviews.isEmpty
            page.superScrollEnabledHandler = { [weak self] isEnabled in
                guard let self = self else { return true }
                self.isSwipeEnabled = isEnabled
                return self.headStackView.arrangedSubviews.isEmpty
            }
            page.setupScrollViewDelegateIfNeeded()
            contentStackView.addArrangedSubview(page)
            placeholderViews.append(page)
            pageCache[index] = page
            page.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
        guard pageCount > 0 else { return }
        visiblePage = pageCache[min(currentIndex, pageCount - 1)]
    }
    func loadPage(at index: Int) {
        guard let dataSource = dataSource, index >= 0, index < pageCount, index < placeholderViews.count else { return }
        currentIndex = index
        isLazyLoading ? loadPageLazily(at: index, dataSource: dataSource) : loadPageEagerly(at: index)
    }
    
    private func loadPageLazily(at index: Int, dataSource: CLNestedSlideViewDataSource) {
        if let page = placeholderViews[index] as? CLNestedSlideViewPage {
            visiblePage = page
            return
        }
        let page = pageCache[index] ?? dataSource.nestedSlideView(self, pageFor: index)
        page.isSwipeEnabled = headStackView.arrangedSubviews.isEmpty
        page.superScrollEnabledHandler = { [weak self] isEnabled in
            guard let self = self else { return true }
            self.isSwipeEnabled = isEnabled
            return self.headStackView.arrangedSubviews.isEmpty
        }
        page.setupScrollViewDelegateIfNeeded()
        let placeholder = placeholderViews[index]
        contentStackView.removeArrangedSubview(placeholder)
        placeholder.removeFromSuperview()
        page.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.insertArrangedSubview(page, at: index)
        page.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        placeholderViews[index] = page
        visiblePage = page
        pageCache[index] = page
    }
    
    private func loadPageEagerly(at index: Int) {
        guard let page = placeholderViews[index] as? CLNestedSlideViewPage else { return }
        visiblePage = page
    }
    
    /// 更新堆栈视图中的子视图
    /// - Parameters:
    ///   - stackView: 目标堆栈视图
    ///   - newView: 新视图
    ///   - oldValue: 旧视图
    func updateStackView(_ stackView: UIStackView, with newView: UIView?, oldValue: UIView?, at stackIndex: Int) {
        guard newView !== oldValue else { return }
        
        // 移除旧的视图
        if let oldValue = oldValue, stackView.arrangedSubviews.contains(oldValue) {
            stackView.removeArrangedSubview(oldValue)
            oldValue.removeFromSuperview()
        }
        
        // 添加新的视图（防止重复添加 + 越界处理）
        if let newView = newView, !stackView.arrangedSubviews.contains(newView) {
            let safeIndex = min(stackIndex, stackView.arrangedSubviews.count)
            stackView.insertArrangedSubview(newView, at: safeIndex)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension CLNestedSlideView: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == contentScrollView else { return }
        mainScrollView.isScrollEnabled = false
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == contentScrollView else { return }
        guard scrollView.bounds.width > 0 else { return }
        
        mainScrollView.isScrollEnabled = true
        
        let targetIndex = Int(round(targetContentOffset.pointee.x / scrollView.bounds.width))
        let clampedIndex = min(max(targetIndex, 0), pageCount - 1)
        targetContentOffset.pointee.x = CGFloat(clampedIndex) * scrollView.bounds.width
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == contentScrollView else { return }
        updateCurrentPageIndex(for: scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == contentScrollView else { return }
        updateCurrentPageIndex(for: scrollView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.showsVerticalScrollIndicator = (scrollView == mainScrollView)
        visiblePage?.scrollView.showsVerticalScrollIndicator = (scrollView != mainScrollView)
        if scrollView == contentScrollView {
            let progress: CGFloat = scrollView.bounds.width > 0 ? scrollView.contentOffset.x / scrollView.bounds.width : 0
            delegate?.contentScrollViewDidScroll(self, scrollView: scrollView, progress: progress)
            return
        }
        guard scrollView.contentSize.height > 0 else { return }
        let maxOffset = (headerView?.bounds.height) ?? 0
        if !isSwipeEnabled {
            scrollView.contentOffset.y = maxOffset
            visiblePage?.isSwipeEnabled = true
        } else if scrollView.contentOffset.y >= maxOffset {
            scrollView.contentOffset.y = maxOffset
            isSwipeEnabled = false
            visiblePage?.isSwipeEnabled = true
        }
    }
}

// MARK: - 私有页面管理

private extension CLNestedSlideView {
    func updateCurrentPageIndex(for scrollView: UIScrollView) {
        guard scrollView == contentScrollView && scrollView.bounds.width > 0 else { return }
        
        let newIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        let clampedIndex = min(max(newIndex, 0), pageCount - 1)
        
        if clampedIndex != currentIndex {
            currentIndex = clampedIndex
        }
    }
}
