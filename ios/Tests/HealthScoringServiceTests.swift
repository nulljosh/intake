import XCTest
@testable import Healstack

@MainActor
final class HealthScoringServiceTests: XCTestCase {

    func testScoreMetricOptimalRange() {
        // Sleep 8h is in optimal range (7-9), should get full 30 points
        let score = HealthScoringService.scoreMetric(key: "sleepHours", value: 8.0)
        XCTAssertEqual(score, 30)
    }

    func testScoreMetricAcceptableRange() {
        // Sleep 6h is in acceptable range (6-10), should get 65% of 30
        let score = HealthScoringService.scoreMetric(key: "sleepHours", value: 6.0)
        XCTAssertEqual(score, 20) // round(30 * 0.65) = 20
    }

    func testScoreMetricOutOfRange() {
        // Sleep 3h is out of all ranges, should get 30% of 30
        let score = HealthScoringService.scoreMetric(key: "sleepHours", value: 3.0)
        XCTAssertEqual(score, 9) // round(30 * 0.3) = 9
    }

    func testScoreMetricThresholdHigh() {
        // Steps 10000+ = full points (22)
        let score = HealthScoringService.scoreMetric(key: "steps", value: 10000)
        XCTAssertEqual(score, 22)
    }

    func testScoreMetricThresholdMid() {
        // Steps 7000 = 70% of 22
        let score = HealthScoringService.scoreMetric(key: "steps", value: 7000)
        XCTAssertEqual(score, 15) // round(22 * 0.7) = 15
    }

    func testScoreMetricThresholdLow() {
        // Steps 4000 = 35% of 22
        let score = HealthScoringService.scoreMetric(key: "steps", value: 4000)
        XCTAssertEqual(score, 8) // round(22 * 0.35) = 8
    }

    func testScoreMetricScale() {
        // Mood 10/10 = full 13 points
        let score = HealthScoringService.scoreMetric(key: "moodScore", value: 10)
        XCTAssertEqual(score, 13)

        // Mood 5/10 = 50% of 13
        let half = HealthScoringService.scoreMetric(key: "moodScore", value: 5)
        XCTAssertEqual(half, 7) // round(13 * 0.5) = 7
    }

    func testScoreMetricUnknownKey() {
        let score = HealthScoringService.scoreMetric(key: "bogus", value: 42)
        XCTAssertNil(score)
    }

    func testHealthRankTiers() {
        XCTAssertEqual(HealthScoringService.healthRank(score: 100), .excellent)
        XCTAssertEqual(HealthScoringService.healthRank(score: 86), .excellent)
        XCTAssertEqual(HealthScoringService.healthRank(score: 85), .healthy)
        XCTAssertEqual(HealthScoringService.healthRank(score: 72), .healthy)
        XCTAssertEqual(HealthScoringService.healthRank(score: 71), .watch)
        XCTAssertEqual(HealthScoringService.healthRank(score: 58), .watch)
        XCTAssertEqual(HealthScoringService.healthRank(score: 57), .atRisk)
        XCTAssertEqual(HealthScoringService.healthRank(score: 0), .atRisk)
    }

    func testConfidencePartialData() {
        // 3 of 5 metrics provided = 60% confidence
        let breakdown = HealthScoringService.scoreBreakdown(metrics: [
            "sleepHours": 8.0,
            "steps": 10000,
            "heartRate": 70,
        ])
        XCTAssertEqual(breakdown.confidence, 60)
        XCTAssertNotNil(breakdown.parts["sleepHours"] ?? nil)
        XCTAssertNotNil(breakdown.parts["steps"] ?? nil)
        XCTAssertNotNil(breakdown.parts["heartRate"] ?? nil)
    }

    func testConfidenceFullData() {
        let breakdown = HealthScoringService.scoreBreakdown(metrics: [
            "sleepHours": 8.0,
            "steps": 10000,
            "heartRate": 70,
            "bloodPressureSys": 115,
            "moodScore": 10,
        ])
        XCTAssertEqual(breakdown.confidence, 100)
        // All optimal: total should be 100. moodScore is a scale metric out of 10,
        // so it has to be 10 here - 8 scores 13 * 0.8 = 10 of 13 and totals 97.
        XCTAssertEqual(breakdown.total, 100)
    }

