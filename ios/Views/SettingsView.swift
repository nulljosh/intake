import SwiftUI

struct SettingsView: View {
    @Bindable var dataStore: DataStore
    @Bindable var syncService: SyncService
    var authService: AuthService
    @State private var nameField = ""
    @State private var showAddMedication = false
    @State private var exportFileURL: URL?
    @AppStorage("app_theme") private var rawTheme = "system"
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var deletingAccount = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    AppearancePicker(rawTheme: $rawTheme)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                Section("Account") {
                    Text(authService.user?.email ?? "")
                        .foregroundStyle(.secondary)
                    Button("Sign out", role: .destructive) {
                        Task { try? await authService.signOut() }
                    }
                    Button("Delete Account", role: .destructive) {
                        confirmingDelete = true
                    }
                    .disabled(deletingAccount)
                }

                Section("Profile") {
                    TextField("Your name", text: $nameField)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                }

                Section {
                    ForEach(dataStore.myMedications) { med in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(med.name)
                                    .font(.body.weight(.semibold))
                                HStack(spacing: 8) {
                                    if let dosage = med.dosage {
                                        Text("\(dosage.formatted()) \(med.unit)")
                                    }
                                    Text(med.schedule.label)
                                    Text(String(format: "%d:%02d", med.reminderHour, med.reminderMinute))
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { offsets in
                        var meds = dataStore.myMedications
                        meds.remove(atOffsets: offsets)
                        dataStore.myMedications = meds
                    }

                    Button("Add Medication") {
                        showAddMedication = true
                    }
                } header: {
                    Text("My Medications")
                } footer: {
                    Text("Pinned substances with daily reminders. These auto-populate Quick Log.")
                }

                Section {
                    Toggle("Sync with your Machaon account", isOn: $syncService.syncEnabled)

                    if syncService.syncEnabled {
                        HStack {
                            Button {
                                Task { await syncService.push(dataStore: dataStore) }
                            } label: {
                                Label("Push", systemImage: "arrow.up.circle")
                            }
                            .disabled(syncService.isSyncing)

                            Spacer()

                            Button {
                                Task { await syncService.pull(dataStore: dataStore) }
                            } label: {
                                Label("Pull", systemImage: "arrow.down.circle")
                            }
                            .disabled(syncService.isSyncing)
                        }

                        if syncService.isSyncing {
                            HStack {
                                ProgressView()
                                Text("Syncing...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let date = syncService.lastSync {
                            Text("Last sync: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let error = syncService.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Sync")
                }

                Section("Data") {
                    if !dataStore.doseEntries.isEmpty || !dataStore.healthEntries.isEmpty {
                        Button {
                            if let data = dataStore.exportData() {
                                let url = exportURL(data: data)
                                exportFileURL = url
                            }
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dataStore.userName = nameField.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                }
            }
            .onAppear {
                nameField = dataStore.userName
            }
            .sheet(isPresented: $showAddMedication) {
                AddMedicationSheet { med in
                    var meds = dataStore.myMedications
                    meds.append(med)
                    dataStore.myMedications = meds
                }
            }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    deletingAccount = true
                    Task {
                        do {
                            try await authService.deleteAccount()
                        } catch {
                            deleteError = error.localizedDescription
                        }
                        deletingAccount = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account and all data. This cannot be undone.")
            }
            .alert("Couldn't Delete Account", isPresented: .constant(deleteError != nil), actions: {
                Button("OK") { deleteError = nil }
            }, message: {
                Text(deleteError ?? "")
            })
        }
    }

    private func exportURL(data: Data) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dose-backup.json")
        try? data.write(to: url)
        return url
    }
}

private struct AddMedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedSubstance: BuiltInSubstance?
    @State private var customName = ""
    @State private var dosage = ""
    @State private var unit = "mg"
    @State private var schedule: MyMedication.Schedule = .daily
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

    let onSave: (MyMedication) -> Void

    private var filteredSubstances: [BuiltInSubstance] {
        guard !searchText.isEmpty else { return [] }
        return SubstanceDatabase.search(searchText).prefix(10).map { $0 }
    }

    private var resolvedName: String {
        selectedSubstance?.name ?? customName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Substance") {
                    if let substance = selectedSubstance {
                        HStack {
                            Text(substance.name).fontWeight(.semibold)
                            Spacer()
                            Button("Change") {
                                selectedSubstance = nil
                                searchText = ""
                            }
                            .font(.subheadline)
                        }
                    } else {
                        TextField("Search or type name...", text: $searchText)
                        ForEach(filteredSubstances) { substance in
                            Button(substance.name) {
                                selectedSubstance = substance
                                unit = substance.unit
                            }
                        }
                    }
                }

                Section("Dosage") {
                    HStack {
                        TextField("Amount", text: $dosage)
                            .keyboardType(.decimalPad)
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                    Picker("Schedule", selection: $schedule) {
                        ForEach(MyMedication.Schedule.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                        let med = MyMedication(
                            builtInSubstanceId: selectedSubstance?.id,
                            name: resolvedName.isEmpty ? searchText : resolvedName,
                            dosage: Double(dosage),
                            unit: unit,
                            schedule: schedule,
                            reminderHour: components.hour ?? 17,
                            reminderMinute: components.minute ?? 0
                        )
                        onSave(med)
                        dismiss()
                    }
                    .disabled(resolvedName.isEmpty && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct AppearancePicker: View {
    @Binding var rawTheme: String
    private let options = [("light", "Light"), ("dark", "Dark"), ("system", "System")]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(options, id: \.0) { id, label in
                Button { rawTheme = id } label: {
                    VStack(spacing: 8) {
                        themePreview(id)
                            .frame(height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(rawTheme == id ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: 2)
                            )
                        Text(label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(rawTheme == id ? Color.accentColor : Color.secondary)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func themePreview(_ id: String) -> some View {
        switch id {
        case "light":
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(white: 0.92))
        case "dark":
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(white: 0.12))
        default:
            GeometryReader { geo in
                ZStack {
                    Color(white: 0.92)
                    Path { p in
                        p.move(to: CGPoint(x: geo.size.width, y: 0))
                        p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                        p.closeSubpath()
                    }.fill(Color(white: 0.12))
                }
            }
        }
    }
}
