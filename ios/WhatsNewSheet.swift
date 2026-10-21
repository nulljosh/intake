import SwiftUI

private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

// ponytail: the sheet only appears when these notes match the shipping version. Bumping the
// marketing version without updating them shows nothing, never the previous release's copy.
private let whatsNewVersion = "2.3.4"
private let whatsNewBullets = [
    "Every substance in the library now cites its sources",
    "Fixed sign-in failures",
]

struct WhatsNewSheet: View {
    @AppStorage("whats_new_seen_version") private var seenVersion = ""
    @State private var isPresented = false
    @State private var contentHeight: CGFloat = 220

    // ponytail: gated on the snapshot launch arg, not on a hardcoded seen-version value —
    // a pinned version silently stops suppressing the sheet the next time whatsNewVersion is
    // bumped, which is exactly how it leaked into the App Store screenshot set.
    private var isUITestSnapshot: Bool {
        CommandLine.isUITestSnapshot
    }

    var body: some View {
        Color.clear
            .onAppear { isPresented = !isUITestSnapshot && whatsNewVersion == appVersion && seenVersion != whatsNewVersion }
            .sheet(isPresented: $isPresented) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What's New in v\(whatsNewVersion)")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(whatsNewBullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(bullet)
                            }
                        }
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    Button {
                        seenVersion = whatsNewVersion
                        isPresented = false
                    } label: {
                        Text("Got it")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: SheetHeightKey.self, value: geo.size.height)
                })
                .onPreferenceChange(SheetHeightKey.self) { contentHeight = $0 }
                .presentationDetents([.height(contentHeight + 34)]) // ponytail: +34 covers home-indicator safe area GeometryReader doesn't include
            }
    }
}

private struct SheetHeightKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 220
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
