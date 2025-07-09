import UIKit
import SnapKit

class CLSegmentedBar: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let indicatorView = UIView()
    private var titleLabels: [UILabel] = []
    private var titles: [String] = []
    private(set) var selectedIndex: Int = 0
    var onSelect: ((Int) -> Void)?
    var normalColor: UIColor = .blue
    var activeColor: UIColor = .orange
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }
    func setTitles(_ titles: [String]) {
        self.titles = titles
        setupLabels()
    }
    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index < titleLabels.count else { return }
        selectedIndex = index
        updateAppearance(for: index)
        updateIndicatorPosition(for: index, animated: animated)
    }
    func updateIndicatorWithOffset(baseIndex: Int, offset: CGFloat) {
        guard baseIndex < titleLabels.count else { return }
        let currentLabel = titleLabels[baseIndex]
        var targetCenterX = currentLabel.center.x
        if offset > 0, baseIndex + 1 < titleLabels.count {
            let nextLabel = titleLabels[baseIndex + 1]
            targetCenterX = currentLabel.center.x + (nextLabel.center.x - currentLabel.center.x) * offset
        } else if offset < 0, baseIndex > 0 {
            let prevLabel = titleLabels[baseIndex - 1]
            targetCenterX = currentLabel.center.x + (prevLabel.center.x - currentLabel.center.x) * (-offset)
        }
        indicatorView.center.x = targetCenterX
    }
    func updateTitleColorWithProgress(baseIndex: Int, offset: CGFloat) {
        for (i, label) in titleLabels.enumerated() {
            var colorProgress: CGFloat = 0
            var fontWeight: UIFont.Weight = .medium
            if i == baseIndex {
                colorProgress = 1.0 - abs(offset)
                fontWeight = abs(offset) < 0.5 ? .semibold : .medium
            } else if (i == baseIndex + 1 && offset > 0) {
                colorProgress = offset
                fontWeight = offset > 0.5 ? .semibold : .medium
            } else if (i == baseIndex - 1 && offset < 0) {
                colorProgress = abs(offset)
                fontWeight = abs(offset) > 0.5 ? .semibold : .medium
            }
            colorProgress = max(0, min(1, colorProgress))
            label.textColor = interpolateColor(from: normalColor, to: activeColor, progress: colorProgress)
            label.font = .systemFont(ofSize: 16, weight: fontWeight)
        }
    }
    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(scrollView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 0
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in make.edges.equalToSuperview(); make.height.equalToSuperview() }
        indicatorView.backgroundColor = .systemBlue
        indicatorView.layer.cornerRadius = 1.5
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in make.bottom.equalToSuperview().offset(-1); make.height.equalTo(3); make.width.equalTo(60) }
    }
    private func setupLabels() {
        titleLabels.forEach { $0.removeFromSuperview() }
        titleLabels.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, title) in titles.enumerated() {
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.textColor = index == 0 ? activeColor : normalColor
            label.textAlignment = .center
            label.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
            label.addGestureRecognizer(tapGesture)
            label.tag = index
            stackView.addArrangedSubview(label)
            titleLabels.append(label)
        }
        stackView.snp.makeConstraints { make in make.width.equalTo(UIScreen.main.bounds.width) }
        DispatchQueue.main.async { self.updateIndicatorPosition(for: 0, animated: false) }
    }
    @objc private func labelTapped(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        setSelectedIndex(label.tag)
        onSelect?(label.tag)
    }
    private func updateAppearance(for index: Int) {
        for (i, label) in titleLabels.enumerated() {
            if i == index {
                label.textColor = activeColor
                label.font = .systemFont(ofSize: 16, weight: .semibold)
            } else {
                label.textColor = normalColor
                label.font = .systemFont(ofSize: 16, weight: .medium)
            }
        }
    }
    private func updateIndicatorPosition(for index: Int, animated: Bool = true) {
        guard index < titleLabels.count else { return }
        let targetLabel = titleLabels[index]
        indicatorView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-1)
            make.height.equalTo(3)
            make.width.equalTo(60)
            make.centerX.equalTo(targetLabel)
        }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                self.layoutIfNeeded()
            })
        } else {
            layoutIfNeeded()
        }
    }
    private func interpolateColor(from startColor: UIColor, to endColor: UIColor, progress: CGFloat) -> UIColor {
        guard progress > 0 else { return startColor }
        guard progress < 1 else { return endColor }
        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0
        startColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        endColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)
        let red = startRed + (endRed - startRed) * progress
        let green = startGreen + (endGreen - startGreen) * progress
        let blue = startBlue + (endBlue - startBlue) * progress
        let alpha = startAlpha + (endAlpha - startAlpha) * progress
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
} 