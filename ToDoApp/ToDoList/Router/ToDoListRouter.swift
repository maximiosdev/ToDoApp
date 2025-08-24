import UIKit

protocol ToDoListRouterProtocol: AnyObject {
    // Навигация
}

class ToDoListRouter: ToDoListRouterProtocol {
    static func assembleModule() -> UIViewController {
        let interactor = ToDoListInteractor()
        let view = ToDoListViewController()
        let presenter = ToDoListPresenter(view: view, interactor: interactor)
        view.presenter = presenter
        return view
    }
}
