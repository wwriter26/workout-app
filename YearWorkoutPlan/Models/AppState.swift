import Foundation
import SwiftUI

// MARK: - Whoop Recovery
enum WhoopStatus: String, Codable, CaseIterable {
    case green  = "green"
    case yellow = "yellow"
    case red    = "red"

    var label: String {
        switch self {
        case .green:  return "Green"
        case .yellow: return "Yellow"
        case .red:    return "Red"
        }
    }

    var color: Color {
        switch self {
        case .green:  return AppColor.spring
        case .yellow: return AppColor.summer
        case .red:    return AppColor.fall
        }
    }

    var description: String {
        switch self {
        case .green:
            return "Execute as planned. Push it on heavy/VO2 days."
        case .yellow:
            return "Higher end of RIR (lighter). Drop one interval on VO2 days."
        case .red:
            return "Swap for Z2 (45 min) or full rest. Don't push through."
        }
    }
}

// MARK: - Persisted State
// Using Codable + UserDefaults for simplicity (no SwiftData dependency).
// @Observable drives reactivity in iOS 17+.
@Observable
@MainActor
final class AppState {

    // MARK: Persisted properties
    var currentWeek: Int = 1 {
        didSet { save() }
    }
    var currentDayIndex: Int = {
        let wd = Calendar.current.component(.weekday, from: Date())
        // Sunday = 1 in Calendar, we want Mon=0 … Sun=6
        return wd == 1 ? 6 : wd - 2
    }() {
        didSet { save() }
    }
    var whoopToday: WhoopStatus? = nil {
        didSet { save() }
    }
    var bodyweightLog: [BodyweightEntry] = [] {
        didSet { save() }
    }
    var workoutLogs: [WorkoutLog] = [] {
        didSet { save() }
    }
    var prLog: [String: Double] = [:] {
        didSet { save() }
    }

    /// Today's exercise swaps keyed by "week-day-originalExerciseName".
    /// Persisted so that if the user backgrounds and returns, swaps survive.
    var swappedExercises: [String: String] = [:] {
        didSet { save() }
    }

    /// User-created recipes (in addition to the built-in seed recipes).
    var userRecipes: [UserRecipe] = [] {
        didSet { save() }
    }

    /// Mobility check-off keyed by date string (e.g. "5/15/2026" in locale short format).
    var mobilityCompleted: [String: Bool] = [:] {
        didSet { save() }
    }

    // completedSets: "exIdx-setIdx" -> Bool, reset per session (NOT persisted across days)
    var completedSets: [String: Bool] = [:]

    // MARK: Transient UI state (not persisted)
    var todayBW: String = ""
    var logWeights: [String: String] = [:]   // "exIdx-setIdx-w/r/rir" -> value
    var isLoggingSession: Bool = false
    var scheduleWeek: Int = 1
    var statsLift: String = SupplementList.bigLifts[0]
    var planTab: String = "nutrition"
    var selectedTab: Tab = .today

    // MARK: - Computed helpers
    var season: Season { Seasons.season(for: currentWeek) }
    var todayDayKey: String { Schedules.days[currentDayIndex] }
    var isDeload: Bool { Seasons.isDeload(currentWeek) }
    var isTransition: Bool { Seasons.isTransition(currentWeek) }

    var todaySession: Session {
        Schedules.session(week: currentWeek, dayKey: todayDayKey)
            ?? Session(dayKey: todayDayKey, label: "Rest", cnsLoad: .rest, isCardio: false, exercises: [])
    }

    /// Applies Whoop adjustment: red → Z2 stub; yellow → strips whoopGreen-only exercises
    var adjustedSession: Session {
        switch whoopToday {
        case .red:
            return Session(
                dayKey: todayDayKey,
                label: "→ Z2 or Rest (Whoop Red)",
                cnsLoad: .low,
                isCardio: true,
                exercises: [
                    Exercise(name: "Zone 2 cardio", sets: 1, reps: "45 min",
                             load: "60–70% HRmax", rir: "—", rest: "—"),
                ]
            )
        case .yellow:
            let filtered = todaySession.exercises.filter { !$0.whoopGreen }
            return Session(
                dayKey: todaySession.dayKey,
                label: todaySession.label,
                cnsLoad: todaySession.cnsLoad,
                isCardio: todaySession.isCardio,
                exercises: filtered
            )
        default:
            return todaySession
        }
    }

    var completionPercent: Double {
        let total = adjustedSession.exercises.reduce(0) { $0 + $1.sets }
        guard total > 0 else { return 0 }
        let done = completedSets.values.filter { $0 }.count
        return Double(done) / Double(total)
    }

