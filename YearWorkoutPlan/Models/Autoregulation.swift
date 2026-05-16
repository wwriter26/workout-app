import Foundation

// MARK: - Autoregulation
/// Pure functions for RPE/RIR-based load management. Stateless enum namespace so
/// callers never need an instance — Autoregulation.nextWeight(...) reads clearly.
enum Autoregulation {

    // MARK: - Load Adjustment

    /// Returns a load multiplier (1.025, 1.0, 0.975, etc.) based on how the
    /// athlete's avg RIR compared with the target.
    ///
    /// Bands (±0.5 dead-zone to prevent oscillation):
    ///   avgRIR ≥ targetRIR + 2   →  +5%
    ///   avgRIR ≥ targetRIR + 1   →  +2.5%
    ///   within ±0.5 of target    →  0%
    ///   avgRIR ≤ targetRIR − 1   →  −2.5%
    ///   avgRIR ≤ targetRIR − 2   →  −5%
    static func loadAdjustment(avgRIR: Double, targetRIR: Double) -> Double {
        let delta = avgRIR - targetRIR
        switch delta {
        case let d where d >= 2.0:   return 1.05
        case let d where d >= 1.0:   return 1.025
        case let d where d <= -2.0:  return 0.95
        case let d where d <= -1.0:  return 0.975
        default:                     return 1.0   // within ±0.5 dead-zone
        }
    }

    /// Calculates the suggested next-session weight, rounded to nearest 2.5 lb.
    /// Rounding to 2.5 lb is standard for barbell increments; the plate calculator
    /// in Wave 2 will further refine using the user's PlateProfile.
    static func nextWeight(lastWeight: Double, avgRIR: Double, targetRIR: Double) -> Double {
        let multiplier = loadAdjustment(avgRIR: avgRIR, targetRIR: targetRIR)
        let raw = lastWeight * multiplier
        // Round to nearest 2.5 lb increment
        return (raw / 2.5).rounded() * 2.5
    }

    // MARK: - Target RIR Parsing

    /// Parses a target RIR string from the Exercise catalogue into a numeric midpoint.
    /// Examples:
    ///   "1–2"  → 1.5   (en-dash range)
    ///   "1-2"  → 1.5   (hyphen range)
    ///   "0–1"  → 0.5
    ///   "2"    → 2.0
    ///   "—"    → nil   (cardio / non-applicable)
    static func parseTargetRIR(_ s: String) -> Double? {
        // Strip whitespace and normalise en-dash / em-dash to hyphen
        let cleaned = s
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\u{2013}", with: "-")  // en-dash
            .replacingOccurrences(of: "\u{2014}", with: "-")  // em-dash

        // Single "—" or "–" placeholder used on cardio rows
        if cleaned == "-" || cleaned.isEmpty { return nil }

        let parts = cleaned.split(separator: "-").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        switch parts.count {
        case 2:  return (parts[0] + parts[1]) / 2.0  // range → midpoint
        case 1:  return parts[0]                      // single value
        default: return nil
        }
    }

    // MARK: - Internal helpers (not exposed; used by SetLog.resolvedRIR)

    /// Extracts the first integer found in a freeform RIR string.
    /// Handles "1–2" → 1, "0" → 0, "2" → 2, "—" → nil.
    static func firstInt(in s: String) -> Int? {
        // Walk characters looking for a digit sequence
        var digits = ""
        for ch in s {
            if ch.isNumber {
                digits.append(ch)
            } else if !digits.isEmpty {
                break  // stop at first non-digit after we've started collecting
            }
        }
        return Int(digits)
    }
}
