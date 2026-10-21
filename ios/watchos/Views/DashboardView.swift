import SwiftUI

struct DashboardView: View {
    var store: SharedDataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    doseCountCard
                    lastDoseCard
                    activeStackCard
                    NavigationLink {
                        FacemaxxingView()
                    } label: {
                        HStack {
                            Image(systemName: "face.smiling")
                            Text("Facemaxxing").font(.caption)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Machaon")
        }
        .onAppear { store.reload() }
    }

    private var doseCountCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(store.doseCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)
            }
            Spacer()
            // Health score arc
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(CGFloat(store.doseCount) / 10.0, 1.0))
                    .stroke(.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "pill.fill")
                    .font(.caption2)
                    .foregroundStyle(.cyan.opacity(0.7))
            }
            .frame(width: 36, height: 36)
        }
        .padding()
        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var lastDoseCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last Dose")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(store.lastDoseName)
                .font(.headline)

            if let latest = store.recentEntries.first {
                Text(latest.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    + Text(" ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var activeStackCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Active Stack")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if store.activePills.isEmpty {
                Text("No active doses")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(store.activePills) { pill in
                    HStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text(pill.name)
                            .font(.caption)
                        Spacer()
                        Text("\(pill.count)x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}
