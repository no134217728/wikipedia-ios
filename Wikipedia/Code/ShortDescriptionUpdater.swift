
import Foundation
import WMF

enum ShortDescriptionUpdaterError: Error {
    case failureFetchingSectionWikitext
    case failureConstructingRegexExpression
}

class ShortDescriptionUpdater: ArticleDescriptionControlling {
    
    private let sectionFetcher: SectionFetcher
    private let sectionUploader: WikiTextSectionUploader
    
    private let articleURL: URL
    private let sectionID: Int
    let currentDescription: String?
    
    fileprivate static let templateRegex = "({{[sS]hort description|(?:1=)?)([^}|]+)([^}]*}})"
    
    init(sectionFetcher: SectionFetcher = SectionFetcher(), sectionUploader: WikiTextSectionUploader = WikiTextSectionUploader(), articleURL: URL, sectionID: Int, currentDescription: String?) {
        self.sectionFetcher = sectionFetcher
        self.sectionUploader = sectionUploader
        self.articleURL = articleURL
        self.sectionID = sectionID
        self.currentDescription = currentDescription
    }
    
    func publish(newDescription: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        //first pull section content
        sectionFetcher.fetchSection(with: sectionID, articleURL: articleURL) { (result) in
            switch result {
            case .success(let response):
                
                let wikitext = response.wikitext
                let revisionID = response.revisionID
                
            case .failure(let error):
                completion(.failure(ShortDescriptionUpdaterError.failureFetchingSectionWikitext))
            }
        }
    }
    
    private func publish(wikitext: String, baseRevisionID: Int, newDescription: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        //todo: move sectionUploader calls to private methods
        //improve toSection: call (maybe should say sectionID or something, or prependToSection("\(sectionID)")
        do {
            guard try wikitext.containsShortDescription() else {
                
                let newTemplateToPrepend = "{{Short description|\(newDescription)}}"
                
                sectionUploader.prepend(toSection: "\(sectionID)", text: newTemplateToPrepend, forArticleURL: articleURL, isMinorEdit: true, baseRevID: baseRevisionID as NSNumber, completion: { (result, error) in
                    
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
                
                return
            }
                
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
    func containsShortDescription() throws -> Bool {
        
        guard let regex = try? NSRegularExpression(pattern: ShortDescriptionUpdater.templateRegex) else {
            throw ShortDescriptionUpdaterError.failureConstructingRegexExpression
        }
        
        let matches = regex.matches(in: self, range: NSMakeRange(0, self.utf16.count))
        
        return matches.count > 0
        
//        for match in matches {
//
////            guard match.numberOfRanges > 1 else {
////                continue
////            }
////
////            let matchRange = match.range(at: 1)
////            let token = (self as NSString).substring(with: matchRange)
//
//
//        }
        
    }
    
    func replacingShortDescription(with newShortDescription: String) throws -> String {
        
        guard let regex = try? NSRegularExpression(pattern: ShortDescriptionUpdater.templateRegex) else {
            throw ShortDescriptionUpdaterError.failureConstructingRegexExpression
        }
        
        return regex.stringByReplacingMatches(in: self, range: NSMakeRange(0, self.utf16.count), withTemplate: "$1\(newShortDescription)$3")
        
    }
}