    // MARK: - Swap helpers

    /// Canonical key for a per-day exercise swap.
    func swapKey(week: Int, day: String, originalName: String) -> String {
        "\(week)-\(day)-\(originalName)"
    }

    /// Saves a swap for today's session only (keyed by week+day+originalName).
    func swap(week: Int, day: String, originalName: String, newName: String) {
        swappedExercises[swapKey(week: week, day: day, originalName: originalName)] = newName
    }

    /// Reverts a swap, restoring the original exercise name.
    func revertSwap(week: Int, day: String, originalName: String) {
        swappedExercises.removeValue(forKey: swapKey(week: week, day: day, originalName: originalName))
    }

    // MARK: - Actions

    func logBodyweight() {
        guard let w = Double(todayBW), w > 0 else { return }
        let dateStr = dateString(from: Date())
        bodyweightLog.removeAll { $0.date == dateStr }
        bodyweightLog.append(BodyweightEntry(date: dateStr, weight: w))
        // Keep last 60 entries
        if bodyweightLog.count > 60 { bodyweightLog = Array(bodyweightLog.suffix(60)) }
        todayBW = ""
    }

    func toggleSet(exIndex: Int, setIndex: Int) {
        let key = "\(exIndex)-\(setIndex)"
        completedSets[key] = !(completedSets[key] ?? false)
    }

    func saveSession() {
        let dateStr = dateString(from: Date())
        let exercises = adjustedSession.exercises.enumerated().map { (i, ex) in
            // Use swapped name if applicable
            let key = swapKey(week: currentWeek, day: todayDayKey, originalName: ex.name)
            let loggedName = swappedExercises[key] ?? ex.name
            return ExerciseLog(
                name: loggedName,
                sets: (0..<ex.sets).map { si in
                    SetLog(
                        weight: logWeights["\(i)-\(si)-w"] ?? "",
                        reps:   logWeights["\(i)-\(si)-r"] ?? ex.reps,
                        rir:    logWeights["\(i)-\(si)-rir"] ?? ex.rir
                    )
                }
            )
        }

        let entry = WorkoutLog(
            date: dateStr,
            week: currentWeek,
            dayKey: todayDayKey,
            sessionLabel: adjustedSession.label,
            exercises: exercises
        )

        workoutLogs.removeAll { $0.date == dateStr }
        workoutLogs.append(entry)
        if workoutLogs.count > 200 { workoutLogs = Array(workoutLogs.suffix(200)) }

        // Update PRs for big lifts
        for ex in exercises where SupplementList.bigLifts.contains(ex.name) {
            if let best = ex.maxWeight {
                let current = prLog[ex.name] ?? 0
                if best > current { prLog[ex.name] = best }
            }
        }

        // Reset session state
        completedSets = [:]
        logWeights = [:]
        isLoggingSession = false
    }

    func toggleMobility(for date: Date) {
        let key = dateString(from: date)
        mobilityCompleted[key] = !(mobilityCompleted[key] ?? false)
    }

    var isMobilityCompletedToday: Bool {
        mobilityCompleted[dateString(from: Date())] ?? false
    }

    func exportJSON() -> Data? {
        let container = ExportContainer(
            currentWeek: currentWeek,
            bodyweightLog: bodyweightLog,
            workoutLogs: workoutLogs,
            prLog: prLog
        )
        return try? JSONEncoder().encode(container)
    }

    // MARK: - New v3 Persisted Properties

    var assessmentHistory: [AssessmentBaseline] = [] {
        didSet { save() }
    }
    var hexagonHistory: [HexagonScore] = [] {
        didSet { save() }
    }
    var bloodworkHistory: [BloodworkEntry] = [] {
        didSet { save() }
    }
    /// Append-only daily supplement check-marks. Wave 2 views filter by date.
    var supplementAdherence: [SupplementAdherence] = [] {
        didSet { save() }
    }

    /// The set of supplement IDs the user has added to their daily stack.
    /// Defaults to all Tier 1 IDs so the adherence card is populated on first launch.
    /// SupplementAdherenceCard shows only these IDs; PlanView lets users toggle membership.
    var activeSupplementIDs: Set<Int> = Set(SupplementList.all.filter { $0.tier == 1 }.map(\.id)) {
        didSet { save() }
    }
    var sessionRPEs: [SessionRPE] = [] {
        didSet { save() }
    }
    var photoEntries: [PhotoEntry] = [] {
        didSet { save() }
    }
    var moodEntries: [MoodEntry] = [] {
        didSet { save() }
    }
    /// Capped at last 90 entries (≈ 3 months of daily HealthKit reads).
    var healthSnapshots: [HealthSnapshot] = [] {
        didSet { save() }
    }
    var userProfile: UserProfile = UserProfile(sexMale: true) {
        didSet { save() }
    }
    /// Non-nil during travel weeks; Wave 2 uses this to show a travel-mode banner.
    var travelModeUntil: Date? = nil {
        didSet { save() }
    }
    var autoregEnabled: Bool = true {
        didSet { save() }
    }
    var onboardingCompleted: Bool = false {
        didSet { save() }
    }

