import UIKit
import CoreData

/// Screen 1 (root of the navigation controller): the list of subjects.
///
/// Navigation: tapping a subject performs "ShowTasksSegue" and hands that Subject to
/// TasksViewController. The info button presents the About screen modally.
class SubjectsViewController: UITableViewController {

    // MARK: - Properties

    private var subjects: [Subject] = []
    private let context = CoreDataStack.shared.context

    private let summaryHeader = SubjectsSummaryHeaderView()
    private let watermarkFooter = InterlinkWatermarkView.makeTableFooter()

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Subjects"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        tableView.backgroundColor = Theme.background

        let aboutButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(aboutTapped))
        aboutButton.accessibilityLabel = "About"
        navigationItem.leftBarButtonItem = aboutButton
    }

    // Runs every time the screen appears, so pending-task counts are refreshed
    // after returning from the Tasks screen.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSubjects()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The summary card uses Auto Layout, so its height is recalculated for the current width.
        tableView.sizeHeaderToFit()
    }

    // MARK: - Core Data

    private func loadSubjects() {
        let request: NSFetchRequest<Subject> = Subject.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        subjects = CoreDataStack.shared.fetch(request)
        updateDecorations()
        tableView.reloadData()
    }

    /// Shows the summary card and INTERLINK footer when there are subjects,
    /// or the empty-state placeholder when there are none.
    private func updateDecorations() {
        guard !subjects.isEmpty else {
            tableView.tableHeaderView = nil
            tableView.tableFooterView = nil
            tableView.backgroundView = emptyStateView(symbol: "books.vertical",
                                                      title: "No subjects yet",
                                                      message: "Tap + to add your first subject.")
            return
        }

        // Totals are read through the relationships, so no extra fetch requests are needed.
        let allTasks = subjects.flatMap { ($0.tasks as? Set<TaskItem>) ?? [] }
        let pendingCount = allTasks.filter { !$0.isDone }.count
        let notesCount = subjects.reduce(0) { $0 + ($1.notes?.count ?? 0) }
        summaryHeader.update(subjects: subjects.count, pendingTasks: pendingCount, notes: notesCount)

        tableView.backgroundView = nil
        tableView.tableHeaderView = summaryHeader
        tableView.tableFooterView = watermarkFooter
        tableView.sizeHeaderToFit()
    }

    // MARK: - Actions

    @IBAction func addSubjectTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Subject",
                                      message: "Enter the name of the subject.",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g., Mobile Application Development 2"
            textField.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [weak self, weak alert] _ in
            // Validation: a blank or whitespace-only name is ignored instead of saved.
            guard let self = self,
                  let name = alert?.textFields?.first?.text?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }

            let subject = Subject(context: self.context)
            subject.name = name
            subject.createdAt = Date()
            CoreDataStack.shared.save()
            self.loadSubjects()
        }
        alert.addAction(saveAction)
        present(alert, animated: true)
    }

    /// The About screen is wrapped in its own navigation controller so it gets a title bar and a Done button.
    @objc private func aboutTapped() {
        let about = UINavigationController(rootViewController: AboutViewController())
        present(about, animated: true)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return subjects.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubjectCell",
                                                 for: indexPath)
        let subject = subjects[indexPath.row]
        let name = subject.name ?? "Untitled subject"

        // subject.tasks is an NSSet of TaskItem objects (the to-many relationship).
        let allTasks = subject.tasks as? Set<TaskItem> ?? []
        let pendingCount = allTasks.filter { !$0.isDone }.count
        let notesCount = subject.notes?.count ?? 0

        var content = cell.defaultContentConfiguration()
        content.text = name
        content.textProperties.font = .preferred(.body, weight: .semibold)
        content.secondaryText = "\(taskSummary(pending: pendingCount, total: allTasks.count))"
            + "  ·  \(notesCount) note\(notesCount == 1 ? "" : "s")"
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
        content.secondaryTextProperties.color = .secondaryLabel
        content.image = Theme.iconTile(symbol: "book.closed.fill",
                                       color: Theme.color(forSubjectNamed: name))
        content.imageToTextPadding = 14
        content.directionalLayoutMargins.top = 12
        content.directionalLayoutMargins.bottom = 12
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    /// Readable, correctly pluralised task status for a subject row.
    private func taskSummary(pending: Int, total: Int) -> String {
        if total == 0 { return "No tasks yet" }
        if pending == 0 { return "All tasks done" }
        return "\(pending) pending task\(pending == 1 ? "" : "s")"
    }

    // MARK: - Table view delegate

    // Swipe left on a row to delete the subject.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        // The Cascade delete rule in the data model also removes this subject's tasks and notes.
        context.delete(subjects[indexPath.row])
        CoreDataStack.shared.save()
        subjects.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        updateDecorations()
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // The tapped Subject travels as the sender and is handed over in prepare(for:sender:).
        performSegue(withIdentifier: "ShowTasksSegue",
                     sender: subjects[indexPath.row])
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowTasksSegue",
              let destination = segue.destination as? TasksViewController,
              let subject = sender as? Subject else { return }
        destination.subject = subject
    }
}
