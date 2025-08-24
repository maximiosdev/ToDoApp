import Foundation

protocol ToDoListPresenterProtocol: AnyObject {
    var tasks: [Task] { get }
    func viewDidLoad()
    func addTask(title: String, details: String)
    func updateTask(task: Task, title: String, details: String, isCompleted: Bool)
    func deleteTask(task: Task)
    func searchTasks(query: String)
}

protocol ToDoListViewProtocol: AnyObject {
    func reloadData()
    func showError(_ message: String)
}

class ToDoListPresenter: ToDoListPresenterProtocol {
    private weak var view: ToDoListViewProtocol?
    private let interactor: ToDoListInteractorProtocol
    private(set) var tasks: [Task] = []
    
    init(view: ToDoListViewProtocol, interactor: ToDoListInteractorProtocol) {
        self.view = view
        self.interactor = interactor
    }
    
    func viewDidLoad() {
        // Удаляем пустые задачи при запуске
        if let interactor = interactor as? ToDoListInteractor {
            interactor.removeEmptyTasks { [weak self] in
                self?.interactor.loadTasksFromAPIIfNeeded { [weak self] _ in
                    self?.fetchTasks()
                }
            }
        } else {
            interactor.loadTasksFromAPIIfNeeded { [weak self] _ in
                self?.fetchTasks()
            }
        }
    }
    
    private func fetchTasks() {
        interactor.fetchTasks { [weak self] tasks in
            self?.tasks = tasks
            self?.view?.reloadData()
        }
    }
    
    func addTask(title: String, details: String) {
        interactor.addTask(title: title, details: details) { [weak self] _ in
            self?.fetchTasks()
        }
    }
    
    func updateTask(task: Task, title: String, details: String, isCompleted: Bool) {
        interactor.updateTask(task: task, title: title, details: details, isCompleted: isCompleted) { [weak self] _ in
            self?.fetchTasks()
        }
    }
    
    func deleteTask(task: Task) {
        interactor.deleteTask(task: task) { [weak self] _ in
            self?.fetchTasks()
        }
    }
    
    func searchTasks(query: String) {
        guard !query.isEmpty else {
            fetchTasks()
            return
        }
        interactor.searchTasks(query: query) { [weak self] tasks in
            self?.tasks = tasks
            self?.view?.reloadData()
        }
    }
}
