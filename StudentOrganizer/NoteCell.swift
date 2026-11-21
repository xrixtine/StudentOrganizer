import UIKit

/// Card-style cell in the Notes grid: a square photo (or a text icon for text-only notes)
/// with the first two lines of the note underneath.
class NoteCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // The rounded corners are clipped on contentView, while the cell itself stays
        // unclipped so its soft shadow can show around the card.
        contentView.backgroundColor = Theme.cardBackground
        contentView.layer.cornerRadius = Theme.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        backgroundColor = .clear
        clipsToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)

        photoImageView.clipsToBounds = true
        noteLabel.font = Theme.noteCellFont
        noteLabel.adjustsFontForContentSizeCategory = true
        noteLabel.textColor = .label
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // An explicit shadow path saves an expensive off-screen render pass while scrolling.
        layer.shadowPath = UIBezierPath(roundedRect: bounds,
                                        cornerRadius: Theme.cornerRadius).cgPath
    }

    /// Small press-down effect so tapping a card feels responsive.
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }

    /// Fills the cell with one Note from the database.
    func configure(with note: Note) {
        noteLabel.text = note.text

        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFill   // fill the square, crop the rest
            photoImageView.backgroundColor = .clear
        } else {
            // Text-only note: a tinted text icon keeps the grid looking even.
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
            photoImageView.image = UIImage(systemName: "text.alignleft",
                                           withConfiguration: symbolConfiguration)
            photoImageView.contentMode = .center
            photoImageView.tintColor = Theme.accent
            photoImageView.backgroundColor = Theme.accent.withAlphaComponent(0.1)
        }
    }

    // Cells are reused while scrolling, so clear the previous note's picture first.
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
}
