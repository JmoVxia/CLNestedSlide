//
//  ViewController.swift
//
//
//  Created by JmoVxia on 2025/7/8.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    private lazy var nestedSlideView: CLNestedSlideView = {
        let view = CLNestedSlideView(isLazyLoading: false)
        view.dataSource = self
        view.delegate = self
        return view
    }()
    private lazy var headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemRed
        let label = UILabel()
        label.text = "Header View"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        v.addSubview(label)
        label.snp.makeConstraints { make in make.center.equalToSuperview() }
        return v
    }()
    private lazy var segmentedBar: CLSegmentedBar = {
        let bar = CLSegmentedBar()
        bar.setTitles(["首页", "发现", "我的", "设置"])
        bar.onSelect = { [weak self] index in self?.nestedSlideView.scrollToPage(at: index, animated: true) }
        return bar
    }()
    private let pageData: [(String, String, UIColor)] = [
        ("首页", "这里是首页内容\n可以展示主要功能", .systemGreen),
        ("发现", "这里是发现页面\n可以浏览新内容", .systemBlue),
        ("我的", "这里是个人中心\n管理个人信息", .systemOrange),
        ("设置", "这里是设置页面\n配置应用选项", .systemPurple)
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(nestedSlideView)
        nestedSlideView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        headerView.snp.makeConstraints { make in make.height.equalTo(180) }
        segmentedBar.snp.makeConstraints { make in make.height.equalTo(60) }
        nestedSlideView.headerView = headerView
        nestedSlideView.hoverView = segmentedBar
        nestedSlideView.reload()
    }
}

extension ViewController: CLNestedSlideViewDataSource {
    func numberOfPages(in nestedSlideView: CLNestedSlideView) -> Int { pageData.count }
    func nestedSlideView(_ nestedSlideView: CLNestedSlideView, pageFor index: Int) -> CLNestedSlideViewPage {
        let data = pageData[index]
        return CLDemoPageView(title: data.0, content: data.1, bgColor: data.2)
    }
}

extension ViewController: CLNestedSlideViewDelegate {
    func contentScrollViewDidScroll(_ nestedSlideView: CLNestedSlideView, scrollView: UIScrollView, progress: CGFloat) {
        let currentIndex = Int(progress.rounded())
        let clampedIndex = min(max(currentIndex, 0), pageData.count - 1)
        let offset = progress - CGFloat(clampedIndex)
        segmentedBar.updateIndicatorWithOffset(baseIndex: clampedIndex, offset: offset)
        segmentedBar.updateTitleColorWithProgress(baseIndex: clampedIndex, offset: offset)
    }
    func contentScrollViewDidScrollToPage(at index: Int) {
        segmentedBar.setSelectedIndex(index)
    }
}
