import SwiftUI

// MARK: - Swap Exercise Sheet
/// Presented modally when the user taps the swap icon on an exercise row.
/// Shows 3–6 alternatives grouped by tier, sorted S+ → S → A+ → A.
struct SwapExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss

    let target: SwapTarget
    let seasonColor: Color
    let onSelect: (String, String) -> Void  // (originalName, newName)

    private var alternatives: [AltExercise] {
        ExerciseAlternatives.alternatives(for: target.originalName)
    }

    /// Alternatives grouped by tier label, preserving tier order.
    private var grouped: [(String, [AltExercise])] {
        var result: [(String, [AltExercise])] = []
        var seen: Set<String> = []
        for alt in alternatives {
            let label = alt.tier.rawValue
            if !seen.contains(label) {
                seen.insert(label)
                result.append((label, []))
            }
            if let idx = result.firstIndex(where: { $0.0 == label }) {
                result[idx].1.append(alt)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Context header
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: "Swapping")
                            Text(target.originalName)
                                .font(.appHeading)
                                .foregroundColor(AppColor.textPrimary)
                            Text("Tap an alternative to replace today's exercise only.")
                                .font(.appSmall)
                                .foregroundColor(AppColor.textDimmed)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        if alternatives.isEmpty {
                            CardView {
                                Text("No alternatives found for this exercise.")
                                    .font(.appBody)
                                    .foregroundColor(AppColor.textDimmed)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 16)
                        } else {
                            ForEach(grouped, id: \.0) { tierLabel, exercises in
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionLabel(text: "TIER \(tierLabel)")
                                        .padding(.horizontal, 20)

                                    ForEach(exercises) { alt in
                                        AltExerciseRow(
                                            exercise: alt,
                                            seasonColor: seasonColor
                                        ) {
                                            onSelect(target.originalName, alt.name)
                                            dismiss()
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Swap Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(seasonColor)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Alt Exercise Row
private struct AltExerciseRow: View {
    let exercise: AltExercise
    let seasonColor: Color
    let onTap: () -> Void

    private var tierColor: Color {
        switch exercise.tier {
        case .sPlus: return AppColor.spring
        case .s:     return AppColor.summer
        case .aPlus: return AppColor.fall.opacity(0.8)
        case .a:     return AppColor.textMuted
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.appSubhead)
                        .foregroundColor(AppColor.textSecondary)
                        .multilineTextAlignment(.leading)
                    Text("TIER \(exercise.tier.rawValue)")
                        .font(.monoTiny)
                        .foregroundColor(tierColor)
                        .tracking(1)
                }
                Spacer()
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(seasonColor)
            }
            .padding(14)
            .background(AppColor.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColor.border1, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
