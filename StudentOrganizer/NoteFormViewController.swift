import UIKit
import PhotosUI

/// Screen 5: writes a new note for a subject, with an optional photo from the photo library.
class NoteFormViewController: UIViewController, PHPickerViewControllerDelegate {

    // MARK: - Data passed in from NotesViewController

    var subject: Subject?

    /// The photo the student picked (nil = no photo).
    private var selectedImage: UIImage?

    // MARK: - Outlets

    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Note"
        view.backgroundColor = Theme.background
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem?.style = .done

        Theme.styleTextView(noteTextView)

        // The preview box starts with a placeholder icon until a photo is chosen.
        photoImageView.backgroundColor = Theme.cardBackground
        photoImageView.layer.cornerRadius = Theme.cornerRadius
        photoImageView.layer.cornerCurve = .continuous
        photoImageView.clipsToBounds = true
        photoImageView.image = UIImage(systemName: "photo.badge.plus",
                                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 36, weight: .light))
        photoImageView.tintColor = .tertiaryLabel
        photoImageView.contentMode = .center

        configurePhotoButton(title: "Choose Photo")

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func configurePhotoButton(title: String) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: "photo.on.rectangle.angled")
        configuration.imagePadding = 8
        configuration.cornerStyle = .large
        configuration.buttonSize = .large
        choosePhotoButton.configuration = configuration
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Actions

    @IBAction func choosePhotoTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images        // photos only, no videos
        configuration.selectionLimit = 1      // one photo per note

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        // Validation: a note must contain some text; whitespace alone does not count.
        let text = (noteTextView.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showAlert(title: "Note is empty",
                      message: "Please write something before saving.")
            return
        }

        let note = Note(context: CoreDataStack.shared.context)
        note.text = text
        note.createdAt = Date()
        // The photo is stored as JPEG bytes in the Binary Data attribute.
        // With no photo, selectedImage is nil, so photoData stays nil too.
        note.photoData = selectedImage?.jpegData(compressionQuality: 0.8)
        note.subject = subject

        CoreDataStack.shared.save()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - PHPickerViewControllerDelegate

    // Called when the student picks a photo or taps Cancel (results is then empty).
    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // The image loads on a background thread, so the UI is updated back on the main thread.
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            let smallImage = image.resized(maxDimension: 1024)   // keeps the database small
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.selectedImage = smallImage
                self.photoImageView.image = smallImage
                self.photoImageView.contentMode = .scaleAspectFit
                self.configurePhotoButton(title: "Change Photo")
            }
        }
    }
}
