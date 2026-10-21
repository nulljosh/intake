import XCTest
@testable import Healstack

@MainActor
final class CSVExporterTests: XCTestCase {
    func testHeaderFormat() throws {
        let store = DataStore()
        store.doseEntries = []
        let result = CSVExporter.export(entries: [], dataStore: store)
        let url = try result.get()
        let csv = try String(contentsOf: url, encoding: .utf8)
        let firstLine = csv.components(separatedBy: "\n").first
        XCTAssertEqual(firstLine, "date,time,substance,dose,unit,route,rating,notes")
    }

    func testFullEntryGeneratesCorrectCSV() throws {
        let store = DataStore()
        store.substances = []
        store.doseEntries = []

        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = DoseEntry(
            builtInSubstanceId: "caffeine",
            timestamp: timestamp,
            notes: "Felt focused",
            dose: 100,
            unit: "mg",
            route: "oral",
            rating: 8
        )

        let url = try CSVExporter.export(entries: [entry], dataStore: store).get()
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let expectedLine = [
            dateFormatter.string(from: timestamp),
            timeFormatter.string(from: timestamp),
            "Caffeine",
            "100.0",
            "mg",
            "oral",
            "8",
            "Felt focused"
        ].joined(separator: ",")

        XCTAssertEqual(lines[1], expectedLine)
    }

    func testNilOptionalsProduceEmptyFields() throws {
        let store = DataStore()
        store.substances = []
        store.doseEntries = []

        let entry = DoseEntry(builtInSubstanceId: "caffeine", notes: "")
        let url = try CSVExporter.export(entries: [entry], dataStore: store).get()
        let csv = try String(contentsOf: url, encoding: .utf8)
        let line = csv.components(separatedBy: "\n")[1]
        let fields = line.components(separatedBy: ",")

        XCTAssertEqual(fields.count, 8)
        XCTAssertEqual(fields[2], "Caffeine")
        XCTAssertEqual(fields[3], "")
        XCTAssertEqual(fields[4], "")
        XCTAssertEqual(fields[5], "")
        XCTAssertEqual(fields[6], "")
        XCTAssertEqual(fields[7], "")
    }

    func testCSVEscapeWithQuotesCommasAndNewlines() throws {
        let store = DataStore()
        store.substances = []
        store.doseEntries = []

        let entry = DoseEntry(
            substanceId: UUID(),
            notes: "Line 1,\n\"quoted\""
        )
        let customSubstance = Substance(
            id: entry.substanceId,
            name: "My, \"Complex\" Name",
            category: .supplement,
            dosage: 1,
            unit: "capsule",
            frequency: "Daily"
        )
        store.addSubstance(customSubstance)

        let url = try CSVExporter.export(entries: [entry], dataStore: store).get()
        let csv = try String(contentsOf: url, encoding: .utf8)

        // Assert against the whole file, not a "\n"-split line: the notes field
        // deliberately embeds a newline, and RFC 4180 keeps that inside the quotes,
        // so one record legitimately spans two physical lines.
        XCTAssertTrue(csv.contains("\"My, \"\"Complex\"\" Name\""))
        XCTAssertTrue(csv.contains("\"Line 1,\n\"\"quoted\"\"\""))
    }
}
