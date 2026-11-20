import UIKit

/// Screen 3: one form used for both adding and editing a task.
/// `taskToEdit` decides the mode: nil = add a new task, non-nil = edit that task.
class TaskFormViewController: UIViewController {

    // MARK: - Data passed in from TasksViewController

    var subject: Subject?
    var taskToEdit: TaskItem?

    // MARK: - Outlets

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet weak var completedSwitch: UISwitch!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        styleForm()

        if let task = taskToEdit {
            // Edit mode: fill the controls with the saved values.
            title = "Edit Task"
            titleTextField.text = task.title
            detailsTextField.text = task.details
            dueDatePicker.date = task.dueDate ?? Date()
            prioritySegmentedControl.selectedSegmentIndex = Int(task.priority)
            completedSwitch.isOn = task.isDone
        } else {
            title = "New Task"
            dueDatePicker.date = Date()
        }

        // Tap anywhere on the background to hide the keyboard.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false   // do not block taps on the other controls
        view.addGestureRecognizer(tap)
    }

    private func styleForm() {
        view.backgroundColor = Theme.background
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem?.style = .done

        Theme.styleTextField(titleTextField)
        Theme.styleTextField(detailsTextField)

        // The fields sit directly in the storyboard's vertical stack view. Extra space after
        // each control groups every label with its input.
        if let form = titleTextField.superview as? UIStackView {
            let groupEnds: [UIView] = [titleTextField, detailsTextField,
                                       dueDatePicker, prioritySegmentedControl]
            groupEnds.forEach { form.setCustomSpacing(22, after: $0) }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Actions

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        // Validation: text fields are optional and may hold only spaces, so trim before checking.
        let taskTitle = (titleTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !taskTitle.isEmpty else {
            showAlert(title: "Title required",
                      message: "Please type a title for your task.")
            return
        }

        // Reuse the task being edited, or create a brand-new one.
        let task = taskToEdit ?? TaskItem(context: CoreDataStack.shared.context)
        task.title = taskTitle
        task.details = detailsTextField.text
        task.dueDate = dueDatePicker.date
        task.priority = Int16(prioritySegmentedControl.selectedSegmentIndex)
        task.isDone = completedSwitch.isOn
        if taskToEdit == nil {
            task.subject = subject   // link only new tasks; edited ones already belong to a subject
        }

        CoreDataStack.shared.save()
        navigationController?.popViewController(animated: true)
    }
}
