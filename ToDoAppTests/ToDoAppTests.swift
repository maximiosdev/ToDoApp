//
//  ToDoAppTests.swift
//  ToDoAppTests
//
//  Created by Maxim on 24.08.2025.
//

import XCTest
@testable import ToDoApp
import CoreData

final class ToDoAppTests: XCTestCase {
    var interactor: ToDoListInteractor!
    var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        persistentContainer = NSPersistentContainer(name: "ToDoApp")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        let exp = expectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
        CoreDataStack.shared.persistentContainer = persistentContainer
        interactor = ToDoListInteractor()
    }

    override func tearDownWithError() throws {
        interactor = nil
        persistentContainer = nil
        try super.tearDownWithError()
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testAddAndFetchTask() throws {
        let addExp = expectation(description: "Add task")
        interactor.addTask(title: "Test", details: "Details") { task in
            XCTAssertNotNil(task)
            addExp.fulfill()
        }
        wait(for: [addExp], timeout: 2)

        let fetchExp = expectation(description: "Fetch tasks")
        interactor.fetchTasks { tasks in
            XCTAssertEqual(tasks.count, 1)
            XCTAssertEqual(tasks.first?.title, "Test")
            fetchExp.fulfill()
        }
        wait(for: [fetchExp], timeout: 2)
    }

    func testDeleteTask() throws {
        let addExp = expectation(description: "Add task")
        var createdTask: Task?
        interactor.addTask(title: "ToDelete", details: "D") { task in
            createdTask = task
            addExp.fulfill()
        }
        wait(for: [addExp], timeout: 2)
        guard let task = createdTask else { XCTFail(); return }

        let deleteExp = expectation(description: "Delete task")
        interactor.deleteTask(task: task) { success in
            XCTAssertTrue(success)
            deleteExp.fulfill()
        }
        wait(for: [deleteExp], timeout: 2)

        let fetchExp = expectation(description: "Fetch tasks after delete")
        interactor.fetchTasks { tasks in
            XCTAssertTrue(tasks.isEmpty)
            fetchExp.fulfill()
        }
        wait(for: [fetchExp], timeout: 2)
    }

    func testSearchTasks() throws {
        let addExp = expectation(description: "Add tasks")
        let group = DispatchGroup()
        for i in 0..<3 {
            group.enter()
            interactor.addTask(title: "Task \(i)", details: i == 1 ? "Special" : "") { _ in group.leave() }
        }
        group.notify(queue: .main) { addExp.fulfill() }
        wait(for: [addExp], timeout: 2)

        let searchExp = expectation(description: "Search tasks")
        interactor.searchTasks(query: "Special") { tasks in
            XCTAssertEqual(tasks.count, 1)
            XCTAssertEqual(tasks.first?.details, "Special")
            searchExp.fulfill()
        }
        wait(for: [searchExp], timeout: 2)
    }

    func testPresenterAddAndFetch() throws {
        let view = MockView()
        let interactor = MockInteractor()
        let presenter = ToDoListPresenter(view: view, interactor: interactor)
        presenter.addTask(title: "PresenterTest", details: "PresenterDetails")
        presenter.searchTasks(query: "PresenterTest")
        XCTAssertTrue(interactor.addTaskCalled)
        XCTAssertTrue(view.reloadDataCalled)
        XCTAssertEqual(presenter.tasks.count, 1)
        XCTAssertEqual(presenter.tasks.first?.title, "PresenterTest")
    }

    func testPresenterDelete() throws {
        let view = MockView()
        let interactor = MockInteractor()
        let presenter = ToDoListPresenter(view: view, interactor: interactor)
        interactor.addTask(title: "ToDelete", details: "", completion: { _ in })
        presenter.deleteTask(task: interactor.tasks.first!)
        XCTAssertTrue(interactor.deleteTaskCalled)
        XCTAssertTrue(view.reloadDataCalled)
        XCTAssertEqual(presenter.tasks.count, 0)
    }

    func testPresenterSearch() throws {
        let view = MockView()
        let interactor = MockInteractor()
        let presenter = ToDoListPresenter(view: view, interactor: interactor)
        interactor.addTask(title: "FindMe", details: "", completion: { _ in })
        interactor.addTask(title: "Other", details: "", completion: { _ in })
        presenter.searchTasks(query: "FindMe")
        XCTAssertTrue(interactor.searchTaskCalled)
        XCTAssertEqual(presenter.tasks.count, 1)
        XCTAssertEqual(presenter.tasks.first?.title, "FindMe")
    }
}

final class MockView: ToDoListViewProtocol {
    var reloadDataCalled = false
    var showErrorCalled = false
    func reloadData() { reloadDataCalled = true }
    func showError(_ message: String) { showErrorCalled = true }
}

final class MockInteractor: ToDoListInteractorProtocol {
    var tasks: [Task] = []
    var addTaskCalled = false
    var updateTaskCalled = false
    var deleteTaskCalled = false
    var searchTaskCalled = false
    var loadFromAPICalled = false
    func fetchTasks(completion: @escaping ([Task]) -> Void) { completion(tasks) }
    func addTask(title: String, details: String, completion: @escaping (Task?) -> Void) {
        addTaskCalled = true
        let task = Task(context: CoreDataStack.shared.context)
        task.id = Int64(Date().timeIntervalSince1970 * 1000)
        task.title = title
        task.details = details
        task.createdAt = Date()
        task.isCompleted = false
        tasks.append(task)
        completion(task)
    }
    func updateTask(task: Task, title: String, details: String, isCompleted: Bool, completion: @escaping (Bool) -> Void) {
        updateTaskCalled = true
        task.title = title
        task.details = details
        task.isCompleted = isCompleted
        completion(true)
    }
    func deleteTask(task: Task, completion: @escaping (Bool) -> Void) {
        deleteTaskCalled = true
        if let idx = tasks.firstIndex(of: task) { tasks.remove(at: idx) }
        completion(true)
    }
    func searchTasks(query: String, completion: @escaping ([Task]) -> Void) {
        searchTaskCalled = true
        let filtered = tasks.filter { $0.title.contains(query) || $0.details.contains(query) }
        completion(filtered)
    }
    func loadTasksFromAPIIfNeeded(completion: @escaping (Bool) -> Void) {
        loadFromAPICalled = true
        completion(false)
    }
}
