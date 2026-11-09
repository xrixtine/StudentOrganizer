import UIKit

class NoteCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 12
        clipsToBounds = true
        backgroundColor = .secondarySystemBackground
        photoImageView.clipsToBounds = true
    }

    func configure(with note: Note) {
        noteLabel.text = note.text

        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFill   
        } else {
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = .systemGray3
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
}