    // MARK: - Computed Helpers (v3)

    var latestSnapshot: HealthSnapshot? { healthSnapshots.last }

    /// Composite daily recovery score, preferring HealthKit data over Whoop manual.
    ///
    /// Scoring logic:
    ///   - Green (90): HRV at or above 30-day avg AND sleep ≥ 7 h
    ///   - Yellow (60): HRV within ±1 SD of avg AND sleep 6–7 h
    ///   - Red (30):    HRV below −1 SD OR sleep < 6 h
    ///   - Fallback:    maps WhoopStatus → matching band when no HealthKit data
    var recoveryScore: RecoveryScore {
        // Use HealthKit data if today has a snapshot
        let today = Self.sharedDateString(from: Date())
        if let snap = healthSnapshots.last(where: { $0.date == today }),
           let hrv = snap.hrvMs {

            // 30-day rolling HRV average
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let cutoffStr = Self.sharedDateString(from: cutoff)
            let recent = healthSnapshots.filter { $0.date >= cutoffStr }.compactMap(\.hrvMs)
            let avg = recent.isEmpty ? hrv : recent.reduce(0, +) / Double(recent.count)

            // Standard deviation for the yellow band check
            let variance = recent.map { pow($0 - avg, 2) }.reduce(0, +) / max(Double(recent.count), 1)
            let sd = sqrt(variance)

            let sleep = snap.sleepHours ?? 0

            if hrv >= avg && sleep >= 7 {
                return RecoveryScore(percent: 90, band: .green,
                                     guidance: "Execute as planned. Push it on heavy/VO2 days.")
            } else if hrv >= (avg - sd) && sleep >= 6 {
                return RecoveryScore(percent: 60, band: .yellow,
                                     guidance: "Higher end of RIR (lighter). Drop one interval on VO2 days.")
            } else {
                return RecoveryScore(percent: 30, band: .red,
                                     guidance: "Swap for Z2 (45 min) or full rest. Don't push through.")
            }
        }

        // Fallback: map WhoopStatus to RecoveryScore bands
        switch whoopToday {
        case .green:
            return RecoveryScore(percent: 90, band: .green,
                                 guidance: "Execute as planned. Push it on heavy/VO2 days.")
        case .yellow:
            return RecoveryScore(percent: 60, band: .yellow,
                                 guidance: "Higher end of RIR (lighter). Drop one interval on VO2 days.")
        case .red:
            return RecoveryScore(percent: 30, band: .red,
                                 guidance: "Swap for Z2 (45 min) or full rest. Don't push through.")
        case nil:
            // No data at all — default to yellow so the user isn't accidentally pushed
            return RecoveryScore(percent: 60, band: .yellow,
                                 guidance: "No recovery data yet. Log Whoop status or connect HealthKit.")
        }
    }

    // MARK: - v3 Helper Methods

    func logSupplementAdherence(supplementId: Int, taken: Bool, date: Date = Date()) {
        let dateStr = Self.sharedDateString(from: date)
        // Upsert: remove existing entry for this supplement on this date, then append
        supplementAdherence.removeAll { $0.date == dateStr && $0.supplementId == supplementId }
        supplementAdherence.append(SupplementAdherence(date: dateStr, supplementId: supplementId, taken: taken))
    }

    func isSupplementTakenToday(supplementId: Int) -> Bool {
        let today = Self.sharedDateString(from: Date())
        return supplementAdherence.last(where: { $0.date == today && $0.supplementId == supplementId })?.taken ?? false
    }

    func logMood(mood: Int, energy: Int, sleepQuality: Int) {
        let today = Self.sharedDateString(from: Date())
        moodEntries.removeAll { $0.date == today }
        moodEntries.append(MoodEntry(date: today, mood: mood, energy: energy, sleepQuality: sleepQuality))
    }

    func logSessionRPE(rpe: Int, durationMin: Int) {
        let today = Self.sharedDateString(from: Date())
        // Upsert by date+dayKey — one RPE entry per session
        sessionRPEs.removeAll { $0.date == today && $0.dayKey == todayDayKey }
        sessionRPEs.append(SessionRPE(
            date:         today,
            week:         currentWeek,
            dayKey:       todayDayKey,
            sessionLabel: adjustedSession.label,
            rpe:          rpe,
            durationMin:  durationMin
        ))
    }

