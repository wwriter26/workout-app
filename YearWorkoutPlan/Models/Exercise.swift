import Foundation

// MARK: - CNS Load
enum CNSLoad: String, Codable, CaseIterable {
    case high           = "high"
    case moderateHigh   = "moderate-high"
    case moderate       = "moderate"
    case low            = "low"
    case rest           = "rest"

    var displayName: String { rawValue.uppercased() }
}

// MARK: - Exercise
/// A single exercise within a session. Matches JSX exercise object shape exactly.
struct Exercise: Identifiable, Codable, Equatable {
    // Stable ID derived from name so we can identify exercises across refreshes.
    var id: String { name }
    let name: String
    let sets: Int
    let reps: String
    let load: String
    let rir: String
    let rest: String
    /// When true, this exercise is only shown on Whoop green days (e.g. sprints).
    let whoopGreen: Bool

    init(
        name: String,
        sets: Int,
        reps: String,
        load: String,
        rir: String,
        rest: String,
        whoopGreen: Bool = false
    ) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.load = load
        self.rir = rir
        self.rest = rest
        self.whoopGreen = whoopGreen
    }
}

// MARK: - Session
struct Session: Identifiable, Codable {
    let dayKey: String       // "Mon", "Tue", etc.
    let label: String
    let cnsLoad: CNSLoad
    let isCardio: Bool
    let exercises: [Exercise]

    var id: String { dayKey }
}
