import SwiftUI

// MARK: - Assessment View

/// Multi-field assessment entry form. Computes e1RM from AMRAP data using Brzycki
/// (reps 1–5) or Epley (reps 6+), then triggers hexagon score recomputation.
struct AssessmentView: View {

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    // MARK: - Strength fields
    @State private var benchWeight: String = ""
    @State private var benchReps: String = ""
    @State private var squatWeight: String = ""
    @State private var squatReps: String = ""
    @State private var deadliftWeight: String = ""
    @State private var deadliftReps: String = ""
    @State private var ohpWeight: String = ""
    @State private var ohpReps: String = ""

    // MARK: - VO2max
    @State private var vo2maxText: String = ""

    // MARK: - Power
    @State private var verticalJumpText: String = ""

    // MARK: - Mobility
    @State private var sitToRiseText: String = ""       // 0–10 in 0.5 steps
    @State private var sitAndReachText: String = ""
    @State private var shoulderFlexionText: String = ""

    // MARK: - Grip / Dead hang
    @State private var gripKgText: String = ""
    @State private var deadHangSecText: String = ""

    // MARK: - Notes
    @State private var notes: String = ""

    // MARK: - Toast
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColor.appBackground.ignoresSafeArea()

                Form {
                    // Style the form for the dark theme
                    strengthSection
                    vo2maxSection
                    powerSection
                    mobilitySection
                    gripSection
                    notesSection
                }
                .scrollContentBackground(.hidden)
                .background(AppColor.appBackground)

