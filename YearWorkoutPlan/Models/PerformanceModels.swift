import Foundation

// MARK: - Assessment Baseline
/// Stores a single performance assessment snapshot. All test values are optional
/// so partial assessments (e.g., strength only) round-trip cleanly.
struct AssessmentBaseline: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String                      // locale short format, matches AppState.dateString(from:)
    var benchE1RM: Double?
    var squatE1RM: Double?
    var deadliftE1RM: Double?
    var ohpE1RM: Double?
    var vo2max: Double?                   // ml/kg/min
    var verticalJumpCm: Double?
    var deadHangSec: Double?
    var sitToRiseScore: Double?           // 0–10 in 0.5 increments
    var sitAndReachCm: Double?
    var shoulderFlexionDeg: Double?
    var gripKg: Double?
    var notes: String
}

// MARK: - Hexagon Score
/// One radar-chart snapshot: six axes, each 0–100. Computed by AppState and stored
/// so Wave 2 views can display history without recomputing.
struct HexagonScore: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var strength: Double                  // 0-100
    var power: Double                     // 0-100
    var vo2max: Double                    // 0-100
    var endurance: Double                 // 0-100
    var flexibility: Double               // 0-100
    var recovery: Double                  // 0-100
}

// MARK: - Bloodwork Entry
struct BloodworkEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var ferritinNgMl: Double?
    var vitaminDNgMl: Double?
    var omega3IndexPct: Double?
    var fastingGlucoseMgDl: Double?
    var hba1cPct: Double?
    var totalTestosteroneNgDl: Double?
    var freeTestosteronePgMl: Double?
    var totalCholesterolMgDl: Double?
    var ldlMgDl: Double?
    var hdlMgDl: Double?
    var hsCRPmgL: Double?
    var notes: String
}

// MARK: - Supplement Adherence
/// Append-only daily check-mark. One entry per supplement per day.
struct SupplementAdherence: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var supplementId: Int
    var taken: Bool
}

// MARK: - Session RPE
/// Post-session rating of perceived exertion. Linked to a specific day's session
/// via week + dayKey so it can be joined with WorkoutLog for analytics.
struct SessionRPE: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var week: Int
    var dayKey: String                    // "Mon", "Tue", etc.
    var sessionLabel: String
    var rpe: Int                          // 0–10
    var durationMin: Int
}

// MARK: - Photo Entry
/// Biweekly progress photo metadata. URLs point to the app's documents directory;
/// Wave 2 will handle the actual file management.
struct PhotoEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var frontURL: String?
    var sideURL: String?
    var backURL: String?
    var weightLbs: Double?
}

// MARK: - Mood Entry
struct MoodEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var mood: Int                         // 1–10
    var energy: Int                       // 1–10
    var sleepQuality: Int                 // 1–5
}

// MARK: - Health Snapshot
/// One day's worth of biometric data from HealthKit (or manual entry).
/// Deduplicated by date in AppState.appendHealthSnapshot(_:).
struct HealthSnapshot: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var hrvMs: Double?                    // SDNN, milliseconds
    var rhrBpm: Double?                   // resting heart rate
    var sleepHours: Double?              // total asleep
    var deepSleepMin: Double?
    var remSleepMin: Double?
    var vo2maxEstimate: Double?           // ml/kg/min, from Apple Watch
    var bodyMassKg: Double?
    var source: String                    // "healthkit" or "manual"
}

// MARK: - Plate Profile
/// Barbell + available plates for the weight-calculator feature in Wave 2.
/// Defaults match a standard commercial gym setup.
struct PlateProfile: Codable, Equatable {
    var barbellLbs: Double = 45
    var availablePlatesLbs: [Double] = [45, 35, 25, 10, 5, 2.5]
}

// MARK: - User Profile
/// Demographic data used for strength-relative scoring (e.g., Hexagon).
struct UserProfile: Codable, Equatable {
    var bodyweightKg: Double?
    var heightCm: Double?
    var ageYears: Int?
    var sexMale: Bool = true
    var plateProfile: PlateProfile = PlateProfile()
}

// MARK: - Recovery Score
/// Computed daily from HealthKit HRV + sleep (or Whoop manual fallback).
/// The `guidance` string surfaces directly on the Today screen in Wave 2.
struct RecoveryScore: Codable, Equatable {
    let percent: Int                      // 0–100
    let band: Band
    let guidance: String

    enum Band: String, Codable {
        case green, yellow, red
    }
}
