import XCTest
@testable import Healstack

final class SubstanceDatabaseTests: XCTestCase {
    func testSearchReturnsResultsForCaffeine() {
        let results = SubstanceDatabase.search("caffeine")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.id == "caffeine" })
    }

    func testSearchReturnsEmptyForGibberish() {
        let results = SubstanceDatabase.search("qzxvnotarealsubstance123")
        XCTAssertTrue(results.isEmpty)
    }

    func testByCategoryVitaminContainsOnlyVitaminCategory() {
        let vitamins = SubstanceDatabase.byCategory(.vitamin)
        XCTAssertFalse(vitamins.isEmpty)
        XCTAssertTrue(vitamins.allSatisfy { $0.category == .vitamin })
    }

    func testFindCaffeineReturnsCorrectSubstance() {
        let substance = SubstanceDatabase.find(id: "caffeine")
        XCTAssertNotNil(substance)
        XCTAssertEqual(substance?.name, "Caffeine")
    }

    func testFindNonexistentReturnsNil() {
        XCTAssertNil(SubstanceDatabase.find(id: "not-a-real-id"))
    }

    func testAllSubstancesCountIsAtLeast200() {
        XCTAssertGreaterThanOrEqual(SubstanceDatabase.allSubstances.count, 200, "Expected 200+ substances, got \(SubstanceDatabase.allSubstances.count)")
    }

    func testAllCategoriesHaveAtLeastOneSubstance() {
        for category in SubstanceDatabase.categories {
            XCTAssertFalse(
                SubstanceDatabase.byCategory(category).isEmpty,
                "Expected category \(category.rawValue) to have at least one substance"
            )
        }
    }

    func testAllSubstancesHaveIcons() {
        for substance in SubstanceDatabase.allSubstances {
            XCTAssertFalse(
                substance.icon.isEmpty,
                "Substance \(substance.name) should have a non-empty icon"
            )
        }
    }

    func testAllSubstancesHaveNonEmptyHalfLife() {
        for substance in SubstanceDatabase.allSubstances {
            XCTAssertFalse(
                substance.halfLife.isEmpty,
                "Substance \(substance.name) should have a non-empty halfLife"
            )
        }
    }

    func testCategoryIconExists() {
        // Every category should have at least one substance with a valid SF Symbol name
        for category in SubstanceDatabase.categories {
            let substances = SubstanceDatabase.byCategory(category)
            XCTAssertFalse(substances.isEmpty)
            let firstIcon = substances.first?.icon ?? ""
            XCTAssertFalse(firstIcon.isEmpty, "Category \(category.rawValue) should have substances with icons")
        }
    }

    func testSearchCaseInsensitive() {
        let upper = SubstanceDatabase.search("CAFFEINE")
        let lower = SubstanceDatabase.search("caffeine")
        let mixed = SubstanceDatabase.search("Caffeine")

        XCTAssertFalse(upper.isEmpty)
        XCTAssertEqual(upper.count, lower.count)
        XCTAssertEqual(upper.count, mixed.count)
        XCTAssertEqual(upper.first?.id, lower.first?.id)
    }

    // Guideline 1.4.1: every substance shown in the library must carry
    // citations, so a missing or malformed source is a submission blocker.
    func testEverySubstanceHasAtLeastTwoSources() {
        for substance in SubstanceDatabase.allSubstances {
            XCTAssertGreaterThanOrEqual(
                substance.sources.count, 2,
                "\(substance.name) has fewer than two citations"
            )
        }
    }

    func testEverySourceURLIsHTTPSAndNamesTheSubstance() {
        for substance in SubstanceDatabase.allSubstances {
            for source in substance.sources {
                XCTAssertEqual(source.url.scheme, "https", "\(source.title) for \(substance.name) is not HTTPS")
                XCTAssertFalse(source.title.isEmpty)
                XCTAssertFalse(source.detail.isEmpty)
                let encoded = substance.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                XCTAssertTrue(
                    source.url.absoluteString.contains(encoded),
                    "\(source.title) for \(substance.name) does not cite that substance"
                )
            }
        }
    }

    func testPrescriptionCategoriesCiteDailyMed() {
        let prescription: Set<BuiltInSubstance.Category> = [.medication, .benzodiazepine, .opioid, .opioidAdjacent]
        let subjects = SubstanceDatabase.allSubstances.filter { prescription.contains($0.category) }
        XCTAssertFalse(subjects.isEmpty)
        for substance in subjects {
            XCTAssertTrue(
                substance.sources.contains { $0.title == "DailyMed" },
                "\(substance.name) is a prescription-class entry with no FDA label citation"
            )
        }
    }
}
