import Foundation
import Observation

nonisolated(unsafe) private let syncISOFormatter = ISO8601DateFormatter()

@MainActor
@Observable
final class SyncService {
    var isSyncing = false
    var lastSync: Date?
    var lastError: String?

    private let lastSyncKey = "dose.lastSyncDate"

    /// On unless the user turned it off, so a phone and the web app on the same account show the same log.
    var syncEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "dose.syncEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "dose.syncEnabled") }
    }

    var isConfigured: Bool { syncEnabled }

    private var baseURL: URL {
        URL(string: "https://machaon.jaybulb.com/api/sync")!
    }

    init() {
        if let date = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSync = date
        }
    }

    // MARK: - Push

    func push(dataStore: DataStore) async {
        guard isConfigured else { return }
        guard let session = try? await supabaseClient.auth.session else {
            lastError = "Not signed in"
            return
        }
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        let payload = SyncPayload(
            log: dataStore.doseEntries.map { DoseLogEntry(from: $0) },
            substances: dataStore.substances.map { CustomSubstance(from: $0) },
            biometrics: dataStore.biometricEntries.map { BiometricLogEntry(from: $0) },
            profile: SyncProfile(
                name: dataStore.userName,
                email: dataStore.userEmail
            ),
            medications: dataStore.myMedications.map { MedicationEntry(from: $0) }
        )

        do {
            var request = URLRequest(url: baseURL)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SyncError.invalidResponse }

            guard http.statusCode != 401 else {
                lastError = "Session expired — sign in again"
                return
            }
            guard (200...299).contains(http.statusCode) else {
                throw SyncError.serverError(http.statusCode)
            }

            if let result = try? JSONDecoder().decode(SyncResult.self, from: data) {
                lastSync = syncISOFormatter.date(from: result.updatedAt) ?? Date()
            } else {
                lastSync = Date()
            }
            UserDefaults.standard.set(lastSync, forKey: lastSyncKey)
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Pull

    func pull(dataStore: DataStore) async {
        guard isConfigured else { return }
        guard let session = try? await supabaseClient.auth.session else {
            lastError = "Not signed in"
            return
        }
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        do {
            var request = URLRequest(url: baseURL)
            request.httpMethod = "GET"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SyncError.invalidResponse }

            guard http.statusCode != 401 else {
                lastError = "Session expired — sign in again"
                return
            }
            guard (200...299).contains(http.statusCode) else {
                throw SyncError.serverError(http.statusCode)
            }

            let payload = try JSONDecoder().decode(SyncPayload.self, from: data)
            apply(payload, to: dataStore)
            lastSync = Date()
            UserDefaults.standard.set(lastSync, forKey: lastSyncKey)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func apply(_ payload: SyncPayload, to dataStore: DataStore) {
        var existingIds = Set(dataStore.doseEntries.map { "\($0.substanceKey)-\(syncISOFormatter.string(from: $0.timestamp))" })
        for entry in payload.log {
            let key = "\(entry.substanceId)-\(entry.timestamp)"
            if !existingIds.contains(key) {
                existingIds.insert(key)
                dataStore.addDoseEntry(entry.toDoseEntry())
            }
        }

        if !payload.profile.name.isEmpty {
            dataStore.userName = payload.profile.name
        }
        if !payload.profile.email.isEmpty {
            dataStore.userEmail = payload.profile.email
        }

        if !payload.medications.isEmpty {
            dataStore.myMedications = payload.medications.map { $0.toMyMedication() }
        }
    }
}

// MARK: - Sync Models

private enum SyncError: LocalizedError {
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error: \(code)"
        }
    }
}

private struct SyncResult: Codable {
    let ok: Bool
    let updatedAt: String
}

struct SyncPayload: Codable {
    var log: [DoseLogEntry]
    var substances: [CustomSubstance]
    var biometrics: [BiometricLogEntry]
    var profile: SyncProfile
    var medications: [MedicationEntry]
}

struct SyncProfile: Codable {
    var name: String
    var email: String
}

struct DoseLogEntry: Codable {
    var id: String
    var substanceId: String
    var dose: Double?
    var unit: String?
    var route: String?
    var timestamp: String
    var notes: String
    var rating: Int?

    init(from entry: DoseEntry) {
        self.id = entry.id.uuidString
        self.substanceId = entry.substanceKey
        self.dose = entry.dose
        self.unit = entry.unit
        self.route = entry.route
        self.timestamp = syncISOFormatter.string(from: entry.timestamp)
        self.notes = entry.notes
        self.rating = entry.rating
    }

    func toDoseEntry() -> DoseEntry {
        DoseEntry(
            builtInSubstanceId: substanceId,
            timestamp: syncISOFormatter.date(from: timestamp) ?? Date(),
            notes: notes,
            dose: dose,
            unit: unit,
            route: route,
            rating: rating
        )
    }
}

struct CustomSubstance: Codable {
    var id: String
    var name: String
    var category: String
    var dosage: Double
    var unit: String

    init(from substance: Substance) {
        self.id = substance.id.uuidString
        self.name = substance.name
        self.category = substance.category.rawValue
        self.dosage = substance.dosage
        self.unit = substance.unit
    }
}

struct BiometricLogEntry: Codable {
    var id: String
    var date: String
    var metrics: [String: Double]
    var notes: String

    init(from entry: BiometricEntry) {
        self.id = entry.id.uuidString
        self.date = syncISOFormatter.string(from: entry.date)
        var m: [String: Double] = [:]
        if let w = entry.weight { m["weight"] = w }
        if let hr = entry.heartRate { m["heartRate"] = Double(hr) }
        if let s = entry.steps { m["steps"] = Double(s) }
        if let sl = entry.sleepHours { m["sleep"] = sl }
        self.metrics = m
        self.notes = entry.notes
    }
}

struct MedicationEntry: Codable {
    var id: String
    var builtInSubstanceId: String?
    var name: String
    var dosage: Double?
    var unit: String
    var schedule: String
    var reminderHour: Int
    var reminderMinute: Int

    init(from med: MyMedication) {
        self.id = med.id.uuidString
        self.builtInSubstanceId = med.builtInSubstanceId
        self.name = med.name
        self.dosage = med.dosage
        self.unit = med.unit
        self.schedule = med.schedule.rawValue
        self.reminderHour = med.reminderHour
        self.reminderMinute = med.reminderMinute
    }

    func toMyMedication() -> MyMedication {
        MyMedication(
            builtInSubstanceId: builtInSubstanceId,
            name: name,
            dosage: dosage,
            unit: unit,
            schedule: MyMedication.Schedule(rawValue: schedule) ?? .daily,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
    }
}
