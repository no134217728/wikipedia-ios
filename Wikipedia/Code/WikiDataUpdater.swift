
import Foundation

class WikiDataUpdater: ArticleDescriptionControlling {

    private let fetcher: WikidataDescriptionEditingController
    private let wikidataDescription: String?
    private let language: String
    private let wikiDataID: String
    
    init?(article: WMFArticle, fetcher: WikidataDescriptionEditingController = WikidataDescriptionEditingController()) {
        self.fetcher = fetcher
        self.wikidataDescription = article.wikidataDescription
        
        guard let wikiDataID = article.wikidataID,
              let language = article.url?.wmf_language else {
            return nil
        }
        
        self.wikiDataID = wikiDataID
        self.language = language
    }
    
    var currentDescription: String? {
        return wikidataDescription
    }
    
    func publish(newDescription: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        //todo: no need to pass in .local anymore
        fetcher.publish(newWikidataDescription: newDescription, from: .local, forWikidataID: wikiDataID, language: language) { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
}
