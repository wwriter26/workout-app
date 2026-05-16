import SwiftUI

// MARK: - Set Log Row
/// A single set input row used in both TodayView's sessionCard and LogView's sessionLogForm.
/// Layout per row:
///   [ S# ] [ Prev: W×R ] [ Weight | Reps | RIR ] [ ✓ ]
/// Tapping the weight value toggles a PlateCalculator below the row.
/// Long-pressing ✓ saves + skips rest timer.
struct SetLogRow: View {
    let exIndex: Int
    let setIndex: Int
    let exercise: Exercise
    let seasonColor: Color
    /// Most recent logged SetLog for this exercise name (for "Prev:" display).
    /// Weight is stored canonical in lbs.
    let prevSetForThisExercise: SetLog?
    @Binding var completedSets: [String: Bool]
    @Binding var logWeights: [String: String]
    let userPlateProfile: PlateProfile
    /// User's current weight unit. Affects placeholder, prev display, plate calc.
    let weightUnit: WeightUnit
    /// Called when the user marks the set complete (starts rest timer, etc.).
    let onComplete: () -> Void

    // MARK: - Local state
    @State private var showPlateCalc: Bool = false

    // MARK: - Computed keys
    private var setKey: String { "\(exIndex)-\(setIndex)" }
    private var weightKey: String { "\(exIndex)-\(setIndex)-w" }
    private var repsKey: String { "\(exIndex)-\(setIndex)-r" }
    private var rirKey: String { "\(exIndex)-\(setIndex)-rir" }

    // MARK: - Derived display values

    private var isDone: Bool { completedSets[setKey] ?? false }

    private var prevDisplay: String? {
        guard let p = prevSetForThisExercise, !p.weight.isEmpty else { return nil }
        let rStr = p.reps.isEmpty ? "?" : p.reps
        // Prev weight is canonical lbs in storage; convert to the user's preferred display unit.
        let displayWeight: String
        if let lbsVal = Double(p.weight) {
            displayWeight = WeightFormat.display(lbsVal, unit: weightUnit, decimals: 1, includeUnit: false)
        } else {
            displayWeight = p.weight
        }
        return "\(displayWeight)×\(rStr)"
    }

