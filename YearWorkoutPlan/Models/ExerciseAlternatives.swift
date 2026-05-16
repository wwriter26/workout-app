import Foundation

// MARK: - Muscle Group
enum MuscleGroup: String, Codable, CaseIterable {
    case back, chest, frontDelts, sideDelts, rearDelts
    case biceps, triceps, quads, hamstrings, glutes, calves, core, cardio, mobility
}

// MARK: - Exercise Tier
enum ExerciseTier: String, Codable {
    case sPlus = "S+"
    case s     = "S"
    case aPlus = "A+"
    case a     = "A"
}

// MARK: - Alternative Exercise
struct AltExercise: Identifiable, Hashable, Codable {
    // id is derived from name — two exercises with the same name are identical.
    var id: String { name }
    let name: String
    let tier: ExerciseTier
}

// MARK: - Exercise Alternatives Library
enum ExerciseAlternatives {

    // MARK: Library
    static let library: [MuscleGroup: [AltExercise]] = [
        .back: [
            AltExercise(name: "Chest-Supported Rows",                     tier: .sPlus),
            AltExercise(name: "Wide-Grip Lat Pulldowns",                   tier: .s),
            AltExercise(name: "Neutral-Grip Lat Pulldowns",                tier: .s),
            AltExercise(name: "One-Arm Lat Pulldowns",                     tier: .s),
            AltExercise(name: "Meadows Rows",                              tier: .s),
            AltExercise(name: "Horizontal Cable Rows",                     tier: .s),
            AltExercise(name: "Wide-Grip Cable Rows",                      tier: .s),
            AltExercise(name: "Face Pulls",                                tier: .s),
            AltExercise(name: "Lat Pullovers",                             tier: .s),
            AltExercise(name: "Wide-Grip Pull-Ups",                        tier: .a),
            AltExercise(name: "Neutral-Grip Pull-Ups",                     tier: .a),
            AltExercise(name: "Cross-Body One-Arm Lat Pulldowns",          tier: .a),
            AltExercise(name: "Deficit Pendlay Rows",                      tier: .a),
            AltExercise(name: "One-Arm DB Rows",                           tier: .a),
            AltExercise(name: "Kroc Rows",                                 tier: .a),
            AltExercise(name: "Cable Lat Prayers",                         tier: .a),
            AltExercise(name: "DB Pullovers",                              tier: .a),
        ],
        .chest: [
            AltExercise(name: "Machine Chest Press",                       tier: .sPlus),
            AltExercise(name: "Deficit Push-Ups",                          tier: .s),
            AltExercise(name: "Seated Cable Flyes",                        tier: .s),
            AltExercise(name: "Bench Press",                               tier: .a),
            AltExercise(name: "Incline Bench Press",                       tier: .a),
            AltExercise(name: "Flat Dumbbell Press",                       tier: .a),
            AltExercise(name: "Incline Dumbbell Press",                    tier: .a),
            AltExercise(name: "Dips",                                      tier: .a),
            AltExercise(name: "Dumbbell Guillotine Press",                 tier: .a),
            AltExercise(name: "Smith Machine Bench Press",                 tier: .a),
            AltExercise(name: "Incline Smith Machine Bench Press",         tier: .a),
            AltExercise(name: "Cable Crossovers",                          tier: .a),
            AltExercise(name: "Pec Deck",                                  tier: .a),
            AltExercise(name: "Dumbbell Flye",                             tier: .a),
            AltExercise(name: "Cable Press-Around",                        tier: .a),
        ],
        .frontDelts: [
            AltExercise(name: "Machine Shoulder Press",                    tier: .sPlus),
        ],
        .sideDelts: [
            AltExercise(name: "Cable Lateral Raises",                      tier: .s),
            AltExercise(name: "Behind-the-Back Cuffed Cable Lateral Raises", tier: .s),
            AltExercise(name: "Cable Y Raises",                            tier: .s),
            AltExercise(name: "Atlantis Standing Machine Lateral Raises",  tier: .aPlus),
            AltExercise(name: "Lean-In DB Lateral Raises",                 tier: .a),
            AltExercise(name: "Arnold Style Side-Lying DB Raises",         tier: .a),
            AltExercise(name: "Seated DB Overhead Press",                  tier: .a),
        ],
        .rearDelts: [
            AltExercise(name: "Reverse Pec Deck",                          tier: .s),
            AltExercise(name: "Reverse Cable Crossovers",                  tier: .s),
            AltExercise(name: "Rope Face Pulls",                           tier: .a),
        ],
        .biceps: [
            AltExercise(name: "Face-Away Bayesian Curls",                  tier: .sPlus),
            AltExercise(name: "Dumbbell Preacher Curls",                   tier: .s),
            AltExercise(name: "Machine Preacher Curls",                    tier: .s),
            AltExercise(name: "Preacher Hammer Curls",                     tier: .s),
            AltExercise(name: "EZ Bar Curls",                              tier: .a),
            AltExercise(name: "Standing Dumbbell Curls",                   tier: .a),
            AltExercise(name: "Incline Curls",                             tier: .a),
            AltExercise(name: "Lying Dumbbell Curls",                      tier: .a),
            AltExercise(name: "Modified 21s",                              tier: .a),
            AltExercise(name: "Standing Cable Curls",                      tier: .a),
            AltExercise(name: "Bayesian Cable Curl Variation",             tier: .a),
            AltExercise(name: "Cheat Curls",                               tier: .a),
            AltExercise(name: "Strict Curls",                              tier: .a),
            AltExercise(name: "Hammer Curls",                              tier: .a),
            AltExercise(name: "Inverse Zottman Curls",                     tier: .a),
        ],
        .triceps: [
            AltExercise(name: "Overhead Cable Triceps Extensions (Bar)",   tier: .sPlus),
            AltExercise(name: "Barbell Skullcrushers",                     tier: .s),
            AltExercise(name: "Rope Overhead Extensions",                  tier: .s),
            AltExercise(name: "Cable Kickbacks",                           tier: .s),
            AltExercise(name: "Cross-Body Extensions",                     tier: .s),
            AltExercise(name: "Katana Extensions",                         tier: .s),
            AltExercise(name: "Triceps Pressdown (Bar)",                   tier: .a),
            AltExercise(name: "Overhead Cable Triceps Extensions (Rope)",  tier: .a),
            AltExercise(name: "1-Arm Dumbbell Overhead Extensions",        tier: .a),
            AltExercise(name: "Dumbbell Skullcrushers",                    tier: .a),
            AltExercise(name: "Smith Machine JM Press",                    tier: .a),
            AltExercise(name: "Close-Grip Bench Press",                    tier: .a),
        ],
        .quads: [
            AltExercise(name: "Hack Squats",                               tier: .sPlus),
            AltExercise(name: "Barbell Back Squats",                       tier: .s),
            AltExercise(name: "Pendulum Squats",                           tier: .s),
            AltExercise(name: "Smith Machine Squats",                      tier: .s),
            AltExercise(name: "Bulgarian Split Squats",                    tier: .s),
            AltExercise(name: "Barbell Front Squats",                      tier: .a),
            AltExercise(name: "Low-Bar Squats",                            tier: .a),
            AltExercise(name: "45-Degree Leg Press",                       tier: .a),
            AltExercise(name: "Leg Extensions",                            tier: .a),
            AltExercise(name: "Reverse Nordics",                           tier: .a),
        ],
        .hamstrings: [
            AltExercise(name: "Seated Hamstring Curls",                    tier: .s),
            AltExercise(name: "Lying Leg Curls",                           tier: .a),
            AltExercise(name: "Nordic Hamstring Curls",                    tier: .a),
            AltExercise(name: "Glute-Ham Raises",                          tier: .a),
            AltExercise(name: "Romanian Deadlifts",                        tier: .a),
            AltExercise(name: "Good Mornings",                             tier: .a),
            AltExercise(name: "Stiff-Leg Deadlifts",                       tier: .a),
        ],
        .glutes: [
            AltExercise(name: "Walking Lunges",                            tier: .sPlus),
            AltExercise(name: "Machine Hip Abductions",                    tier: .s),
            AltExercise(name: "45-Degree Back Extensions",                 tier: .s),
            AltExercise(name: "Smith Machine Lunges (Front Foot Elevated)", tier: .s),
            AltExercise(name: "Machine Hip Thrusts",                       tier: .a),
            AltExercise(name: "Single-Leg Dumbbell Hip Thrusts",           tier: .a),
            AltExercise(name: "Barbell Back Squats",                       tier: .a),
            AltExercise(name: "Smith Machine Squats",                      tier: .a),
            AltExercise(name: "Bulgarian Split Squats",                    tier: .a),
            AltExercise(name: "Kickbacks",                                 tier: .a),
            AltExercise(name: "Step-Ups",                                  tier: .a),
            AltExercise(name: "Romanian Deadlifts",                        tier: .a),
            AltExercise(name: "Smith Machine Lunges",                      tier: .a),
        ],
        .calves: [
            AltExercise(name: "Standing Calf Raise",                       tier: .s),
            AltExercise(name: "Seated Calf Raise",                         tier: .s),
            AltExercise(name: "Smith Machine Calf Raise",                  tier: .a),
            AltExercise(name: "Single-Leg DB Calf Raise",                  tier: .a),
        ],
        .core: [
            AltExercise(name: "Pallof Press",                              tier: .s),
            AltExercise(name: "Cable Crunch",                              tier: .s),
            AltExercise(name: "Hanging Leg Raise",                         tier: .s),
            AltExercise(name: "Ab Wheel Rollout",                          tier: .a),
            AltExercise(name: "Plank → Side Plank",                        tier: .a),
            AltExercise(name: "Dead Bug",                                   tier: .a),
            AltExercise(name: "Farmer's Carry",                            tier: .a),
        ],
        .cardio: [
            AltExercise(name: "Treadmill",                                 tier: .s),
            AltExercise(name: "Air Bike",                                  tier: .s),
            AltExercise(name: "Rower",                                     tier: .s),
            AltExercise(name: "Stair Climber",                             tier: .a),
            AltExercise(name: "Elliptical",                                tier: .a),
            AltExercise(name: "Outdoor Run",                               tier: .a),
            AltExercise(name: "Hill Repeats",                              tier: .a),
        ],
        // Mobility uses MobilityCatalog (see MobilityCatalog.swift)
        .mobility: [],
    ]

