import UIKit

/// About screen that identifies the app and the INTERLINK group.
///
/// Navigation: opened modally (inside its own navigation controller) from the info button
/// on the Subjects screen and closed with Done. It is built in code rather than in the
/// storyboard because it is a static page that takes no part in the segue-based data
/// flow between the six main screens.
final class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
        view.backgroundColor = Theme.background
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneTapped))
        buildLayout()
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }

    // MARK: - Layout

    private func buildLayout() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView(arrangedSubviews: [
            makeHeader(),
            makeCard(title: "About the app", rows: [
                makeBodyLabel("A companion app that keeps a student's schoolwork organized by subject. "
                              + "Everything is stored on the device, so no internet connection is needed.")
            ]),
            makeCard(title: "Features", rows: [
                makeFeatureRow(symbol: "books.vertical.fill", color: .systemIndigo,
                               title: "Subjects", detail: "Group your coursework by subject."),
                makeFeatureRow(symbol: "checklist", color: .systemOrange,
                               title: "Tasks", detail: "Due dates, priorities and completion status."),
                makeFeatureRow(symbol: "photo.on.rectangle.angled", color: .systemTeal,
                               title: "Photo notes", detail: "Text notes with an optional photo."),
                makeFeatureRow(symbol: "internaldrive.fill", color: .systemGreen,
                               title: "Saved on device", detail: "Data persists with Core Data.")
            ]),
            makeCard(title: "Developed by", rows: [makeTeamRow()]),
            InterlinkWatermarkView()
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            // Width tied to the visible frame so the page only ever scrolls vertically.
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    /// App icon tile, app name and version.
    private func makeHeader() -> UIView {
        let tile = GradientView()
        tile.layer.cornerRadius = 24
        tile.layer.cornerCurve = .continuous
        tile.clipsToBounds = true
        tile.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "graduationcap.fill"))
        icon.tintColor = .white
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
        icon.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(icon)

        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: 96),
            tile.heightAnchor.constraint(equalToConstant: 96),
            icon.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])

        let nameLabel = UILabel()
        nameLabel.text = Theme.appName
        nameLabel.font = .preferred(.title2, weight: .bold)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0

        let versionLabel = UILabel()
        versionLabel.text = "Version \(appVersion)"
        versionLabel.font = .preferredFont(forTextStyle: .footnote)
        versionLabel.adjustsFontForContentSizeCategory = true
        versionLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [tile, nameLabel, versionLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.setCustomSpacing(16, after: tile)
        return stack
    }

    /// Reads the version from the bundle so the About screen never shows a stale number.
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// A rounded card with a small section title, matching the inset-grouped lists.
    private func makeCard(title: String, rows: [UIView]) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title.uppercased()
        titleLabel.font = .preferred(.footnote, weight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .secondaryLabel

        let content = UIStackView(arrangedSubviews: rows)
        content.axis = .vertical
        content.spacing = 14
        content.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.backgroundColor = Theme.cardBackground
        card.layer.cornerRadius = Theme.cornerRadius
        card.layer.cornerCurve = .continuous
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        let section = UIStackView(arrangedSubviews: [titleLabel, card])
        section.axis = .vertical
        section.spacing = 8
        return section
    }

    private func makeBodyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    private func makeFeatureRow(symbol: String, color: UIColor, title: String, detail: String) -> UIView {
        let icon = UIImageView(image: Theme.iconTile(symbol: symbol, color: color, size: 34))
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferred(.subheadline, weight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .preferredFont(forTextStyle: .footnote)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0

        let texts = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        texts.axis = .vertical
        texts.spacing = 1

        let row = UIStackView(arrangedSubviews: [icon, texts])
        row.spacing = 12
        row.alignment = .center
        return row
    }

    private func makeTeamRow() -> UIView {
        let groupLabel = UILabel()
        groupLabel.attributedText = NSAttributedString(string: Theme.groupName, attributes: [
            .kern: 4,
            .font: UIFont.preferred(.title2, weight: .heavy),
            .foregroundColor: Theme.accent
        ])

        let courseLabel = UILabel()
        courseLabel.text = "IT0093 · Mobile Application Development 2\nFinal Project"
        courseLabel.font = .preferredFont(forTextStyle: .footnote)
        courseLabel.adjustsFontForContentSizeCategory = true
        courseLabel.textColor = .secondaryLabel
        courseLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [groupLabel, courseLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }
}
