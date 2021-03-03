
import Foundation
import WMF

enum ShortDescriptionControllerError: Error {
    case failureConstructingRegexExpression
}

class ShortDescriptionController: ArticleDescriptionControlling {
    
    private let sectionFetcher: SectionFetcher
    private let sectionUploader: WikiTextSectionUploader
    
    private let articleURL: URL
    private let sectionID: Int = 0 //{{Short description}} template should always be in the first section.
    let currentDescription: String?
    
    fileprivate static let templateRegex = "(\\{\\{\\s*[sS]hort description\\|(?:1=)?)([^}|]+)([^}]*\\}\\})"
    
//MARK: Public
    
    /// Inits for use of updating EN Wikipedia article description
    /// - Parameters:
    ///   - sectionFetcher: section fetcher that fetches the first section of wikitext. Injectable for unit tests.
    ///   - sectionUploader: section uploader that uploads the new section wikitext. Injectable for unit tests.
    ///   - articleURL: URL of article that we want to updates
    ///   - currentDescription: Current article description for pre-populating the native update screen textfield. Since we likely already have this (i.e. coming from article content), this saves us a loading step of fetching wikitext and parsing short description upon load of the native update screen.
    init(sectionFetcher: SectionFetcher = SectionFetcher(), sectionUploader: WikiTextSectionUploader = WikiTextSectionUploader(), articleURL: URL, currentDescription: String?) {
        self.sectionFetcher = sectionFetcher
        self.sectionUploader = sectionUploader
        self.articleURL = articleURL
        self.currentDescription = currentDescription
    }
    
    /// Publishes a new article description to article wikitext. Detects the existence of the {{Short description}} template in the first section and replaces the text within or prepends the section with the new template.
    /// - Parameters:
    ///   - description: The new description to insert into the wikitext
    ///   - completion: Completion called when updated section upload call is successful.
    func publishDescription(_ description: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        sectionFetcher.fetchSection(with: sectionID, articleURL: articleURL) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let response):
                
                let wikitext = response.wikitext
                let revisionID = response.revisionID
                
                self.uploadNewDescriptionToWikitext(wikitext, baseRevisionID: revisionID, newDescription: description, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

//MARK: Private helpers

private extension ShortDescriptionController {
    
    func uploadNewDescriptionToWikitext(_ wikitext: String, baseRevisionID: Int, newDescription: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        //todo: move sectionUploader calls to private methods
        //improve toSection: call (maybe should say sectionID or something, or prependToSection("\(sectionID)")
        do {
            guard try wikitext.containsShortDescription() else {
                
                prependNewDescriptionToWikitextAndUpload(wikitext, baseRevisionID: baseRevisionID, newDescription: newDescription, completion: completion)
                return
            }
                
            replaceDescriptionInWikitextAndUpload(wikitext, newDescription: newDescription, baseRevisionID: baseRevisionID, completion: completion)
            
        } catch (let error) {
            completion(.failure(error))
        }
    }
    
    func prependNewDescriptionToWikitextAndUpload(_ wikitext: String, baseRevisionID: Int, newDescription: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        let newTemplateToPrepend = "{{Short description|\(newDescription)}}"
        
        sectionUploader.prepend(toSectionID: "\(sectionID)", text: newTemplateToPrepend, forArticleURL: articleURL, isMinorEdit: true, baseRevID: baseRevisionID as NSNumber, completion: { (result, error) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard result != nil else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            completion(.success(()))
        })
    }
    
    func replaceDescriptionInWikitextAndUpload(_ wikitext: String, newDescription: String, baseRevisionID: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        
        do {
            
            let updatedWikitext = try wikitext.replacingShortDescription(with: newDescription)
            
            sectionUploader.uploadWikiText(updatedWikitext, forArticleURL: articleURL, section: "\(sectionID)", summary: nil, isMinorEdit: true, addToWatchlist: false, baseRevID: baseRevisionID as NSNumber, captchaId: nil, captchaWord: nil, completion: { (result, error) in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard result != nil else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                
                completion(.success(()))
            })
            
        } catch (let error) {
            completion(.failure(error))
        }
    }
}

private extension String {
    
    /// Detects if the message receiver contains a {{short description}} template or not
    /// - Throws: If short description NSRegularExpression fails to instantiate
    /// - Returns: Boolean indicating whether the message receiver contains a {{short description}} template or not
    func containsShortDescription() throws -> Bool {
        
        guard let regex = try? NSRegularExpression(pattern: ShortDescriptionController.templateRegex) else {
            throw ShortDescriptionControllerError.failureConstructingRegexExpression
        }
        
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        
        return matches.count > 0
    }
    
    /// Replaces the {{short description}} template value in message receiver with the new description.
    /// Assumes the {{short description}} template already exists. Does not insert a {{short description}} template if it doesn't exist.
    /// - Parameter newShortDescription: new short description value to replace existing with
    /// - Throws: If short description NSRegularExpression fails to instantiate
    /// - Returns: Message receiver with short description template within replaced.
    func replacingShortDescription(with newShortDescription: String) throws -> String {
        
        guard let regex = try? NSRegularExpression(pattern: ShortDescriptionController.templateRegex) else {
            throw ShortDescriptionControllerError.failureConstructingRegexExpression
        }
        
        return regex.stringByReplacingMatches(in: self, range: NSRange(self.startIndex..., in: self), withTemplate: "$1\(newShortDescription)$3")
        
    }
}

#if TEST

extension String {
    func testContainsShortDescription() throws -> Bool {
        return try containsShortDescription()
    }
    
    func testReplacingShortDescription(with newShortDescription: String) throws -> String {
        return try replacingShortDescription(with: newShortDescription)
    }
}

#endif
