import Foundation
import HealthKit

// MARK: - HealthKit Errors
enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:          return "HealthKit is not available on this device."
        case .notAuthorized:         return "HealthKit authorization was denied."
        case .queryFailed(let msg):  return "HealthKit query failed: \(msg)"
        }
    }
}

// MARK: - HealthKitManager
/// Singleton that owns all HealthKit interactions. Running on @MainActor ensures
/// that property updates are safe for SwiftUI observation via AppState without
/// additional hops. Individual query closures are dispatched on arbitrary threads
/// by HealthKit; we resume onto @MainActor via async continuations.
@MainActor
final class HealthKitManager {

    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    private init() {}

    // MARK: - Availability

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Read / write type sets

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .vo2Max,
            .bodyMass,
        ]
        for id in quantityIds {
            types.insert(HKQuantityType(id))
        }
        // Sleep is a category type, not a quantity type
        types.insert(HKCategoryType(.sleepAnalysis))
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        types.insert(HKWorkoutType.workoutType())
        types.insert(HKQuantityType(.heartRate))
        types.insert(HKQuantityType(.activeEnergyBurned))
        return types
    }

    // MARK: - Authorization

    /// Request read permissions for HRV, RHR, sleep, VO2max, body mass and
    /// write permissions for workouts, heart rate, and active energy.
    /// Throws HealthKitError.notAvailable if the device doesn't support HealthKit
    /// (e.g., iPad without HealthKit support on older iOS).
    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitError.notAvailable }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // MARK: - Fetch Latest Snapshot

    /// Reads the most recent biometric samples from the last 24 hours and
    /// assembles a HealthSnapshot. Partial data is fine — all fields are optional.
    func fetchLatestSnapshot() async throws -> HealthSnapshot {
        guard isAvailable else { throw HealthKitError.notAvailable }

        // Composed units — safer than string parsing. HKUnit(from: "ml/kg/min")
        // throws NSInvalidArgumentException at runtime because chained `/` isn't
        // accepted by HealthKit's parser ("ml/(kg*min)" works, composition is bulletproof).
        let bpmUnit    = HKUnit.count().unitDivided(by: .minute())
        let vo2maxUnit = HKUnit.literUnit(with: .milli)
            .unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))

        // Run all queries concurrently — independent reads, no ordering requirement
        async let hrv        = latestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let rhr        = latestQuantity(.restingHeartRate, unit: bpmUnit)
        async let vo2        = latestQuantity(.vo2Max, unit: vo2maxUnit)
        async let mass       = latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let sleepData  = fetchSleepSummary()

        let (hrvVal, rhrVal, vo2Val, massVal, sleep) = try await (hrv, rhr, vo2, mass, sleepData)

        let dateStr = AppState.sharedDateString(from: Date())
        return HealthSnapshot(
            date:            dateStr,
            hrvMs:           hrvVal,
            rhrBpm:          rhrVal,
            sleepHours:      sleep.totalHours,
            deepSleepMin:    sleep.deepMin,
            remSleepMin:     sleep.remMin,
            vo2maxEstimate:  vo2Val,
            bodyMassKg:      massVal,
            source:          "healthkit"
        )
    }

    // MARK: - Save Workout

    /// Push a completed strength or cardio session to the Health app.
    /// Returns the UUID string of the saved HKWorkout for cross-referencing.
    func saveWorkout(
        start: Date,
        end: Date,
        isCardio: Bool,
        activeEnergyKcal: Double?,
        avgHeartRate: Double?
    ) async throws -> String {
        guard isAvailable else { throw HealthKitError.notAvailable }

        let config = HKWorkoutConfiguration()
        // Use crossTraining for cardio (covers unknown cardio modality) and
        // traditionalStrengthTraining for lifting sessions.
        config.activityType = isCardio ? .crossTraining : .traditionalStrengthTraining
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())

        try await builder.beginCollection(at: start)

        // Add optional active energy sample
        if let kcal = activeEnergyKcal, kcal > 0 {
            let energyType  = HKQuantityType(.activeEnergyBurned)
            let energyQty   = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: energyQty,
                start: start,
                end: end
            )
            try await builder.addSamples([energySample])
        }

        // Add optional average heart rate sample
        if let bpm = avgHeartRate, bpm > 0 {
            let hrType   = HKQuantityType(.heartRate)
            let hrUnit   = HKUnit.count().unitDivided(by: .minute())
            let hrQty    = HKQuantity(unit: hrUnit, doubleValue: bpm)
            let hrSample = HKQuantitySample(
                type: hrType,
                quantity: hrQty,
                start: start,
                end: end
            )
            try await builder.addSamples([hrSample])
        }

        try await builder.endCollection(at: end)
        // finishWorkout() returns HKWorkout? on some SDK versions; guard to avoid
        // a force-unwrap crash on older simulators.
        guard let workout = try await builder.finishWorkout() else {
            throw HealthKitError.queryFailed("finishWorkout returned nil")
        }
        return workout.uuid.uuidString
    }

    // MARK: - Private Query Helpers

    /// Fetches the most recent sample within the last 24 h for the given quantity type.
    private func latestQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double? {
        let type = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-86_400),
            end: Date(),
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep

    private struct SleepSummary {
        var totalHours: Double?
        var deepMin: Double?
        var remMin: Double?
    }

    /// Sums HKCategoryValueSleepAnalysis samples from last night (midnight–now).
    /// Maps Apple's sleep stage cases: asleepCore + asleepDeep + asleepREM → total;
    /// asleepDeep → deepSleepMin; asleepREM → remSleepMin.
    private func fetchSleepSummary() async throws -> SleepSummary {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let yesterday = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86_400)
        let predicate = HKQuery.predicateForSamples(
            withStart: yesterday,
            end: Date(),
            options: .strictStartDate
        )

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, rawSamples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }
                let typed = (rawSamples ?? []).compactMap { $0 as? HKCategorySample }
                continuation.resume(returning: typed)
            }
            store.execute(query)
        }

        var totalSec: Double = 0
        var deepSec: Double  = 0
        var remSec: Double   = 0

        for sample in samples {
            guard let stage = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            switch stage {
            case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                // All "asleep" variants contribute to total
                totalSec += duration
                if stage == .asleepDeep { deepSec += duration }
                if stage == .asleepREM  { remSec  += duration }
            default:
                break  // inBed, awake, etc. — ignore for totals
            }
        }

        return SleepSummary(
            totalHours: totalSec > 0 ? totalSec / 3_600 : nil,
            deepMin:    deepSec  > 0 ? deepSec  / 60    : nil,
            remMin:     remSec   > 0 ? remSec   / 60    : nil
        )
    }
}
