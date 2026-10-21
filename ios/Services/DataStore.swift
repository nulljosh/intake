import Foundation
import Observation
import WidgetKit

@Observable
final class DataStore {
    static let appGroupId = "group.com.heyitsmejosh.dose"

    var substances: [Substance] = [] {
        didSet { guard !isLoading else { return }; saveSubstances() }
    }

    var doseEntries: [DoseEntry] = [] {
        didSet { guard !isLoading else { return }; saveDoseEntries(); syncWidgetData() }
    }

    var healthEntries: [HealthEntry] = [] {
        didSet { guard !isLoading else { return }; saveHealthEntries() }
    }

    var biometricEntries: [BiometricEntry] = [] {
        didSet { guard !isLoading else { return }; saveBiometricEntries() }
    }

    var myMedications: [MyMedication] = [] {
        didSet { guard !isLoading else { return }; saveMedications() }
    }

    var labResults: [LabResult] = [] {
        didSet { guard !isLoading else { return }; saveLabResults() }
    }

    var lastError: String?

    var userName: String {
        get { defaults.string(forKey: userNameKey) ?? "" }
        set { defaults.set(newValue, forKey: userNameKey) }
    }

    var userEmail: String {
        get { defaults.string(forKey: userEmailKey) ?? "" }
        set { defaults.set(newValue, forKey: userEmailKey) }
    }

    private var isLoading = false
    private let defaults = UserDefaults.standard
    private let substancesKey = "dose.substances"
    private let doseEntriesKey = "dose.doseEntries"
    private let healthEntriesKey = "dose.healthEntries"
    private let biometricEntriesKey = "dose.biometricEntries"
    private let userNameKey = "dose.userName"
    private let userEmailKey = "dose.userEmail"
    private let myMedicationsKey = "dose.myMedications"
    private let labResultsKey = "dose.labResults"

    init() {
        if CommandLine.isUITestSnapshot {
            seedForSnapshot()
            isLoading = false
            return
        }
        loadAll()
        seedIfNeeded()
    }

    private func seedForSnapshot() {
        isLoading = true
        let vitaminD = Substance(name: "Vitamin D3", category: .vitamin, dosage: 2000, unit: "IU", frequency: "Daily")
        let magnesium = Substance(name: "Magnesium Glycinate", category: .supplement, dosage: 400, unit: "mg", frequency: "Nightly")
        let omega3 = Substance(name: "Omega-3", category: .supplement, dosage: 1, unit: "capsule", frequency: "Daily")
        substances = [vitaminD, magnesium, omega3]

        let now = Date()
        doseEntries = [
            DoseEntry(substanceId: vitaminD.id, timestamp: now.addingTimeInterval(-3600), notes: "With breakfast", dose: 2000, unit: "IU", route: "oral", rating: 4),
            DoseEntry(substanceId: magnesium.id, timestamp: now.addingTimeInterval(-7 * 3600), notes: "Before bed", dose: 400, unit: "mg", route: "oral", rating: 5),
            DoseEntry(substanceId: omega3.id, timestamp: now.addingTimeInterval(-27 * 3600), notes: "", dose: 1, unit: "capsule", route: "oral", rating: 4)
        ]

        myMedications = [
            MyMedication(builtInSubstanceId: nil, name: "Vitamin D3", dosage: 2000, unit: "IU", schedule: .daily, reminderHour: 8, reminderMinute: 0),
            MyMedication(builtInSubstanceId: nil, name: "Magnesium Glycinate", dosage: 400, unit: "mg", schedule: .daily, reminderHour: 21, reminderMinute: 0)
        ]

        biometricEntries = [
            BiometricEntry(id: UUID(), date: now, weight: 172, bpSystolic: 118, bpDiastolic: 76, heartRate: 62, sleepHours: 7.5, steps: 8420, notes: "", respiratoryRate: 14, bloodOxygen: 98, hrv: 55, activeEnergy: 420, distance: 5200)
        ]

        healthEntries = [
            HealthEntry(date: now, mood: 4, energy: 4, sleepHours: 7.5, notes: "Felt good after morning walk")
        ]

        labResults = [
            LabResult(date: now.addingTimeInterval(-30 * 24 * 3600), lab: "Quest Diagnostics", panel: "Basic Metabolic Panel", markers: [
                LabMarker(name: "Vitamin D, 25-OH", value: 42, unit: "ng/mL", refLow: 30, refHigh: 100, flag: .normal),
                LabMarker(name: "Glucose", value: 88, unit: "mg/dL", refLow: 70, refHigh: 99, flag: .normal),
                LabMarker(name: "LDL Cholesterol", value: 118, unit: "mg/dL", refLow: 0, refHigh: 100, flag: .high)
            ])
        ]
        isLoading = false
    }

    // MARK: - Substances

    func addSubstance(_ substance: Substance) {
        substances.append(substance)
    }

    func deleteSubstance(_ substance: Substance) {
        substances.removeAll { $0.id == substance.id }
        doseEntries.removeAll { $0.substanceId == substance.id }
    }

    func substance(for id: UUID) -> Substance? {
        substances.first { $0.id == id }
    }

    // MARK: - Dose Entries

    func addDoseEntry(_ entry: DoseEntry) {
        doseEntries.append(entry)
    }

    func deleteDoseEntry(_ entry: DoseEntry) {
        doseEntries.removeAll { $0.id == entry.id }
    }

    func getActive() -> [DoseEntry] {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        let now = Date()
        return doseEntries.filter { $0.timestamp >= cutoff && $0.timestamp <= now }
    }

    func substanceName(for entry: DoseEntry) -> String {
        resolveSubstanceName(for: entry.substanceKey)
    }

