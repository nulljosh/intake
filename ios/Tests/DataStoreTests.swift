import XCTest
@testable import Healstack

@MainActor
final class DataStoreTests: XCTestCase {
    private let defaults = UserDefaults.standard
    private let substancesKey = "dose.substances"
    private let doseEntriesKey = "dose.doseEntries"
    private let healthEntriesKey = "dose.healthEntries"
    private let biometricEntriesKey = "dose.biometricEntries"

    override func setUp() {
        super.setUp()
        clearPersistence()
    }

    override func tearDown() {
        clearPersistence()
        super.tearDown()
    }

    func testAddAndDeleteDoseEntry() {
        let store = DataStore()
        store.substances = []

        let entry = DoseEntry(notes: "Test dose")
        store.addDoseEntry(entry)
        XCTAssertEqual(store.doseEntries.count, 1)

        store.deleteDoseEntry(entry)
        XCTAssertTrue(store.doseEntries.isEmpty)
    }

    func testAddAndDeleteSubstanceAlsoDeletesRelatedDoseEntries() {
        let store = DataStore()
        store.substances = []
        store.doseEntries = []

        let substance = Substance(
            name: "Test Substance",
            category: .supplement,
            dosage: 1,
            unit: "capsule",
            frequency: "Daily"
        )
        store.addSubstance(substance)

        let related = DoseEntry(substanceId: substance.id, notes: "Related")
        let unrelated = DoseEntry(substanceId: UUID(), notes: "Unrelated")
        store.addDoseEntry(related)
        store.addDoseEntry(unrelated)
        XCTAssertEqual(store.doseEntries.count, 2)

        store.deleteSubstance(substance)
        XCTAssertFalse(store.substances.contains { $0.id == substance.id })
        XCTAssertFalse(store.doseEntries.contains { $0.id == related.id })
        XCTAssertTrue(store.doseEntries.contains { $0.id == unrelated.id })
    }

    func testAddAndDeleteHealthEntry() {
        let store = DataStore()
        store.healthEntries = []

        let entry = HealthEntry(mood: 7, energy: 8, sleepHours: 7.5, notes: "Good day")
        store.addHealthEntry(entry)
        XCTAssertEqual(store.healthEntries.count, 1)

        store.deleteHealthEntry(entry)
        XCTAssertTrue(store.healthEntries.isEmpty)
    }

    func testAddAndDeleteBiometricEntry() {
        let store = DataStore()
        store.biometricEntries = []

        let entry = BiometricEntry(weight: 175, heartRate: 62, notes: "Baseline")
        store.addBiometricEntry(entry)
        XCTAssertEqual(store.biometricEntries.count, 1)

        store.deleteBiometricEntry(entry)
        XCTAssertTrue(store.biometricEntries.isEmpty)
    }

    func testGetActiveReturnsOnlyLast24Hours() {
        let store = DataStore()
        store.doseEntries = []

        let recent = DoseEntry(timestamp: Date().addingTimeInterval(-60 * 60))
        let old = DoseEntry(timestamp: Date().addingTimeInterval(-25 * 60 * 60))
        let future = DoseEntry(timestamp: Date().addingTimeInterval(60 * 60))

        store.addDoseEntry(recent)
        store.addDoseEntry(old)
        store.addDoseEntry(future)

        let active = store.getActive()
        XCTAssertTrue(active.contains { $0.id == recent.id })
        XCTAssertFalse(active.contains { $0.id == old.id })
        XCTAssertFalse(active.contains { $0.id == future.id })
    }

    func testSubstanceNameResolvesBuiltInId() {
        let store = DataStore()
        let entry = DoseEntry(builtInSubstanceId: "caffeine")
        XCTAssertEqual(store.substanceName(for: entry), "Caffeine")
    }

    func testSubstanceNameReturnsUnknownForUnmatchedEntry() {
        let store = DataStore()
        store.substances = []
        let entry = DoseEntry(substanceId: UUID(), builtInSubstanceId: "does-not-exist")
        XCTAssertEqual(store.substanceName(for: entry), "Unknown")
    }

    func testSeedIfNeededOnlySeedsWhenEmpty() throws {
        clearPersistence()
        let freshStore = DataStore()
        XCTAssertFalse(freshStore.substances.isEmpty)

        clearPersistence()
        let custom = [Substance(
            name: "Custom",
            category: .medication,
            dosage: 10,
            unit: "mg",
            frequency: "Daily"
        )]
        defaults.set(try JSONEncoder().encode(custom), forKey: substancesKey)

        let seededStore = DataStore()
        XCTAssertEqual(seededStore.substances.count, 1)
        XCTAssertEqual(seededStore.substances.first?.name, "Custom")
    }

    nonisolated private func clearPersistence() {
        let d = UserDefaults.standard
        d.removeObject(forKey: "dose.substances")
        d.removeObject(forKey: "dose.doseEntries")
        d.removeObject(forKey: "dose.healthEntries")
        d.removeObject(forKey: "dose.biometricEntries")
    }
}
