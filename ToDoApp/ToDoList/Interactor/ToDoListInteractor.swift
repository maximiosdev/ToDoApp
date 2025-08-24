import Foundation
import CoreData

protocol ToDoListInteractorProtocol: AnyObject {
    func fetchTasks(completion: @escaping ([Task]) -> Void)
    func addTask(title: String, details: String, completion: @escaping (Task?) -> Void)
    func updateTask(task: Task, title: String, details: String, isCompleted: Bool, completion: @escaping (Bool) -> Void)
    func deleteTask(task: Task, completion: @escaping (Bool) -> Void)
    func searchTasks(query: String, completion: @escaping ([Task]) -> Void)
    func loadTasksFromAPIIfNeeded(completion: @escaping (Bool) -> Void)
}

class ToDoListInteractor: ToDoListInteractorProtocol {
    private let context = CoreDataStack.shared.context
    private let backgroundContext: NSManagedObjectContext = {
        return CoreDataStack.shared.persistentContainer.newBackgroundContext()
    }()

    func fetchTasks(completion: @escaping ([Task]) -> Void) {
        backgroundContext.perform {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let tasks = (try? self.backgroundContext.fetch(request)) ?? []
            let filtered = tasks.filter { !($0.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
            DispatchQueue.main.async { completion(filtered) }
        }
    }

    func addTask(title: String, details: String, completion: @escaping (Task?) -> Void) {
        backgroundContext.perform {
            let task = Task(context: self.backgroundContext)
            task.id = Int64(Date().timeIntervalSince1970 * 1000)
            task.title = title
            task.details = details
            task.createdAt = Date()
            task.isCompleted = false
            do {
                try self.backgroundContext.save()
                DispatchQueue.main.async { completion(task) }
            } catch {
                print("Failed to save task: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    func updateTask(task: Task, title: String, details: String, isCompleted: Bool, completion: @escaping (Bool) -> Void) {
        backgroundContext.perform {
            task.title = title
            task.details = details
            task.isCompleted = isCompleted
            do {
                try self.backgroundContext.save()
                DispatchQueue.main.async { completion(true) }
            } catch {
                print("Failed to update task: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    func deleteTask(task: Task, completion: @escaping (Bool) -> Void) {
        backgroundContext.perform {
            self.backgroundContext.delete(task)
            do {
                try self.backgroundContext.save()
                DispatchQueue.main.async { completion(true) }
            } catch {
                print("Failed to delete task: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    func searchTasks(query: String, completion: @escaping ([Task]) -> Void) {
        backgroundContext.perform {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR details CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let tasks = (try? self.backgroundContext.fetch(request)) ?? []
            let filtered = tasks.filter { !($0.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
            DispatchQueue.main.async { completion(filtered) }
        }
    }

    func loadTasksFromAPIIfNeeded(completion: @escaping (Bool) -> Void) {
        backgroundContext.perform {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            let count = (try? self.backgroundContext.count(for: request)) ?? 0
            guard count == 0 else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let url = URL(string: "https://dummyjson.com/todos") else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                do {
                    let apiResponse = try JSONDecoder().decode(DummyTodosResponse.self, from: data)
                    self.backgroundContext.perform {
                        for todo in apiResponse.todos {
                            let trimmed = todo.todo.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { continue }
                            let task = Task(context: self.backgroundContext)
                            task.id = Int64(todo.id)
                            task.title = trimmed
                            task.details = ""
                            // Генерируем разные даты для каждой задачи
                            let baseDate = Date()
                            let timeInterval = TimeInterval(todo.id * 3600) // 1 час между задачами
                            task.createdAt = baseDate.addingTimeInterval(-timeInterval)
                            task.isCompleted = todo.completed
                        }
                        try? self.backgroundContext.save()
                        DispatchQueue.main.async { completion(true) }
                    }
                } catch {
                    print("Failed to decode API: \(error)")
                    DispatchQueue.main.async { completion(false) }
                }
            }.resume()
        }
    }

    /// Удаляет все задачи с пустым или пробельным названием (однократно при запуске)
    func removeEmptyTasks(completion: (() -> Void)? = nil) {
        backgroundContext.perform {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            if let tasks = try? self.backgroundContext.fetch(request) {
                for task in tasks {
                    if (task.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                        self.backgroundContext.delete(task)
                    }
                }
                try? self.backgroundContext.save()
            }
            DispatchQueue.main.async { completion?() }
        }
    }
}

// MARK: - Dummy API Models
struct DummyTodosResponse: Codable {
    let todos: [DummyTodo]
}

struct DummyTodo: Codable {
    let id: Int
    let todo: String
    let completed: Bool
}
