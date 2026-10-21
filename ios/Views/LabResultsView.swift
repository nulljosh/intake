import SwiftUI
import Charts

struct LabResultsView: View {
    @Bindable var dataStore: DataStore
    @State private var tab = "timeline"
    @State private var showAdd = false
    @State private var selectedMarker = ""
    @State private var expandedId: UUID?

    private var sorted: [LabResult] {
        dataStore.labResults.sorted { $0.date > $1.date }
    }

    private var markerNames: [String] { dataStore.allMarkerNames }

    private var markerHistory: [(date: Date, marker: LabMarker)] {
        dataStore.labResultsByMarker(selectedMarker)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Tab", selection: $tab) {
                    Text("Timeline").tag("timeline")
                    Text("Markers").tag("markers")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                if tab == "timeline" {
                    timelineTab
                } else {
                    markersTab
                }
            }
            .navigationTitle("Lab Results")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddLabResultSheet(dataStore: dataStore)
            }
        }
    }

    // MARK: Timeline

    @ViewBuilder
    var timelineTab: some View {
        if sorted.isEmpty {
            EmptyState(title: "No lab results", message: "Add results manually or import from a LifeLabs PDF on the web.")
        } else {
            List {
                ForEach(sorted) { result in
                    LabResultRow(result: result, isExpanded: expandedId == result.id) {
                        withAnimation(.spring(response: 0.3)) {
                            expandedId = expandedId == result.id ? nil : result.id
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            dataStore.deleteLabResult(result)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: Markers

    @ViewBuilder
    var markersTab: some View {
        if markerNames.isEmpty {
            EmptyState(title: "No markers yet", message: "Add lab results to track individual markers.")
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Picker("Marker", selection: $selectedMarker) {
                    ForEach(markerNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if markerHistory.count < 2 {
                    Text("Need at least 2 readings to show a trend.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .padding()
                } else {
                    LabMarkerChartView(history: markerHistory, markerName: selectedMarker)
                        .padding(.horizontal)

                    List(markerHistory.reversed(), id: \.date) { row in
                        HStack {
                            Text(row.date, style: .date)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Spacer()
                            Text("\(row.marker.value, specifier: "%.1f") \(row.marker.unit)")
                                .fontWeight(.semibold)
                            FlagLabel(flag: row.marker.flag)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .onAppear {
                if selectedMarker.isEmpty, let first = markerNames.first {
                    selectedMarker = first
                }
            }
        }
    }
}

// MARK: - Row

struct LabResultRow: View {
    let result: LabResult
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text("\(result.lab) — \(result.panel)")
                            .fontWeight(.semibold)
                        Text("\(result.markers.count) marker\(result.markers.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if result.flaggedCount > 0 {
                        Text("\(result.flaggedCount) flagged")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.vertical, 8)
                ForEach(result.markers) { m in
                    LabMarkerRowView(marker: m)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct LabMarkerRowView: View {
    let marker: LabMarker

    var flagColor: Color {
        switch marker.flag {
        case .normal: return .green
        case .low, .high: return .orange
        case .critical: return .red
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(flagColor.opacity(0.8))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(marker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let lo = marker.refLow, let hi = marker.refHigh {
                    Text("ref: \(lo, specifier: "%.1f") – \(hi, specifier: "%.1f") \(marker.unit)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text("\(marker.value, specifier: "%.1f")")
                .fontWeight(.semibold)
                .foregroundStyle(flagColor)
            Text(marker.unit)
                .font(.caption)
                .foregroundStyle(.secondary)

            FlagLabel(flag: marker.flag)
        }
        .padding(.vertical, 4)
    }
}

struct FlagLabel: View {
    let flag: MarkerFlag
    var body: some View {
        if flag != .normal {
            Text(flag.label)
                .font(.caption2)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(flagBg)
                .foregroundStyle(flagFg)
                .clipShape(Capsule())
        }
    }

    var flagBg: Color {
        switch flag {
        case .normal: return .clear
        case .low, .high: return .orange.opacity(0.12)
        case .critical: return .red.opacity(0.12)
        }
    }

    var flagFg: Color {
        switch flag {
        case .normal: return .clear
        case .low, .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Add Sheet

struct AddLabResultSheet: View {
    @Bindable var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var lab = "LifeLabs"
    @State private var selectedPanel = "Thyroid"
    @State private var markers: [MarkerEntry] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Lab", text: $lab)
                }

                Section("Panel") {
                    Picker("Panel", selection: $selectedPanel) {
                        ForEach(LabPanel.all.map(\.name), id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .onChange(of: selectedPanel) { _, name in
                        loadPanel(name)
                    }
                }

                Section("Markers") {
                    ForEach($markers) { $marker in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(marker.name).fontWeight(.medium)
                            HStack {
                                TextField("Value", text: $marker.value)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .accessibilityLabel("\(marker.name) value in \(marker.unit)")
                                Text(marker.unit)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Lab Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); dismiss() }
                        .disabled(markers.filter { !$0.value.isEmpty }.isEmpty)
                }
            }
            .onAppear { loadPanel(selectedPanel) }
        }
    }

    func loadPanel(_ name: String) {
        guard let panel = LabPanel.all.first(where: { $0.name == name }) else { return }
        markers = panel.entries
    }

    func save() {
        let filled = markers.filter { !$0.value.isEmpty }
        let labMarkers: [LabMarker] = filled.compactMap { m in
            guard let v = Double(m.value) else { return nil }
            let lo = Double(m.refLow)
            let hi = Double(m.refHigh)
            return LabMarker(
                name: m.name, value: v, unit: m.unit,
                refLow: lo, refHigh: hi,
                flag: LabMarker.computeFlag(value: v, refLow: lo, refHigh: hi)
            )
        }
        let result = LabResult(
            date: date, lab: lab, panel: selectedPanel, markers: labMarkers
        )
        dataStore.addLabResult(result)
    }
}
