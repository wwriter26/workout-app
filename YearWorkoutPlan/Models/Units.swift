import Foundation

// MARK: - WeightUnit
/// Global preference for weight display + input. Canonical storage is always lbs;
/// conversions happen at the view boundary so existing data needs no migration.
enum WeightUnit: String, Codable, CaseIterable {
    case lbs
    case kg

    var label: String {
        switch self {
        case .lbs: return "lbs"
        case .kg:  return "kg"
        }
    }

    /// Standard plate set on offer in this unit (largest first).
    var defaultPlates: [Double] {
        switch self {
        case .lbs: return [45, 35, 25, 10, 5, 2.5, 1.25]
        case .kg:  return [25, 20, 15, 10, 5, 2.5, 1.25]
        }
    }

    /// Standard barbell weight in this unit.
    var defaultBarbell: Double {
        switch self {
        case .lbs: return 45
        case .kg:  return 20
        }
    }
}

// MARK: - Conversion
enum WeightConverter {
    static let lbsPerKg: Double = 2.2046226218

    /// Pounds → kilograms.
    static func lbsToKg(_ lbs: Double) -> Double { lbs / lbsPerKg }
    /// Kilograms → pounds.
    static func kgToLbs(_ kg: Double) -> Double { kg * lbsPerKg }

    /// Convert canonical lbs to the user's preferred unit.
    static func fromCanonical(_ lbs: Double, to unit: WeightUnit) -> Double {
        unit == .lbs ? lbs : lbsToKg(lbs)
    }

    /// Convert from the user's preferred unit back to canonical lbs.
    static func toCanonical(_ value: Double, from unit: WeightUnit) -> Double {
        unit == .lbs ? value : kgToLbs(value)
    }
}

// MARK: - Formatter
enum WeightFormat {
    /// Format a canonical-lbs value for display in the user's preferred unit.
    /// Examples: 185.0 lbs in .lbs → "185" / in .kg → "84"
    ///           185.5 lbs in .lbs → "185.5" / in .kg → "84.1"
    static func display(_ lbs: Double, unit: WeightUnit, decimals: Int = 1, includeUnit: Bool = true) -> String {
        let value = WeightConverter.fromCanonical(lbs, to: unit)
        // Hide decimal when whole-number to keep tile UI tight (e.g. "225 lbs" not "225.0 lbs")
        let number: String
        if value == value.rounded() {
            number = String(Int(value.rounded()))
        } else {
            number = String(format: "%.\(decimals)f", value)
        }
        return includeUnit ? "\(number) \(unit.label)" : number
    }

    /// Parse a user-typed string in the given unit, returning canonical lbs.
    /// Accepts comma decimal separator (European locales) and trims whitespace.
    static func parseToCanonical(_ string: String, unit: WeightUnit) -> Double? {
        let cleaned = string.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned), v > 0 else { return nil }
        return WeightConverter.toCanonical(v, from: unit)
    }

    /// Round a value (in the user's unit) to the nearest valid plate increment.
    /// Lb mode → nearest 2.5; kg mode → nearest 1.0 (since 2.5kg plates exist but
    /// 1kg precision matches kg-gym practice).
    static func roundToIncrement(_ value: Double, unit: WeightUnit) -> Double {
        let inc: Double = unit == .lbs ? 2.5 : 1.0
        return (value / inc).rounded() * inc
    }
}
