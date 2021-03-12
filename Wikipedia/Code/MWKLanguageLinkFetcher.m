#import "MWKLanguageLinkFetcher.h"
@import WMF.NSURL_WMFLinkParsing;
@import WMF.Swift;
@import WMF.MWKLanguageLink;
@import WMF.WMFComparison;
@import WMF.MWKLanguageLinkController;

@implementation MWKLanguageLinkFetcher

- (void)fetchLanguageLinksForArticleURL:(NSURL *)articleURL
                     languageController:(MWKLanguageLinkController *)languageController
                                success:(void (^)(NSArray *))success
                                failure:(void (^)(NSError *))failure {
    NSString *title = articleURL.wmf_title;
    if (!title.length) {
        failure([WMFFetcher invalidParametersError]);
        return;
    }
    NSDictionary *params = @{
        @"action": @"query",
        @"prop": @"langlinks",
        @"titles": title,
        @"lllimit": @"500",
        @"llprop": [@[@"langname", @"autonym"] componentsJoinedByString:@"|"],
        @"llinlanguagecode": [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode],
        @"redirects": @"",
        @"format": @"json"
    };
    [self performMediaWikiAPIGETForURL:articleURL
                   withQueryParameters:params
                     completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
                         if (error) {
                             failure(error);
                             return;
                         }
                         NSDictionary *pagesByID = result[@"query"][@"pages"];
                         NSDictionary *indexedLanguageLinks = [[pagesByID wmf_map:^id(id key, NSDictionary *result) {
                             return [result[@"langlinks"] wmf_map:^MWKLanguageLink *(NSDictionary *jsonLink) {
                                 
                                 NSString *altSubdomainCode = nil;
                                 if ([jsonLink[@"lang"] isKindOfClass:[NSString class]]) {
                                     NSString *jsonLangCode = jsonLink[@"lang"];
                                     MWKLanguageLink *existingLanguageLink = [languageController languageForContentLanguageCode:jsonLangCode];
                                     if (existingLanguageLink) {
                                         altSubdomainCode = existingLanguageLink.altSubdomainCode;
                                     } else {
                                         MWKLanguageLink *altExistingLanguageLink = [languageController languageForAltSubdomainCode:jsonLangCode];
                                         altSubdomainCode = altExistingLanguageLink.altSubdomainCode;
                                     }
                                 }
                                 
                                 return [[MWKLanguageLink alloc] initWithLanguageCode:jsonLink[@"lang"]
                                                                        pageTitleText:jsonLink[@"*"]
                                                                                 name:jsonLink[@"autonym"]
                                                                        localizedName:jsonLink[@"langname"]
                                                                  languageVariantCode:nil
                                                                     altSubdomainCode:altSubdomainCode];
                             }];
                         }] wmf_reject:^BOOL(id key, id obj) {
                             return WMF_IS_EQUAL(obj, [NSNull null]);
                         }];
                         NSAssert(indexedLanguageLinks.count < 2,
                                  @"Expected language links to return one or no objects for the title we fetched, but got: %@",
                                  indexedLanguageLinks);
                         NSArray *languageLinksForTitle = [[indexedLanguageLinks allValues] firstObject];
                         success(languageLinksForTitle);
                     }];
}

@end
