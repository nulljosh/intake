# Intake (iOS)

v2.3.3

Display name renamed from Dose 2026-07-01. Bundle ID, App Group (group.com.heyitsmejosh.dose), and URL scheme (dose://) unchanged.

## Rules

- iOS 17+, SwiftUI only, @Observable, @Bindable
- xcodegen (project.yml), no checked-in .xcodeproj
- HealthKit entitlements via Dose.entitlements
- App Group: group.com.heyitsmejosh.dose (widget data sync)
- Supabase auth (email/password, password reset via dose:// deep link)
- Local persistence: UserDefaults via DataStore; syncs to healstack.heyitsmejosh.com/api/sync using Supabase JWT
- no emojis

## Run

```bash
xcodegen generate && open Healstack.xcodeproj   # project is Healstack.xcodeproj; scheme/target are still Dose
xcodebuild build -scheme Healstack -project Healstack.xcodeproj -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation
xcodebuild test -scheme Healstack -project Healstack.xcodeproj -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation
```

## Key Files

- DoseApp.swift: app entry point with tab layout, splash, biometric lock, and auth/recovery gating
- Services/AuthService.swift: Supabase auth — sign in, sign up, sign out, password reset, recovery flow, Google sign-in (OAuth browser flow, wired into AuthView). Apple sign-in stays behind `appleSignInEnabled = false` until the Apple provider is enabled on spark; macOS's button is now gated by the same flag (was previously unguarded and would have errored on tap)
- Services/DataStore.swift: UserDefaults persistence, widget sync, and import/export bundle
- Services/SyncService.swift: push/pull sync to web API using Supabase JWT
- Services/HealthKitService.swift: HealthKit authorization and metric fetching
- Services/InteractionEngine.swift: interaction classification for built-in substances
- Views/AuthView.swift: sign in / register / forgot password UI
- Views/NewPasswordView.swift: password update after deep-link recovery
- Views/DashboardView.swift: home dashboard for active stack and recent entries
- Views/SettingsView.swift: account (email, sign out), profile, medications, sync, data export
- 2026-10-21: the custom floating tab bar is gone; the native TabView bar is back, because the custom one covered content. In-app name is Intake; the project, scheme and targets keep the Healstack name.
- Changelog v2.3.2 (2026-06-28): Added custom DoseFloatingTabBar (regularMaterial capsule, haptics, symbolEffect bounce). Fixed tab icons: house/house.fill, books.vertical/fill, chart.line.uptrend.xyaxis.circle/fill, figure.mind.and.body, cross.vial/cross.vial.fill. Corrected always-filled icon bug (unselected tabs now use outline variants).
