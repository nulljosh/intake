import SwiftUI

struct QuickLogView: View {
    var store: SharedDataStore
    @State private var loggedName: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    if store.substances.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.substances) { substance in
                            Button {
                                store.logDose(
                                    substanceName: substance.name,
                                    substanceId: substance.id,
                                    dose: substance.dosage,
                                    unit: substance.unit
                                )
                                loggedName = substance.name
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(substance.name)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text(formatDose(substance))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Quick Log")
            .overlay {
                if let name = loggedName {
                    confirmationOverlay(name: name)
                }
            }
        }
        .onAppear { store.reload() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No substances")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Add substances in the Machaon app")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func confirmationOverlay(name: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
            Text("Logged \(name)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { loggedName = nil }
            }
        }
    }

    private func formatDose(_ substance: WatchSubstance) -> String {
        let value = substance.dosage
        if value == value.rounded() {
            return "\(Int(value)) \(substance.unit)"
        }
        return "\(String(format: "%.1f", value)) \(substance.unit)"
    }
}
