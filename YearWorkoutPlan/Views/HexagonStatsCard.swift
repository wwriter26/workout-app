import SwiftUI

// MARK: - Hexagon Stats Card

/// Card wrapping HexagonRadarView. Shows a 3-segment time-scale picker in the
/// header and handles the empty state when no assessments exist yet.
struct HexagonStatsCard: View {

    @Environment(AppState.self) private var state
    @State private var timeScale: TimeScale = .season
    @State private var showAssessment = false
    @State private var drillAxis: HexagonAxis? = nil

    var body: some View {
        CardView {
            // Header row
            HStack {
                SectionLabel(text: "Hexagon — \(timeScale.rawValue)")
                Spacer()
                Picker("Time Scale", selection: $timeScale) {
                    ForEach(TimeScale.allCases, id: \.self) { scale in
                        Text(scale.rawValue).tag(scale)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                // Dark segmented control tint
                .colorMultiply(state.season.color)
            }
            .padding(.bottom, 8)

            if let current = currentScore {
                // Radar
                HexagonRadarView(
                    current: current,
                    previous: previousScore,
                    seasonColor: state.season.color,
                    timeScale: timeScale
                )
                .frame(height: 260)
                .frame(maxWidth: .infinity)

                // Delta legend (previous score outline explanation)
                if previousScore != nil {
                    HStack(spacing: 6) {
                        // Dashed line swatch
                        Rectangle()
                            .fill(AppColor.textFaint.opacity(0.6))
                            .frame(width: 16, height: 1.5)
                        Text("Previous")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textFaint)
                        Spacer()
                    }
                    .padding(.top, 4)
                }

                // Axis drill-down grid
                axisGrid(score: current)
                    .padding(.top, 8)

            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showAssessment) {
            AssessmentView()
                .environment(state)
        }
        .sheet(item: $drillAxis) { axis in
            HexagonAxisDetailView(axis: axis, score: currentScore)
                .environment(state)
        }
    }

    // MARK: - Score Selection

    /// Resolves the current score based on the selected time scale.
    private var currentScore: HexagonScore? {
        switch timeScale {
        case .week:
            // Most recent score within the last 7 days
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let cutoffStr = AppState.sharedDateString(from: cutoff)
            return state.hexagonHistory
                .filter { $0.date >= cutoffStr }
                .last
        case .season:
            // Most recent score — season filtering deferred to Wave 3 when scores
            // carry a week number. For now the latest score represents the season.
            return state.hexagonHistory.last
        case .allTime:
            return state.hexagonHistory.last
        }
    }

    /// Returns the score one entry before current, used as the "previous" outline.
    private var previousScore: HexagonScore? {
        guard state.hexagonHistory.count >= 2 else { return nil }
        return state.hexagonHistory[state.hexagonHistory.count - 2]
    }

    // MARK: - Axis Grid

    /// 2-column grid of axis chips. Tapping any chip opens the drill-down sheet.
    private func axisGrid(score: HexagonScore) -> some View {
        let items: [(HexagonAxis, Double)] = [
            (.strength,    score.strength),
            (.power,       score.power),
            (.vo2max,      score.vo2max),
            (.endurance,   score.endurance),
            (.recovery,    score.recovery),
            (.flexibility, score.flexibility),
        ]

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 6
        ) {
            ForEach(items, id: \.0) { axis, value in
                Button {
                    drillAxis = axis
                } label: {
                    HStack(spacing: 8) {
                        // Score bar
                        VStack(alignment: .leading, spacing: 3) {
                            Text(axis.displayName)
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textFaint)
                            HStack(spacing: 4) {
                                Text("\(Int(value))")
                                    .font(.monoSmall)
                                    .foregroundColor(state.season.color)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(AppColor.border2)
                                            .frame(height: 3)
                                        Capsule()
                                            .fill(state.season.color)
                                            .frame(width: geo.size.width * CGFloat(value / 100), height: 3)
                                    }
                                }
                                .frame(height: 3)
                            }
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundColor(AppColor.textFaint)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppColor.cardBackground2)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColor.border2, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "hexagon.fill")
                .font(.system(size: 36))
                .foregroundColor(AppColor.textVeryFaint)
                .padding(.top, 12)

            Text("Complete the assessment to unlock your hexagon")
                .font(.appBody)
                .foregroundColor(AppColor.textDimmed)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "RUN ASSESSMENT", color: state.season.color) {
                showAssessment = true
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Hexagon Axis Enum

enum HexagonAxis: String, Identifiable, CaseIterable {
    case strength, power, vo2max, endurance, recovery, flexibility

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vo2max: return "VO2max"
        default: return rawValue.capitalized
        }
    }

    var description: String {
        switch self {
        case .strength:
            return "Estimated 1RM strength composite across bench, squat, deadlift, and OHP relative to bodyweight."
        case .power:
            return "Vertical jump height in cm. Reflects fast-twitch neuromuscular output."
        case .vo2max:
            return "Maximal oxygen uptake in ml/kg/min. From Apple Watch estimate or manual entry."
        case .endurance:
            return "Longest Zone 2 cardio session in minutes. Reflects aerobic base."
        case .recovery:
            return "Today's HRV as a percentage of 30-day rolling average."
        case .flexibility:
            return "Composite of sit-to-rise, sit-and-reach, and shoulder flexion tests."
        }
    }
}

// MARK: - Axis Detail View

/// Modal sheet with sub-test breakdown for a single axis.
struct HexagonAxisDetailView: View {
    let axis: HexagonAxis
    let score: HexagonScore?

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let score {
                            scoreHeader(score: score)
                        }

