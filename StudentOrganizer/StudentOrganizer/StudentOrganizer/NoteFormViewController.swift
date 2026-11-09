import UIKit
import PhotosUI

class NoteFormViewController: UIViewController, PHPickerViewControllerDelegate {

    var subject: Subject?

    private var selectedImage: UIImage?

    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Note"

        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.systemGray4.cgColor
        noteTextView.layer.cornerRadius = 8

        photoImageView.image = UIImage(systemName: "photo")
        photoImageView.tintColor = .systemGray3
        photoImageView.contentMode = .center

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func choosePhotoTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images        
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

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
        note.photoData = selectedImage?.jpegData(compressionQuality: 0.8)
        note.subject = subject

        CoreDataStack.shared.save()
        navigationController?.popViewController(animated: true)
    }


    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage else { return }
            let smallImage = image.resized(maxDimension: 1024)
            DispatchQueue.main.async {
                self?.selectedImage = smallImage
                self?.photoImageView.image = smallImage
                self?.photoImageView.contentMode = .scaleAspectFit
            }
        }
    }
}
