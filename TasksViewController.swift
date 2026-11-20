import UIKit
import CoreData

/// Screen 2: the tasks of one subject, with a progress card at the top.
///
/// Navigation: "+" or tapping a task opens TaskFormViewController ("ShowTaskFormSegue",
/// add or edit mode); the Notes button opens NotesViewController ("ShowNotesSegue").
class TasksViewController: UITableViewController {

    // MARK: - Properties

    /// Set by SubjectsViewController in prepare(for:sender:).
    var subject: Subject?

    private var tasks: [TaskItem] = []
    private let context = CoreDataStack.shared.context

    private let progressHeader = SubjectProgressHeaderView()
    private let watermarkFooter = InterlinkWatermarkView.makeTableFooter()

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = subject?.name
        // Subject names can be long; the small title plus the header card shows them in full.
        navigationItem.largeTitleDisplayMode = .never
        tableView.backgroundColor = Theme.background
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()   // refresh after returning from the Task Form
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.sizeHeaderToFit()
    }

    // MARK: - Core Data

    private func loadTasks() {
        guard let subject = subject else { return }
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        // Only the tasks that belong to this subject.
        request.predicate = NSPredicate(format: "subject == %@", subject)
        // Unfinished tasks first, then the earliest due date first.
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDone", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]
        tasks = CoreDataStack.shared.fetch(request)
        updateDecorations()
        tableView.reloadData()
    }

    /// Shows the progress card and INTERLINK footer, or the empty state when there are no tasks.
    private func updateDecorations() {
        guard !tasks.isEmpty else {
            tableView.tableHeaderView = nil
            tableView.tableFooterView = nil
            tableView.backgroundView = emptyStateView(symbol: "checklist",
                                                      title: "No tasks yet",
                                                      message: "Tap + to add a task for this subject.")
            return
        }

        let name = subject?.name ?? "Untitled subject"
        let completed = tasks.filter { $0.isDone }.count
        let overdue = tasks.filter { isOverdue($0) }.count
        progressHeader.update(subjectName: name,
                              color: Theme.color(forSubjectNamed: name),
                              completed: completed,
                              total: tasks.count,
                              overdue: overdue)

        tableView.backgroundView = nil
        tableView.tableHeaderView = progressHeader
        tableView.tableFooterView = watermarkFooter
        tableView.sizeHeaderToFit()
    }

    /// A task is overdue when it is not finished and its due date has already passed.
    private func isOverdue(_ task: TaskItem) -> Bool {
        guard !task.isDone, let dueDate = task.dueDate else { return false }
        return dueDate < Date()
    }

    // MARK: - Actions

    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        // sender nil means "no existing task", so the form opens in add mode.
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: nil)
    }

    @IBAction func notesTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowNotesSegue", sender: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell",
                                                 for: indexPath)
        let task = tasks[indexPath.row]
        let title = task.title ?? "Untitled task"
        let dueText = task.dueDate?.formatted(date: .abbreviated, time: .shortened)
            ?? "no due date"
        let overdue = isOverdue(task)

        var content = cell.defaultContentConfiguration()
        if task.isDone {
            // Completed tasks are struck through and dimmed so they read as finished at a glance.
            content.attributedText = NSAttributedString(string: title, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.preferredFont(forTextStyle: .body)
            ])
        } else {
            content.text = title
            content.textProperties.font = .preferred(.body, weight: .medium)
        }

        let priority = priorityName(for: task.priority)
        content.secondaryText = overdue
            ? "Overdue · \(dueText) · \(priority)"
            : "Due \(dueText) · \(priority)"
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
        content.secondaryTextProperties.color = overdue ? .systemRed : .secondaryLabel

        // The flag color shows the priority; finished tasks use a neutral gray.
        content.image = UIImage(systemName: "flag.fill")
        content.imageProperties.tintColor = task.isDone ? .tertiaryLabel : priorityColor(for: task.priority)
        content.directionalLayoutMargins.top = 10
        content.directionalLayoutMargins.bottom = 10

        cell.contentConfiguration = content
        cell.accessoryType = task.isDone ? .checkmark : .none
        cell.tintColor = .systemGreen   // color of the "done" checkmark
        return cell
    }

    /// Priority is stored as Int16 in Core Data: 0 = Low, 1 = Medium, 2 = High.
    private func priorityName(for value: Int16) -> String {
        switch value {
        case 0:  return "Low"
        case 2:  return "High"
        default: return "Medium"
        }
    }

    private func priorityColor(for value: Int16) -> UIColor {
        switch value {
        case 0:  return .systemGray
        case 2:  return .systemRed
        default: return .systemOrange
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Passing the tapped task opens the form in edit mode.
        performSegue(withIdentifier: "ShowTaskFormSegue",
                     sender: tasks[indexPath.row])
    }

    // Swipe right: mark done / undo.
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        let title = task.isDone ? "Undo" : "Done"
        let action = UIContextualAction(style: .normal, title: title) {
            [weak self] _, _, completion in
            task.isDone.toggle()
            CoreDataStack.shared.save()
            self?.loadTasks()   // re-sorts, so finished tasks move to the bottom
            completion(true)
        }
        action.image = UIImage(systemName: task.isDone ? "arrow.uturn.backward" : "checkmark")
        action.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [action])
    }

    // Swipe left: delete.
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.context.delete(self.tasks[indexPath.row])
            CoreDataStack.shared.save()
            self.loadTasks()
            completion(true)
        }
        action.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [action])
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowTaskFormSegue":
            guard let destination = segue.destination as? TaskFormViewController
            else { return }
            destination.subject = subject
            destination.taskToEdit = sender as? TaskItem   // nil when adding a new task
        case "ShowNotesSegue":
            guard let destination = segue.destination as? NotesViewController
            else { return }
            destination.subject = subject
        default:
            break
        }
    }
}