    func testAnomalySleepDip() {
        let avg = ["sleepHours": 8.0]
        let latest = ["sleepHours": 5.0] // 3h drop > 1.5h threshold
        let anomalies = HealthScoringService.metricAnomalies(last7Avg: avg, latest: latest)
        XCTAssertTrue(anomalies.contains("Sleep dipped sharply vs weekly baseline"))
    }

    func testAnomalyStepDrop() {
        let avg = ["steps": 10000.0]
        let latest = ["steps": 4000.0] // < 60% of avg
        let anomalies = HealthScoringService.metricAnomalies(last7Avg: avg, latest: latest)
        XCTAssertTrue(anomalies.contains("Step count dropped materially today"))
    }

    func testAnomalyElevatedHR() {
        let anomalies = HealthScoringService.metricAnomalies(last7Avg: [:], latest: ["heartRate": 100])
        XCTAssertTrue(anomalies.contains("Heart rate is elevated"))
    }

    func testAnomalyHighBP() {
        let anomalies = HealthScoringService.metricAnomalies(last7Avg: [:], latest: ["bloodPressureSys": 145])
        XCTAssertTrue(anomalies.contains("Blood pressure systolic above 140 mmHg"))
    }

    func testNoAnomaliesWhenNormal() {
        let avg = ["sleepHours": 8.0, "steps": 10000.0]
        let latest = ["sleepHours": 7.5, "steps": 9000.0, "heartRate": 72.0, "bloodPressureSys": 118.0]
        let anomalies = HealthScoringService.metricAnomalies(last7Avg: avg, latest: latest)
        XCTAssertTrue(anomalies.isEmpty)
    }

    func testEmptyData() {
        let breakdown = HealthScoringService.scoreBreakdown(metrics: [:])
        XCTAssertEqual(breakdown.total, 0)
        XCTAssertEqual(breakdown.confidence, 0)
    }

    func testComputeFullScoreWithRealData() {
        let breakdown = HealthScoringService.scoreBreakdown(metrics: [
            "sleepHours": 7.5,
            "steps": 8500,
            "heartRate": 68,
            "bloodPressureSys": 118,
            "moodScore": 8,
        ])
        XCTAssertGreaterThan(breakdown.total, 0)
        XCTAssertEqual(breakdown.confidence, 100)
        XCTAssertGreaterThanOrEqual(breakdown.total, 70, "All-optimal-ish data should score well")
    }

    func testFlattenTodayMergesAllSources() {
        let bio = BiometricEntry(weight: 175, heartRate: 72, sleepHours: 7.0, steps: 5000)
        let health = HealthEntry(mood: 4, energy: 4, sleepHours: 7.5, notes: "")
        let result = HealthScoringService.flattenToday(
            biometricEntries: [bio],
            healthEntries: [health],
            healthKit: nil
        )
        // Sleep from bio (first priority after HK)
        XCTAssertEqual(result["sleepHours"], 7.0)
        XCTAssertEqual(result["steps"], 5000)
        XCTAssertEqual(result["heartRate"], 72)
        // Mood from health entry, scaled 1-5 to 1-10
        XCTAssertEqual(result["moodScore"], 8.0)
    }

    func testNegativeMetricValues() {
        let score = HealthScoringService.scoreMetric(key: "steps", value: -100)
        // Negative steps should still return a score (bottom tier)
        XCTAssertNotNil(score)
    }

    func testNaNMetricValues() {
        let score = HealthScoringService.scoreMetric(key: "sleepHours", value: Double.nan)
        XCTAssertNil(score, "NaN should be rejected by isFinite guard")
    }

    func testSupplementAdherence() {
        guard let vitD = SubstanceDatabase.allSubstances.first(where: { $0.category == .vitamin }) else {
            return
        }
        let calendar = Calendar.current
        var entries: [DoseEntry] = []

        for dayOffset in [0, 2, 4, 6, 8] {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            entries.append(DoseEntry(builtInSubstanceId: vitD.id, timestamp: date))
        }

        let adherence = HealthScoringService.supplementAdherence(doseEntries: entries)
        if let item = adherence.first(where: { $0.name == vitD.name }) {
            XCTAssertEqual(item.taken, 5)
            XCTAssertEqual(item.total, 14)
            XCTAssertEqual(item.rate, 36)
        }
    }
}
