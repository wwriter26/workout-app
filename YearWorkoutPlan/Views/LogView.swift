import SwiftUI

// MARK: - Log Filter
private enum LogFilter: String, CaseIterable {
    case all        = "All"
    case thisWeek   = "This Week"
    case thisMonth  = "This Month"
    case thisSeason = "This Season"
}

// MARK: - Log View
struct LogView: View {
    @Environment(AppState.self) private var state
    @State private var showShareSheet = false
    @State private var exportData: Data?
    @State private var filter: LogFilter = .all
    @State private var showDatePicker = false
    @State private var exportStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var exportEnd = Date()

    // Post-save RPE flow
    @State private var showRPESheet = false
    @State private var sessionStartDate: Date = Date()  // captured when logging starts
    @State private var rpeValue: Double = 7
    @State private var durationMin: Double = 60

    private var filteredLogs: [WorkoutLog] {
        let all = state.workoutLogs.reversed() as [WorkoutLog]
        switch filter {
        case .all:
            return all
        case .thisWeek:
            let start = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
            return all.filter { parseDate($0.date) >= start }
        case .thisMonth:
            let comps = Calendar.current.dateComponents([.year, .month], from: Date())
            let start = Calendar.current.date(from: comps) ?? Date()
            return all.filter { parseDate($0.date) >= start }
        case .thisSeason:
            return all.filter { $0.week == state.currentWeek || Seasons.season(for: $0.week).name == state.season.name }
        }
    }

    // Weekly summary for "This Week"
    private var thisWeekLogs: [WorkoutLog] {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return state.workoutLogs.filter { parseDate($0.date) >= start }
    }

    private var weeklyVolume: Double {
        thisWeekLogs.reduce(0.0) { total, log in
            total + log.exercises.reduce(0.0) { $0 + sessionVolume($1) }
        }
    }

