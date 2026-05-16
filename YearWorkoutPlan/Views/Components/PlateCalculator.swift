import SwiftUI

// MARK: - Plate Calculator
/// Stateless view that renders a horizontal barbell plate diagram for a given load.
/// Greedy algorithm (largest plate first) mirrors real gym plate selection.
struct PlateCalculator: View {
    let weightLbs: Double
    let barbellLbs: Double
    let availablePlates: [Double]  // sorted descending by caller or here

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
                                PlateRect(weightLbs: plate)
                            }
                        }
                    }
                }
            }

            // Barbell + total weight reminder
            Text("Bar \(Int(barbellLbs)) lb · Total \(Int(weightLbs)) lb")
                .font(.monoTiny)
                .foregroundColor(AppColor.textVeryFaint)
        }
    }

    // MARK: - Greedy plate computation

    /// Returns the ordered list of plate weights (one side) needed to reach the target load.
    /// Unused weight (< 1.25 lb) is silently ignored — no fractional plates.
    private func platesPerSide() -> [Double] {
        let perSide = (weightLbs - barbellLbs) / 2.0
        guard perSide > 0 else { return [] }

        // Sort available plates descending so greedy picks largest first
        let sorted = availablePlates.sorted(by: >)
        var remaining = perSide
        var result: [Double] = []

        for plate in sorted {
            while remaining >= plate - 0.01 {  // 0.01 tolerance for floating point
                result.append(plate)
                remaining -= plate
            }
        }

        return result
    }
}

// MARK: - Plate Rectangle
/// Single colored plate tile. Standard IPF/gym colour conventions.
private struct PlateRect: View {
    let weightLbs: Double

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

    // MARK: Colours (loosely based on IWF/IPF colour convention adapted for lbs)
    private var plateColor: Color {
        switch weightLbs {
        case 45:   return Color(hex: "#DC2626")  // red
        case 35:   return Color(hex: "#2563EB")  // blue
        case 25:   return Color(hex: "#16A34A")  // green
        case 10:   return Color(hex: "#D1D5DB")  // white/light grey
        case 5:    return Color(hex: "#3B82F6")  // lighter blue
        case 2.5:  return Color(hex: "#EF4444")  // lighter red
        case 1.25: return Color(hex: "#9CA3AF")  // chrome / grey
        default:   return Color(hex: "#6B7280")  // unknown — muted grey
        }
    }

    private var plateWidth: CGFloat {
        switch weightLbs {
        case 45:   return 18
        case 35:   return 16
        case 25:   return 14
        case 10:   return 11
        case 5:    return 9
        case 2.5:  return 7
        default:   return 7
        }
    }

    private var plateLabel: String {
        // Show "45", "10", "2.5" etc. without trailing zero for whole numbers
        if weightLbs == weightLbs.rounded() {
            return "\(Int(weightLbs))"
        }
        return String(format: "%.1f", weightLbs)
    }
}
