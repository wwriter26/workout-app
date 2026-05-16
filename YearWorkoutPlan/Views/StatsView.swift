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
    @State private var showAssessment = false
    @State private var showBloodwork = false

    var body: some View {
        @Bindable var bindState = state
        ScrollView {
            VStack(spacing: 10) {
                // Wave 2B: Hexagon radar — first card
                HexagonStatsCard()

                // Wave 2B: Muscle group volume heatmap
                MuscleGroupHeatmapCard()

                // Wave 2B: ACWR chart
                ACWRCard()

                // Existing cards
                liftTrackerCard
                bodyweightCard
                bodyCompositionCard
                recoveryCard
                sessionHeatmapCard
                macroTilesCard

                // Wave 2B: Nav entry points
                actionRowCard

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAssessment) {
            AssessmentView()
                .environment(state)
        }
        .sheet(isPresented: $showBloodwork) {
            BloodworkView()
                .environment(state)
        }
    }

    // MARK: - Action Row (Assessment + Bloodwork entry points)

    private var actionRowCard: some View {
        HStack(spacing: 10) {
            PrimaryButton(title: "RUN ASSESSMENT", color: state.season.color) {
                showAssessment = true
            }
            OutlineButton(title: "BLOODWORK LOG") {
                showBloodwork = true
            }
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

            // PR number — stored in canonical lbs; display in user's preferred unit
            if let pr = state.prLog[state.statsLift] {
                let displayLbs: Double = statsMode == .oneRM
                    ? epley1RM(weight: pr, reps: 1)
                    : pr
                let unit = state.weightUnit
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(WeightFormat.display(displayLbs, unit: unit, decimals: 1, includeUnit: false))
                        .font(.system(size: 36, weight: .semibold, design: .monospaced))
                        .foregroundColor(state.season.color)
                    SectionLabel(text: statsMode == .oneRM ? "est 1RM (\(unit.label))" : "\(unit.label) PR")
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
                let unit = state.weightUnit
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(WeightFormat.display(a, unit: unit, decimals: 1, includeUnit: false))
                            .font(.monoBig)
                            .foregroundColor(AppColor.textPrimary)
                        Text("7-DAY AVG (\(unit.label))")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textFaint)
                    }
                    if let d = diff {
                        // Delta is a difference of canonical-lbs values; convert to user unit.
                        let displayDelta = WeightConverter.fromCanonical(d, to: unit)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(displayDelta >= 0 ? "+" : "")\(displayDelta, specifier: "%.1f")")
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

    /// Epley formula: estimated 1RM = weight × (1 + reps/30).
    /// Used for the PR display when statsMode == .oneRM (1 rep → trivially = weight).
    private func epley1RM(weight: Double, reps: Double) -> Double {
        guard reps > 0 else { return weight }
        return weight * (1 + reps / 30)
    }

    /// Brzycki: more accurate at low rep counts (1–5).
    private func brzycki1RM(weight: Double, reps: Double) -> Double {
        guard reps > 0 else { return weight }
        let denominator = 37.0 - reps
        guard denominator > 0 else { return weight }
        return weight * 36.0 / denominator
    }

    /// Selects Brzycki for 1–5 reps, Epley for 6+. Matches AssessmentView logic.
    private func bestE1RM(weight: Double, reps: Double) -> Double {
        reps <= 5 ? brzycki1RM(weight: weight, reps: reps) : epley1RM(weight: weight, reps: reps)
    }

    private func buildLiftHistory(for lift: String, mode: StatsMode) -> [LiftPoint] {
        // Raw per-week data collected in a first pass
        var weekRaw: [Int: [Double]] = [:]

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
                        // Volume accumulates per week (sets × reps × weight)
                        weekRaw[log.week, default: []].append(w * r)
                        continue
                    case .oneRM:
                        // Wave 2B: Brzycki for ≤5 reps, Epley for 6+
                        value = bestE1RM(weight: w, reps: r)
                    }
                    weekRaw[log.week, default: []].append(value)
                }
            }
        }

        // Reduce raw points to a single value per week (max for weight/1RM, sum for volume)
        var weekData: [Int: Double] = [:]
        for (week, values) in weekRaw {
            if mode == .volume {
                weekData[week] = values.reduce(0, +)
            } else {
                weekData[week] = values.max() ?? 0
            }
        }

        // Apply 4-week moving average to smooth the 1RM trend line
        let sorted = weekData.sorted { $0.key < $1.key }
        if mode == .oneRM && sorted.count > 1 {
            var smoothed: [Int: Double] = [:]
            for (i, item) in sorted.enumerated() {
                let window = sorted[max(0, i - 3)...i]
                let avg = window.map(\.value).reduce(0, +) / Double(window.count)
                smoothed[item.key] = avg
            }
            return smoothed.sorted { $0.key < $1.key }
                .map { LiftPoint(week: $0.key, value: $0.value) }
        }

        return sorted.map { LiftPoint(week: $0.key, value: $0.value) }
    }
}

