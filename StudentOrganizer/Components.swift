import UIKit

// Reusable views shared by several screens: the INTERLINK watermark, empty states,
// and the summary cards shown at the top of the Subjects and Tasks lists.

// MARK: - Gradient view

/// A view whose backing layer is a CAGradientLayer, so the gradient resizes with
/// Auto Layout automatically (no frame updates in layoutSubviews needed).
final class GradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        if let gradient = layer as? CAGradientLayer {
            gradient.colors = Theme.gradientColors.map(\.cgColor)
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - INTERLINK watermark

/// The subtle "INTERLINK" group mark shown at the bottom of every list and on the About screen.
/// Small, letter-spaced and in the tertiary label color so it identifies the group
/// without competing with the student's data.
final class InterlinkWatermarkView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        let icon = UIImageView(image: UIImage(systemName: "link"))
        icon.tintColor = .tertiaryLabel
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)

        let label = UILabel()
        label.attributedText = NSAttributedString(string: Theme.groupName, attributes: [
            .kern: 2.4,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.tertiaryLabel
        ])

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.spacing = 5
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        isAccessibilityElement = true
        accessibilityLabel = "Made by \(Theme.groupName)"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Gives the watermark a natural height when it is placed in a stack view or pinned in an empty state.
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    /// Ready-made table footer. Table footers are sized by their frame, not Auto Layout.
    static func makeTableFooter() -> InterlinkWatermarkView {
        InterlinkWatermarkView(frame: CGRect(x: 0, y: 0, width: 0, height: 64))
    }
}

/// Collection view footer that hosts the watermark at the end of the Notes grid.
final class WatermarkFooterView: UICollectionReusableView {

    static let reuseIdentifier = "WatermarkFooterView"

    override init(frame: CGRect) {
        super.init(frame: frame)
        let watermark = InterlinkWatermarkView()
        watermark.translatesAutoresizingMaskIntoConstraints = false
        addSubview(watermark)
        NSLayoutConstraint.activate([
            watermark.topAnchor.constraint(equalTo: topAnchor),
            watermark.leadingAnchor.constraint(equalTo: leadingAnchor),
            watermark.trailingAnchor.constraint(equalTo: trailingAnchor),
            watermark.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Empty state

/// Friendly placeholder used as a list's `backgroundView` when there is nothing to show.
/// It explains what to do next ("Tap + …") and keeps the INTERLINK mark visible at the bottom.
func emptyStateView(symbol: String, title: String, message: String) -> UIView {
    let container = UIView()

    let iconView = UIImageView(image: UIImage(systemName: symbol))
    iconView.tintColor = Theme.accent
    iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
    iconView.contentMode = .center
    iconView.translatesAutoresizingMaskIntoConstraints = false

    let circle = UIView()
    circle.backgroundColor = Theme.accent.withAlphaComponent(0.12)
    circle.layer.cornerRadius = 44
    circle.addSubview(iconView)
    circle.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferred(.title3, weight: .semibold)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0

    let messageLabel = UILabel()
    messageLabel.text = message
    messageLabel.font = .preferredFont(forTextStyle: .subheadline)
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.textColor = .secondaryLabel
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [circle, titleLabel, messageLabel])
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 6
    stack.setCustomSpacing(18, after: circle)
    stack.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(stack)

    let watermark = InterlinkWatermarkView()
    watermark.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(watermark)

    NSLayoutConstraint.activate([
        circle.widthAnchor.constraint(equalToConstant: 88),
        circle.heightAnchor.constraint(equalToConstant: 88),
        iconView.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
        iconView.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

        // Slightly above center looks optically centered below a navigation bar.
        stack.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
        stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 40),
        stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -40),
        stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),

        watermark.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        watermark.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        watermark.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor)
    ])
    return container
}

// MARK: - Subjects summary header

/// Gradient "at a glance" card at the top of the Subjects screen.
/// The numbers are real totals calculated from Core Data by SubjectsViewController.
final class SubjectsSummaryHeaderView: UIView {

    private let dateLabel = UILabel()
    private let subjectsValue = UILabel()
    private let pendingValue = UILabel()
    private let notesValue = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Inherit the table's margins so the card lines up with the inset-grouped rows below it.
        preservesSuperviewLayoutMargins = true

