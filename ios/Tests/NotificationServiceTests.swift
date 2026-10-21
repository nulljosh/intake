import XCTest
import UserNotifications
@testable import Healstack

/// These never call `requestAuthorization()`. It presents a system permission alert that
/// nothing dismisses under `xcodebuild test`, which hung the whole suite indefinitely.
/// Scheduling and cancelling work without authorization, which is what these actually test.
@MainActor
final class NotificationServiceTests: XCTestCase {
    /// `UNUserNotificationCenter.add` silently drops requests when the app is not
    /// authorized, so any test asserting a request is *pending* needs real permission.
    /// `notificationSettings()` reads the status without prompting, unlike
    /// `requestAuthorization()`, which blocks forever on a headless simulator.
    private func skipUnlessNotificationsAuthorized() async throws {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        try XCTSkipUnless(
            settings.authorizationStatus == .authorized,
            "Notification authorization not granted on this simulator"
        )
    }

    func testScheduleReminderCreatesRequest() async throws {
        try await skipUnlessNotificationsAuthorized()
        let service = NotificationService()

        service.scheduleDoseReminder(substanceName: "TestVitamin", at: Date(), repeats: false)

        let pending = await service.getPending()
        let found = pending.contains { $0.identifier.contains("TestVitamin") }
        XCTAssertTrue(found, "Expected a pending notification for TestVitamin")

        // cleanup
        service.cancelAll()
    }

    func testCancelRemovesNotification() async {
        let service = NotificationService()

        let date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        service.scheduleDoseReminder(substanceName: "CancelTest", at: date, repeats: false)

        let id = "dose-CancelTest-9-0"
        service.cancelReminder(id: id)

        // Give a moment for removal to propagate
        try? await Task.sleep(nanoseconds: 100_000_000)

        let pending = await service.getPending()
        let found = pending.contains { $0.identifier == id }
        XCTAssertFalse(found, "Cancelled notification should not be pending")

        service.cancelAll()
    }

    func testScheduleWithEmptyNameUsesEmptyId() async throws {
        try await skipUnlessNotificationsAuthorized()
        let service = NotificationService()

        service.scheduleDoseReminder(substanceName: "", at: Date(), repeats: false)

        let pending = await service.getPending()
        let found = pending.contains { $0.identifier.hasPrefix("dose-") }
        XCTAssertTrue(found)

        service.cancelAll()
    }
}
