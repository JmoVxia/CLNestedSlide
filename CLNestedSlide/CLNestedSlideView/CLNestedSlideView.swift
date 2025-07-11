import UIKit
import SnapKit

fileprivate class CLMultiGestureScrollView: UIScrollView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CLMultiGestureScrollView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

fileprivate class CLObservingScrollView: UIScrollView {
    var contentSizeChangedHandler: ((CGSize) -> Void)?
    
    override var contentSize: CGSize {
        didSet {
            guard oldValue != contentSize else { return }
            contentSizeChangedHandler?(contentSize)
        }
    }
}

public protocol CLNestedSlideViewDataSource: AnyObject {
    func numberOfPages(in nestedSlideView: CLNestedSlideView) -> Int
    func nestedSlideView(_ nestedSlideView: CLNestedSlideView, pageFor index: Int) -> CLNestedSlideViewPage
}

public protocol CLNestedSlideViewDelegate: AnyObject {
    func contentScrollViewDidScroll(_ nestedSlideView: CLNestedSlideView, scrollView: UIScrollView, progress: CGFloat)
    func contentScrollViewDidScrollToPage(at index: Int)
}

public extension CLNestedSlideViewDelegate {
    func contentScrollViewDidScroll(_ nestedSlideView: CLNestedSlideView, scrollView: UIScrollView, progress: CGFloat) {}
    func contentScrollViewDidScrollToPage(at index: Int) {}
}

public class CLNestedSlideView: UIView {
    
    // MARK: - Public Properties
    
    public var headerView: UIView? {
        didSet {
            guard headerView != oldValue else { return }
            updateStackView(mainStackView, with: headerView, oldValue: oldValue, at: 0)
        }
    }
    
    public var hoverView: UIView? {
        didSet {
            guard hoverView != oldValue else { return }
            updateStackView(bodyStackView, with: hoverView, oldValue: oldValue, at: 0)
        }
    }
    
    public weak var dataSource: CLNestedSlideViewDataSource?
    public weak var delegate: CLNestedSlideViewDelegate?
    
    public var isLazyLoadingEnabled: Bool { isLazyLoading }
    public var numberOfPages: Int { pageCount }
    public var currentPage: CLNestedSlideViewPage? { visiblePage }
    
    public var currentPageIndex: Int {
        get { currentIndex }
        set {
            let targetIndex = clampIndex(newValue)
            if targetIndex != currentIndex { 
                scrollToPage(at: targetIndex, animated: false) 
            }
        }
    }
    
    public var isHorizontalScrollEnabled: Bool {
        get { contentScrollView.isScrollEnabled }
        set { contentScrollView.isScrollEnabled = newValue }
    }
    
    // MARK: - Private Properties
    
    private let isLazyLoading: Bool
    private var currentIndex = 0 {
        didSet {
            guard currentIndex != oldValue else { return }
            loadPage(at: currentIndex)
            delegate?.contentScrollViewDidScrollToPage(at: currentIndex)
        }
    }
    private var visiblePage: CLNestedSlideViewPage?
    private var pageCache = [Int: CLNestedSlideViewPage]()
    private var placeholderViews = [UIView]()
    private var pageCount = 0
    private var isSwipeEnabled = true
    private var lastMainScrollOffsetY: CGFloat = 0
    private var lastScrollIndicatorState: (main: Bool, page: Bool) = (true, false)
    
    // MARK: - UI Components
    