    /// Appends or replaces a HealthSnapshot for the given date, then caps at 90 entries.
    func appendHealthSnapshot(_ snap: HealthSnapshot) {
        healthSnapshots.removeAll { $0.date == snap.date }
        healthSnapshots.append(snap)
        if healthSnapshots.count > 90 {
            healthSnapshots = Array(healthSnapshots.suffix(90))
        }
    }

    /// Fetches today's biometrics from HealthKit and stores them.
    /// Silent no-op if HealthKit is unavailable or authorization wasn't granted.
    func refreshHealthData() async {
        guard HealthKitManager.shared.isAvailable else { return }
        do {
            let snap = try await HealthKitManager.shared.fetchLatestSnapshot()
            appendHealthSnapshot(snap)
        } catch {
            // Non-fatal: HealthKit is optional enrichment, not a core requirement
        }
    }

    func saveAssessment(_ a: AssessmentBaseline) {
        // Upsert by date — only one assessment per calendar day
        assessmentHistory.removeAll { $0.date == a.date }
        assessmentHistory.append(a)
    }

    /// Computes a HexagonScore from the most recent AssessmentBaseline and current
    /// health data, then appends it to hexagonHistory.
    @discardableResult
    func computeHexagonScore(for date: Date = Date()) -> HexagonScore {
        let dateStr = Self.sharedDateString(from: date)
        let latest  = assessmentHistory.last

        // --- Strength (0-100) ---
        // Average the four lift E1RMs as multiples of bodyweight.
        // Scale: avg BW multiple → score (1.0→30, 1.5→60, 2.0→90, 2.5→100)
        let strengthScore: Double = {
            guard let bwKg = userProfile.bodyweightKg, bwKg > 0, let a = latest else { return 0 }
            let bwLbs = bwKg * 2.20462
            let multiples: [Double] = [
                a.benchE1RM.map { $0 / bwLbs },
                a.squatE1RM.map { $0 / bwLbs },
                a.deadliftE1RM.map { $0 / bwLbs },
                a.ohpE1RM.map { $0 / bwLbs },
            ].compactMap { $0 }
            guard !multiples.isEmpty else { return 0 }
            let avg = multiples.reduce(0, +) / Double(multiples.count)
            // Linear interpolation between anchor points
            return linearInterpolate(
                x: avg,
                points: [(1.0, 30), (1.5, 60), (2.0, 90), (2.5, 100)]
            )
        }()

        // --- Power (0-100) ---
        // Vertical jump cm: <40→30, 60→70, 80→100 (linear between anchors)
        let powerScore: Double = {
            guard let jump = latest?.verticalJumpCm else { return 0 }
            return linearInterpolate(
                x: jump,
                points: [(40, 30), (60, 70), (80, 100)]
            )
        }()

        // --- VO2max (0-100) ---
        // ml/kg/min: 35→30, 45→60, 55→90, 60→100
        let vo2Score: Double = {
            let val = latest?.vo2max ?? healthSnapshots.last?.vo2maxEstimate
            guard let v2 = val else { return 0 }
            return linearInterpolate(
                x: v2,
                points: [(35, 30), (45, 60), (55, 90), (60, 100)]
            )
        }()

        // --- Endurance (0-100) ---
        // Longest weekly Z2 block in minutes: 30→30, 90→70, 180→100
        // Wave 2 TODO: compute from workoutLogs where isCardio. Default 0 for Wave 1.
        let enduranceScore: Double = {
            // Approximate from longest Z2 session in workoutLogs
            let z2Minutes: [Int] = workoutLogs.compactMap { log in
                guard log.exercises.contains(where: { $0.name.lowercased().contains("zone 2") || $0.name.lowercased().contains("z2") }) else { return nil }
                // Use sessionRPE durationMin if available for same date+dayKey
                return sessionRPEs.first(where: { $0.date == log.date && $0.dayKey == log.dayKey })?.durationMin
            }
            let maxZ2 = Double(z2Minutes.max() ?? 0)
            guard maxZ2 > 0 else { return 0 }
            return linearInterpolate(x: maxZ2, points: [(30, 30), (90, 70), (180, 100)])
        }()

        // --- Flexibility (0-100) ---
        // Weighted composite of three tests:
        //   sit-to-rise (0-10) → up to 50 pts
        //   sit-and-reach (0-25 cm) → up to 30 pts
        //   shoulder flexion (deg / 180) → up to 20 pts
        let flexScore: Double = {
            guard let a = latest else { return 0 }
            let str  = (a.sitToRiseScore ?? 0) / 10.0 * 50.0
            let sar  = min((a.sitAndReachCm ?? 0) / 25.0, 1.0) * 30.0
            let shld = min((a.shoulderFlexionDeg ?? 0) / 180.0, 1.0) * 20.0
            return min(str + sar + shld, 100)
        }()

        // --- Recovery (0-100) ---
        // HRV today as % of 30-day rolling avg, clamped 0-100.
        // 100 = at or above avg (no bonus for exceeding).
        let recoveryScoreVal: Double = {
            let todayHRV = healthSnapshots.last(where: { $0.date == dateStr })?.hrvMs
            guard let todayHRV else { return Double(recoveryScore.percent) }
            let recent = healthSnapshots.compactMap(\.hrvMs)
            guard !recent.isEmpty else { return min(todayHRV / 50.0 * 100, 100) }
            let avg = recent.reduce(0, +) / Double(recent.count)
            guard avg > 0 else { return 100 }
            return min((todayHRV / avg) * 100, 100)
        }()

        let score = HexagonScore(
            date:        dateStr,
            strength:    strengthScore.clamped(0, 100),
            power:       powerScore.clamped(0, 100),
            vo2max:      vo2Score.clamped(0, 100),
            endurance:   enduranceScore.clamped(0, 100),
            flexibility: flexScore.clamped(0, 100),
            recovery:    recoveryScoreVal.clamped(0, 100)
        )

        hexagonHistory.removeAll { $0.date == dateStr }
        hexagonHistory.append(score)
        return score
    }