// MARK: - Muscle Group Heatmap Card

struct MuscleGroupHeatmapCard: View {

    @Environment(AppState.self) private var state

    var body: some View {
        CardView {
            SectionLabel(text: "Muscle Group Volume — 4 Weeks")
                .padding(.bottom, 8)

            let weeklyVolume = compute4WeekSetsPerWeek()

            HStack(alignment: .top, spacing: 12) {
                // Front-body column
                VStack(alignment: .leading, spacing: 4) {
                    Text("FRONT")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                        .padding(.bottom, 2)
                    ForEach(MuscleGroup.heatmapGroups.filter(\.isFrontBody), id: \.self) { group in
                        heatmapRow(group: group, setsPerWeek: weeklyVolume[group] ?? 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(AppColor.border1)

                // Back-body column
                VStack(alignment: .leading, spacing: 4) {
                    Text("BACK")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                        .padding(.bottom, 2)
                    ForEach(MuscleGroup.heatmapGroups.filter { !$0.isFrontBody }, id: \.self) { group in
                        heatmapRow(group: group, setsPerWeek: weeklyVolume[group] ?? 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Legend
            heatmapLegend
                .padding(.top, 10)
        }
    }

    private func heatmapRow(group: MuscleGroup, setsPerWeek: Double) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(heatmapColor(group: group, setsPerWeek: setsPerWeek))
                .frame(width: 12, height: 12)
            Text(group.displayName)
                .font(.monoTiny)
                .foregroundColor(AppColor.textSecondary)
            Spacer()
            Text("\(Int(setsPerWeek))")
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 12) {
            legendItem(color: AppColor.cardBackground2,           label: "Low")
            legendItem(color: AppColor.spring.opacity(0.3),       label: "MEV")
            legendItem(color: AppColor.spring,                    label: "MAV")
            legendItem(color: AppColor.summer,                    label: "MRV")
            legendItem(color: AppColor.fall,                      label: "MRV+")
            Spacer()
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
        }
    }

    // MARK: - Volume Computation

    /// Returns average sets per week per muscle group over the last 4 weeks.
    /// Each completed set in a workout log contributes 1 set to all mapped muscle groups.
    private func compute4WeekSetsPerWeek() -> [MuscleGroup: Double] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -28, to: Date()) else { return [:] }
        let cutoffStr = AppState.sharedDateString(from: cutoff)

        var totalSets: [MuscleGroup: Int] = [:]

        for log in state.workoutLogs where log.date >= cutoffStr {
            for ex in log.exercises {
                let groups = MuscleGroupMap.groups(for: ex.name)
                for group in groups {
                    totalSets[group, default: 0] += ex.sets.count
                }
            }
        }

        // Divide by 4 to get sets/week
        return totalSets.mapValues { Double($0) / 4.0 }
    }

    // MARK: - Color Mapping

    private func heatmapColor(group: MuscleGroup, setsPerWeek: Double) -> Color {
        let t = group.volumeThresholds
        if setsPerWeek == 0    { return AppColor.cardBackground2 }
        if setsPerWeek < Double(t.mev) { return AppColor.cardBackground2 }
        if setsPerWeek < Double(t.mav) { return AppColor.spring.opacity(0.3) }
        if setsPerWeek < Double(t.mrv) { return AppColor.spring }
        if setsPerWeek == Double(t.mrv) { return AppColor.summer }
        return AppColor.fall  // above MRV — overreach zone
    }
}

// MARK: - ACWR Card

struct ACWRCard: View {

    @Environment(AppState.self) private var state

    var body: some View {
        CardView {
            SectionLabel(text: "ACWR — Workload Ratio")
                .padding(.bottom, 4)

            Text("Acute:Chronic Workload Ratio. Sweet spot 0.8–1.3. Above 1.5 = injury risk.")
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)

            let points = computeACWR()

            if points.count > 1 {
                Chart {
                    // Green sweet-spot band (0.8–1.3)
                    RectangleMark(
                        xStart: .value("Start", points.first?.week ?? 1),
                        xEnd:   .value("End",   points.last?.week ?? 8),
                        yStart: .value("Low",   0.8),
                        yEnd:   .value("High",  1.3)
                    )
                    .foregroundStyle(AppColor.spring.opacity(0.10))

                    // Red danger band (1.5+)
                    RectangleMark(
                        xStart: .value("Start", points.first?.week ?? 1),
                        xEnd:   .value("End",   points.last?.week ?? 8),
                        yStart: .value("Low",   1.5),
                        yEnd:   .value("High",  3.0)
                    )
                    .foregroundStyle(AppColor.fall.opacity(0.10))

                    // ACWR line
                    ForEach(points, id: \.week) { p in
                        LineMark(
                            x: .value("Week", p.week),
                            y: .value("ACWR", p.ratio)
                        )
                        .foregroundStyle(acwrColor(p.ratio))
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Week", p.week),
                            y: .value("ACWR", p.ratio)
                        )
                        .foregroundStyle(acwrColor(p.ratio))
                        .symbolSize(30)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { val in
                        AxisValueLabel {
                            if let w = val.as(Int.self) {
                                Text("W\(w)").font(.monoTiny).foregroundColor(AppColor.textFaint)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0.5, 0.8, 1.0, 1.3, 1.5, 2.0]) { val in
                        AxisGridLine().foregroundStyle(AppColor.border2.opacity(0.4))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(String(format: "%.1f", v))
                                    .font(.monoTiny)
                                    .foregroundColor(AppColor.textFaint)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...2.5)
                .frame(height: 160)
                .padding(.top, 4)

                // Latest ACWR readout
                if let latest = points.last {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(String(format: "%.2f", latest.ratio))
                            .font(.monoBig)
                            .foregroundColor(acwrColor(latest.ratio))
                        Text("current ACWR")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textFaint)
                        Spacer()
                        Text(acwrInterpretation(latest.ratio))
                            .font(.monoTiny)
                            .foregroundColor(acwrColor(latest.ratio))
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("Log sessions with RPE to compute ACWR")
                    .font(.appBody)
                    .foregroundColor(AppColor.textVeryFaint)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            }
        }
    }

    // MARK: - ACWR Computation

    private struct ACWRPoint {
        let week: Int
        let ratio: Double
    }

    /// Computes rolling-week ACWR for the last 8 weeks.
    ///
    /// Load for a given day:
    ///   - If SessionRPE exists for that date: RPE × durationMin
    ///   - Else if a WorkoutLog exists: flat 30 arbitrary units (session count proxy)
    ///
    /// Acute  = total load in the most recent 7 days.
    /// Chronic = average weekly load over the previous 28 days.
    /// ACWR   = acute / chronic (undefined / 0 → excluded from chart).
    private func computeACWR() -> [ACWRPoint] {
        // Build a date-keyed load dictionary from workoutLogs + sessionRPEs
        var dailyLoad: [String: Double] = [:]

        let loggedDates = Set(state.workoutLogs.map(\.date))
        for date in loggedDates {
            dailyLoad[date] = 30  // flat baseline when no RPE data
        }

        for rpe in state.sessionRPEs {
            // RPE × duration overrides the flat baseline for the same date
            dailyLoad[rpe.date] = Double(rpe.rpe) * Double(rpe.durationMin)
        }

        guard !dailyLoad.isEmpty else { return [] }

        var results: [ACWRPoint] = []
        let calendar = Calendar.current

        // Compute for each of the last 8 weeks
        for weekOffset in (0..<8).reversed() {
            guard let acuteEnd = calendar.date(byAdding: .day, value: -(weekOffset * 7), to: Date()),
                  let acuteStart = calendar.date(byAdding: .day, value: -7, to: acuteEnd),
                  let chronicStart = calendar.date(byAdding: .day, value: -28, to: acuteEnd)
            else { continue }

            let acuteStartStr   = AppState.sharedDateString(from: acuteStart)
            let acuteEndStr     = AppState.sharedDateString(from: acuteEnd)
            let chronicStartStr = AppState.sharedDateString(from: chronicStart)

            // Acute: sum loads in (acuteStart, acuteEnd]
            let acuteLoad = dailyLoad
                .filter { $0.key > acuteStartStr && $0.key <= acuteEndStr }
                .values.reduce(0, +)

            // Chronic: sum loads in the 28-day window, then average per week
            let chronicLoad = dailyLoad
                .filter { $0.key > chronicStartStr && $0.key <= acuteEndStr }
                .values.reduce(0, +) / 4.0

            guard chronicLoad > 0 else { continue }

            let week = 8 - weekOffset
            results.append(ACWRPoint(week: week, ratio: acuteLoad / chronicLoad))
        }

        return results
    }

    // MARK: - Helpers

    private func acwrColor(_ ratio: Double) -> Color {
        if ratio < 0.8  { return AppColor.textFaint }
        if ratio <= 1.3 { return AppColor.spring }
        if ratio <= 1.5 { return AppColor.summer }
        return AppColor.fall
    }

    private func acwrInterpretation(_ ratio: Double) -> String {
        if ratio < 0.8  { return "Under-training" }
        if ratio <= 1.3 { return "Optimal zone" }
        if ratio <= 1.5 { return "Caution — high load" }
        return "Danger — injury risk"
    }
}

// MARK: - Preview

#Preview {
    StatsView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