                // Success toast
                if showToast {
                    toastBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationTitle("Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColor.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAssessment() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(state.season.color)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Sections

    private var strengthSection: some View {
        Section {
            liftRow(
                exercise: "Bench Press",
                weightBinding: $benchWeight,
                repsBinding: $benchReps
            )
            liftRow(
                exercise: "Squat",
                weightBinding: $squatWeight,
                repsBinding: $squatReps
            )
            liftRow(
                exercise: "Deadlift",
                weightBinding: $deadliftWeight,
                repsBinding: $deadliftReps
            )
            liftRow(
                exercise: "OHP",
                weightBinding: $ohpWeight,
                repsBinding: $ohpReps
            )
        } header: {
            Text("Strength (AMRAP → e1RM)")
                .foregroundColor(AppColor.textFaint)
                .font(.monoTiny)
        } footer: {
            Text("Brzycki formula for ≤5 reps, Epley for 6+. Enter the weight and reps completed in your max-effort set.")
                .foregroundColor(AppColor.textFaint)
                .font(.monoTiny)
        }
    }

    private var vo2maxSection: some View {
        Section {
            HStack {
                Text("VO2max (ml/kg/min)")
                    .font(.appBody)
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                TextField("50.0", text: $vo2maxText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .font(.monoSmall)
                    .foregroundColor(AppColor.textPrimary)
            }

            // Pull from HealthKit if available
            if let hkVO2 = state.latestSnapshot?.vo2maxEstimate {
                Button {
                    vo2maxText = String(format: "%.1f", hkVO2)
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(AppColor.fall)
                        Text("Pull from Apple Health (\(String(format: "%.1f", hkVO2)) ml/kg/min)")
                            .font(.appSmall)
                            .foregroundColor(state.season.color)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Aerobic Capacity")
                .foregroundColor(AppColor.textFaint)
                .font(.monoTiny)
        }
    }

    private var powerSection: some View {
        Section {
            HStack {
                Text("Vertical Jump (cm)")
                    .font(.appBody)
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                TextField("50", text: $verticalJumpText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .font(.monoSmall)
                    .foregroundColor(AppColor.textPrimary)
            }
        } header: {
            Text("Power")
                .foregroundColor(AppColor.textFaint)
                .font(.monoTiny)
        }
    }

    private var mobilitySection: some View {
        Section {
            // Sit-to-rise: 0–10 in 0.5 steps — stepper UI
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sit-to-Rise (0–10)")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Text("Each failed attempt or hand touch = −1")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        let v = (Double(sitToRiseText) ?? 0)
                        if v > 0 { sitToRiseText = String(format: "%.1f", max(0, v - 0.5)) }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundColor(AppColor.textMuted)
                    }
                    .buttonStyle(.plain)

                    Text(sitToRiseText.isEmpty ? "5.0" : sitToRiseText)
                        .font(.monoSmall)
                        .foregroundColor(AppColor.textPrimary)
                        .frame(width: 32, alignment: .center)

                    Button {
                        let v = (Double(sitToRiseText) ?? 5.0)
                        if v < 10 { sitToRiseText = String(format: "%.1f", min(10, v + 0.5)) }
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(AppColor.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text("Sit-and-Reach (cm)")
                    .font(.appBody)
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                TextField("15", text: $sitAndReachText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .font(.monoSmall)
                    .foregroundColor(AppColor.textPrimary)
            }

            HStack {
                Text("Shoulder Flexion (°)")
                    .font(.appBody)
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                TextField("160", text: $shoulderFlexionText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .font(.monoSmall)
                    .foregroundColor(AppColor.textPrimary)
            }

        } header: {
            Text("Mobility")
                .foregroundColor(AppColor.textFaint)
                .font(.monoTiny)
        }
    }

    private var gripSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grip Strength — dominant (kg)")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Text("Optional — only if dynamometer available")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }
                Spacer()
                TextField("50", text: $gripKgText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .font(.monoSmall)
                    .foregroundColor(AppColor.textPrimary)
            }

            HStack {
                Text("Dead Hang (seconds)")
                    .font(.appBody)
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                TextField("60", text: $deadHangSecText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .font(.monoSmall)
                    .foregroundColor(AppColor.textPrimary)
            }
        } header: {
            Text("Grip & Hang")
                .foregroundColor(AppColor.textFaint)
                .font(.monoTiny)
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Any notes about conditions, equipment, etc.", text: $notes, axis: .vertical)
                .font(.appBody)
                .foregroundColor(AppColor.textSecondary)
                .lineLimit(3...6)
        } header: {
            Text("Notes")
                .foregroundColor(AppColor.textFaint)
                .font(.monoTiny)
        }
    }

    // MARK: - Lift Row Helper

    /// A row containing weight + reps fields plus a computed e1RM readout.
    private func liftRow(
        exercise: String,
        weightBinding: Binding<String>,
        repsBinding: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise)
                .font(.appBody)
                .foregroundColor(AppColor.textSecondary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight (lbs)")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                    TextField("225", text: weightBinding)
                        .keyboardType(.decimalPad)
                        .font(.monoSmall)
                        .foregroundColor(AppColor.textPrimary)
                        .frame(width: 80)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reps")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                    TextField("5", text: repsBinding)
                        .keyboardType(.numberPad)
                        .font(.monoSmall)
                        .foregroundColor(AppColor.textPrimary)
                        .frame(width: 50)
                }

                Spacer()

                // Live e1RM preview
                if let w = Double(weightBinding.wrappedValue),
                   let r = Int(repsBinding.wrappedValue), r > 0, w > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("e1RM")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textFaint)
                        Text("\(Int(computeE1RM(weight: w, reps: r))) lbs")
                            .font(.monoSmall)
                            .foregroundColor(state.season.color)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Toast Banner

    private var toastBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColor.spring)
            Text(toastMessage)
                .font(.appBody)
                .foregroundColor(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColor.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColor.spring.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - e1RM Formulas

    /// Brzycki: more accurate for low-rep (1–5) AMRAP sets.
    private func brzycki1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        // Brzycki formula: 1RM = weight × 36 / (37 − reps)
        // Undefined at reps = 37, but physiologically irrelevant (≥ 37 reps ≠ 1RM test).
        let denominator = 37.0 - Double(reps)
        guard denominator > 0 else { return weight }
        return weight * 36.0 / denominator
    }

    /// Epley: more accurate for moderate-to-high rep (6+) AMRAP sets.
    private func epley1RM(weight: Double, reps: Int) -> Double {
        weight * (1 + Double(reps) / 30)
    }

    /// Selects the appropriate formula based on rep count.
    private func computeE1RM(weight: Double, reps: Int) -> Double {
        reps <= 5 ? brzycki1RM(weight: weight, reps: reps) : epley1RM(weight: weight, reps: reps)
    }

    // MARK: - Save

    private func saveAssessment() {
        let previous = state.assessmentHistory.last

        let benchE1RM: Double? = {
            guard let w = Double(benchWeight), let r = Int(benchReps), w > 0, r > 0 else { return nil }
            return computeE1RM(weight: w, reps: r)
        }()
        let squatE1RM: Double? = {
            guard let w = Double(squatWeight), let r = Int(squatReps), w > 0, r > 0 else { return nil }
            return computeE1RM(weight: w, reps: r)
        }()
        let deadliftE1RM: Double? = {
            guard let w = Double(deadliftWeight), let r = Int(deadliftReps), w > 0, r > 0 else { return nil }
            return computeE1RM(weight: w, reps: r)
        }()
        let ohpE1RM: Double? = {
            guard let w = Double(ohpWeight), let r = Int(ohpReps), w > 0, r > 0 else { return nil }
            return computeE1RM(weight: w, reps: r)
        }()

        let baseline = AssessmentBaseline(
            date:               AppState.sharedDateString(from: Date()),
            benchE1RM:          benchE1RM,
            squatE1RM:          squatE1RM,
            deadliftE1RM:       deadliftE1RM,
            ohpE1RM:            ohpE1RM,
            vo2max:             Double(vo2maxText),
            verticalJumpCm:     Double(verticalJumpText),
            deadHangSec:        Double(deadHangSecText),
            sitToRiseScore:     Double(sitToRiseText),
            sitAndReachCm:      Double(sitAndReachText),
            shoulderFlexionDeg: Double(shoulderFlexionText),
            gripKg:             Double(gripKgText),
            notes:              notes
        )

        state.saveAssessment(baseline)
        state.computeHexagonScore()

        // Build delta message vs previous assessment
        toastMessage = buildDeltaMessage(new: baseline, previous: previous)
        withAnimation(.spring(duration: 0.4)) {
            showToast = true
        }

        // Auto-dismiss the toast and the sheet after 2.5 s
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { showToast = false }
            try? await Task.sleep(nanoseconds: 500_000_000)
            dismiss()
        }
    }

    /// Generates a concise delta string comparing the new assessment to the previous one.
    private func buildDeltaMessage(new: AssessmentBaseline, previous: AssessmentBaseline?) -> String {
        guard let prev = previous else {
            return "First assessment saved. Hexagon unlocked!"
        }

        var parts: [String] = []

        func delta(label: String, newVal: Double?, prevVal: Double?, unit: String, format: String = "%.0f") -> String? {
            guard let n = newVal, let p = prevVal else { return nil }
            let diff = n - p
            let sign = diff >= 0 ? "+" : ""
            return "\(label): \(sign)\(String(format: format, diff))\(unit)"
        }

        if let d = delta(label: "Bench", newVal: new.benchE1RM, prevVal: prev.benchE1RM, unit: " lb") { parts.append(d) }
        if let d = delta(label: "Squat", newVal: new.squatE1RM, prevVal: prev.squatE1RM, unit: " lb") { parts.append(d) }
        if let d = delta(label: "DL",    newVal: new.deadliftE1RM, prevVal: prev.deadliftE1RM, unit: " lb") { parts.append(d) }
        if let d = delta(label: "OHP",   newVal: new.ohpE1RM, prevVal: prev.ohpE1RM, unit: " lb") { parts.append(d) }
        if let d = delta(label: "VO2",   newVal: new.vo2max, prevVal: prev.vo2max, unit: "", format: "%.1f") { parts.append(d) }

        if parts.isEmpty { return "Assessment saved!" }
        return parts.prefix(3).joined(separator: " · ") + " since last test"
    }
}

// MARK: - Preview

#Preview {
    AssessmentView()
        .environment(AppState())
}
