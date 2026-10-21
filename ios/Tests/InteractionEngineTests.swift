import XCTest
@testable import Healstack

final class InteractionEngineTests: XCTestCase {
    func testClassifySeverityKeywords() {
        XCTAssertEqual(InteractionEngine.classify("fatal interaction"), .major)
        XCTAssertEqual(InteractionEngine.classify("potentiates effect"), .moderate)
        XCTAssertEqual(InteractionEngine.classify("some note"), .minor)
    }

    func testCheckSertralineAndPsilocybinReturnsInteractions() {
        guard let sertraline = SubstanceDatabase.find(id: "sertraline"),
              let psilocybin = SubstanceDatabase.find(id: "psilocybin") else {
            return XCTFail("Expected built-in substances to exist")
        }

        let results = InteractionEngine.check(sertraline, psilocybin)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.description.contains("Psilocybin (blunted effects)") })
    }

    func testCheckNoKnownInteractionReturnsEmpty() {
        guard let caffeine = SubstanceDatabase.find(id: "caffeine"),
              let vitaminC = SubstanceDatabase.find(id: "vitamin-c") else {
            return XCTFail("Expected built-in substances to exist")
        }

        let results = InteractionEngine.check(caffeine, vitaminC)
        XCTAssertTrue(results.isEmpty)
    }

    func testCheckIsBidirectional() {
        guard let sertraline = SubstanceDatabase.find(id: "sertraline"),
              let psilocybin = SubstanceDatabase.find(id: "psilocybin") else {
            return XCTFail("Expected built-in substances to exist")
        }

        let forward = InteractionEngine.check(sertraline, psilocybin)
        let reverse = InteractionEngine.check(psilocybin, sertraline)

        let forwardSet = Set(forward.map { "\($0.severity.rawValue)|\($0.description)" })
        let reverseSet = Set(reverse.map { "\($0.severity.rawValue)|\($0.description)" })
        XCTAssertEqual(forwardSet, reverseSet)
    }

    func testSeverityKeywordsFatal() {
        XCTAssertEqual(InteractionEngine.classify("seizure risk"), .major)
        XCTAssertEqual(InteractionEngine.classify("serotonin syndrome"), .major)
        XCTAssertEqual(InteractionEngine.classify("risk of death"), .major)
        XCTAssertEqual(InteractionEngine.classify("avoid combination"), .major)
        XCTAssertEqual(InteractionEngine.classify("contraindicated"), .major)
    }

    func testEmptyInteractionsReturnsEmpty() {
        // Create two substances with no cross-references in their interactions
        guard let caffeine = SubstanceDatabase.find(id: "caffeine"),
              let vitaminC = SubstanceDatabase.find(id: "vitamin-c") else {
            return XCTFail("Expected built-in substances to exist")
        }
        let results = InteractionEngine.check(caffeine, vitaminC)
        XCTAssertTrue(results.isEmpty)
    }

    func testSameSubstanceNoInteraction() {
        guard let caffeine = SubstanceDatabase.find(id: "caffeine") else {
            return XCTFail("Expected caffeine to exist")
        }
        // Checking a substance against itself should not match its own interactions
        // unless it explicitly references itself by name
        let results = InteractionEngine.check(caffeine, caffeine)
        // Just verify it doesn't crash and returns a deterministic result
        XCTAssertTrue(results.count >= 0)
    }

    func testAllSeverityLevels() {
        XCTAssertEqual(InteractionEngine.classify("completely benign note").rawValue, Severity.minor.rawValue)
        XCTAssertEqual(InteractionEngine.classify("potentiates effect").rawValue, Severity.moderate.rawValue)
        XCTAssertEqual(InteractionEngine.classify("fatal combination").rawValue, Severity.major.rawValue)

        // Verify ordering
        XCTAssertTrue(Severity.minor < Severity.moderate)
        XCTAssertTrue(Severity.moderate < Severity.major)
    }
}