    func resolveSubstanceName(for key: String) -> String {
        if let builtIn = SubstanceDatabase.find(id: key) {
            return builtIn.name
        }
        if let uuid = UUID(uuidString: key), let custom = substance(for: uuid) {
            return custom.name
        }
        return "Unknown"
    }

    var streakCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let uniqueDays = Set(doseEntries.map { calendar.startOfDay(for: $0.timestamp) })
        var streak = 0
        var checkDate = today
        while uniqueDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    // MARK: - Health Entries

    func addHealthEntry(_ entry: HealthEntry) {
        healthEntries.append(entry)
    }

    func deleteHealthEntry(_ entry: HealthEntry) {
        healthEntries.removeAll { $0.id == entry.id }
    }

    // MARK: - Biometric Entries

    func addBiometricEntry(_ entry: BiometricEntry) {
        biometricEntries.append(entry)
    }

    func deleteBiometricEntry(_ entry: BiometricEntry) {
        biometricEntries.removeAll { $0.id == entry.id }
    }

    // MARK: - Export / Import

    private struct ExportBundle: Codable {
        let substances: [Substance]
        let doseEntries: [DoseEntry]
        let healthEntries: [HealthEntry]
        let biometricEntries: [BiometricEntry]
    }

    func exportData() -> Data? {
        let bundle = ExportBundle(
            substances: substances,
            doseEntries: doseEntries,
            healthEntries: healthEntries,
            biometricEntries: biometricEntries
        )
        return try? JSONEncoder().encode(bundle)
    }

    func importData(_ data: Data) -> Bool {
        guard let bundle = try? JSONDecoder().decode(ExportBundle.self, from: data) else {
            lastError = "Import failed: invalid data format"
            return false
        }
        isLoading = true
        substances = bundle.substances
        doseEntries = bundle.doseEntries
        healthEntries = bundle.healthEntries
        biometricEntries = bundle.biometricEntries
        isLoading = false
        // Single batch save
        saveSubstances()
        saveDoseEntries()
        saveHealthEntries()
        saveBiometricEntries()
        syncWidgetData()
        return true
    }

    // MARK: - Widget Sync

    private func syncWidgetData() {
        guard let shared = UserDefaults(suiteName: Self.appGroupId) else { return }

        let active = getActive()
        shared.set(active.count, forKey: "widget.doseCount")

        if let last = doseEntries.max(by: { $0.timestamp < $1.timestamp }) {
            shared.set(substanceName(for: last), forKey: "widget.lastDoseName")
        }

        struct WidgetPill: Codable {
            let name: String
            let count: Int
        }

        let grouped = Dictionary(grouping: active) { substanceName(for: $0) }
        let pills = grouped.map { WidgetPill(name: $0.key, count: $0.value.count) }
        if let data = try? JSONEncoder().encode(pills) {
            shared.set(data, forKey: "widget.activePills")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Persistence

    private func loadAll() {
        isLoading = true
        defer { isLoading = false }
        substances = load([Substance].self, forKey: substancesKey) ?? []
        doseEntries = load([DoseEntry].self, forKey: doseEntriesKey) ?? []
        healthEntries = load([HealthEntry].self, forKey: healthEntriesKey) ?? []
        biometricEntries = load([BiometricEntry].self, forKey: biometricEntriesKey) ?? []
        myMedications = load([MyMedication].self, forKey: myMedicationsKey) ?? []
        labResults = load([LabResult].self, forKey: labResultsKey) ?? []
    }

    private func seedIfNeeded() {
        guard substances.isEmpty else { return }
        substances = [
            Substance(name: "Vitamin D", category: .vitamin, dosage: 1000, unit: "IU", frequency: "Daily"),
            Substance(name: "Omega-3", category: .supplement, dosage: 1, unit: "capsule", frequency: "Daily")
        ]
    }

    private func saveSubstances() {
        save(substances, forKey: substancesKey)
    }

    private func saveDoseEntries() {
        save(doseEntries, forKey: doseEntriesKey)
    }

    private func saveHealthEntries() {
        save(healthEntries, forKey: healthEntriesKey)
    }

    private func saveBiometricEntries() {
        save(biometricEntries, forKey: biometricEntriesKey)
    }

    private func saveMedications() {
        save(myMedications, forKey: myMedicationsKey)
    }

    private func saveLabResults() {
        save(labResults, forKey: labResultsKey)
    }

    // MARK: - Lab Results

    func addLabResult(_ result: LabResult) {
        labResults.append(result)
    }

    func deleteLabResult(_ result: LabResult) {
        labResults.removeAll { $0.id == result.id }
    }

    func labResultsByMarker(_ markerName: String) -> [(date: Date, marker: LabMarker)] {
        var rows: [(date: Date, marker: LabMarker)] = []
        for result in labResults {
            if let m = result.markers.first(where: { $0.name == markerName }) {
                rows.append((date: result.date, marker: m))
            }
        }
        return rows.sorted { $0.date < $1.date }
    }

    var allMarkerNames: [String] {
        var names = Set<String>()
        for result in labResults {
            result.markers.forEach { names.insert($0.name) }
        }
        return names.sorted()
    }

    private func save<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

extension CommandLine {
    /// Screenshot runs launch with the snapshot flag. Accept `-UITEST_SNAPSHOT` too: macOS treats a bare
    /// argument as a document to open, and an app launched to open a document gets no window (issue #18).
    static var isUITestSnapshot: Bool {
        arguments.contains("UITEST_SNAPSHOT") || arguments.contains("-UITEST_SNAPSHOT")
    }
}
