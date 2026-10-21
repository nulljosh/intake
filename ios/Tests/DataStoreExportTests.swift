import XCTest
@testable import Healstack

@MainActor
final class DataStoreExportTests: XCTestCase {
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

    func testExportDataProducesValidJSON() {
        let store = DataStore()
        store.substances = []
        store.doseEntries = [DoseEntry(builtInSubstanceId: "caffeine", notes: "test")]
        store.healthEntries = [HealthEntry(mood: 4, energy: 3, sleepHours: 7.5, notes: "")]
        store.biometricEntries = []

        let data = store.exportData()
        XCTAssertNotNil(data)

        if let data {
            let json = try? JSONSerialization.jsonObject(with: data)
            XCTAssertNotNil(json, "Export should produce valid JSON")
        }
    }

    func testImportDataRestoresEntries() {
        let store = DataStore()
        store.substances = []
        let entry = DoseEntry(builtInSubstanceId: "caffeine", notes: "imported")
        store.doseEntries = [entry]
        store.healthEntries = [HealthEntry(mood: 5, energy: 5, sleepHours: 8.0, notes: "")]
        store.biometricEntries = [BiometricEntry(weight: 170)]

        guard let exported = store.exportData() else {
            return XCTFail("Export should not be nil")
        }

        let newStore = DataStore()
        newStore.substances = []
        newStore.doseEntries = []
        newStore.healthEntries = []
        newStore.biometricEntries = []

        let success = newStore.importData(exported)
        XCTAssertTrue(success)
        XCTAssertEqual(newStore.doseEntries.count, 1)
        XCTAssertEqual(newStore.doseEntries.first?.notes, "imported")
        XCTAssertEqual(newStore.healthEntries.count, 1)
        XCTAssertEqual(newStore.biometricEntries.count, 1)
    }

    func testImportMalformedJSONFails() {
        let store = DataStore()
        store.substances = []
        let badData = Data("not json".utf8)

        let result = store.importData(badData)
        XCTAssertFalse(result)
        XCTAssertNotNil(store.lastError)
    }

    func testExportEmptyDataStore() {
        let store = DataStore()
        store.substances = []
        store.doseEntries = []
        store.healthEntries = []
        store.biometricEntries = []

        let data = store.exportData()
        XCTAssertNotNil(data)
    }

    func testRoundTripExportImport() {
        let store = DataStore()
        store.substances = [Substance(name: "TestSub", category: .supplement, dosage: 500, unit: "mg", frequency: "Daily")]
        store.doseEntries = [
            DoseEntry(builtInSubstanceId: "caffeine", notes: "morning"),
            DoseEntry(builtInSubstanceId: "l-theanine", notes: "stacked"),
        ]
        store.healthEntries = [HealthEntry(mood: 4, energy: 4, sleepHours: 7.0, notes: "")]
        store.biometricEntries = [BiometricEntry(heartRate: 68)]

        guard let exported = store.exportData() else {
            return XCTFail("Export should succeed")
        }

        let restored = DataStore()
        restored.substances = []
        restored.doseEntries = []
        XCTAssertTrue(restored.importData(exported))

        XCTAssertEqual(restored.substances.count, store.substances.count)
        XCTAssertEqual(restored.doseEntries.count, store.doseEntries.count)
        XCTAssertEqual(restored.healthEntries.count, store.healthEntries.count)
        XCTAssertEqual(restored.biometricEntries.count, store.biometricEntries.count)
        XCTAssertEqual(restored.substances.first?.name, "TestSub")
    }

    func testSyncWidgetDataWritesToSharedDefaults() {
        let store = DataStore()
        store.substances = []
        store.doseEntries = []

        let entry = DoseEntry(builtInSubstanceId: "caffeine", timestamp: Date(), notes: "widget test")
        store.addDoseEntry(entry)

        let shared = UserDefaults(suiteName: DataStore.appGroupId)
        let count = shared?.integer(forKey: "widget.doseCount") ?? 0
        XCTAssertGreaterThanOrEqual(count, 1)
    }

    func testWidgetPillEncoding() {
        let store = DataStore()
        store.substances = []
        store.doseEntries = []

        store.addDoseEntry(DoseEntry(builtInSubstanceId: "caffeine", timestamp: Date(), notes: ""))
        store.addDoseEntry(DoseEntry(builtInSubstanceId: "caffeine", timestamp: Date(), notes: ""))

        let shared = UserDefaults(suiteName: DataStore.appGroupId)
        guard let data = shared?.data(forKey: "widget.activePills") else {
            return XCTFail("Expected activePills data in shared defaults")
        }

        struct WidgetPill: Codable {
            let name: String
            let count: Int
        }

        let pills = try? JSONDecoder().decode([WidgetPill].self, from: data)
        XCTAssertNotNil(pills)
        if let pill = pills?.first(where: { $0.name == "Caffeine" }) {
            XCTAssertEqual(pill.count, 2)
        }
    }

    func testLastErrorSetOnImportFailure() {
        let store = DataStore()
        store.substances = []
        store.lastError = nil

        _ = store.importData(Data("garbage".utf8))
        XCTAssertNotNil(store.lastError)
        XCTAssertTrue(store.lastError?.contains("Import failed") == true)
    }

    nonisolated private func clearPersistence() {
        let d = UserDefaults.standard
        d.removeObject(forKey: "dose.substances")
        d.removeObject(forKey: "dose.doseEntries")
        d.removeObject(forKey: "dose.healthEntries")
        d.removeObject(forKey: "dose.biometricEntries")
    }
}
