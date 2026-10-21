import SwiftUI

struct SessionHistoryView: View {
    @Environment(BodyworkSessionStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    EmptyState(title: "No Sessions", message: "Log your first session from the Reflexology or Points tab.")
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(session.type.uppercased())
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .tracking(1)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(session.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(session.name)
                                    .fontWeight(.medium)
                                Text(session.area)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { offsets in
                            store.delete(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}
