import UIKit
import SnapKit

class CLDemoPageView: UIView, CLNestedSlideViewPage {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let separator = UIView()
    private let innerScrollView = UIScrollView()
    private let contentView = UIView()
    var scrollView: UIScrollView { innerScrollView }
    init(title: String, content: String, bgColor: UIColor) {
        super.init(frame: .zero)
        // 卡片化、圆角、阴影
        layer.cornerRadius = 20
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 16
        backgroundColor = .clear
        setupUI(title: title, content: content, bgColor: bgColor)
        setupConstraints()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private extension CLDemoPageView {
    func setupUI(title: String, content: String, bgColor: UIColor) {
        contentView.backgroundColor = bgColor.withAlphaComponent(0.12)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        innerScrollView.backgroundColor = .clear
        innerScrollView.showsVerticalScrollIndicator = true
        innerScrollView.alwaysBounceVertical = true
        // 顶部 SF Symbol 图标
        iconView.image = UIImage(systemName: "sparkles")
        iconView.tintColor = bgColor.withAlphaComponent(0.8)
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.layer.shadowColor = UIColor.white.withAlphaComponent(0.2).cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowOpacity = 0.5
        titleLabel.layer.shadowRadius = 2
        contentLabel.text = content
        contentLabel.font = .systemFont(ofSize: 17, weight: .medium)
        contentLabel.textColor = .secondaryLabel
        contentLabel.textAlignment = .center
        contentLabel.numberOfLines = 0
        // 滚动条样式
        innerScrollView.indicatorStyle = .black
        // 分割线
        separator.backgroundColor = bgColor.withAlphaComponent(0.18)
        contentView.addSubview(separator)
        // 按钮
        actionButton.setTitle("查看更多", for: .normal)
        actionButton.setTitleColor(bgColor, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        actionButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        actionButton.layer.cornerRadius = 8
        actionButton.layer.masksToBounds = true
        contentView.addSubview(actionButton)
        addSubview(innerScrollView)
        innerScrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        innerScrollView.delegate = self
    }
    func setupConstraints() {
        innerScrollView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        contentView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(20)
            make.left.right.equalToSuperview().inset(20)
            make.width.equalTo(innerScrollView.snp.width).offset(-40)
            make.height.greaterThanOrEqualTo(innerScrollView.snp.height).priority(.low)
        }
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }
        titleLabel.snp.makeConstraints { make in make.top.equalToSuperview().offset(36); make.left.right.equalToSuperview().inset(16) }
        contentLabel.snp.makeConstraints { make in make.top.equalTo(titleLabel.snp.bottom).offset(18); make.left.right.equalToSuperview().inset(16); make.bottom.lessThanOrEqualToSuperview().offset(-36) }
        separator.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(32)
            make.height.equalTo(1.5)
        }
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(18)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(38)
            make.bottom.lessThanOrEqualToSuperview().offset(-24)
        }
    }
}
extension CLDemoPageView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
} 