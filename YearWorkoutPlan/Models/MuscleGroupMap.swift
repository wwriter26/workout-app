import Foundation

// MARK: - MuscleGroup Extensions (Wave 2B)
//
// MuscleGroup is declared in ExerciseAlternatives.swift. This file adds:
//  1. volumeThresholds — MEV/MAV/MRV sets-per-week (Israetel guidelines)
//  2. isFrontBody      — layout column for the heatmap card
//  3. displayName      — human-readable label (already provided by rawValue.capitalized
//     for simple cases; override for multi-word groups)
//
// Design note: The existing enum splits shoulders into frontDelts/sideDelts/rearDelts.
// For the heatmap we group all three under a single "Shoulders" bucket using
// MuscleGroupMap.heatmapGroups(for:) which maps them to a [HeatmapGroup]. This avoids
// breaking the existing ExerciseAlternatives library, which depends on the original cases.

extension MuscleGroup {

    // MARK: Display Name
    var displayName: String {
        switch self {
        case .frontDelts:  return "Front Delts"
        case .sideDelts:   return "Side Delts"
        case .rearDelts:   return "Rear Delts"
        case .biceps:      return "Biceps"
        case .triceps:     return "Triceps"
        case .quads:       return "Quads"
        case .hamstrings:  return "Hamstrings"
        case .glutes:      return "Glutes"
        case .calves:      return "Calves"
        case .core:        return "Core"
        case .chest:       return "Chest"
        case .back:        return "Back"
        case .cardio:      return "Cardio"
        case .mobility:    return "Mobility"
        }
    }

    // MARK: Volume Thresholds (sets / week)
    // Based on Renaissance Periodization MEV/MAV/MRV recommendations.
    var volumeThresholds: (mev: Int, mav: Int, mrv: Int) {
        switch self {
        case .chest, .back:
            return (mev: 10, mav: 16, mrv: 22)
        case .frontDelts, .sideDelts, .rearDelts:
            return (mev: 8,  mav: 14, mrv: 20)
        case .biceps, .triceps:
            return (mev: 6,  mav: 12, mrv: 18)
        case .quads, .hamstrings, .glutes:
            return (mev: 8,  mav: 14, mrv: 20)
        case .calves:
            return (mev: 8,  mav: 14, mrv: 20)
        case .core:
            return (mev: 0,  mav: 10, mrv: 20)
        case .cardio, .mobility:
            return (mev: 0,  mav: 0,  mrv: 0)
        }
    }

    // MARK: Front / Back Body Column
    var isFrontBody: Bool {
        switch self {
        case .chest, .frontDelts, .sideDelts, .biceps, .quads, .core: return true
        case .back, .rearDelts, .triceps, .hamstrings, .glutes, .calves: return false
        case .cardio, .mobility: return true  // arbitrary — these won't appear in the heatmap
        }
    }

    // MARK: Heatmap-eligible groups (excludes cardio/mobility which have no volume thresholds)
    static var heatmapGroups: [MuscleGroup] {
        allCases.filter { $0 != .cardio && $0 != .mobility }
    }
}

// MARK: - Muscle Group Map

enum MuscleGroupMap {

    /// Maps an exercise name to the primary MuscleGroup cases it targets.
    /// Returns an empty array for cardio/unknown exercises.
    /// Shoulder-family exercises map to frontDelts, sideDelts, or rearDelts as appropriate.
    static func groups(for exerciseName: String) -> [MuscleGroup] {
        let name = exerciseName.lowercased()
        var out: [MuscleGroup] = []

        // Chest — push patterns, pec isolation
        if name.contains("bench") || name.contains("dip") || name.contains("incline")
            || name.contains("fly") || name.contains("push press") {
            out.append(.chest)
        }

        // Back — rows, pull patterns, face pulls
        if name.contains("row") || name.contains("pull-up") || name.contains("pulldown")
            || name.contains("pendlay") || name.contains("face pull") {
            out.append(.back)
        }

        // Front delts — overhead press patterns (all three delt heads receive some stimulus;
        // OHP biases front/side more than rear)
        if name.contains("ohp") || name.contains("overhead press") || name.contains("arnold")
            || name.contains("push press") || name.contains("shoulder press") || name.contains("military") {
            out.append(.frontDelts)
        }

        // Side delts — isolation
        if name.contains("lateral raise") || name.contains("side raise") {
            out.append(.sideDelts)
        }

        // Rear delts — isolation and row accessory
        if name.contains("rear delt") || name.contains("reverse fly") || name.contains("face pull") {
            out.append(.rearDelts)
        }

        // Biceps — all curl variants
        if name.contains("curl") {
            out.append(.biceps)
        }

        // Triceps — extensions, close-grip, pushdowns
        if name.contains("triceps") || name.contains("skull crusher") || name.contains("close-grip")
            || name.contains("pushdown") {
            out.append(.triceps)
        }

        // Quads — knee-dominant lower body
        if name.contains("squat") || name.contains("leg press") || name.contains("front squat")
            || name.contains("lunge") || name.contains("hack squat") || name.contains("bulgarian") {
            out.append(.quads)
        }

        // Hamstrings — hip-dominant and isolation
        if name.contains("rdl") || name.contains("romanian") || name.contains("deadlift")
            || name.contains("leg curl") || name.contains("glute-ham") || name.contains("nordic") {
            out.append(.hamstrings)
        }

        // Glutes — hip thrust, bridges, kickbacks
        if name.contains("hip thrust") || name.contains("glute bridge") || name.contains("glute")
            || name.contains("kickback") {
            out.append(.glutes)
        }

        // Calves
        if name.contains("calf") {
            out.append(.calves)
        }

        // Core — anti-rotation and flexion
        if name.contains("plank") || name.contains("pallof") || name.contains("dead bug")
            || name.contains("ab") || name.contains("crunch") || name.contains("core") {
            out.append(.core)
        }

        return out
    }
}