    // MARK: Classifier
    /// Maps a scheduled exercise name to its primary muscle group via keyword matching.
    /// Falls back to .core if no keyword matches — every exercise should have some alternative.
    static func classify(_ exerciseName: String) -> MuscleGroup {
        let n = exerciseName.lowercased()

        // Cardio / conditioning
        if n.contains("zone 2") || n.contains("z2") || n.contains("cardio") ||
           n.contains("interval") || n.contains("sprint") || n.contains("run") ||
           n.contains("4×4") || n.contains("threshold") || n.contains("warm-up") ||
           n.contains("cool-down") || n.contains("rower") || n.contains("bike") ||
           n.contains("air bike") || n.contains("broad jump") || n.contains("box jump") ||
           n.contains("plyo") { return .cardio }

        // Mobility
        if n.contains("mobility") || n.contains("yoga") || n.contains("stretch") ||
           n.contains("foam roll") { return .mobility }

        // Hamstrings — check before "deadlift" generic
        if n.contains("rdl") || n.contains("romanian") || n.contains("stiff-leg") ||
           n.contains("leg curl") || n.contains("lying leg") || n.contains("nordic") ||
           n.contains("glute-ham") || n.contains("good morning") || n.contains("hamstring") { return .hamstrings }

        // Glutes
        if n.contains("hip thrust") || n.contains("glute") || n.contains("kickback") ||
           n.contains("hip abduct") || n.contains("back extension") { return .glutes }

        // Quads / lower body compound
        if n.contains("squat") || n.contains("leg press") || n.contains("lunge") ||
           n.contains("split squat") || n.contains("hack squat") || n.contains("front squat") ||
           n.contains("deadlift") || n.contains("trap bar") || n.contains("leg extension") ||
           n.contains("pendulum squat") || n.contains("reverse nordic") { return .quads }

        // Calves
        if n.contains("calf") || n.contains("calves") { return .calves }

        // Rear delts
        if n.contains("face pull") || n.contains("rear delt") || n.contains("reverse fly") ||
           n.contains("reverse pec") || n.contains("band pull-apart") { return .rearDelts }

        // Side delts
        if n.contains("lateral raise") || n.contains("lateral") && n.contains("raise") ||
           n.contains("side raise") || n.contains("cable y raise") { return .sideDelts }

        // Front delts / shoulder press
        if n.contains("overhead press") || n.contains("ohp") || n.contains("push press") ||
           n.contains("shoulder press") || n.contains("arnold press") ||
           n.contains("seated db ohp") || n.contains("seated ohp") { return .frontDelts }

        // Chest
        if n.contains("bench press") || n.contains("bench") || n.contains("push-up") ||
           n.contains("push up") || n.contains("chest press") || n.contains("cable fly") ||
           n.contains("chest fly") || n.contains("pec deck") || n.contains("dip") ||
           n.contains("incline db press") || n.contains("incline barbell") ||
           n.contains("cable crossover") { return .chest }

        // Back
        if n.contains("pull-up") || n.contains("pullup") || n.contains("pull up") ||
           n.contains("pulldown") || n.contains("pull down") || n.contains("row") ||
           n.contains("lat pullover") || n.contains("pullover") || n.contains("deadlift") ||
           n.contains("pendlay") || n.contains("barbell row") { return .back }

        // Biceps
        if n.contains("curl") || n.contains("bicep") || n.contains("hammer curl") ||
           n.contains("ez-bar") || n.contains("ez bar") || n.contains("preacher") ||
           n.contains("bayesian") { return .biceps }

        // Triceps
        if n.contains("tricep") || n.contains("skull") || n.contains("pushdown") ||
           n.contains("pressdown") || n.contains("overhead ext") || n.contains("triceps ext") ||
           n.contains("katana") || n.contains("jm press") || n.contains("close-grip") ||
           n.contains("rope push") || n.contains("cable kick") { return .triceps }

        // Core
        if n.contains("plank") || n.contains("pallof") || n.contains("carry") ||
           n.contains("dead bug") || n.contains("ab wheel") || n.contains("core") ||
           n.contains("hanging leg") { return .core }

        // Default fallback
        return .core
    }

    /// Returns the best 3–6 alternatives for a given exercise, sorted S+ → S → A+ → A.
    /// Excludes the exercise itself by name (case-insensitive).
    static func alternatives(for exerciseName: String) -> [AltExercise] {
        let group = classify(exerciseName)
        let pool = library[group] ?? []
        let filtered = pool.filter { $0.name.lowercased() != exerciseName.lowercased() }
        // Tier ordering: S+ first, then S, A+, A
        let ordered = filtered.sorted { a, b in tierRank(a.tier) < tierRank(b.tier) }
        // Return up to 6 alternatives; at least 3 if available
        return Array(ordered.prefix(6))
    }

    private static func tierRank(_ tier: ExerciseTier) -> Int {
        switch tier {
        case .sPlus: return 0
        case .s:     return 1
        case .aPlus: return 2
        case .a:     return 3
        }
    }
}
