import UIKit

/// Screen 6: shows one note full size and lets the student delete it after confirming.
class NoteDetailViewController: UIViewController {

    // MARK: - Data passed in from NotesViewController

    var note: Note?

    // MARK: - Outlets

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Note"
        view.backgroundColor = Theme.background
        navigationItem.largeTitleDisplayMode = .never
        styleViews()

        guard let note = note else { return }
        noteLabel.text = note.text
        if let createdAt = note.createdAt {
            dateLabel.text = "Created " + createdAt.formatted(date: .long, time: .shortened)
        }

        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFit
        } else {
            // Text-only note: hiding the image view lets the stack view move the text to the top
            // instead of leaving a large empty box.
            photoImageView.isHidden = true
        }
    }

    private func styleViews() {
        photoImageView.backgroundColor = Theme.cardBackground
        photoImageView.layer.cornerRadius = Theme.cornerRadius
        photoImageView.layer.cornerCurve = .continuous
        photoImageView.clipsToBounds = true

        dateLabel.font = .preferred(.footnote, weight: .medium)
        dateLabel.adjustsFontForContentSizeCategory = true

        noteLabel.font = .preferredFont(forTextStyle: .body)
        noteLabel.adjustsFontForContentSizeCategory = true

        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Delete Note"
        configuration.image = UIImage(systemName: "trash")
        configuration.imagePadding = 8
        configuration.cornerStyle = .large
        configuration.buttonSize = .large
        configuration.baseForegroundColor = .systemRed
        configuration.baseBackgroundColor = .systemRed
        deleteButton.configuration = configuration

        // Keep the destructive button visually separate from the note's content.
        (deleteButton.superview as? UIStackView)?.setCustomSpacing(32, after: noteLabel)
    }

    // MARK: - Actions

    @IBAction func deleteTapped(_ sender: UIButton) {
        // Ask first, because deleting cannot be undone.
        let alert = UIAlertController(title: "Delete this note?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {
            [weak self] _ in
            guard let self = self, let note = self.note else { return }
            CoreDataStack.shared.context.delete(note)
            CoreDataStack.shared.save()
            // Back to the grid, which reloads in viewWillAppear and no longer shows the note.
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }
}
