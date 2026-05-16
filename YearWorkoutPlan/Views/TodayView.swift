import SwiftUI

// MARK: - Today View
struct TodayView: View {
    @Environment(AppState.self) private var state
    @State private var swapTarget: SwapTarget? = nil

    var body: some View {
        @Bindable var bindState = state
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 10) {
                    RecoveryBanner()
                    headerCard
                    SupplementAdherenceCard()
                    MoodSliderCard()
                    bodyweightCard
                    sessionCard
                    weekAdjusterCard
                    mobilityCard
                    Spacer().frame(height: 80)  // space for rest timer overlay
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
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

            // Rest timer overlay — floats above scroll content, below tab bar
            RestTimerView(seasonColor: state.season.color)
                .padding(.bottom, 8)
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
                        if state.travelModeUntil != nil && state.travelModeUntil! > Date() {
                            BadgeView("TRAVEL MODE",
                                      foreground: AppColor.summer,
                                      background: AppColor.summer.opacity(0.13))
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

    // MARK: - Session Card (uses SetLogRow)
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
                    let swapKey = state.swapKey(week: state.currentWeek,
                                                day: state.todayDayKey,
                                                originalName: ex.name)
                    let displayName = state.swappedExercises[swapKey] ?? ex.name
                    let isSwapped   = state.swappedExercises[swapKey] != nil
                    let prevSet     = state.prevSetForExercise(displayName)
                    let suggested   = state.suggestedNextWeight(
                        forExercise: displayName,
                        targetRIRString: ex.rir
                    )

                    ExerciseBlockView(
                        exercise: ex,
                        displayName: displayName,
                        isSwapped: isSwapped,
                        exIndex: i,
                        seasonColor: state.season.color,
                        prevSet: prevSet,
                        suggestedWeight: suggested,
                        completedSets: $bindState.completedSets,
                        logWeights: $bindState.logWeights,
                        userPlateProfile: state.userProfile.plateProfile,
                        onSwap: {
                            swapTarget = SwapTarget(originalName: ex.name, exIndex: i)
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

    // MARK: - Mobility Card
    private var mobilityCard: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: "Mobility")
                    Text("Did mobility today?")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                Button {
                    state.toggleMobility(for: Date())
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: state.isMobilityCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(state.isMobilityCompletedToday ? AppColor.spring : AppColor.textFaint)
                        Text(state.isMobilityCompletedToday ? "DONE" : "LOG")
                            .font(.system(size: 11, weight: .heavy, design: .default))
                            .foregroundColor(state.isMobilityCompletedToday ? AppColor.spring : AppColor.textDimmed)
                            .tracking(1)
                    }
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: state.isMobilityCompletedToday)
            }
        }
    }
}

// MARK: - Exercise Block View
/// Wraps exercise header (name, swap controls, RIR/rest info) + SetLogRow per set
/// + optional AutoregHint below the last set.
private struct ExerciseBlockView: View {
    let exercise: Exercise
    let displayName: String
    let isSwapped: Bool
    let exIndex: Int
    let seasonColor: Color
    let prevSet: SetLog?
    let suggestedWeight: Double?
    @Binding var completedSets: [String: Bool]
    @Binding var logWeights: [String: String]
    let userPlateProfile: PlateProfile
    let onSwap: () -> Void
    let onRevert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Exercise name row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

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

            // One SetLogRow per set
            ForEach(0..<exercise.sets, id: \.self) { si in
                SetLogRow(
                    exIndex: exIndex,
                    setIndex: si,
                    exercise: exercise,
                    seasonColor: seasonColor,
                    prevSetForThisExercise: prevSet,
                    completedSets: $completedSets,
                    logWeights: $logWeights,
                    userPlateProfile: userPlateProfile,
                    onComplete: {}  // completion side-effects handled inside SetLogRow
                )
            }

            // Autoreg hint below the last set
            AutoregHint(suggestedWeight: suggestedWeight, seasonColor: seasonColor)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Swap Target
struct SwapTarget: Identifiable {
    let id = UUID()
    let originalName: String
    let exIndex: Int
}
