import SwiftUI

// MARK: - Today View
struct TodayView: View {
    @Environment(AppState.self) private var state
    /// Tracks which exercise index is awaiting a swap selection.
    @State private var swapTarget: SwapTarget? = nil

    var body: some View {
        @Bindable var bindState = state
        ScrollView {
            VStack(spacing: 10) {
                headerCard
                bodyweightCard
                whoopCard
                sessionCard
                weekAdjusterCard
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        // Present the swap sheet when swapTarget is set.
        .sheet(item: $swapTarget) { target in
            SwapExerciseSheet(
                target: target,
                seasonColor: state.season.color
            ) { originalName, newName in
                state.swap(week: state.currentWeek,
                           day: state.todayDayKey,
                           originalName: originalName,
                           newName: newName)
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        CardView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: "\(state.season.name) · WK \(state.currentWeek)", color: state.season.color)
                    Text(state.todayDayKey)
                        .font(.appHero)
                        .foregroundColor(AppColor.textPrimary)
                    HStack(spacing: 6) {
                        if state.isTransition {
                            BadgeView("TRANSITION WEEK",
                                      foreground: AppColor.infoBlue,
                                      background: AppColor.infoBlue.opacity(0.13))
                        } else if state.isDeload {
                            BadgeView("DELOAD WEEK",
                                      foreground: AppColor.deload,
                                      background: AppColor.deloadBg)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    SectionLabel(text: "Season Goal")
                    Text(state.season.goal)
                        .font(.appSmall)
                        .foregroundColor(AppColor.textSecondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140, alignment: .trailing)
                }
            }
        }
        // Season-colour left accent border
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(state.season.color)
                .frame(width: 3)
                .cornerRadius(2)
                .padding(.vertical, 1)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#111111"), Color(hex: "#1A1A1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(12)
        )
    }

    // MARK: - Bodyweight Card
    private var bodyweightCard: some View {
        @Bindable var bindState = state
        return CardView {
            SectionLabel(text: "Bodyweight")
            HStack(spacing: 8) {
                MonoTextField(placeholder: "165.0 lbs", text: $bindState.todayBW)
                Button {
                    state.logBodyweight()
                } label: {
                    Text("LOG")
                        .font(.system(size: 12, weight: .heavy, design: .default))
                        .foregroundColor(.black)
                        .tracking(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(state.season.color)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
            if let last = state.bodyweightLog.last {
                Text("Last: \(last.weight, specifier: "%.1f") lbs")
                    .font(.monoLabel)
                    .foregroundColor(AppColor.textDimmed)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Whoop Card
    private var whoopCard: some View {
        CardView {
            SectionLabel(text: "Whoop Recovery")
            HStack(spacing: 8) {
                ForEach(WhoopStatus.allCases, id: \.self) { status in
                    let isSelected = state.whoopToday == status
                    Button {
                        state.whoopToday = isSelected ? nil : status
                    } label: {
                        Text(status.label)
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundColor(isSelected ? status.color : AppColor.textDimmed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? status.color.opacity(0.13) : AppColor.cardBackground2)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? status.color : AppColor.border2, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
            .padding(.top, 8)

            if let w = state.whoopToday {
                Text(w.description)
                    .font(.appSmall)
                    .foregroundColor(w.color)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Session Card
    private var sessionCard: some View {
        @Bindable var bindState = state
        let session = state.adjustedSession
        let exList = session.exercises

        return CardView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel(text: "Today's Session")
                    Text(session.label)
                        .font(.appHeading)
                        .foregroundColor(cnsColor(session.cnsLoad))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(state.completionPercent * 100))%")
                        .font(.monoMid)
                        .foregroundColor(AppColor.textPrimary)
                    Text("COMPLETE")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }
            }

            SeasonProgressBar(percent: state.completionPercent, color: state.season.color)
                .padding(.vertical, 10)

            if exList.isEmpty {
                Text("Rest day. Recover hard.")
                    .font(.appSmall)
                    .foregroundColor(AppColor.textDimmed)
                    .padding(.top, 4)
            } else {
                ForEach(Array(exList.enumerated()), id: \.offset) { i, ex in
                    // Resolve whether this exercise has been swapped today
                    let swapKey = state.swapKey(week: state.currentWeek,
                                                 day: state.todayDayKey,
                                                 originalName: ex.name)
                    let displayName = state.swappedExercises[swapKey] ?? ex.name
                    let isSwapped   = state.swappedExercises[swapKey] != nil

                    ExerciseRowView(
                        exercise: ex,
                        displayName: displayName,
                        isSwapped: isSwapped,
                        exIndex: i,
                        seasonColor: state.season.color,
                        completedSets: $bindState.completedSets,
                        logWeights: $bindState.logWeights,
                        onToggle: { si in state.toggleSet(exIndex: i, setIndex: si) },
                        onSwap: {
                            swapTarget = SwapTarget(originalName: ex.name,
                                                    exIndex: i)
                        },
                        onRevert: {
                            state.revertSwap(week: state.currentWeek,
                                             day: state.todayDayKey,
                                             originalName: ex.name)
                        }
                    )
                    if i < exList.count - 1 {
                        Divider().background(AppColor.border1).padding(.vertical, 4)
                    }
                }

                PrimaryButton(title: "SAVE SESSION", color: state.season.color) {
                    state.saveSession()
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Week Adjuster Card
    private var weekAdjusterCard: some View {
        CardView {
            SectionLabel(text: "Current Week")
            HStack(spacing: 12) {
                IconButton(symbol: "−") {
                    state.currentWeek = max(1, state.currentWeek - 1)
                }
                Text("WK \(state.currentWeek)")
                    .font(.monoLarge)
                    .foregroundColor(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                IconButton(symbol: "+") {
                    state.currentWeek = min(52, state.currentWeek + 1)
                }
            }
            .padding(.top, 8)

            // Day selector row
            HStack(spacing: 4) {
                ForEach(Array(Schedules.days.enumerated()), id: \.offset) { i, day in
                    let isSelected = i == state.currentDayIndex
                    Button {
                        state.currentDayIndex = i
                    } label: {
                        Text(day)
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .foregroundColor(isSelected ? state.season.color : AppColor.textDimmed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isSelected ? state.season.color.opacity(0.13) : AppColor.cardBackground2)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? state.season.color : AppColor.border2, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Swap Target (sheet item model)
struct SwapTarget: Identifiable {
    let id = UUID()
    let originalName: String
    let exIndex: Int
}

// MARK: - Exercise Row
private struct ExerciseRowView: View {
    let exercise: Exercise
    let displayName: String
    let isSwapped: Bool
    let exIndex: Int
    let seasonColor: Color
    @Binding var completedSets: [String: Bool]
    @Binding var logWeights: [String: String]
    let onToggle: (Int) -> Void
    let onSwap: () -> Void
    let onRevert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    // Exercise name + swap controls
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Swap button — circular icon
                        Button(action: onSwap) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColor.textFaint)
                                .frame(width: 24, height: 24)
                                .background(AppColor.cardBackground2)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Swap \(exercise.name)")
                    }

                    // Swapped badge + revert button
                    if isSwapped {
                        HStack(spacing: 6) {
                            BadgeView("SWAPPED",
                                      foreground: seasonColor,
                                      background: seasonColor.opacity(0.15))
                            Button(action: onRevert) {
                                Text("revert")
                                    .font(.monoTiny)
                                    .foregroundColor(AppColor.textFaint)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if exercise.rir != "—" {
                        Text("RIR \(exercise.rir)")
                            .font(.monoSmall)
                            .foregroundColor(AppColor.textMuted)
                    }
                    if exercise.rest != "—" {
                        Text(exercise.rest)
                            .font(.monoSmall)
                            .foregroundColor(AppColor.textMuted)
                    }
                }
            }

            Text("\(exercise.sets) × \(exercise.reps) · \(exercise.load)")
                .font(.appBody)
                .foregroundColor(AppColor.textDimmed)

            // Set toggles
            HStack(spacing: 6) {
                ForEach(0..<exercise.sets, id: \.self) { si in
                    let key = "\(exIndex)-\(si)"
                    SetToggle(
                        index: si,
                        isDone: completedSets[key] ?? false,
                        color: seasonColor,
                        onTap: { onToggle(si) }
                    )
                }
            }

            // Weight / RIR quick log
            HStack(spacing: 6) {
                TextField("Weight (lbs)", text: Binding(
                    get: { logWeights["\(exIndex)-0-w"] ?? "" },
                    set: { logWeights["\(exIndex)-0-w"] = $0 }
                ))
                .keyboardType(.decimalPad)
                .font(.monoSmall)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppColor.cardBackground2)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border2, lineWidth: 1))

                TextField("RIR", text: Binding(
                    get: { logWeights["\(exIndex)-0-rir"] ?? "" },
                    set: { logWeights["\(exIndex)-0-rir"] = $0 }
                ))
                .keyboardType(.numberPad)
                .font(.monoSmall)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppColor.cardBackground2)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border2, lineWidth: 1))
                .frame(width: 52)
            }
        }
        .padding(.vertical, 6)
    }
}
