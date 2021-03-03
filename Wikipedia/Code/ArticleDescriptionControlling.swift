
import Foundation

protocol ArticleDescriptionControlling {
    var currentDescription: String? { get }
    func publishDescription(_ description: String, completion: @escaping (Result<Void, Error>) -> Void)
}