    // MARK: - Persistence

    private static let v3Key = "app_state_v3"
    private static let v2Key = "app_state_v2"

    func save() {
        let container = PersistenceContainerV3(
            currentWeek:           currentWeek,
            currentDayIndex:       currentDayIndex,
            whoopToday:            whoopToday,
            bodyweightLog:         bodyweightLog,
            workoutLogs:           workoutLogs,
            prLog:                 prLog,
            swappedExercises:      swappedExercises,
            userRecipes:           userRecipes,
            mobilityCompleted:     mobilityCompleted,
            assessmentHistory:     assessmentHistory,
            hexagonHistory:        hexagonHistory,
            bloodworkHistory:      bloodworkHistory,
            supplementAdherence:   supplementAdherence,
            sessionRPEs:           sessionRPEs,
            photoEntries:          photoEntries,
            moodEntries:           moodEntries,
            healthSnapshots:       healthSnapshots,
            userProfile:           userProfile,
            travelModeUntil:       travelModeUntil,
            autoregEnabled:        autoregEnabled,
            onboardingCompleted:   onboardingCompleted,
            activeSupplementIDs:   activeSupplementIDs
        )
        if let data = try? JSONEncoder().encode(container) {
            UserDefaults.standard.set(data, forKey: Self.v3Key)
        }
    }

    func load() {
        // 1. Try v3
        if let data = UserDefaults.standard.data(forKey: Self.v3Key),
           let c = try? JSONDecoder().decode(PersistenceContainerV3.self, from: data) {
            applyV3Container(c)
            return
        }
        // 2. Try v2 — copy shared fields, new fields default
        if let data = UserDefaults.standard.data(forKey: Self.v2Key),
           let c = try? JSONDecoder().decode(PersistenceContainer.self, from: data) {
            applyV2Container(c)
            return
        }
        // 3. Legacy v1 — copy original fields only
        if let data = UserDefaults.standard.data(forKey: "app_state_v1"),
           let legacy = try? JSONDecoder().decode(LegacyPersistenceContainer.self, from: data) {
            currentWeek     = legacy.currentWeek
            currentDayIndex = legacy.currentDayIndex
            whoopToday      = legacy.whoopToday
            bodyweightLog   = legacy.bodyweightLog
            workoutLogs     = legacy.workoutLogs
            prLog           = legacy.prLog
            scheduleWeek    = legacy.currentWeek
        }
    }

    private func applyV3Container(_ c: PersistenceContainerV3) {
        currentWeek          = c.currentWeek
        currentDayIndex      = c.currentDayIndex
        whoopToday           = c.whoopToday
        bodyweightLog        = c.bodyweightLog
        workoutLogs          = c.workoutLogs
        prLog                = c.prLog
        swappedExercises     = c.swappedExercises
        userRecipes          = c.userRecipes
        mobilityCompleted    = c.mobilityCompleted
        assessmentHistory    = c.assessmentHistory
        hexagonHistory       = c.hexagonHistory
        bloodworkHistory     = c.bloodworkHistory
        supplementAdherence  = c.supplementAdherence
        sessionRPEs          = c.sessionRPEs
        photoEntries         = c.photoEntries
        moodEntries          = c.moodEntries
        healthSnapshots      = c.healthSnapshots
        userProfile          = c.userProfile
        travelModeUntil      = c.travelModeUntil
        autoregEnabled       = c.autoregEnabled
        onboardingCompleted  = c.onboardingCompleted
        activeSupplementIDs  = c.activeSupplementIDs
        scheduleWeek         = c.currentWeek
    }

