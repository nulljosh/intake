import SwiftUI

struct BodyView: View {
    @Bindable var dataStore: DataStore
    var healthKitService: HealthKitService
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Biometrics").tag(0)
                    Text("Health").tag(1)
                    Text("Grade").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    BiometricsTab(dataStore: dataStore, healthKitService: healthKitService)
                } else if selectedTab == 1 {
                    HealthTab(dataStore: dataStore)
                } else {
                    HealthGradeView(dataStore: dataStore, healthKitService: healthKitService)
                }
            }
            .navigationTitle("Body")
            .alert("Save Error", isPresented: .init(
                get: { dataStore.lastError != nil },
                set: { if !$0 { dataStore.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(dataStore.lastError ?? "")
            }
        }
    }
}

private struct BiometricsTab: View {
    @Bindable var dataStore: DataStore
    var healthKitService: HealthKitService
    @State private var weight = ""
    @State private var bpSystolic = ""
    @State private var bpDiastolic = ""
    @State private var heartRate = ""
    @State private var sleepHours = 8.0
    @State private var steps = ""
    @State private var notes = ""

    private var recentEntries: [BiometricEntry] {
        Array(dataStore.biometricEntries.sorted { $0.date > $1.date }.prefix(10))
    }

    var body: some View {
        Form {
            #if !os(macOS)
            // HealthKit has no macOS counterpart, so this section could only ever
            // render fifteen empty cards there. Compile-time, not `isAvailable`:
            // the iOS rendering must stay byte-for-byte what App Review is looking at.
            Section {
                if HealthKitService.isAvailable && !healthKitService.isAuthorized {
                    Button("Connect Apple Health") {
                        Task {
                            await healthKitService.requestAuthorization()
                            await healthKitService.fetchAll()
                        }
                    }
                }
                healthDataGrid
            } header: {
                Label("Apple Health", systemImage: "heart.text.square.fill")
            } footer: {
                Text("Heart rate, sleep, steps, weight, and blood pressure below are read from Apple Health via HealthKit. Intake never writes to Apple Health.")
            }
            #endif

            Section("Notes") {
                TextField("Daily notes...", text: $notes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)

                if healthKitService.systolicBP == nil {
                    HStack {
                        Text("Blood Pressure")
                        Spacer()
                        TextField("sys", text: $bpSystolic)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("/")
                        TextField("dia", text: $bpDiastolic)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                    }
                }

                Button("Save Note") {
                    var validSys: Int?
                    var validDia: Int?
                    if !bpSystolic.isEmpty || !bpDiastolic.isEmpty {
                        guard let sys = Int(bpSystolic), sys > 0, sys < 300,
                              let dia = Int(bpDiastolic), dia > 0, dia < 300 else { return }
                        validSys = sys
                        validDia = dia
                    }
                    let entry = BiometricEntry(
                        bpSystolic: validSys,
                        bpDiastolic: validDia,
                        notes: String(notes.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
                    )
                    dataStore.addBiometricEntry(entry)
                    Haptics.impact(.medium)
                    notes = ""
                    bpSystolic = ""
                    bpDiastolic = ""
                }
            }

            if !recentEntries.isEmpty {
                Section("Recent") {
                    ForEach(recentEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, style: .date)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 12) {
                                if let w = entry.weight {
                                    Label("\(w, specifier: "%.1f") lbs", systemImage: "scalemass")
                                }
                                if let hr = entry.heartRate {
                                    Label("\(hr) bpm", systemImage: "heart")
                                }
                                if let s = entry.steps {
                                    Label("\(s)", systemImage: "figure.walk")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            if let sys = entry.bpSystolic, let dia = entry.bpDiastolic {
                                Text("BP: \(sys)/\(dia)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !entry.notes.isEmpty {
                                Text(entry.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { recentEntries[$0] }
                        for entry in toDelete {
                            dataStore.deleteBiometricEntry(entry)
                        }
                        Haptics.warning()
                    }
                }
            }
        }
        .task {
            await healthKitService.fetchAll()
        }
    }

    @ViewBuilder
    private var healthDataGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            healthCard("Heart Rate", value: healthKitService.heartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill", color: .red)
            healthCard("Resting HR", value: healthKitService.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart", color: .red)
            healthCard("HRV", value: healthKitService.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg", color: .purple)
            healthCard("SpO2", value: healthKitService.bloodOxygen.map { "\(Int($0))%" }, icon: "lungs.fill", color: .blue)
            healthCard("Respiratory", value: healthKitService.respiratoryRate.map { "\(Int($0))/min" }, icon: "wind", color: .teal)
            healthCard("Sleep", value: healthKitService.sleepHours.map { String(format: "%.1fh", $0) }, icon: "bed.double.fill", color: .indigo)
            healthCard("Steps", value: healthKitService.steps.map { "\($0)" }, icon: "figure.walk", color: .green)
            healthCard("Energy", value: healthKitService.activeEnergy.map { "\(Int($0)) kcal" }, icon: "flame.fill", color: .orange)
            healthCard("Distance", value: healthKitService.walkingDistance.map { String(format: "%.1f mi", $0) }, icon: "map.fill", color: .cyan)
            healthCard("Weight", value: healthKitService.bodyMass.map { String(format: "%.1f lbs", $0) }, icon: "scalemass.fill", color: .brown)
            healthCard("Water", value: healthKitService.dietaryWater.map { "\(Int($0)) mL" }, icon: "drop.fill", color: .blue)
            healthCard("Caffeine", value: healthKitService.dietaryCaffeine.map { "\(Int($0)) mg" }, icon: "cup.and.saucer.fill", color: .brown)
            healthCard("Body Temp", value: healthKitService.bodyTemperature.map { String(format: "%.1f F", $0) }, icon: "thermometer.medium", color: .orange)
            healthCard("Audio", value: healthKitService.environmentalAudioExposure.map { "\(Int($0)) dB" }, icon: "ear.fill", color: .purple)
            healthCard("Brushing", value: healthKitService.toothbrushingToday.map { $0 ? "Done" : "Not yet" }, icon: "mouth.fill", color: .mint)
        }
        if let sys = healthKitService.systolicBP, let dia = healthKitService.diastolicBP {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundStyle(.pink)
                Text("Blood Pressure")
                Spacer()
                Text("\(sys)/\(dia) mmHg")
                    .fontWeight(.semibold)
            }
        }
        Button("Refresh") {
            Task { await healthKitService.fetchAll() }
        }
    }

    private func healthCard(_ title: String, value: String?, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value ?? "--")
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func clearForm() {
        weight = ""
        bpSystolic = ""
        bpDiastolic = ""
        heartRate = ""
        sleepHours = 8.0
        steps = ""
        notes = ""
    }
}

private struct HealthTab: View {
    @Bindable var dataStore: DataStore
    @State private var mood = 3.0
    @State private var energy = 3.0
    @State private var sleepHours = 8.0
    @State private var notes = ""

    private var recentEntries: [HealthEntry] {
        Array(dataStore.healthEntries.sorted { $0.date > $1.date }.prefix(10))
    }

    var body: some View {
        Form {
            Section("Daily Check-In") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Mood: \(Int(mood))")
                        Spacer()
                        Text(sliderLabel(Int(mood)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $mood, in: 1...5, step: 1)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Energy: \(Int(energy))")
                        Spacer()
                        Text(sliderLabel(Int(energy)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $energy, in: 1...5, step: 1)
                }

                VStack(alignment: .leading) {
                    Text("Sleep: \(sleepHours, specifier: "%.1f") hrs")
                    Slider(value: $sleepHours, in: 0...12, step: 0.5)
                }

                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section {
                Button("Save Health Entry") {
                    dataStore.addHealthEntry(
                        HealthEntry(
                            mood: Int(mood),
                            energy: Int(energy),
                            sleepHours: sleepHours,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                    Haptics.impact(.medium)
                    mood = 3.0
                    energy = 3.0
                    sleepHours = 8.0
                    notes = ""
                }
            }

            if !recentEntries.isEmpty {
                Section("Recent") {
                    ForEach(recentEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, style: .date)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 12) {
                                Text("Mood: \(entry.mood)/5")
                                Text("Energy: \(entry.energy)/5")
                                Text("Sleep: \(entry.sleepHours, specifier: "%.1f")h")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { recentEntries[$0] }
                        for entry in toDelete {
                            dataStore.deleteHealthEntry(entry)
                        }
                        Haptics.warning()
                    }
                }
            }
        }
    }

    private func sliderLabel(_ value: Int) -> String {
        switch value {
        case 1: return "Low"
        case 2: return "Okay"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excellent"
        default: return ""
        }
    }
}
