import UIKit
import CoreData

/// Screen 4: a two-column grid (UICollectionView) of the notes for one subject.
///
/// Navigation: "+" opens NoteFormViewController ("ShowNoteFormSegue");
/// tapping a note opens NoteDetailViewController ("ShowNoteDetailSegue").
class NotesViewController: UIViewController,
                           UICollectionViewDataSource,
                           UICollectionViewDelegateFlowLayout {

    // MARK: - Properties

    /// Set by TasksViewController in prepare(for:sender:).
    var subject: Subject?

    private var notes: [Note] = []
    private let context = CoreDataStack.shared.context

    private let columns: CGFloat = 2    // cells per row
    private let spacing: CGFloat = 16   // gap between cells and around the grid

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.background
        collectionView.backgroundColor = Theme.background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WatermarkFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: WatermarkFooterView.reuseIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()   // refresh after adding or deleting a note
    }

    // MARK: - Core Data

    private func loadNotes() {
        guard let subject = subject else { return }
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "subject == %@", subject)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]   // newest first
        notes = CoreDataStack.shared.fetch(request)
        collectionView.backgroundView = notes.isEmpty
            ? emptyStateView(symbol: "note.text",
                             title: "No notes yet",
                             message: "Tap + to save a note or a photo of the whiteboard.")
            : nil
        collectionView.reloadData()
    }

    // MARK: - Actions

    @IBAction func addNoteTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowNoteFormSegue", sender: nil)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "NoteCell", for: indexPath) as? NoteCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: notes[indexPath.item])
        return cell
    }

    // The only supplementary view requested is the footer (see referenceSizeForFooterInSection).
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: WatermarkFooterView.reuseIdentifier,
            for: indexPath)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowNoteDetailSegue",
                     sender: notes[indexPath.item])
    }

    // MARK: - UICollectionViewDelegateFlowLayout (grid size and spacing)

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Screen width minus every gap, shared equally between the columns,
        // so the grid fits any iPhone width.
        let totalSpacing = spacing * (columns + 1)
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)
        // Square photo + room for two lines of text (8 pt padding above and below).
        // Based on the live font, so larger Dynamic Type sizes get taller cells.
        let textHeight = ceil(Theme.noteCellFont.lineHeight * 2) + 16
        return CGSize(width: width, height: width + textHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }

    // The INTERLINK footer is only shown under real notes; an empty grid shows the empty state instead.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        return notes.isEmpty ? .zero : CGSize(width: collectionView.bounds.width, height: 56)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowNoteFormSegue":
            guard let destination = segue.destination as? NoteFormViewController
            else { return }
            destination.subject = subject
        case "ShowNoteDetailSegue":
            guard let destination = segue.destination as? NoteDetailViewController,
                  let note = sender as? Note else { return }
            destination.note = note
        default:
            break
        }
    }
}
