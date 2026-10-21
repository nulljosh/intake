import SwiftUI
#if os(iOS)
import UIKit
#endif
import LocalAuthentication

/// The five destinations, in order. `selectedTab` indexes into this.
/// Shared by the iOS TabView, and the macOS sidebar.
private let doseTabs: [(icon: String, fill: String, label: String)] = [
    ("house", "house.fill", "Home"),
    ("books.vertical", "books.vertical.fill", "Library"),
    ("chart.line.uptrend.xyaxis.circle", "chart.line.uptrend.xyaxis.circle.fill", "Insights"),
    ("figure.mind.and.body", "figure.mind.and.body", "Body"),
    ("cross.vial", "cross.vial.fill", "Labs"),
]

@main
struct HealstackApp: App {
    @State private var authService = AuthService()
    @State private var dataStore = DataStore()
    @State private var healthKitService = HealthKitService()
    @State private var notificationService = NotificationService()
    @State private var syncService = SyncService()
    @Environment(\.scenePhase) private var scenePhase
    @State private var bodyworkStore = BodyworkSessionStore()
    @State private var showSplash = true
    @State private var biometryType: LABiometryType = .none
    @AppStorage("app_theme") private var rawTheme = "system"
    // ponytail: persists across launches so Face ID gates login, not every cold start
    // (per notes 2026-09-12: "required every app open" was the complaint). Cleared on sign-out.
    @AppStorage("dose_biometric_verified") private var isUnlocked = false
    @State private var isUnlocking = false
    @State private var unlockError: String?
    @State private var selectedTab = Self.initialTab

    private var isUITestSnapshot: Bool {
        CommandLine.isUITestSnapshot
    }

    // ponytail: screenshot capture selects the tab by launch argument instead of tapping the
    // floating bar. The bar is drawn over scrollable content, so a tap can land on whatever
    // card happens to sit under it — that is how the Library grid's Zinc card ended up in the
    // Insights and Body screenshots. No coordinates, no hit-test race.
    private static var initialTab: Int {
        let args = CommandLine.arguments
        guard let flag = args.firstIndex(of: "-UITEST_TAB"), flag + 1 < args.count,
              let tab = Int(args[flag + 1]), doseTabs.indices.contains(tab) else { return 0 }
        return tab
    }

    private var requiresUnlock: Bool {
        !isUITestSnapshot && biometryType != .none
    }

    init() {
        #if os(iOS)
        // Large titles in a light weight, the app's echo of the landing's thin headlines.
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .light)]
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
            if authService.isLoading {
                SplashView()
            } else if authService.user == nil && !isUITestSnapshot {
                AuthView(authService: authService)
            } else if authService.isPasswordRecovery {
                NewPasswordView(authService: authService)
            } else {
            ZStack {
                // Group so the shared modifiers below chain onto whichever shell is compiled.
                Group {
                #if os(macOS)
                NavigationSplitView {
                    List(doseTabs.indices, id: \.self, selection: sidebarSelection) { index in
                        Label(doseTabs[index].label, systemImage: doseTabs[index].fill)
                            .tag(index)
                    }
                    .listStyle(.sidebar)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
                } detail: {
                    destination(for: selectedTab)
                }
                #else
                TabView(selection: $selectedTab) {
                    ForEach(doseTabs.indices, id: \.self) { index in
                        destination(for: index)
                            .tabItem { Label(doseTabs[index].label, systemImage: doseTabs[index].fill) }
                            .tag(index)
                    }
                }
                #endif
                }
                .onChange(of: selectedTab) { _, _ in
                    Haptics.impact(.light)
                }
                .task {
                    if HealthKitService.isAvailable && !isUITestSnapshot {
                        await healthKitService.requestAuthorization()
                    }
                }
                // Same account, same log as the web: pull what the web added, then push what this device has.
                .onChange(of: scenePhase, initial: true) { _, phase in
                    guard phase == .active, syncService.syncEnabled, authService.user != nil, !isUITestSnapshot else { return }
                    Task {
                        await syncService.pull(dataStore: dataStore)
                        await syncService.push(dataStore: dataStore)
                    }
                }

                if !requiresUnlock || isUnlocked {
                    WhatsNewSheet()
                }

                if !showSplash, requiresUnlock, !isUnlocked {
                    HealstackLockView(
                        biometryType: biometryType,
                        isUnlocking: isUnlocking,
                        errorMessage: unlockError
                    ) {
                        Task {
                            await unlock()
                        }
                    }
                    .zIndex(2)
                    .transition(.opacity)
                }

                if showSplash {
                    SplashView()
                        .zIndex(1)
                        .transition(.opacity)
                }
            }
            .onAppear {
                biometryType = availableBiometryType()
                if !requiresUnlock { isUnlocked = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                    if requiresUnlock, !isUnlocked {
                        await unlock()
                    }
                }
            }
            .onChange(of: authService.user == nil) { _, signedOut in
                if signedOut { isUnlocked = false }
            }
            } // end auth check
            } // end Group
            .formStyle(.grouped) // macOS defaults to a two-column form that clipped labels in sheets (4, 2.3.5)
            .preferredColorScheme(rawTheme == "dark" ? .dark : rawTheme == "light" ? .light : nil)
            .onboarding(key: "healstack",
                        signedIn: authService.user != nil,
                        slides: healstackOnboardingSlides)
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        #endif
    }

    /// One construction of each destination, used by both the iOS TabView and the macOS sidebar.
    @ViewBuilder
    private func destination(for index: Int) -> some View {
        switch index {
        case 0:
            DashboardView(dataStore: dataStore, notificationService: notificationService, syncService: syncService, authService: authService)
        case 1:
            LibraryView(dataStore: dataStore)
        case 2:
            InsightsView(dataStore: dataStore)
        case 3:
            CombinedBodyView(dataStore: dataStore, healthKitService: healthKitService)
                .environment(bodyworkStore)
        default:
            LabResultsView(dataStore: dataStore)
        }
    }

    /// `List` single-selection binds an optional; `selectedTab` is not. Ignore deselection
    /// so the detail column always has something to show.
    private var sidebarSelection: Binding<Int?> {
        Binding(get: { selectedTab }, set: { if let new = $0 { selectedTab = new } })
    }

    private func availableBiometryType() -> LABiometryType {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        return context.biometryType
    }

    private func unlock() async {
        guard requiresUnlock, !isUnlocking else { return }
        isUnlocking = true
        unlockError = nil
        defer { isUnlocking = false }

        let context = LAContext()
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Healstack")
            isUnlocked = true
        } catch let error as LAError where error.code == .userCancel || error.code == .systemCancel || error.code == .appCancel {
            unlockError = nil
        } catch {
            unlockError = error.localizedDescription
        }
    }
}

private struct HealstackLockView: View {
    let biometryType: LABiometryType
    let isUnlocking: Bool
    let errorMessage: String?
    let unlockAction: () -> Void

    private var biometricLabel: String {
        biometryType == .faceID ? "Face ID" : "Touch ID"
    }

    private var biometricIcon: String {
        biometryType == .faceID ? "faceid" : "touchid"
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: biometricIcon)
                    .font(.system(size: 42))
                    .foregroundStyle(.primary)

                Text("Healstack is locked")
                    .font(.title2.weight(.semibold))

                Text("Authenticate with \(biometricLabel) to access your health data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: unlockAction) {
                    HStack {
                        if isUnlocking {
                            ProgressView()
                        }
                        Text("Unlock with \(biometricLabel)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
    }
}