    private func applyV2Container(_ c: PersistenceContainer) {
        currentWeek       = c.currentWeek
        currentDayIndex   = c.currentDayIndex
        whoopToday        = c.whoopToday
        bodyweightLog     = c.bodyweightLog
        workoutLogs       = c.workoutLogs
        prLog             = c.prLog
        swappedExercises  = c.swappedExercises
        userRecipes       = c.userRecipes
        mobilityCompleted = c.mobilityCompleted
        scheduleWeek      = c.currentWeek
        // v3-only fields use their declared defaults (empty arrays, UserProfile(), etc.)
    }

    // MARK: - Helpers

    /// Instance method — used throughout the file and existing views.
    func dateString(from date: Date) -> String {
        Self.sharedDateString(from: date)
    }

    /// Static version so HealthKitManager and other non-AppState types can produce
    /// date strings in the same locale-short format without holding an AppState ref.
    static func sharedDateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }

    // MARK: - Wave 2A Helpers

    /// Returns the most recent SetLog for the given exercise name across all workoutLogs.
    /// Used by SetLogRow to populate "Prev: W×R" in the logging UI.
    func prevSetForExercise(_ name: String) -> SetLog? {
        // workoutLogs is stored oldest-first; iterate reversed for most-recent first
        for log in workoutLogs.reversed() {
            if let ex = log.exercises.first(where: { $0.name == name }),
               let lastSet = ex.sets.last {
                return lastSet
            }
        }
        return nil
    }

    /// Suggests next-session weight based on last session's avgRIR vs target.
    /// Returns nil when autoregEnabled is false, or when there's no prior log data.
    func suggestedNextWeight(forExercise name: String, targetRIRString: String) -> Double? {
        guard autoregEnabled else { return nil }
        guard let targetRIR = Autoregulation.parseTargetRIR(targetRIRString) else { return nil }

        // Find the most recent workout log containing this exercise
        for log in workoutLogs.reversed() {
            if let ex = log.exercises.first(where: { $0.name == name }) {
                guard let avgRIR = ex.avgRIR,
                      let lastWeight = ex.sets.compactMap({ Double($0.weight) }).last,
                      lastWeight > 0 else { continue }
                return Autoregulation.nextWeight(
                    lastWeight: lastWeight,
                    avgRIR: avgRIR,
                    targetRIR: targetRIR
                )
            }
        }
        return nil
    }

    /// Weekly supplement compliance for the user's active supplement stack.
    /// Returns a value in [0, 1]: 1.0 = all active supplements taken every day this week.
    var weeklySupplementCompliance: Double {
        // Use the active set rather than a hard-coded tier filter so the compliance
        // percentage reflects the stack the user has actually committed to.
        let active = SupplementList.all.filter { activeSupplementIDs.contains($0.id) }
        let tier12 = active.isEmpty ? SupplementList.all.filter { $0.tier <= 2 } : active
        guard !tier12.isEmpty else { return 0 }

        // Build the set of dates for the current calendar week (Mon–today)
        let calendar = Calendar.current
        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) else { return 0 }

        var dates: [String] = []
        var d = weekStart
        let today = calendar.startOfDay(for: Date())
        while d <= today {
            dates.append(Self.sharedDateString(from: d))
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? d.addingTimeInterval(86_400)
        }

        guard !dates.isEmpty else { return 0 }
        let total = Double(tier12.count * dates.count)
        let taken = supplementAdherence.filter { entry in
            entry.taken && dates.contains(entry.date) &&
            tier12.contains(where: { $0.id == entry.supplementId })
        }.count
        return Double(taken) / total
    }

    // MARK: - Hexagon Math

    /// Linear interpolation between a sorted set of (x, y) anchor points.
    /// Clamps to the first and last y-value outside the defined range.
    private func linearInterpolate(x: Double, points: [(Double, Double)]) -> Double {
        guard points.count >= 2 else { return points.first?.1 ?? 0 }
        if x <= points.first!.0 { return points.first!.1 }
        if x >= points.last!.0  { return points.last!.1  }
        for i in 0..<(points.count - 1) {
            let (x0, y0) = points[i]
            let (x1, y1) = points[i + 1]
            if x >= x0 && x <= x1 {
                let t = (x - x0) / (x1 - x0)
                return y0 + t * (y1 - y0)
            }
        }
        return points.last!.1
    }
}

