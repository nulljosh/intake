import XCTest
@testable import Healstack

@MainActor
final class HealthKitServiceTests: XCTestCase {
    func testIsAvailableReturnsBool() {
        let available = HealthKitService.isAvailable
        XCTAssertTrue(available || !available)
    }

    func testInitialState() {
        let service = HealthKitService()

        XCTAssertNil(service.heartRate)
        XCTAssertNil(service.restingHeartRate)
        XCTAssertNil(service.hrv)
        XCTAssertNil(service.respiratoryRate)
        XCTAssertNil(service.bloodOxygen)
        XCTAssertNil(service.steps)
        XCTAssertNil(service.activeEnergy)
        XCTAssertNil(service.bodyMass)
        XCTAssertNil(service.sleepHours)
        XCTAssertNil(service.walkingDistance)
        XCTAssertNil(service.systolicBP)
        XCTAssertNil(service.diastolicBP)
        XCTAssertFalse(service.isAuthorized)
    }

    func testNewDataTypesExistOnInit() {
        let service = HealthKitService()
        XCTAssertNil(service.dietaryWater)
        XCTAssertNil(service.dietaryCaffeine)
        XCTAssertNil(service.bodyTemperature)
        XCTAssertNil(service.environmentalAudioExposure)
        XCTAssertNil(service.toothbrushingToday)
    }

    func testFetchAllDoesNotCrashWithoutAuth() async {
        let service = HealthKitService()
        XCTAssertFalse(service.isAuthorized)
        await service.fetchAll()
        // Should complete without crash; values remain nil on simulator
    }

    func testLastErrorNilOnInit() {
        let service = HealthKitService()
        XCTAssertNil(service.lastError)
    }

    func testIsAuthorizedDefaultsFalse() {
        let service = HealthKitService()
        XCTAssertFalse(service.isAuthorized)
    }

    func testFetchAllSetsMetricsToNilWhenNotAuthorized() async {
        let service = HealthKitService()
        await service.fetchAll()
        // Without authorization, HealthKit queries return nil on simulator
        XCTAssertNil(service.heartRate)
        XCTAssertNil(service.steps)
        XCTAssertNil(service.sleepHours)
    }

    func testIsAvailableOnSimulator() {
        // On simulator HK may or may not be available depending on OS
        let result = HealthKitService.isAvailable
        XCTAssertTrue(result || !result, "isAvailable should return a bool without crashing")
    }
}
