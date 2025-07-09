import UIKit
import SnapKit

class CLDemoPageView: UIView, CLNestedSlideViewPage {
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let innerScrollView = UIScrollView()
    private let contentView = UIView()
    var scrollView: UIScrollView { innerScrollView }
    init(title: String, content: String, bgColor: UIColor) {
        super.init(frame: .zero)
        setupUI(title: title, content: content, bgColor: bgColor)
        setupConstraints()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private extension CLDemoPageView {
    func setupUI(title: String, content: String, bgColor: UIColor) {
        backgroundColor = bgColor.withAlphaComponent(0.1)
        innerScrollView.backgroundColor = bgColor.withAlphaComponent(0.3)
        innerScrollView.showsVerticalScrollIndicator = true
        innerScrollView.alwaysBounceVertical = true
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        contentLabel.text = content
        contentLabel.font = .systemFont(ofSize: 16, weight: .regular)
        contentLabel.textColor = .secondaryLabel
        contentLabel.textAlignment = .center
        contentLabel.numberOfLines = 0
        addSubview(innerScrollView)
        innerScrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        innerScrollView.delegate = self
    }
    func setupConstraints() {
        innerScrollView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        contentView.snp.makeConstraints { make in make.edges.equalToSuperview(); make.width.equalToSuperview(); make.height.greaterThanOrEqualToSuperview().priority(.low) }
        titleLabel.snp.makeConstraints { make in make.top.equalToSuperview().offset(40); make.centerX.equalToSuperview() }
        contentLabel.snp.makeConstraints { make in make.top.equalTo(titleLabel.snp.bottom).offset(20); make.centerX.equalToSuperview() }
    }
}
extension CLDemoPageView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
} 