    private var streakCount: Int {
        // Count consecutive calendar days (going backwards) that have a log entry
        let sortedDates = state.workoutLogs
            .map { parseDate($0.date) }
            .sorted(by: >)
        guard !sortedDates.isEmpty else { return 0 }
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        for date in sortedDates {
            let logDay = Calendar.current.startOfDay(for: date)
            if logDay == checkDate {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if logDay < checkDate {
                break
            }
        }
        return streak
    }

    var body: some View {
        @Bindable var bindState = state
        ScrollView {
            VStack(spacing: 10) {
                // Action row
                HStack(spacing: 8) {
                    PrimaryButton(title: "+ LOG TODAY", color: state.season.color) {
                        state.logWeights = [:]
                        sessionStartDate = Date()
                        state.isLoggingSession = true
                    }
                    OutlineButton(title: "EXPORT") {
                        showDatePicker = true
                    }
                    .frame(width: 90)
                }

                // Filter row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(LogFilter.allCases, id: \.self) { f in
                            let isSelected = filter == f
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { filter = f }
                            } label: {
                                Text(f.rawValue)
                                    .font(.system(size: 11, weight: .semibold, design: .default))
                                    .foregroundColor(isSelected ? state.season.color : AppColor.textDimmed)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? state.season.color.opacity(0.13) : AppColor.cardBackground)
                                    .cornerRadius(7)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(isSelected ? state.season.color : AppColor.border2, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Weekly summary card
                weekSummaryCard

                // Streak card
                if streakCount > 0 { streakCard }

                // Inline session log form
                if state.isLoggingSession { sessionLogForm }

                // PR tiles
                if !state.prLog.isEmpty { prSection }

                // History
                if filteredLogs.isEmpty {
                    emptyHistoryCard
                } else {
                    ForEach(filteredLogs) { entry in
                        HistoryEntryCard(entry: entry, season: Seasons.season(for: entry.week), weightUnit: state.weightUnit)
                    }
                }

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showRPESheet) {
            SessionRPESheet(
                sessionLabel: state.todaySession.label,
                seasonColor: state.season.color,
                rpe: $rpeValue,
                durationMin: $durationMin
            ) {
                // Save RPE to state
                state.logSessionRPE(
                    rpe: Int(rpeValue),
                    durationMin: Int(durationMin)
                )
                // Push workout to HealthKit (fire-and-forget — failure is non-fatal)
                let isCardio = state.adjustedSession.isCardio
                let endDate = Date()
                Task {
                    try? await HealthKitManager.shared.saveWorkout(
                        start: sessionStartDate,
                        end: endDate,
                        isCardio: isCardio,
                        activeEnergyKcal: nil,
                        avgHeartRate: nil
                    )
                }
                showRPESheet = false
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportData {
                ShareSheet(items: [data])
            }
        }
        .sheet(isPresented: $showDatePicker) {
            ExportOptionsSheet(
                startDate: $exportStart,
                endDate: $exportEnd,
                seasonColor: state.season.color
            ) { format in
                exportData = buildExportData(format: format)
                showDatePicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showShareSheet = exportData != nil
                }
            }
        }
    }

    // MARK: - Weekly Summary
    private var weekSummaryCard: some View {
        let sessionCount = thisWeekLogs.count
        // Estimate planned sessions this week (5 training days as default)
        let planned = 5

        return CardView {
            SectionLabel(text: "This Week")
            HStack(spacing: 16) {
                SummaryTile(value: "\(sessionCount)/\(planned)", label: "Sessions")
                SummaryTile(value: weeklyVolume > 0 ? String(format: "%.0f", weeklyVolume) : "—",
                            label: "Vol (\(state.weightUnit.label))")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        CardView {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColor.fall)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streakCount) day streak")
                        .font(.appSubhead)
                        .foregroundColor(AppColor.textPrimary)
                    Text("Keep the momentum going")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textDimmed)
                }
                Spacer()
            }
        }
    }

    // MARK: - Session Log Form (uses shared SetLogRow)
    private var sessionLogForm: some View {
        @Bindable var bindState = state
        let session = state.todaySession

        return CardView {
            HStack {
                Text("\(state.todayDayKey) — \(session.label)")
                    .font(.appHeading)
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Button {
                    state.isLoggingSession = false
                } label: {
                    Text("✕")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColor.textMuted)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            ForEach(Array(session.exercises.enumerated()), id: \.offset) { i, ex in
                VStack(alignment: .leading, spacing: 6) {
                    // Exercise header
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                        Text("\(ex.sets) × \(ex.reps) · RIR \(ex.rir)")
                            .font(.appBody)
                            .foregroundColor(AppColor.textDimmed)
                    }

                    // One SetLogRow per set using the shared component
                    ForEach(0..<ex.sets, id: \.self) { si in
                        SetLogRow(
                            exIndex: i,
                            setIndex: si,
                            exercise: ex,
                            seasonColor: state.season.color,
                            prevSetForThisExercise: state.prevSetForExercise(ex.name),
                            completedSets: $bindState.completedSets,
                            logWeights: $bindState.logWeights,
                            userPlateProfile: state.userProfile.plateProfile,
                            weightUnit: state.weightUnit,
                            onComplete: {}
                        )
                    }

                    // Autoreg hint below last set
                    AutoregHint(
                        suggestedWeightLbs: state.suggestedNextWeight(
                            forExercise: ex.name,
                            targetRIRString: ex.rir
                        ),
                        weightUnit: state.weightUnit,
                        seasonColor: state.season.color
                    )
                }
                .padding(.vertical, 8)
                if i < session.exercises.count - 1 {
                    Divider().background(AppColor.border1)
                }
            }

            // Save triggers the RPE sheet post-save
            PrimaryButton(title: "SAVE SESSION ✓", color: state.season.color) {
                state.saveSession()
                showRPESheet = true
            }
            .padding(.top, 8)
        }
    }

    // MARK: - PR Section
    private var prSection: some View {
        CardView {
            SectionLabel(text: "Personal Records")
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach(SupplementList.bigLifts, id: \.self) { lift in
                    if let w = state.prLog[lift] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(WeightFormat.display(w, unit: state.weightUnit))
                                .font(.monoBig)
                                .foregroundColor(state.season.color)
                            Text(lift)
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textDimmed)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.cardBackground2)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColor.border2, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Empty History
    private var emptyHistoryCard: some View {
        CardView {
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(AppColor.textVeryFaint)
                Text("No sessions logged yet.")
                    .font(.appBody)
                    .foregroundColor(AppColor.textFaint)
                Text("Start logging to track progress.")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textVeryFaint)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Helpers
    private func parseDate(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.date(from: str) ?? .distantPast
    }

    private func sessionVolume(_ ex: ExerciseLog) -> Double {
        ex.sets.reduce(0.0) { total, set in
            let w = Double(set.weight) ?? 0
            let r = Double(set.reps) ?? 1
            return total + (w * r)
        }
    }

    private func buildExportData(format: ExportFormat) -> Data? {
        let inRange = state.workoutLogs.filter {
            let d = parseDate($0.date)
            return d >= exportStart && d <= exportEnd
        }
        switch format {
        case .json:
            let container = ExportContainer(
                currentWeek: state.currentWeek,
                bodyweightLog: state.bodyweightLog,
                workoutLogs: inRange,
                prLog: state.prLog
            )
            return try? JSONEncoder().encode(container)
        case .csv:
            var lines = ["Date,Week,Day,Session,Exercise,Set,Weight (lbs),Reps,RIR"]
            for log in inRange {
                for ex in log.exercises {
                    for (si, set) in ex.sets.enumerated() {
                        lines.append([log.date, "\(log.week)", log.dayKey,
                                       "\"\(log.sessionLabel)\"", "\"\(ex.name)\"",
                                       "\(si + 1)", set.weight, set.reps, set.rir].joined(separator: ","))
                    }
                }
            }
            return lines.joined(separator: "\n").data(using: .utf8)
        }
    }
}

// MARK: - Session RPE Sheet
/// Post-save sheet that collects session RPE (0–10) and duration in minutes.
/// Presented automatically after the user taps "SAVE SESSION ✓" in sessionLogForm.
struct SessionRPESheet: View {
    @Environment(\.dismiss) private var dismiss

    let sessionLabel: String
    let seasonColor: Color
    @Binding var rpe: Double
    @Binding var durationMin: Double
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    CardView {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionLabel(text: "How was \(sessionLabel)?")

                            // RPE slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Session RPE")
                                        .font(.appBody)
                                        .foregroundColor(AppColor.textSecondary)
                                    Spacer()
                                    Text("\(Int(rpe))/10")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundColor(rpeColor)
                                }
                                Slider(value: $rpe, in: 0...10, step: 1)
                                    .tint(rpeColor)
                                HStack {
                                    Text("Easy")
                                        .font(.monoTiny)
                                        .foregroundColor(AppColor.textFaint)
                                    Spacer()
                                    Text("Max effort")
                                        .font(.monoTiny)
                                        .foregroundColor(AppColor.textFaint)
                                }
                            }

                            Divider().background(AppColor.border1)

                            // Duration stepper
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Duration")
                                        .font(.appBody)
                                        .foregroundColor(AppColor.textSecondary)
                                    Spacer()
                                    Text("\(Int(durationMin)) min")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppColor.textPrimary)
                                }
                                Slider(value: $durationMin, in: 15...180, step: 5)
                                    .tint(seasonColor)
                            }
                        }
                    }

                    PrimaryButton(title: "SAVE & DONE", color: seasonColor) {
                        onSave()
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                        .foregroundColor(AppColor.textFaint)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var rpeColor: Color {
        switch Int(rpe) {
        case 0...4: return AppColor.spring
        case 5...7: return AppColor.summer
        default:    return AppColor.fall
        }
    }
}