    /// User-typed weight is in their CURRENT display unit (lbs or kg).
    private var currentWeight: Double? {
        guard let wStr = logWeights[weightKey], !wStr.isEmpty else { return nil }
        return Double(wStr)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            mainRow
            if showPlateCalc, let w = currentWeight, w > 0 {
                // PlateCalculator receives the value in the user's CURRENT unit
                // plus the plate set + barbell appropriate for that unit.
                PlateCalculator(
                    weight: w,
                    barbell: weightUnit.defaultBarbell,
                    availablePlates: weightUnit.defaultPlates,
                    unit: weightUnit
                )
                .padding(.leading, 30)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPlateCalc)
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(spacing: 6) {
            // Set number label
            Text("S\(setIndex + 1)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(AppColor.textFaint)
                .frame(width: 22)

            // Previous performance (muted, small)
            if let prev = prevDisplay {
                Text("Prev:\(prev)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppColor.textVeryFaint)
                    .lineLimit(1)
                    .frame(minWidth: 56, alignment: .leading)
            }

            // Weight field — tapping label toggles plate calculator
            weightField

            // Reps field
            repsField

            // RIR stepper
            rirStepper

            // Complete button (tap = save + start timer; long press = save + skip timer)
            completeButton
        }
    }

    // MARK: - Weight Field

    private var weightField: some View {
        // Tapping the field label area toggles the plate calculator;
        // the actual TextField still accepts input normally.
        VStack(spacing: 0) {
            TextField(prevWeightDisplay ?? weightUnit.label.capitalized, text: Binding(
                get: { logWeights[weightKey] ?? "" },
                set: { logWeights[weightKey] = $0 }
            ))
            .keyboardType(.decimalPad)
            .font(.monoSmall)
            .foregroundColor(AppColor.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.vertical, 7)
            .background(AppColor.cardBackground2)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(showPlateCalc ? seasonColor.opacity(0.5) : AppColor.border2, lineWidth: 1)
            )
            .onTapGesture {
                // First tap populates from previous if empty (converted to display unit).
                if logWeights[weightKey] == nil || logWeights[weightKey]!.isEmpty,
                   let prevStr = prevWeightDisplay {
                    logWeights[weightKey] = prevStr
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPlateCalc.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reps Field

    private var repsField: some View {
        TextField(prevReps ?? "Reps", text: Binding(
            get: { logWeights[repsKey] ?? "" },
            set: { logWeights[repsKey] = $0 }
        ))
        .keyboardType(.numberPad)
        .font(.monoSmall)
        .foregroundColor(AppColor.textPrimary)
        .multilineTextAlignment(.center)
        .frame(width: 46)
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .background(AppColor.cardBackground2)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppColor.border2, lineWidth: 1)
        )
    }

    // MARK: - RIR Stepper
    // Mini +/- buttons instead of a system Stepper — more compact for row layout.

    private var rirStepper: some View {
        HStack(spacing: 0) {
            Button {
                let current = rirValue
                logWeights[rirKey] = "\(max(0, current - 1))"
            } label: {
                Text("−")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColor.textMuted)
                    .frame(width: 20, height: 30)
            }
            .buttonStyle(.plain)

            Text("\(rirValue)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(AppColor.textSecondary)
                .frame(width: 20)

            Button {
                let current = rirValue
                logWeights[rirKey] = "\(min(5, current + 1))"
            } label: {
                Text("+")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColor.textMuted)
                    .frame(width: 20, height: 30)
            }
            .buttonStyle(.plain)
        }
        .background(AppColor.cardBackground2)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppColor.border2, lineWidth: 1)
        )
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        // Long press skips rest; tap starts rest timer
        Button {
            markComplete(startTimer: true)
        } label: {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isDone ? seasonColor : AppColor.textFaint)
        }
        .buttonStyle(.plain)
        .frame(width: 30)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in markComplete(startTimer: false) }
        )
        .accessibilityLabel(isDone ? "Set \(setIndex + 1) complete" : "Mark set \(setIndex + 1) complete")
    }

    // MARK: - Helpers

    /// Previous weight string in the user's current display unit (converted from canonical lbs).
    private var prevWeightDisplay: String? {
        guard let p = prevSetForThisExercise, !p.weight.isEmpty else { return nil }
        guard let lbsVal = Double(p.weight) else { return p.weight }
        return WeightFormat.display(lbsVal, unit: weightUnit, decimals: 1, includeUnit: false)
    }

    private var prevReps: String? {
        guard let p = prevSetForThisExercise, !p.reps.isEmpty else { return nil }
        return p.reps
    }

    /// Current RIR value from logWeights, defaulting to the exercise's target RIR.
    private var rirValue: Int {
        if let stored = logWeights[rirKey], let v = Int(stored) { return v }
        if let target = Autoregulation.parseTargetRIR(exercise.rir) { return Int(target.rounded()) }
        return 2
    }

    private func markComplete(startTimer: Bool) {
        // Write rirInt into the key so it's available at save time
        if logWeights[rirKey] == nil {
            logWeights[rirKey] = "\(rirValue)"
        }
        completedSets[setKey] = !(completedSets[setKey] ?? false)

        if completedSets[setKey] == true && startTimer {
            let restSecs = RestTimer.parseRestSeconds(exercise.rest)
            RestTimer.shared.start(seconds: restSecs, exerciseName: exercise.name)
        } else if completedSets[setKey] == false {
            // Unchecking — cancel any running timer for this exercise
            // (only skip if this exercise started the current timer)
            if RestTimer.shared.exerciseName == exercise.name {
                RestTimer.shared.skip()
            }
        }

        onComplete()
    }
}

// MARK: - Autoregulation Hint
/// Shows the autoreg next-weight suggestion below the last set row of an exercise.
/// Input is canonical lbs; display converts to user's preferred unit.
struct AutoregHint: View {
    let suggestedWeightLbs: Double?
    let weightUnit: WeightUnit
    let seasonColor: Color

    var body: some View {
        if let w = suggestedWeightLbs {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(seasonColor.opacity(0.8))
                Text("Next session suggestion: \(WeightFormat.display(w, unit: weightUnit))")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textDimmed)
            }
            .padding(.top, 2)
        }
    }
}