        let card = GradientView()
        card.layer.cornerRadius = Theme.cornerRadius
        card.layer.cornerCurve = .continuous
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        dateLabel.font = .preferred(.caption1, weight: .semibold)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        dateLabel.adjustsFontForContentSizeCategory = true

        let headline = UILabel()
        headline.text = "Your semester at a glance"
        headline.font = .preferred(.title3, weight: .bold)
        headline.textColor = .white
        headline.numberOfLines = 0
        headline.adjustsFontForContentSizeCategory = true

        let stats = UIStackView(arrangedSubviews: [
            makeStat(valueLabel: subjectsValue, caption: "Subjects"),
            makeStat(valueLabel: pendingValue, caption: "Pending tasks"),
            makeStat(valueLabel: notesValue, caption: "Notes")
        ])
        stats.distribution = .fillEqually
        stats.spacing = 12

        let content = UIStackView(arrangedSubviews: [dateLabel, headline, stats])
        content.axis = .vertical
        content.spacing = 4
        content.setCustomSpacing(18, after: headline)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(subjects: Int, pendingTasks: Int, notes: Int) {
        dateLabel.text = Date()
            .formatted(.dateTime.weekday(.wide).month(.wide).day())
            .uppercased()
        subjectsValue.text = "\(subjects)"
        pendingValue.text = "\(pendingTasks)"
        notesValue.text = "\(notes)"
    }

    private func makeStat(valueLabel: UILabel, caption: String) -> UIView {
        valueLabel.font = .preferred(.title1, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.adjustsFontForContentSizeCategory = true

        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = .preferred(.caption1, weight: .semibold)
        captionLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        return stack
    }
}

// MARK: - Subject progress header

/// Card at the top of the Tasks screen: shows the full subject name (the navigation title
/// may be truncated) and how many of its tasks are done, pending and overdue.
final class SubjectProgressHeaderView: UIView {

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        preservesSuperviewLayoutMargins = true

        let card = UIView()
        card.backgroundColor = Theme.cardBackground
        card.layer.cornerRadius = Theme.cornerRadius
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        nameLabel.font = .preferred(.title3, weight: .bold)
        nameLabel.numberOfLines = 0
        nameLabel.adjustsFontForContentSizeCategory = true

        progressLabel.font = .preferredFont(forTextStyle: .subheadline)
        progressLabel.textColor = .secondaryLabel
        progressLabel.adjustsFontForContentSizeCategory = true

        let titles = UIStackView(arrangedSubviews: [nameLabel, progressLabel])
        titles.axis = .vertical
        titles.spacing = 2

        let topRow = UIStackView(arrangedSubviews: [iconView, titles])
        topRow.spacing = 12
        topRow.alignment = .center

        progressView.trackTintColor = .tertiarySystemFill
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 0

        let content = UIStackView(arrangedSubviews: [topRow, progressView, statusLabel])
        content.axis = .vertical
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            progressView.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(subjectName: String, color: UIColor, completed: Int, total: Int, overdue: Int) {
        iconView.image = Theme.iconTile(symbol: "book.closed.fill", color: color, size: 44)
        nameLabel.text = subjectName
        progressLabel.text = "\(completed) of \(total) task\(total == 1 ? "" : "s") completed"
        progressView.progressTintColor = color
        progressView.setProgress(total == 0 ? 0 : Float(completed) / Float(total), animated: false)

        let pending = total - completed
        if pending == 0 {
            statusLabel.attributedText = NSAttributedString(
                string: "All tasks completed",
                attributes: [.foregroundColor: UIColor.systemGreen])
            return
        }
        let status = NSMutableAttributedString(
            string: "\(pending) pending",
            attributes: [.foregroundColor: UIColor.secondaryLabel])
        if overdue > 0 {
            status.append(NSAttributedString(
                string: "  ·  \(overdue) overdue",
                attributes: [.foregroundColor: UIColor.systemRed]))
        }
        statusLabel.attributedText = status
    }
}

// MARK: - Table header sizing

extension UITableView {
    /// UITableView does not size `tableHeaderView` with Auto Layout by itself, so this
    /// measures the header at the table's current width and re-assigns it when its size changes.
    func sizeHeaderToFit() {
        guard let header = tableHeaderView else { return }
        let targetSize = CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
        // Re-assigning the header triggers another layout pass, so only do it when something changed.
        guard header.frame.height != height || header.frame.width != bounds.width else { return }
        header.frame.size = CGSize(width: bounds.width, height: height)
        tableHeaderView = header
    }
}
