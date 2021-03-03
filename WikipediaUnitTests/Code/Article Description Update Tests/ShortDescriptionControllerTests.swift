
import XCTest
@testable import Wikipedia

class ShortDescriptionControllerTests: XCTestCase {
    
    private let wikiTextWithShortDescription = """
        {{about|the species that is commonly kept as a pet|the cat family|Felidae|other uses|Cat (disambiguation)|and|Cats (disambiguation)}}
        {{Good article}}
        {{short description|Domesticated felid species}}
        {{technical reasons|Cat #1|the album|Cat 1 (album)}}

        The '''cat''' (''Felis catus'') is a [[Domestication|domestic]] [[species]] of small [[carnivorous]] [[mammal]].<ref name="Linnaeus1758">{{Cite book |last=Linnaeus |first=C. |title=Systema naturae per regna tria naturae: secundum classes, ordines, genera, species, cum characteribus, differentiis, synonymis, locis |location=Holmiae |publisher=Laurentii Salvii |date=1758 |page=42 |chapter=Felis Catus |language=la |volume=1 |edition=Tenth reformed |chapter-url= https://archive.org/details/mobot31753000798865/page/42}}</ref><ref name="MSW3fc">{{MSW3 Wozencraft |id=14000031 |pages=534–535 |heading=Species ''Felis catus''}}</ref>
        """

    private let wikiTextWithoutShortDescription = """
        {{about|the species that is commonly kept as a pet|the cat family|Felidae|other uses|Cat (disambiguation)|and|Cats (disambiguation)}}
        {{Good article}}
        {{technical reasons|Cat #1|the album|Cat 1 (album)}}

        The '''cat''' (''Felis catus'') is a [[Domestication|domestic]] [[species]] of small [[carnivorous]] [[mammal]].<ref name="Linnaeus1758">{{Cite book |last=Linnaeus |first=C. |title=Systema naturae per regna tria naturae: secundum classes, ordines, genera, species, cum characteribus, differentiis, synonymis, locis |location=Holmiae |publisher=Laurentii Salvii |date=1758 |page=42 |chapter=Felis Catus |language=la |volume=1 |edition=Tenth reformed |chapter-url= https://archive.org/details/mobot31753000798865/page/42}}</ref><ref name="MSW3fc">{{MSW3 Wozencraft |id=14000031 |pages=534–535 |heading=Species ''Felis catus''}}</ref>
        """
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDetectShortDescription() throws {
        
        let withShortDescriptionEvaluation = try wikiTextWithShortDescription.testContainsShortDescription()
        let withoutShortDescriptionEvaluation = try wikiTextWithoutShortDescription.testContainsShortDescription()
        XCTAssertTrue(withShortDescriptionEvaluation)
        XCTAssertFalse(withoutShortDescriptionEvaluation)
    }
    
    func testReplaceShortDescription() throws {
        
        let wikiTextWithShortDescriptionReplacement = """
        {{about|the species that is commonly kept as a pet|the cat family|Felidae|other uses|Cat (disambiguation)|and|Cats (disambiguation)}}
        {{Good article}}
        {{short description|testing}}
        {{technical reasons|Cat #1|the album|Cat 1 (album)}}

        The '''cat''' (''Felis catus'') is a [[Domestication|domestic]] [[species]] of small [[carnivorous]] [[mammal]].<ref name="Linnaeus1758">{{Cite book |last=Linnaeus |first=C. |title=Systema naturae per regna tria naturae: secundum classes, ordines, genera, species, cum characteribus, differentiis, synonymis, locis |location=Holmiae |publisher=Laurentii Salvii |date=1758 |page=42 |chapter=Felis Catus |language=la |volume=1 |edition=Tenth reformed |chapter-url= https://archive.org/details/mobot31753000798865/page/42}}</ref><ref name="MSW3fc">{{MSW3 Wozencraft |id=14000031 |pages=534–535 |heading=Species ''Felis catus''}}</ref>
        """
        
        let withShortDescriptionResult = try wikiTextWithShortDescription.testReplacingShortDescription(with: "testing")
        let withoutShortDescriptionResult = try wikiTextWithoutShortDescription.testReplacingShortDescription(with: "testing")
        XCTAssertEqual(withShortDescriptionResult, wikiTextWithShortDescriptionReplacement)
        XCTAssertEqual(wikiTextWithoutShortDescription, withoutShortDescriptionResult)
    }

}