    private lazy var mainScrollView: CLMultiGestureScrollView = {
        let scrollView = CLMultiGestureScrollView()
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    private lazy var contentScrollView: CLObservingScrollView = {
        let scrollView = CLObservingScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSizeChangedHandler = { [weak self] _ in
            guard let self = self else { return }
            self.scrollToPage(at: self.currentPageIndex, animated: false)
        }
        return scrollView
    }()
    
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
    
    private lazy var bodyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private lazy var pageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    // MARK: - Initialization
    
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
    
    // MARK: - Public Methods
    
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
    
    public func scrollToPage(at index: Int, animated: Bool) {
        let targetIndex = clampIndex(index)
        guard targetIndex < placeholderViews.count else { return }
        
        if isLazyLoading { loadPage(at: targetIndex) }
        let targetOffset = CGPoint(x: CGFloat(targetIndex) * bounds.width, y: 0)
        contentScrollView.setContentOffset(targetOffset, animated: animated)
    }
    
    public func page(at index: Int) -> CLNestedSlideViewPage? {
        guard isValidIndex(index) else { return nil }
        return isLazyLoading ? pageCache[index] : (placeholderViews[index] as? CLNestedSlideViewPage)
    }
    
    // MARK: - Helper Methods
    
    private func clampIndex(_ index: Int) -> Int {
        return min(max(index, 0), pageCount - 1)
    }
    
    private func isValidIndex(_ index: Int) -> Bool {
        return index >= 0 && index < pageCount && index < placeholderViews.count
    }
}

// MARK: - UI Setup

private extension CLNestedSlideView {
    func setupUI() {
        addSubview(mainScrollView)
        mainScrollView.addSubview(mainStackView)
        mainStackView.addArrangedSubview(bodyStackView)
        bodyStackView.addArrangedSubview(contentScrollView)
        contentScrollView.addSubview(pageStackView)
        
        contentScrollView.panGestureRecognizer.addTarget(self, action: #selector(handleContentPan(_:)))
    }
    
    func setupConstraints() {
        mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mainStackView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        bodyStackView.snp.makeConstraints { make in
            make.height.equalTo(self)
        }
        pageStackView.snp.makeConstraints { make in
            make.edges.height.equalToSuperview()
        }
    }
}

// MARK: - Gesture Handling

private extension CLNestedSlideView {
    @objc func handleContentPan(_ gesture: UIPanGestureRecognizer) {
        let velocity = gesture.velocity(in: contentScrollView)
        switch gesture.state {
        case .began:
            if abs(velocity.x) > abs(velocity.y) {
                mainScrollView.isScrollEnabled = false
            }
        case .ended, .cancelled, .failed:
            mainScrollView.isScrollEnabled = true
        default:
            break
        }
    }
}

// MARK: - Page Management

private extension CLNestedSlideView {
    func setupPlaceholderViews() {
        guard let dataSource = dataSource else { return }
        
        placeholderViews.forEach { view in
            pageStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        placeholderViews.removeAll()
        
        isLazyLoading ? setupLazyLoadingViews() : setupEagerLoadingViews(dataSource: dataSource)
    }
    
    func setupLazyLoadingViews() {
        for _ in 0..<pageCount {
            let placeholder = UIView()
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            placeholder.backgroundColor = .clear
            
            pageStackView.addArrangedSubview(placeholder)
            placeholderViews.append(placeholder)
            placeholder.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
    }
    
    func setupEagerLoadingViews(dataSource: CLNestedSlideViewDataSource) {
        for index in 0..<pageCount {
            let page = dataSource.nestedSlideView(self, pageFor: index)
            configurePage(page)
            
            pageStackView.addArrangedSubview(page)
            placeholderViews.append(page)
            pageCache[index] = page
            page.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
        
        if pageCount > 0 {
            visiblePage = pageCache[min(currentIndex, pageCount - 1)]
        }
    }
    
    func loadPage(at index: Int) {
        guard let dataSource = dataSource, isValidIndex(index) else { return }
        
        currentIndex = index
        isLazyLoading ? loadPageLazily(at: index, dataSource: dataSource) : loadPageEagerly(at: index)
    }
    
    func loadPageLazily(at index: Int, dataSource: CLNestedSlideViewDataSource) {
        if let page = placeholderViews[index] as? CLNestedSlideViewPage {
            visiblePage = page
            return
        }
        
        let page = pageCache[index] ?? dataSource.nestedSlideView(self, pageFor: index)
        configurePage(page)
        
        let placeholder = placeholderViews[index]
        pageStackView.removeArrangedSubview(placeholder)
        placeholder.removeFromSuperview()
        
        page.translatesAutoresizingMaskIntoConstraints = false
        pageStackView.insertArrangedSubview(page, at: index)
        page.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        
        placeholderViews[index] = page
        visiblePage = page
        pageCache[index] = page
    }
    
    func loadPageEagerly(at index: Int) {
        guard let page = placeholderViews[index] as? CLNestedSlideViewPage else { return }
        visiblePage = page
    }
    
    func configurePage(_ page: CLNestedSlideViewPage) {
        page.isSwipeEnabled = headerView == nil
        page.superScrollEnabledHandler = { [weak self] isEnabled in
            guard let self = self else { return true }
            self.isSwipeEnabled = isEnabled
            return self.headerView == nil
        }
        page.setupScrollViewDelegateIfNeeded()
    }
    
    func updateStackView(_ stackView: UIStackView, with newView: UIView?, oldValue: UIView?, at index: Int) {
        guard newView !== oldValue else { return }
        
        if let oldValue = oldValue, stackView.arrangedSubviews.contains(oldValue) {
            stackView.removeArrangedSubview(oldValue)
            oldValue.removeFromSuperview()
        }
        
        if let newView = newView, !stackView.arrangedSubviews.contains(newView) {
            let safeIndex = min(index, stackView.arrangedSubviews.count)
            stackView.insertArrangedSubview(newView, at: safeIndex)
        }
    }
    
    func updateCurrentPageIndex(for scrollView: UIScrollView) {
        guard scrollView == contentScrollView else { return }
        
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        
        let newIndex = Int(round(scrollView.contentOffset.x / width))
        let clampedIndex = clampIndex(newIndex)
        
        if clampedIndex != currentIndex {
            currentIndex = clampedIndex
        }
    }
    

}

// MARK: - UIScrollViewDelegate

extension CLNestedSlideView: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == mainScrollView {
            lastMainScrollOffsetY = scrollView.contentOffset.y
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == contentScrollView else { return }
        guard scrollView.bounds.width > 0 else { return }
        
        mainScrollView.isScrollEnabled = true
        
        let targetIndex = Int(round(targetContentOffset.pointee.x / scrollView.bounds.width))
        let clampedIndex = clampIndex(targetIndex)
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
        configureScrollIndicators(scrollView)
        
        if scrollView == contentScrollView {
            handleContentScrollViewScroll(scrollView)
            return
        }
        
        handleMainScrollViewScroll(scrollView)
    }
}

// MARK: - Scroll Handling

private extension CLNestedSlideView {
    func configureScrollIndicators(_ scrollView: UIScrollView) {
        let isMainScrollView = (scrollView == mainScrollView)
        let newState = (main: isMainScrollView, page: !isMainScrollView)
        
        guard newState.main != lastScrollIndicatorState.main || 
              newState.page != lastScrollIndicatorState.page else { return }
        
        scrollView.showsVerticalScrollIndicator = newState.main
        visiblePage?.scrollView.showsVerticalScrollIndicator = newState.page
        lastScrollIndicatorState = newState
    }
    
    func handleContentScrollViewScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        let progress: CGFloat = width > 0 ? scrollView.contentOffset.x / width : 0
        delegate?.contentScrollViewDidScroll(self, scrollView: scrollView, progress: progress)
    }
    
    func handleMainScrollViewScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height > 0 else { return }
        
        let maxOffset = headerView?.bounds.height ?? 0
        let offsetY = scrollView.contentOffset.y
        let isScrollingDown = offsetY < lastMainScrollOffsetY
        
        let isPageScrollAtTop = visiblePage?.scrollView.contentOffset.y ?? 0 <= 0
        
        if !isSwipeEnabled {
            if isScrollingDown && isPageScrollAtTop {
                isSwipeEnabled = true
                visiblePage?.isSwipeEnabled = false
            } else {
                scrollView.contentOffset.y = maxOffset
                visiblePage?.isSwipeEnabled = true
            }
        } else if offsetY >= maxOffset {
            scrollView.contentOffset.y = maxOffset
            isSwipeEnabled = false
            visiblePage?.isSwipeEnabled = true
        } else {
            visiblePage?.isSwipeEnabled = false
        }
        lastMainScrollOffsetY = scrollView.contentOffset.y
    }
}
