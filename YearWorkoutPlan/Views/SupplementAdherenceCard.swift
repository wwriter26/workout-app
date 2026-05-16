import SwiftUI

// MARK: - Supplement Adherence Card
/// Today's supplement checklist for tier 1–2 (year-round + test-driven) supplements.
/// Reads and writes adherence via AppState to keep persistence consistent.
struct SupplementAdherenceCard: View {
    @Environment(AppState.self) private var state

    // Tier 1–2 supplements only (year-round + test-driven protocols)
    private var supplements: [Supplement] {
        SupplementList.all.filter { $0.tier <= 2 }
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionLabel(text: "Supplements")
                    Spacer()
                    // Weekly compliance percentage
                    let pct = state.weeklySupplementCompliance
                    if pct > 0 {
                        Text("\(Int(pct * 100))% this week")
                            .font(.monoTiny)
                            .foregroundColor(complianceColor(pct))
                    }
                }

                Divider().background(AppColor.border1)

                ForEach(supplements) { supplement in
                    SupplementRow(supplement: supplement)
                }
            }
        }
    }

    private func complianceColor(_ pct: Double) -> Color {
        switch pct {
        case 0.8...: return AppColor.spring
        case 0.6..<0.8: return AppColor.summer
        default:        return AppColor.fall
        }
    }
}

// MARK: - Supplement Row
private struct SupplementRow: View {
    @Environment(AppState.self) private var state
    let supplement: Supplement

    private var isTaken: Bool {
        state.isSupplementTakenToday(supplementId: supplement.id)
    }

    var body: some View {
        Button {
            state.logSupplementAdherence(supplementId: supplement.id, taken: !isTaken)
        } label: {
            HStack(spacing: 10) {
                // Checkbox
                Image(systemName: isTaken ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(isTaken ? AppColor.spring : AppColor.textFaint)

                // Name + dose
                VStack(alignment: .leading, spacing: 2) {
                    Text(supplement.name)
                        .font(.appBody)
                        .foregroundColor(isTaken ? AppColor.textSecondary : AppColor.textMuted)
                        .strikethrough(isTaken, color: AppColor.textFaint)
                    Text("\(supplement.dose) · \(supplement.timing)")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }

                Spacer()

                // Tier badge
                BadgeView(
                    "T\(supplement.tier)",
                    foreground: supplement.tier == 1 ? AppColor.spring : AppColor.summer,
                    background: (supplement.tier == 1 ? AppColor.spring : AppColor.summer).opacity(0.13)
                )
            }
            .animation(.easeInOut(duration: 0.15), value: isTaken)
        }
        .buttonStyle(.plain)
    }
}
