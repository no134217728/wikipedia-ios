
import Foundation

protocol ArticleDescriptionControlling {
    var currentDescription: String? { get }
    func publish(newDescription: String, completion: @escaping (Result<Void, Error>) -> Void)
}
