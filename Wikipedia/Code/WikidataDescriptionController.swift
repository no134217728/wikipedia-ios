
import Foundation

class WikidataDescriptionController: ArticleDescriptionControlling {

    private let fetcher: WikidataFetcher
    private let wikidataDescription: String?
    private let language: String
    private let wikiDataID: String
    
    init?(article: WMFArticle, fetcher: WikidataFetcher = WikidataFetcher()) {
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
    
    func publishDescription(_ description: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        //todo: no need to pass in .local anymore
        fetcher.publish(newWikidataDescription: description, from: ArticleDescriptionSource.central, forWikidataID: wikiDataID, language: language) { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
}
