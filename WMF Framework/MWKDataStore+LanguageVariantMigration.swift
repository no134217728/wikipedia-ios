import Foundation

extension MWKDataStore {
    
    @objc(migrateToLanguageVariantsForLanguages:inManagedObjectContext:)
    public func migrateToLanguageVariants(for languages:[String], in moc: NSManagedObjectContext) {
        // Map all languages with variants being migrated to the user's preferred variant
        // Even if the user does not have a language in preferred language settings,
        // the user could have chosen to read or save an article in any language.
        let migrationMapping = languages.reduce(into: [String:String]()) { (result, languageCode) in
            guard let languageVariantCode = NSLocale.wmf_bestLanguageVariantCodeForLanguageCode(languageCode) else {
                assertionFailure("No variant found for language code \(languageCode). Every language migrating to use language variants should return a language variant code")
                return
            }
            result[languageCode] = languageVariantCode
        }
        
        self.languageLinkController.migratePreferredLanguages(toLanguageVariants:migrationMapping, in: moc)
        self.feedContentController.migrateExploreFeedSettings(toLanguageVariants: migrationMapping, in: moc)
        
        let defaults = UserDefaults.standard
        if let url = defaults.url(forKey: WMFSearchURLKey),
           let languageCode = url.wmf_language {
            let searchLanguageCode = migrationMapping[languageCode] ?? languageCode
            defaults.wmf_setCurrentSearchContentLanguageCode(searchLanguageCode)
            defaults.removeObject(forKey: WMFSearchURLKey)
        }
        
        self.readingListsController.migrateWikipediaEntitiesToLanguageVariants(languageMapping: migrationMapping, in: moc)
//        self.readingListsController.migrateArticlesAndEntriesToLanguageVariants(with: mappings.variantToArticleKeyMapping, languageToMostRecentVariant: mappings.languageToMostRecentVariant, migratedLanguageCodes: languages, in: moc)

    }
    
    

}
