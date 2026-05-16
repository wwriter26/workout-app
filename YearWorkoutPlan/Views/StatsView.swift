import SwiftUI
import Charts

// MARK: - Stats View Mode
private enum StatsMode: String, CaseIterable {
    case volume   = "Volume"
    case weight   = "Weight"
    case oneRM    = "Est 1RM"
}

// MARK: - Stats View
struct StatsView: View {
    @Environment(AppState.self) private var state
    @State private var statsMode: StatsMode = .weight

    var body: some View {
        @Bindable var bindState = state
        ScrollView {
            VStack(spacing: 10) {
                liftTrackerCard
                bodyweightCard
                bodyCompositionCard
                recoveryCard
                sessionHeatmapCard
                macroTilesCard
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Lift Tracker Card
    private var liftTrackerCard: some View {
        @Bindable var bindState = state

        return CardView {
            SectionLabel(text: "Lift Tracker")

            // Mode selector
            HStack(spacing: 6) {
                ForEach(StatsMode.allCases, id: \.self) { mode in
                    let isSelected = statsMode == mode
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { statsMode = mode }
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .default))
                            .foregroundColor(isSelected ? state.season.color : AppColor.textDimmed)
                            .padding(.horizontal, 10)
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
            .padding(.top, 4)

            // Lift selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SupplementList.bigLifts, id: \.self) { lift in
                        let isSelected = state.statsLift == lift
                        Button {
                            state.statsLift = lift
                        } label: {
                            Text(lift)
                                .font(.system(size: 11, weight: .semibold, design: .default))
                                .foregroundColor(isSelected ? state.season.color : AppColor.textDimmed)
                                .padding(.horizontal, 10)
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
            }
            .padding(.top, 8)

            // PR number
            if let pr = state.prLog[state.statsLift] {
                let displayValue: Double = statsMode == .oneRM
                    ? epley1RM(weight: pr, reps: 1)  // PR weight as single rep = itself
                    : pr
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("\(displayValue, specifier: "%.1f")")
                        .font(.system(size: 36, weight: .semibold, design: .monospaced))
                        .foregroundColor(state.season.color)
                    SectionLabel(text: statsMode == .oneRM ? "est 1RM (lbs)" : "lbs PR")
                }
                .padding(.top, 12)
            }

            // Chart
            let history = buildLiftHistory(for: state.statsLift, mode: statsMode)
            Group {
                if history.count > 1 {
                    Chart(history, id: \.week) { item in
                        // Annotate deload and transition weeks with dimmed area
                        if Seasons.isDeload(item.week) || Seasons.isTransition(item.week) {
                            BarMark(x: .value("Week", item.week), yStart: .value("", 0), yEnd: .value("", item.value))
                                .foregroundStyle(AppColor.cnsRest.opacity(0.3))
                        }
                        LineMark(
                            x: .value("Week", item.week),
                            y: .value("Value", item.value)
                        )
                        .foregroundStyle(state.season.color)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Week", item.week),
                            y: .value("Value", item.value)
                        )
                        .foregroundStyle(state.season.color)
                        .symbolSize(30)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { val in
                            AxisValueLabel {
                                if let wk = val.as(Int.self) {
                                    Text("W\(wk)").font(.monoTiny).foregroundColor(AppColor.textFaint)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { val in
                            AxisValueLabel {
                                if let w = val.as(Double.self) {
                                    Text("\(Int(w))").font(.monoTiny).foregroundColor(AppColor.textFaint)
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                    .padding(.top, 12)
                } else {
                    Text("Log 2+ sessions to see trend")
                        .font(.appBody)
                        .foregroundColor(AppColor.textVeryFaint)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                        .padding(.top, 12)
                }
            }
        }
    }

    // MARK: - Bodyweight Card
    private var bodyweightCard: some View {
        let bwHistory = Array(state.bodyweightLog.suffix(20))
        let last7 = Array(state.bodyweightLog.suffix(7))
        let prev7 = Array(state.bodyweightLog.dropLast(min(7, state.bodyweightLog.count)).suffix(7))

        let avg7: Double? = last7.isEmpty ? nil :
            last7.map(\.weight).reduce(0, +) / Double(last7.count)
        let avgPrev: Double? = prev7.isEmpty ? nil :
            prev7.map(\.weight).reduce(0, +) / Double(prev7.count)
        let diff: Double? = (avg7 != nil && avgPrev != nil) ? (avg7! - avgPrev!) : nil

        return CardView {
            SectionLabel(text: "Bodyweight Trend")

            if bwHistory.count > 1 {
                Chart(Array(bwHistory.enumerated()), id: \.offset) { idx, entry in
                    BarMark(
                        x: .value("Entry", idx + 1),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(state.season.color.opacity(0.6))
                    .cornerRadius(3)
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisValueLabel {
                            if let w = val.as(Double.self) {
                                Text("\(Int(w))").font(.monoTiny).foregroundColor(AppColor.textFaint)
                            }
                        }
                    }
                }
                .frame(height: 140)
                .padding(.top, 12)
            } else {
                Text("Log bodyweight daily to track")
                    .font(.appBody)
                    .foregroundColor(AppColor.textVeryFaint)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                    .padding(.top, 12)
            }

            if let a = avg7 {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(a, specifier: "%.1f")")
                            .font(.monoBig)
                            .foregroundColor(AppColor.textPrimary)
                        Text("7-DAY AVG (lbs)")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textFaint)
                    }
                    if let d = diff {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(d >= 0 ? "+" : "")\(d, specifier: "%.1f")")
                                .font(.monoBig)
                                .foregroundColor(d > 0 ? AppColor.fall : AppColor.spring)
                            Text("VS PREV WEEK")
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textFaint)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Body Composition
    private var bodyCompositionCard: some View {
        // 4-week moving average from bodyweight log
        let bw = state.bodyweightLog
        let movingAvgData = stride(from: 0, to: bw.count, by: 1).compactMap { i -> (Int, Double)? in
            let window = bw[max(0, i - 3)...i]
            let avg = window.map(\.weight).reduce(0, +) / Double(window.count)
            return (i, avg)
        }

        return CardView {
            SectionLabel(text: "Body Composition")

            if bw.count >= 4 {
                Chart {
                    ForEach(Array(bw.enumerated()), id: \.offset) { idx, entry in
                        PointMark(
                            x: .value("Day", idx + 1),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(state.season.color.opacity(0.4))
                        .symbolSize(20)
                    }
                    ForEach(movingAvgData, id: \.0) { idx, avg in
                        LineMark(
                            x: .value("Day", idx + 1),
                            y: .value("4-wk MA", avg)
                        )
                        .foregroundStyle(state.season.color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { val in
                        AxisValueLabel {
                            if let w = val.as(Double.self) {
                                Text("\(Int(w))").font(.monoTiny).foregroundColor(AppColor.textFaint)
                            }
                        }
                    }
                }
                .frame(height: 120)
                .padding(.top, 8)

                Text("Dots = daily · Line = 4-week moving avg")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textFaint)
                    .padding(.top, 6)
            } else {
                Text("Log 4+ bodyweight entries to see chart")
                    .font(.appBody)
                    .foregroundColor(AppColor.textVeryFaint)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Recovery (Whoop summary — stored manually)
    private var recoveryCard: some View {
        // Count how many logs in the last 30 days have a corresponding Whoop entry
        // Since we don't persist per-day Whoop status (only "today"), show a placeholder
        // with instructions for manual entry. A full Whoop integration would require OAuth.
        CardView {
            SectionLabel(text: "Recovery — Last 30 Days")
            Text("Log your Whoop status on the Today tab each day to populate this view.")
                .font(.appSmall)
                .foregroundColor(AppColor.textDimmed)
                .padding(.top, 4)
            HStack(spacing: 16) {
                ForEach(WhoopStatus.allCases, id: \.self) { status in
                    HStack(spacing: 6) {
                        Circle().fill(status.color).frame(width: 8, height: 8)
                        Text(status.label)
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textMuted)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Session Frequency Heatmap
    private var sessionHeatmapCard: some View {
        let calendar = Calendar.current
        // Build a set of training dates from workoutLogs
        let trainingDates: Set<String> = Set(state.workoutLogs.map { $0.date })

        // Build last 7 weeks (49 days) grid
        let today = Date()
        let gridDays: [Date] = (0..<49).compactMap {
            calendar.date(byAdding: .day, value: -48 + $0, to: today)
        }

        let df = DateFormatter()
        df.dateStyle = .short

        return CardView {
            SectionLabel(text: "Training Frequency (7 Weeks)")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7),
                spacing: 3
            ) {
                // Day-of-week headers
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { d in
                    Text(d)
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                        .frame(maxWidth: .infinity)
                }
                ForEach(gridDays, id: \.self) { date in
                    let dateStr = df.string(from: date)
                    let trained = trainingDates.contains(dateStr)
                    let isToday = calendar.isDateInToday(date)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(trained ? state.season.color : AppColor.cardBackground2)
                        .frame(height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(isToday ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                        .accessibilityLabel(trained ? "Trained \(dateStr)" : "Rest \(dateStr)")
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Season Macro Tiles
    private var macroTilesCard: some View {
        let s = state.season
        let tiles: [(String, Int, String)] = [
            ("Calories",     s.calories,  "kcal"),
            ("Protein",      s.protein,   "g"),
            ("Carbs (train)",s.carbsTrain,"g"),
            ("Fat",          s.fat,       "g"),
        ]

        return CardView {
            SectionLabel(text: "Season Target Macros")
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(tiles, id: \.0) { (label, value, unit) in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(value)")
                            .font(.monoBig)
                            .foregroundColor(s.color)
                        Text("\(unit) \(label.uppercased())")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textFaint)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.cardBackground2)
                    .cornerRadius(8)
                }
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Lift History Builder
    private struct LiftPoint {
        let week: Int
        let value: Double
    }

    /// Epley formula: estimated 1RM = weight × (1 + reps/30)
    private func epley1RM(weight: Double, reps: Double) -> Double {
        guard reps > 0 else { return weight }
        return weight * (1 + reps / 30)
    }

    private func buildLiftHistory(for lift: String, mode: StatsMode) -> [LiftPoint] {
        var weekData: [Int: Double] = [:]
        for log in state.workoutLogs {
            for ex in log.exercises where ex.name == lift {
                for set in ex.sets {
                    let w = Double(set.weight) ?? 0
                    let r = Double(set.reps) ?? 1
                    guard w > 0 else { continue }

                    let value: Double
                    switch mode {
                    case .weight:
                        value = w
                    case .volume:
                        // Accumulate volume for this week
                        value = (weekData[log.week] ?? 0) + w * r
                        weekData[log.week] = value
                        continue
                    case .oneRM:
                        value = epley1RM(weight: w, reps: r)
                    }
                    weekData[log.week] = max(weekData[log.week] ?? 0, value)
                }
            }
        }
        return weekData.sorted { $0.key < $1.key }
            .map { LiftPoint(week: $0.key, value: $0.value) }
    }
}
