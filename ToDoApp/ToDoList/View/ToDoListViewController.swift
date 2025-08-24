import UIKit

class TaskTableViewCell: UITableViewCell {
    let checkBox = UIButton(type: .system)
    let titleLabel = UILabel()
    let detailsLabel = UILabel()
    let dateLabel = UILabel()
    var task: Task?
    var onCheckboxTapped: ((Task) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        checkBox.setImage(UIImage(systemName: "circle"), for: .normal)
        checkBox.tintColor = UIColor.systemGray
        checkBox.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
        contentView.addSubview(checkBox)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 2
        detailsLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(detailsLabel)
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .light)
        dateLabel.textColor = .tertiaryLabel
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            checkBox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 28),
            checkBox.heightAnchor.constraint(equalToConstant: 28),
            
            titleLabel.leadingAnchor.constraint(equalTo: checkBox.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailsLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 4),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }
    
    @objc private func checkBoxTapped() {
        if let task = task {
            onCheckboxTapped?(task)
        }
    }
    
    func configure(with task: Task, onCheckboxTapped: @escaping (Task) -> Void) {
        self.task = task
        self.onCheckboxTapped = onCheckboxTapped
        
        detailsLabel.text = task.details
        
        // Форматируем дату в коротком формате
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        
        if let createdAt = task.createdAt {
            dateLabel.text = formatter.string(from: createdAt)
        } else {
            dateLabel.text = ""
        }
        
        if task.isCompleted {
            checkBox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            checkBox.tintColor = UIColor.systemGreen
            titleLabel.textColor = .systemGray
            titleLabel.attributedText = NSAttributedString(string: task.title ?? "", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
        } else {
            checkBox.setImage(UIImage(systemName: "circle"), for: .normal)
            checkBox.tintColor = UIColor.systemGray
            titleLabel.textColor = .label
            titleLabel.attributedText = nil
            titleLabel.text = task.title ?? ""
        }
    }
}