// MARK: - Export Format
enum ExportFormat { case json, csv }

// MARK: - Export Options Sheet
struct ExportOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date
    @Binding var endDate: Date
    let seasonColor: Color
    let onExport: (ExportFormat) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    CardView {
                        SectionLabel(text: "Date Range")
                        DatePicker("From", selection: $startDate, displayedComponents: .date)
                            .colorScheme(.dark)
                        Divider().background(AppColor.border1)
                        DatePicker("To", selection: $endDate, displayedComponents: .date)
                            .colorScheme(.dark)
                    }

                    VStack(spacing: 10) {
                        PrimaryButton(title: "EXPORT AS JSON", color: seasonColor) {
                            onExport(.json)
                            dismiss()
                        }
                        PrimaryButton(title: "EXPORT AS CSV", color: AppColor.infoBlue) {
                            onExport(.csv)
                            dismiss()
                        }
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Export Options")
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

// MARK: - Summary Tile
private struct SummaryTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.monoBig)
                .foregroundColor(AppColor.textPrimary)
            Text(label.uppercased())
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppColor.cardBackground2)
        .cornerRadius(8)
    }
}

// MARK: - History Entry Card
private struct HistoryEntryCard: View {
    let entry: WorkoutLog
    let season: Season
    let weightUnit: WeightUnit
    @State private var isExpanded = false

