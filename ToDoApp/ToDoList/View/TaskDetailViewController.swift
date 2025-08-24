import UIKit

class TaskDetailViewController: UIViewController {
    private let task: Task
    private let onSave: (Task) -> Void
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailsTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(task: Task, onSave: @escaping (Task) -> Void) {
        self.task = task
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTaskData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        title = "Задача"
        
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(dateLabel)
        view.addSubview(detailsTextView)
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            detailsTextView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            detailsTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detailsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            detailsTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadTaskData() {
        titleLabel.text = task.title
        
        // Форматируем дату в коротком формате
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        
        if let createdAt = task.createdAt {
            dateLabel.text = "Создано: \(formatter.string(from: createdAt))"
        } else {
            dateLabel.text = "Дата создания неизвестна"
        }
        
        detailsTextView.text = task.details
        
        // Если задача выполнена, зачеркиваем название
        if task.isCompleted {
            titleLabel.attributedText = NSAttributedString(
                string: task.title ?? "",
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            titleLabel.textColor = .systemGray
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        // Обновляем только описание задачи
        task.details = detailsTextView.text
        
        onSave(task)
        dismiss(animated: true)
    }
}