// MARK: - Codable Containers

// MARK: v2 Container (kept intact for migration reads)
/// v2 container is retained read-only. AppState.load() decodes this when no v3
/// blob is present, then migrates forward. Never write to this format again.
private struct PersistenceContainer: Codable {
    var currentWeek: Int
    var currentDayIndex: Int
    var whoopToday: WhoopStatus?
    var bodyweightLog: [BodyweightEntry]
    var workoutLogs: [WorkoutLog]
    var prLog: [String: Double]
    var swappedExercises: [String: String]
    var userRecipes: [UserRecipe]
    var mobilityCompleted: [String: Bool]

    // Custom decode so old blobs without v2 keys decode gracefully
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentWeek       = try c.decode(Int.self,                forKey: .currentWeek)
        currentDayIndex   = try c.decode(Int.self,                forKey: .currentDayIndex)
        whoopToday        = try c.decodeIfPresent(WhoopStatus.self, forKey: .whoopToday)
        bodyweightLog     = try c.decode([BodyweightEntry].self,   forKey: .bodyweightLog)
        workoutLogs       = try c.decode([WorkoutLog].self,        forKey: .workoutLogs)
        prLog             = try c.decode([String: Double].self,    forKey: .prLog)
        swappedExercises  = (try? c.decode([String: String].self,  forKey: .swappedExercises)) ?? [:]
        userRecipes       = (try? c.decode([UserRecipe].self,      forKey: .userRecipes))       ?? []
        mobilityCompleted = (try? c.decode([String: Bool].self,    forKey: .mobilityCompleted)) ?? [:]
    }
}

// MARK: v3 Container
private struct PersistenceContainerV3: Codable {
    // --- v1 / v2 fields ---
    var currentWeek: Int
    var currentDayIndex: Int
    var whoopToday: WhoopStatus?
    var bodyweightLog: [BodyweightEntry]
    var workoutLogs: [WorkoutLog]
    var prLog: [String: Double]
    var swappedExercises: [String: String]
    var userRecipes: [UserRecipe]
    var mobilityCompleted: [String: Bool]

    // --- v3 new fields ---
    var assessmentHistory: [AssessmentBaseline]
    var hexagonHistory: [HexagonScore]
    var bloodworkHistory: [BloodworkEntry]
    var supplementAdherence: [SupplementAdherence]
    var sessionRPEs: [SessionRPE]
    var photoEntries: [PhotoEntry]
    var moodEntries: [MoodEntry]
    var healthSnapshots: [HealthSnapshot]
    var userProfile: UserProfile
    var travelModeUntil: Date?
    var autoregEnabled: Bool
    var onboardingCompleted: Bool

    // --- Wave 3 additions ---
    /// Encoded as a JSON array of Int; decoded with decodeIfPresent so Wave 2
    /// blobs (which don't have this key) fall back to the Tier 1 default set.
    var activeSupplementIDs: Set<Int>

    // Custom decode with decodeIfPresent for every v3 field so that a v2 blob
    // accidentally decoded here still produces valid defaults rather than a throw.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentWeek       = try c.decode(Int.self,                forKey: .currentWeek)
        currentDayIndex   = try c.decode(Int.self,                forKey: .currentDayIndex)
        whoopToday        = try c.decodeIfPresent(WhoopStatus.self, forKey: .whoopToday)
        bodyweightLog     = try c.decode([BodyweightEntry].self,   forKey: .bodyweightLog)
        workoutLogs       = try c.decode([WorkoutLog].self,        forKey: .workoutLogs)
        prLog             = try c.decode([String: Double].self,    forKey: .prLog)
        swappedExercises  = (try? c.decode([String: String].self,  forKey: .swappedExercises)) ?? [:]
        userRecipes       = (try? c.decode([UserRecipe].self,      forKey: .userRecipes))       ?? []
        mobilityCompleted = (try? c.decode([String: Bool].self,    forKey: .mobilityCompleted)) ?? [:]