class ToDoListViewController: UIViewController, ToDoListViewProtocol {
    var presenter: ToDoListPresenterProtocol!
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Нет задач"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.isHidden = true
        return label
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Задачи"
        label.font = UIFont.systemFont(ofSize: 48, weight: .black)
        label.textColor = .label
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let bottomBarExtension: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let tasksCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 задач"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupSearchController()
        setupUI()
        presenter.viewDidLoad()
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск задач"
        searchController.searchBar.showsBookmarkButton = false
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.searchTextField.rightViewMode = .always
        searchController.searchBar.searchTextField.rightView = createVoiceButton()
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.definesPresentationContext = true
        searchController.searchBar.returnKeyType = .search
        searchController.searchBar.enablesReturnKeyAutomatically = false
    }
    
    private func createVoiceButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        button.tintColor = .systemGray
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        return button
    }
    
    @objc private func voiceButtonTapped() {
        // Здесь можно добавить логику голосового ввода
        // print("Voice button tapped")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Кастомный заголовок "Задачи" в navigation bar
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupCustomTitle()
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(bottomBar)
        view.addSubview(bottomBarExtension)
        bottomBar.addSubview(tasksCountLabel)
        bottomBar.addSubview(addButton)
        
        // TableView constraints (под navigation bar с отступом от поиска)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ])
        
        // Bottom bar constraints (возвращаю до safeArea)
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Bottom bar extension (растягиваю до низа экрана)
        NSLayoutConstraint.activate([
            bottomBarExtension.topAnchor.constraint(equalTo: bottomBar.bottomAnchor),
            bottomBarExtension.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBarExtension.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBarExtension.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Tasks count label constraints (по центру)
        NSLayoutConstraint.activate([
            tasksCountLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            tasksCountLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor)
        ])
        
        // Add button constraints (справа)
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            addButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Empty label constraints
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.autoresizingMask = []
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        addButton.addTarget(self, action: #selector(addTaskTapped), for: .touchUpInside)
    }
    
    private func setupCustomTitle() {
        let titleLabel = UILabel()
        titleLabel.text = "Задачи"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        container.heightAnchor.constraint(equalToConstant: 56).isActive = true
        container.widthAnchor.constraint(equalToConstant: 400).isActive = true
        navigationItem.titleView = container
    }
    
    func reloadData() {
        tableView.reloadData()
        emptyLabel.isHidden = presenter.tasks.count > 0
        updateTasksCount()
    }
    
    private func updateTasksCount() {
        let count = presenter.tasks.count
        if count == 0 {
            tasksCountLabel.text = "Нет задач"
        } else if count == 1 {
            tasksCountLabel.text = "1 задача"
        } else if count < 5 {
            tasksCountLabel.text = "\(count) задачи"
        } else {
            tasksCountLabel.text = "\(count) задач"
        }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func addTaskTapped() {
        showTaskAlert(title: "Новая задача", task: nil)
    }
    
    private func showTaskAlert(title: String, task: Task?) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название"; $0.text = task?.title }
        alert.addTextField { $0.placeholder = "Описание"; $0.text = task?.details }
        
        if let task = task {
            // Для редактирования существующей задачи
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self, weak alert] _ in
                guard let fields = alert?.textFields, let title = fields[0].text, !title.isEmpty else { return }
                let details = fields[1].text ?? ""
                self?.presenter.updateTask(task: task, title: title, details: details, isCompleted: task.isCompleted)
            })
        } else {
            // Для создания новой задачи
            alert.addAction(UIAlertAction(title: "Добавить", style: .default) { [weak self, weak alert] _ in
                guard let fields = alert?.textFields, let title = fields[0].text, !title.isEmpty else { return }
                let details = fields[1].text ?? ""
                self?.presenter.addTask(title: title, details: details)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

extension ToDoListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskTableViewCell else {
            return UITableViewCell()
        }
        let task = presenter.tasks[indexPath.row]
        cell.configure(with: task) { [weak self] task in
            self?.presenter.updateTask(task: task, title: task.title ?? "", details: task.details ?? "", isCompleted: !task.isCompleted)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = presenter.tasks[indexPath.row]
        showTaskDetailView(task: task)
    }
    
    private func showTaskDetailView(task: Task) {
        let detailVC = TaskDetailViewController(task: task) { [weak self] updatedTask in
            // Обновляем задачу после редактирования
            self?.presenter.updateTask(
                task: updatedTask,
                title: updatedTask.title ?? "",
                details: updatedTask.details ?? "",
                isCompleted: updatedTask.isCompleted
            )
        }
        
        let navController = UINavigationController(rootViewController: detailVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - 3D Touch Support
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let task = presenter.tasks[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = UIAction(title: "Редактировать", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.showTaskAlert(title: "Редактировать задачу", task: task)
            }
            
            let shareAction = UIAction(title: "Поделиться", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.shareTask(task: task)
            }
            
            let deleteAction = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteTask(task: task)
            }
            
            return UIMenu(title: "", children: [editAction, shareAction, deleteAction])
        }
    }
    
    // Убираю неправильную логику previewForHighlightingContextMenuWithConfiguration
    // Теперь 3D Touch будет работать корректно для каждой ячейки
    
    // MARK: - Context Menu Actions
    private func shareTask(task: Task) {
        let taskText = """
        Задача: \(task.title ?? "")
        Описание: \(task.details ?? "")
        Статус: \(task.isCompleted ? "Выполнена" : "Не выполнена")
        Дата создания: \(formatDate(task.createdAt))
        """
        
        let activityViewController = UIActivityViewController(activityItems: [taskText], applicationActivities: nil)
        
        // Для iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func deleteTask(task: Task) {
        let alert = UIAlertController(title: "Удалить задачу", message: "Вы уверены, что хотите удалить задачу '\(task.title ?? "")'?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.presenter.deleteTask(task: task)
        })
        
        present(alert, animated: true)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Неизвестно" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension ToDoListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        presenter.searchTasks(query: query)
    }
}
