import Foundation

// MARK: - Set Log
struct SetLog: Codable, Identifiable {
    var id: UUID = UUID()
    var weight: String   // stored as String to handle empty / partial input
    var reps: String
    var rir: String      // original freeform field kept for backward compat ("1–2", "0", "—")

    // New in v3: integer RIR for autoregulation. Decoded with decodeIfPresent so
    // old persisted blobs (which lack this key) decode to nil rather than failing.
    var rirInt: Int?

    // MARK: Custom decode — preserves rir String and adds rirInt gracefully
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id     = (try? c.decodeIfPresent(UUID.self,   forKey: .id))   ?? UUID()
        weight = try c.decode(String.self, forKey: .weight)
        reps   = try c.decode(String.self, forKey: .reps)
        rir    = try c.decode(String.self, forKey: .rir)
        rirInt = try? c.decodeIfPresent(Int.self, forKey: .rirInt)
    }

    // Memberwise init used by AppState.saveSession() and unit tests
    init(weight: String, reps: String, rir: String, rirInt: Int? = nil) {
        self.weight = weight
        self.reps   = reps
        self.rir    = rir
        self.rirInt = rirInt
    }

    /// Resolved integer RIR: prefers the explicit rirInt if present, otherwise
    /// falls back to parsing the first digit out of the legacy freeform rir string
    /// (e.g. "1–2" → 1). Returns nil for non-applicable rows like "—".
    var resolvedRIR: Int? {
        if let explicit = rirInt { return explicit }
        return Autoregulation.firstInt(in: rir)
    }
}

// MARK: - Exercise Log
struct ExerciseLog: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var sets: [SetLog]

    /// Returns the maximum weight logged across all sets for PR tracking.
    var maxWeight: Double? {
        sets.compactMap { Double($0.weight) }.max()
    }

    /// Average resolved RIR across sets that have a non-nil resolved value.
    /// Used by Autoregulation.nextWeight to suggest load for the next session.
    var avgRIR: Double? {
        let values = sets.compactMap { $0.resolvedRIR }.map { Double($0) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Workout Log Entry
/// One complete session log, saved after the user taps "Save Session".
struct WorkoutLog: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String          // "M/d/yyyy" locale string, mirrors JSX
    var week: Int
    var dayKey: String        // "Mon", "Tue", etc.
    var sessionLabel: String
    var exercises: [ExerciseLog]
}

// MARK: - Bodyweight Entry
struct BodyweightEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: String
    var weight: Double
}