        assessmentHistory   = (try? c.decode([AssessmentBaseline].self,   forKey: .assessmentHistory))  ?? []
        hexagonHistory      = (try? c.decode([HexagonScore].self,         forKey: .hexagonHistory))      ?? []
        bloodworkHistory    = (try? c.decode([BloodworkEntry].self,       forKey: .bloodworkHistory))    ?? []
        supplementAdherence = (try? c.decode([SupplementAdherence].self,  forKey: .supplementAdherence)) ?? []
        sessionRPEs         = (try? c.decode([SessionRPE].self,           forKey: .sessionRPEs))         ?? []
        photoEntries        = (try? c.decode([PhotoEntry].self,           forKey: .photoEntries))        ?? []
        moodEntries         = (try? c.decode([MoodEntry].self,            forKey: .moodEntries))         ?? []
        healthSnapshots     = (try? c.decode([HealthSnapshot].self,       forKey: .healthSnapshots))     ?? []
        userProfile         = (try? c.decode(UserProfile.self,            forKey: .userProfile))         ?? UserProfile(sexMale: true)
        travelModeUntil     = try? c.decodeIfPresent(Date.self,           forKey: .travelModeUntil)
        autoregEnabled      = (try? c.decode(Bool.self,                   forKey: .autoregEnabled))      ?? true
        onboardingCompleted = (try? c.decode(Bool.self,                   forKey: .onboardingCompleted)) ?? false
        // Wave 3: default to Tier 1 IDs when decoding a pre-Wave-3 blob
        let defaultTier1 = Set(SupplementList.all.filter { $0.tier == 1 }.map(\.id))
        activeSupplementIDs = (try? c.decodeIfPresent(Set<Int>.self, forKey: .activeSupplementIDs)) ?? defaultTier1
    }

    // Memberwise init used by AppState.save()
    init(
        currentWeek: Int, currentDayIndex: Int, whoopToday: WhoopStatus?,
        bodyweightLog: [BodyweightEntry], workoutLogs: [WorkoutLog], prLog: [String: Double],
        swappedExercises: [String: String], userRecipes: [UserRecipe], mobilityCompleted: [String: Bool],
        assessmentHistory: [AssessmentBaseline], hexagonHistory: [HexagonScore],
        bloodworkHistory: [BloodworkEntry], supplementAdherence: [SupplementAdherence],
        sessionRPEs: [SessionRPE], photoEntries: [PhotoEntry], moodEntries: [MoodEntry],
        healthSnapshots: [HealthSnapshot], userProfile: UserProfile,
        travelModeUntil: Date?, autoregEnabled: Bool, onboardingCompleted: Bool,
        activeSupplementIDs: Set<Int>
    ) {
        self.currentWeek         = currentWeek
        self.currentDayIndex     = currentDayIndex
        self.whoopToday          = whoopToday
        self.bodyweightLog       = bodyweightLog
        self.workoutLogs         = workoutLogs
        self.prLog               = prLog
        self.swappedExercises    = swappedExercises
        self.userRecipes         = userRecipes
        self.mobilityCompleted   = mobilityCompleted
        self.assessmentHistory   = assessmentHistory
        self.hexagonHistory      = hexagonHistory
        self.bloodworkHistory    = bloodworkHistory
        self.supplementAdherence = supplementAdherence
        self.sessionRPEs         = sessionRPEs
        self.photoEntries        = photoEntries
        self.moodEntries         = moodEntries
        self.healthSnapshots     = healthSnapshots
        self.userProfile         = userProfile
        self.travelModeUntil     = travelModeUntil
        self.autoregEnabled      = autoregEnabled
        self.onboardingCompleted = onboardingCompleted
        self.activeSupplementIDs = activeSupplementIDs
    }
}

/// Legacy v1 container — only the original fields needed for migration.
private struct LegacyPersistenceContainer: Codable {
    var currentWeek: Int
    var currentDayIndex: Int
    var whoopToday: WhoopStatus?
    var bodyweightLog: [BodyweightEntry]
    var workoutLogs: [WorkoutLog]
    var prLog: [String: Double]
}

// MARK: - Double Clamp Helper
private extension Double {
    /// Clamps the value to [lo, hi]. Private to this file — Wave 2 can promote to
    /// a shared extension if needed by multiple targets.
    func clamped(_ lo: Double, _ hi: Double) -> Double {
        Swift.min(Swift.max(self, lo), hi)
    }
}

struct ExportContainer: Codable {
    var currentWeek: Int
    var bodyweightLog: [BodyweightEntry]
    var workoutLogs: [WorkoutLog]
    var prLog: [String: Double]
}

// MARK: - Tab enum
enum Tab: String, CaseIterable {
    case today    = "today"
    case schedule = "schedule"
    case log      = "log"
    case stats    = "stats"
    case plan     = "plan"

    var label: String { rawValue.uppercased() }

    var systemImage: String {
        switch self {
        case .today:    return "bolt.circle"
        case .schedule: return "calendar"
        case .log:      return "plus.circle"
        case .stats:    return "chart.line.uptrend.xyaxis"
        case .plan:     return "list.bullet"
        }
    }
}
