import SwiftUI

struct DashboardView: View {
    @Bindable var dataStore: DataStore
    @Bindable var notificationService: NotificationService
    var syncService: SyncService
    var authService: AuthService
    @State private var showAddDose = false
    @State private var showReminders = false
    @State private var showSettings = false

    private var topInsight: Insight? {
        InsightEngine.topInsights(
            doseEntries: dataStore.doseEntries,
            biometrics: dataStore.biometricEntries,
            labResults: dataStore.labResults,
            getName: { dataStore.substanceName(for: $0) }
        ).first
    }

    private var healthScore: Int? {
        guard let e = dataStore.biometricEntries.sorted(by: { $0.date > $1.date }).first else { return nil }
        var scores: [Double] = []
        if let v = e.sleepHours   { scores.append(min(100, (v / 8) * 100)) }
        if let v = e.steps        { scores.append(min(100, (Double(v) / 10000) * 100)) }
        if let v = e.heartRate    { scores.append(min(100, (60.0 / Double(v)) * 100)) }
        if let v = e.hrv          { scores.append(min(100, (v / 50) * 100)) }
        if let v = e.bloodOxygen  { scores.append(min(100, (v / 98) * 100)) }
        guard !scores.isEmpty else { return nil }
        return Int(scores.reduce(0, +) / Double(scores.count))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        if (5...11).contains(hour) {
            timeGreeting = "Good morning"
        } else if (12...16).contains(hour) {
            timeGreeting = "Good afternoon"
        } else {
            timeGreeting = "Good evening"
        }
        let name = dataStore.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? timeGreeting : "\(timeGreeting), \(name)"
    }

    private var activePills: [ActivePill] {
        let grouped = Dictionary(grouping: dataStore.getActive()) { dataStore.substanceName(for: $0) }

        return grouped.compactMap { name, entries in
            let first = entries.first
            let builtIn = first.flatMap { SubstanceDatabase.find(id: $0.substanceKey) }
            let color = builtIn?.category.categoryColor ?? Color.secondary
            let latest = entries.map(\.timestamp).max() ?? .distantPast
            return ActivePill(name: name, color: color, count: entries.count, latestTimestamp: latest)
        }
        .sorted { $0.latestTimestamp > $1.latestTimestamp }
    }

    private var recentEntries: [DoseEntry] {
        Array(dataStore.doseEntries.sorted { $0.timestamp > $1.timestamp }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if dataStore.streakCount > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                            Text("\(dataStore.streakCount) day streak")
                                .glowText()
                        }
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .glassCard()
                    }

                    // Health score ring
                    if let score = healthScore {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemFill), lineWidth: 5)
                                Circle()
                                    .trim(from: 0, to: CGFloat(score) / 100)
                                    .stroke(
                                        score >= 80 ? Color.green : score >= 50 ? Color.orange : Color.red,
                                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                Text("\(score)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .frame(width: 48, height: 48)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Health Score")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .kerning(0.8)
                                Text(score >= 80 ? "Looking good" : score >= 50 ? "Room to improve" : "Needs attention")
                                    .font(.subheadline.weight(.medium))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .glassCard()
                    }

                    // Top insight card
                    if let insight = topInsight {
                        HStack(spacing: 10) {
                            Image(systemName: insightIcon(insight.type))
                                .foregroundStyle(insightColor(insight.severity))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(insight.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(insight.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(insightColor(insight.severity).opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(insightColor(insight.severity).opacity(0.2), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Active stack")
                                .font(.headline)

                            Spacer()

                            Button("Quick log") {
                                showAddDose = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue.opacity(0.85))
                        }

                        if activePills.isEmpty {
                            EmptyState(title: "No Active Substances", message: "Nothing taken in the last 24 hours", size: 40)
                                .frame(maxHeight: 160)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(activePills) { pill in
                                        Text(pill.count > 1 ? "\(pill.name) x\(pill.count)" : pill.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(pill.color)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(16)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent entries")
                            .font(.headline)

                        if recentEntries.isEmpty {
                            EmptyState(title: "No Doses Yet", message: "Tap Quick log to log your first dose", size: 40)
                                .frame(maxHeight: 160)
                        } else {
                            ForEach(recentEntries) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dataStore.substanceName(for: entry))
                                        .font(.body.weight(.semibold))

                                    if let dose = entry.dose {
                                        let unit = (entry.unit ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                                        Text(unit.isEmpty ? "\(dose.formatted())" : "\(dose.formatted()) \(unit)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(entry.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .glassCard()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showReminders = true
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
            .sheet(isPresented: $showAddDose) {
                AddDoseSheet(dataStore: dataStore)
                    .macSheetSize()
            }
            .sheet(isPresented: $showReminders) {
                RemindersView(notificationService: notificationService)
                    .macSheetSize()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(dataStore: dataStore, syncService: syncService, authService: authService)
                    .macSheetSize()
            }
        }
    }

    func insightIcon(_ type: InsightType) -> String {
        switch type {
        case .labFlag: return "flag.fill"
        case .anomaly: return "exclamationmark.triangle.fill"
        case .labTrend: return "chart.line.uptrend.xyaxis"
        case .correlation: return "waveform.path.ecg"
        }
    }

    func insightColor(_ severity: InsightSeverity) -> Color {
        switch severity {
        case .urgent: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

private struct ActivePill: Identifiable {
    var id: String { name }
    let name: String
    let color: Color
    let count: Int
    let latestTimestamp: Date
}
