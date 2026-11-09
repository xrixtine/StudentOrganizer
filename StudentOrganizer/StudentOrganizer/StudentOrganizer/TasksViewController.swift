import UIKit
import CoreData

class TasksViewController: UITableViewController {

    
    var subject: Subject?

    private var tasks: [TaskItem] = []
    private let context = CoreDataStack.shared.context

    override func viewDidLoad() {
        super.viewDidLoad()
        title = subject?.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
    }

    private func loadTasks() {
        guard let subject = subject else { return }
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "subject == %@", subject)
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDone", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]
        do {
            tasks = try context.fetch(request)
        } catch {
            print("Could not fetch tasks: \(error)")
            tasks = []
        }
        tableView.backgroundView = tasks.isEmpty
            ? emptyStateLabel("No tasks yet.\nTap + to add one.") : nil
        tableView.reloadData()
    }

    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: nil)
    }

    @IBAction func notesTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowNotesSegue", sender: nil)
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell",
                                                 for: indexPath)
        let task = tasks[indexPath.row]

        let dueText = task.dueDate?.formatted(date: .abbreviated, time: .shortened)
            ?? "no due date"

        var content = cell.defaultContentConfiguration()
        content.text = task.title ?? "Untitled task"
        content.secondaryText = "Due \(dueText) - \(priorityName(for: task.priority))"
        content.textProperties.color = task.isDone ? .secondaryLabel : .label
        cell.contentConfiguration = content
        cell.accessoryType = task.isDone ? .checkmark : .none
        return cell
    }

    private func priorityName(for value: Int16) -> String {
        switch value {
        case 0:  return "Low"
        case 2:  return "High"
        default: return "Medium"
        }
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowTaskFormSegue",
                     sender: tasks[indexPath.row])
    }

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        let title = task.isDone ? "Undo" : "Done"
        let action = UIContextualAction(style: .normal, title: title) {
            [weak self] _, _, completion in
            task.isDone.toggle()
            CoreDataStack.shared.save()
            self?.loadTasks()
            completion(true)
        }
        action.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [action])
    }

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
        return UISwipeActionsConfiguration(actions: [action])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowTaskFormSegue":
            guard let destination = segue.destination as? TaskFormViewController
            else { return }
            destination.subject = subject
            destination.taskToEdit = sender as? TaskItem   
        case "ShowNotesSegue":
            guard let destination = segue.destination as? NotesViewController
            else { return }
            destination.subject = subject
        default:
            break
        }
    }
}
