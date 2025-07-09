//
//  ViewController.swift
//
//
//  Created by JmoVxia on 2025/7/8.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    // MARK: - UI 组件
    private lazy var nestedSlideView: CLNestedSlideView = {
        let view = CLNestedSlideView(isLazyLoading: false)
        view.dataSource = self
        view.delegate = self
        return view
    }()
    /// 顶部渐变卡片头部
    private lazy var headerView: UIView = {
        let v = UIView()
        // 渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.systemPurple.cgColor, UIColor.systemBlue.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 180)
        v.layer.insertSublayer(gradientLayer, at: 0)
        // 圆角和阴影
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = false
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 8)
        v.layer.shadowOpacity = 0.5
        v.layer.shadowRadius = 16
        // 主标题
        let titleLabel = UILabel()
        titleLabel.text = "CLNestedSlide Demo"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        // 副标题
        let subtitleLabel = UILabel()
        subtitleLabel.text = "专业级嵌套滑动演示"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        v.addSubview(titleLabel)
        v.addSubview(subtitleLabel)
        titleLabel.snp.makeConstraints { make in make.centerX.equalToSuperview(); make.top.equalToSuperview().offset(48) }
        subtitleLabel.snp.makeConstraints { make in make.centerX.equalToSuperview(); make.top.equalTo(titleLabel.snp.bottom).offset(8) }
        return v
    }()
    /// 毛玻璃分段栏
    private lazy var segmentedBar: CLSegmentedBar = {
        let bar = CLSegmentedBar()
        bar.setTitles(["首页", "发现", "我的", "设置"])
        bar.onSelect = { [weak self] index in self?.nestedSlideView.scrollToPage(at: index, animated: true) }
        return bar
    }()
    /// 页面数据
    private let pageData: [(String, String, UIColor)] = [
        ("首页", "这里是首页内容\n可以展示主要功能", .systemGreen),
        ("发现", "这里是发现页面\n可以浏览新内容", .systemBlue),
        ("我的", "这里是个人中心\n管理个人信息", .systemOrange),
        ("设置", "这里是设置页面\n配置应用选项", .systemPurple)
    ]
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 245/255, green: 247/255, blue: 251/255, alpha: 1)
        setupUI()
    }
    /// UI布局
    private func setupUI() {
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
