import SwiftUI

// MARK: - Plate Calculator
/// Stateless view that renders a horizontal barbell plate diagram for a given load.
/// Greedy algorithm (largest plate first) mirrors real gym plate selection.
/// All inputs are in the user's CURRENT unit (lbs or kg) — no conversion done here.
struct PlateCalculator: View {
    let weight: Double
    let barbell: Double
    let availablePlates: [Double]
    let unit: WeightUnit

    var body: some View {
        let stack = platesPerSide()

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Per side:")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textFaint)

                if stack.isEmpty {
                    Text("—")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textDimmed)
                } else {
                    // Render plates as colored rectangles, left to right (largest outermost)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 3) {
                            ForEach(Array(stack.enumerated()), id: \.offset) { _, plate in
                                PlateRect(value: plate, unit: unit)
                            }
                        }
                    }
                }
            }

            // Barbell + total weight reminder
            Text("Bar \(formatted(barbell)) \(unit.label) · Total \(formatted(weight)) \(unit.label)")
                .font(.monoTiny)
                .foregroundColor(AppColor.textVeryFaint)
        }
    }

    // MARK: - Greedy plate computation

    /// Returns the ordered list of plate weights (one side) needed to reach the target load.
    /// Unused weight (< smallest plate) is silently ignored — no fractional plates.
    private func platesPerSide() -> [Double] {
        let perSide = (weight - barbell) / 2.0
        guard perSide > 0 else { return [] }

        let sorted = availablePlates.sorted(by: >)
        var remaining = perSide
        var result: [Double] = []

        for plate in sorted {
            while remaining >= plate - 0.01 {  // floating-point tolerance
                result.append(plate)
                remaining -= plate
            }
        }

        return result
    }

    private func formatted(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v)
    }
}

// MARK: - Plate Rectangle
/// Single colored plate tile. Color conventions:
///   lbs gym plates — IPF-adjacent colors (45 red, 35 blue, 25 green, …)
///   kg gym plates — IWF official competition colors (25 red, 20 blue, 15 yellow, 10 green, 5 white, 2.5 red, 1.25 chrome)
private struct PlateRect: View {
    let value: Double
    let unit: WeightUnit

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 3)
                .fill(plateColor)
                .frame(width: plateWidth, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(plateColor.opacity(0.5), lineWidth: 1)
                )
            Text(plateLabel)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(plateColor.opacity(0.9))
        }
    }

    private var plateColor: Color {
        if unit == .kg {
            // IWF competition color codes for kg plates
            switch value {
            case 25:   return Color(hex: "#DC2626")  // red
            case 20:   return Color(hex: "#2563EB")  // blue
            case 15:   return Color(hex: "#F59E0B")  // yellow
            case 10:   return Color(hex: "#16A34A")  // green
            case 5:    return Color(hex: "#D1D5DB")  // white
            case 2.5:  return Color(hex: "#EF4444")  // red (small)
            case 1.25: return Color(hex: "#9CA3AF")  // chrome
            default:   return Color(hex: "#6B7280")
            }
        } else {
            // Lb plates
            switch value {
            case 45:   return Color(hex: "#DC2626")
            case 35:   return Color(hex: "#2563EB")
            case 25:   return Color(hex: "#16A34A")
            case 10:   return Color(hex: "#D1D5DB")
            case 5:    return Color(hex: "#3B82F6")
            case 2.5:  return Color(hex: "#EF4444")
            case 1.25: return Color(hex: "#9CA3AF")
            default:   return Color(hex: "#6B7280")
            }
        }
    }

    private var plateWidth: CGFloat {
        // Width tracks visual heft of the largest available plate in each unit set
        let max: Double = unit == .kg ? 25 : 45
        let ratio = value / max
        return CGFloat(max * 0.4 * ratio + 8)
    }

    private var plateLabel: String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