                        CardView {
                            SectionLabel(text: "About this axis")
                                .padding(.bottom, 6)
                            Text(axis.description)
                                .font(.appBody)
                                .foregroundColor(AppColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        subTestSection

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle(axis.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(state.season.color)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func scoreHeader(score: HexagonScore) -> some View {
        let value: Double = {
            switch axis {
            case .strength:    return score.strength
            case .power:       return score.power
            case .vo2max:      return score.vo2max
            case .endurance:   return score.endurance
            case .recovery:    return score.recovery
            case .flexibility: return score.flexibility
            }
        }()

        return CardView {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(Int(value))")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(state.season.color)
                Text("/ 100")
                    .font(.monoMid)
                    .foregroundColor(AppColor.textFaint)
            }
            .padding(.bottom, 4)
            Text(score.date)
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
        }
    }

    @ViewBuilder
    private var subTestSection: some View {
        let latest = state.assessmentHistory.last

        CardView {
            SectionLabel(text: "Sub-tests")
                .padding(.bottom, 8)

            switch axis {
            case .strength:
                strengthRows(assessment: latest)
            case .power:
                if let jump = latest?.verticalJumpCm {
                    metricRow(label: "Vertical jump", value: "\(Int(jump)) cm")
                } else {
                    placeholderRow
                }
            case .vo2max:
                if let v = latest?.vo2max ?? state.healthSnapshots.last?.vo2maxEstimate {
                    metricRow(label: "VO2max", value: "\(String(format: "%.1f", v)) ml/kg/min")
                } else {
                    placeholderRow
                }
            case .endurance:
                let z2 = state.sessionRPEs.filter { rpe in
                    state.workoutLogs.contains { log in
                        log.date == rpe.date && log.exercises.contains { $0.name.lowercased().contains("zone 2") }
                    }
                }.map(\.durationMin).max() ?? 0
                if z2 > 0 {
                    metricRow(label: "Longest Z2 session", value: "\(z2) min")
                } else {
                    placeholderRow
                }
            case .recovery:
                if let hrv = state.healthSnapshots.last?.hrvMs {
                    metricRow(label: "HRV (SDNN)", value: "\(String(format: "%.0f", hrv)) ms")
                } else {
                    placeholderRow
                }
            case .flexibility:
                flexibilityRows(assessment: latest)
            }
        }
    }

    private func strengthRows(assessment: AssessmentBaseline?) -> some View {
        VStack(spacing: 6) {
            if let a = assessment {
                Group {
                    if let v = a.benchE1RM    { metricRow(label: "Bench e1RM",     value: "\(Int(v)) lbs") }
                    if let v = a.squatE1RM    { metricRow(label: "Squat e1RM",     value: "\(Int(v)) lbs") }
                    if let v = a.deadliftE1RM { metricRow(label: "Deadlift e1RM",  value: "\(Int(v)) lbs") }
                    if let v = a.ohpE1RM      { metricRow(label: "OHP e1RM",       value: "\(Int(v)) lbs") }
                }
            } else {
                placeholderRow
            }
        }
    }

    private func flexibilityRows(assessment: AssessmentBaseline?) -> some View {
        VStack(spacing: 6) {
            if let a = assessment {
                Group {
                    if let v = a.sitToRiseScore    { metricRow(label: "Sit-to-rise",      value: "\(String(format: "%.1f", v)) / 10") }
                    if let v = a.sitAndReachCm      { metricRow(label: "Sit-and-reach",    value: "\(Int(v)) cm") }
                    if let v = a.shoulderFlexionDeg { metricRow(label: "Shoulder flexion", value: "\(Int(v))°") }
                }
            } else {
                placeholderRow
            }
        }
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.appBody)
                .foregroundColor(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(.monoSmall)
                .foregroundColor(state.season.color)
        }
        .padding(.vertical, 3)
    }

    private var placeholderRow: some View {
        Text("No data — run an assessment")
            .font(.appSmall)
            .foregroundColor(AppColor.textVeryFaint)
            .padding(.vertical, 4)
    }
}


// MARK: - Preview

#Preview {
    HexagonStatsCard()
        .environment(AppState())
        .padding()
        .background(AppColor.appBackground)
        .preferredColorScheme(.dark)
}