    private var exercisesWithWeight: [ExerciseLog] {
        entry.exercises.filter { ex in ex.sets.contains { !$0.weight.isEmpty } }
    }

    /// Stored weights are canonical lbs; convert volume to display unit.
    private func volumeString(for ex: ExerciseLog) -> String {
        let totalLbs = ex.sets.reduce(0.0) { sum, s in
            let w = Double(s.weight) ?? 0
            let r = Double(s.reps) ?? 1
            return sum + w * r
        }
        guard totalLbs > 0 else { return "" }
        return "\(WeightFormat.display(totalLbs, unit: weightUnit, decimals: 0)) vol"
    }

    var body: some View {
        CardView {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            SectionLabel(text: entry.date)
                            BadgeView("WK \(entry.week) · \(entry.dayKey)",
                                      foreground: AppColor.textMuted,
                                      background: Color(hex: "#1F2937"))
                        }
                        Text(entry.sessionLabel)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.textFaint)
                }
            }
            .buttonStyle(.plain)

            // Volume summary line (always visible)
            if !exercisesWithWeight.isEmpty {
                let totalVol = exercisesWithWeight.reduce(0.0) { sum, ex in
                    sum + ex.sets.reduce(0.0) { s2, set in
                        s2 + (Double(set.weight) ?? 0) * (Double(set.reps) ?? 1)
                    }
                }
                Text("Total volume: \(WeightFormat.display(totalVol, unit: weightUnit, decimals: 0))")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textDimmed)
                    .padding(.top, 4)
            }

            // Expanded sets
            if isExpanded {
                Divider().background(AppColor.border1).padding(.top, 8)

                ForEach(exercisesWithWeight) { ex in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(ex.name)
                                .font(.appBody)
                                .foregroundColor(AppColor.textMuted)
                            Spacer()
                            let vol = volumeString(for: ex)
                            if !vol.isEmpty {
                                Text(vol)
                                    .font(.monoTiny)
                                    .foregroundColor(AppColor.textDimmed)
                            }
                        }
                        .padding(.top, 4)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(ex.sets.filter { !$0.weight.isEmpty }) { s in
                                    // Display the canonical-lbs weight in user's preferred unit.
                                    let displayW: String = {
                                        if let lbs = Double(s.weight) {
                                            return WeightFormat.display(lbs, unit: weightUnit, decimals: 1, includeUnit: false)
                                        }
                                        return s.weight
                                    }()
                                    Text("\(displayW)×\(s.reps)")
                                        .font(.monoSmall)
                                        .foregroundColor(AppColor.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppColor.cardBackground2)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
