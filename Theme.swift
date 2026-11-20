import UIKit

/// Central design system for Interlink Student Organizer.
///
/// Every screen takes its colors, corner radii and text styles from here instead of
/// hard-coding them, so the whole app looks consistent and can be re-themed in one place.
enum Theme {

    // MARK: - Branding

    static let groupName = "INTERLINK"
    static let appName = "Interlink Student Organizer"

    // MARK: - Colors

    /// Brand accent (indigo). Dynamic, so it stays readable in both Light and Dark Mode.
    static let accent = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.51, green: 0.55, blue: 0.97, alpha: 1)
            : UIColor(red: 0.31, green: 0.27, blue: 0.90, alpha: 1)
    }

    /// Fixed start/end colors of the brand gradient. Gradient layers use CGColor, which does
    /// not follow Dark Mode automatically, so these are chosen to look good in both modes.
    static let gradientColors: [UIColor] = [
        UIColor(red: 0.31, green: 0.27, blue: 0.90, alpha: 1),
        UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
    ]

    /// Screens use the grouped background, and content sits on lighter "cards" above it.
    static let background = UIColor.systemGroupedBackground
    static let cardBackground = UIColor.secondarySystemGroupedBackground

    // MARK: - Metrics

    static let cornerRadius: CGFloat = 14
    static let smallCornerRadius: CGFloat = 10
    static let fieldHeight: CGFloat = 44

    // MARK: - Fonts

    /// Font used by the note text in the Notes grid. NotesViewController also uses it to
    /// calculate the cell height, so it is a computed property that always reflects the
    /// user's current Dynamic Type size.
    static var noteCellFont: UIFont { .preferred(.subheadline, weight: .medium) }

    // MARK: - Subject colors

    private static let subjectPalette: [UIColor] = [
        .systemIndigo, .systemTeal, .systemOrange, .systemPink,
        .systemPurple, .systemGreen, .systemBlue
    ]

    /// Gives every subject its own color, derived from its name.
    /// `String.hashValue` changes on every app launch, so the Unicode values are summed
    /// instead; the same subject name therefore always gets the same color.
    static func color(forSubjectNamed name: String) -> UIColor {
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return subjectPalette[sum % subjectPalette.count]
    }

    /// Draws a rounded, colored square with a white SF Symbol in the middle.
    /// List cells can only show one image, so the "icon on a colored tile" look is
    /// rendered into a single image.
    static func iconTile(symbol: String, color: UIColor, size: CGFloat = 36) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let image = UIGraphicsImageRenderer(size: rect.size).image { _ in
            color.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: size * 0.28).fill()

            let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.45, weight: .semibold)
            if let glyph = UIImage(systemName: symbol, withConfiguration: configuration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let origin = CGPoint(x: (size - glyph.size.width) / 2,
                                     y: (size - glyph.size.height) / 2)
                glyph.draw(at: origin)
            }
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    // MARK: - Global appearance

    /// Called once at launch, before any screen is created, so every segmented control
    /// and switch in the app uses the brand accent.
    static func applyGlobalAppearance() {
        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = accent
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)

        UISwitch.appearance().onTintColor = accent
    }

    // MARK: - Control styling

    /// Turns a storyboard text field into a borderless, rounded "card" field.
    static func styleTextField(_ field: UITextField) {
        field.borderStyle = .none
        field.backgroundColor = cardBackground
        field.layer.cornerRadius = smallCornerRadius
        field.layer.cornerCurve = .continuous
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.clearButtonMode = .whileEditing
        // A borderless field has no inner padding, so an empty left view keeps the text off the edge.
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: fieldHeight).isActive = true
    }

    /// Matches the text view to the look of `styleTextField(_:)`.
    static func styleTextView(_ textView: UITextView) {
        textView.backgroundColor = cardBackground
        textView.layer.cornerRadius = smallCornerRadius
        textView.layer.cornerCurve = .continuous
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
    }
}

extension UIFont {
    /// A Dynamic Type font with a custom weight. `preferredFont(forTextStyle:)` only gives the
    /// regular weight, so this builds the weighted font at the default size and lets
    /// UIFontMetrics scale it to the user's chosen text size.
    static func preferred(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let defaultTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let defaultSize = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultTraits)
            .pointSize
        return UIFontMetrics(forTextStyle: style)
            .scaledFont(for: .systemFont(ofSize: defaultSize, weight: weight))
    }
}
