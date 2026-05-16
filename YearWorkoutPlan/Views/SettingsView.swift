import SwiftUI

// MARK: - Settings View
/// User profile, plate configuration, HealthKit controls, autoregulation toggle,
/// travel mode, and notification preferences.
struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    // MARK: - Local state for profile fields (synced from/to state.userProfile)
    @State private var bodyweightKgText: String = ""
    @State private var heightCmText: String = ""
    @State private var ageText: String = ""
    @State private var sexMale: Bool = true
    @State private var barbellText: String = "45"
    @State private var availablePlates: Set<Double> = [45, 35, 25, 10, 5, 2.5]
    @State private var travelUntil: Date = Date()
    @State private var travelEnabled: Bool = false
    @State private var healthRefreshMessage: String? = nil
    @State private var isRefreshing: Bool = false
    @State private var showBloodwork: Bool = false
    @State private var notifStatusMessage: String? = nil

    private let standardPlates: [Double] = [45, 35, 25, 10, 5, 2.5, 1.25]
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        unitsSection
                        programStartSection
                        profileSection
                        plateSection
                        healthKitSection
                        notificationsSection
                        autoregSection
                        travelModeSection
                        bloodworkSection
                        resetSection
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyChanges()
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(state.season.color)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { loadFromState() }
    }

    // MARK: - Units Section

    /// Weight unit preference (lbs ↔ kg). Storage stays canonical (lbs); this
    /// only affects display + input. No data migration needed.
    private var unitsSection: some View {
        @Bindable var bindState = state

        return CardView {
            SectionLabel(text: "Units")
                .padding(.bottom, 8)

            HStack(spacing: 0) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    let isSelected = state.weightUnit == unit
                    Button {
                        state.weightUnit = unit
                    } label: {
                        Text(unit.label.uppercased())
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(isSelected ? .black : AppColor.textDimmed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isSelected ? state.season.color : AppColor.cardBackground2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColor.border2, lineWidth: 1)
            )
            .padding(.top, 4)

            Text("All weights — bodyweight, lifts, PRs, plate calculator — switch immediately. Stored data is unchanged.")
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
                .padding(.top, 8)
        }
    }

    // MARK: - Program Start Section

    /// Calendar anchoring: the date that corresponds to "Day 1 / Week 1 Monday".
    /// Letting the user pick this lets a mid-Spring install land in mid-Spring
    /// rather than starting at Week 1 of the program in May.
    private var programStartSection: some View {
        @Bindable var bindState = state

        return CardView {
            SectionLabel(text: "Program Start")
                .padding(.bottom, 8)

            // Day counter + current week summary
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(state.dayNumber + 1)")
                        .font(.monoBig)
                        .foregroundColor(state.season.color)
                    Text("DAY OF PROGRAM")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("WK \(state.currentWeek)")
                        .font(.monoBig)
                        .foregroundColor(AppColor.textPrimary)
                    Text(state.season.name.uppercased())
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }
                Spacer()
            }
            .padding(.bottom, 8)

            Divider().background(AppColor.border1)

            // Date picker
            HStack {
                Text("Start date")
                    .font(.appBody)
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                DatePicker("", selection: $bindState.programStartDate,
                           in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
            }
            .padding(.vertical, 8)

            Divider().background(AppColor.border1)

            // Auto-sync toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-sync to calendar")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Text("Week advances automatically each Monday")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }
                Spacer()
                Toggle("", isOn: $bindState.autoSyncWeekToCalendar)
                    .labelsHidden()
                    .tint(state.season.color)
                    .onChange(of: bindState.autoSyncWeekToCalendar) { _, on in
                        if on { state.syncWeekToCalendar() }
                    }
            }
            .padding(.vertical, 8)

            Divider().background(AppColor.border1)

            // Quick presets
            VStack(spacing: 6) {
                Button {
                    state.programStartDate = AppState.defaultProgramStartDate()
                    state.syncWeekToCalendar()
                } label: {
                    Text("ALIGN TO CURRENT SEASON")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(state.season.color)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button {
                    state.programStartDate = Calendar.current.startOfDay(for: Date())
                    state.syncWeekToCalendar()
                } label: {
                    Text("RESET TO WEEK 1 TODAY")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(AppColor.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColor.cardBackground2)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColor.border2, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        CardView {
            SectionLabel(text: "Profile")
                .padding(.bottom, 8)

            SettingsRow(label: "Bodyweight (kg)") {
                TextField("75.0", text: $bodyweightKgText)
                    .settingsTextField()
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
            }

            Divider().background(AppColor.border1)

            SettingsRow(label: "Height (cm)") {
                TextField("178", text: $heightCmText)
                    .settingsTextField()
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
            }

            Divider().background(AppColor.border1)

            SettingsRow(label: "Age") {
                TextField("30", text: $ageText)
                    .settingsTextField()
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }

            Divider().background(AppColor.border1)

            SettingsRow(label: "Sex") {
                HStack(spacing: 0) {
                    sexPill("Male", selected: sexMale) { sexMale = true }
                    sexPill("Female", selected: !sexMale) { sexMale = false }
                }
            }
        }
    }

    // MARK: - Plate Section

    private var plateSection: some View {
        CardView {
            SectionLabel(text: "Plate Profile")
                .padding(.bottom, 8)

            SettingsRow(label: "Barbell (lbs)") {
                TextField("45", text: $barbellText)
                    .settingsTextField()
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
            }

            Divider().background(AppColor.border1)

            VStack(alignment: .leading, spacing: 8) {
                Text("Available plates (lbs)")
                    .font(.appSmall)
                    .foregroundColor(AppColor.textMuted)

                // Wrap in a flex grid of pill toggles
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 8
                ) {
                    ForEach(standardPlates, id: \.self) { plate in
                        let isOn = availablePlates.contains(plate)
                        Button {
                            if isOn { availablePlates.remove(plate) }
                            else    { availablePlates.insert(plate) }
                        } label: {
                            Text(plateName(plate))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(isOn ? .black : AppColor.textDimmed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isOn ? state.season.color : AppColor.cardBackground2)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isOn ? state.season.color : AppColor.border2, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: isOn)
                    }
                }
            }
        }
    }

    // MARK: - HealthKit Section

    private var healthKitSection: some View {
        CardView {
            SectionLabel(text: "Recovery & HealthKit")
                .padding(.bottom, 8)

            let isAvailable = HealthKitManager.shared.isAvailable
            HStack {
                Text(isAvailable ? "HealthKit available" : "HealthKit unavailable")
                    .font(.appBody)
                    .foregroundColor(isAvailable ? AppColor.textSecondary : AppColor.textDimmed)
                Spacer()
                Circle()
                    .fill(isAvailable ? AppColor.spring : AppColor.textFaint)
                    .frame(width: 8, height: 8)
            }

            Divider().background(AppColor.border1).padding(.vertical, 6)

            VStack(spacing: 8) {
                PrimaryButton(title: "REAUTHORIZE APPLE HEALTH", color: AppColor.infoBlue) {
                    Task {
                        try? await HealthKitManager.shared.requestAuthorization()
                        healthRefreshMessage = "Authorization requested."
                    }
                }

                OutlineButton(title: "REFRESH NOW") {
                    isRefreshing = true
                    Task {
                        await state.refreshHealthData()
                        isRefreshing = false
                        healthRefreshMessage = "Refreshed at \(formattedNow())"
                    }
                }
            }

            if let msg = healthRefreshMessage {
                Text(msg)
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textDimmed)
                    .padding(.top, 4)
            }

            if isRefreshing {
                HStack {
                    ProgressView()
                        .tint(AppColor.textMuted)
                    Text("Fetching from HealthKit…")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        @Bindable var bindState = state
        return CardView {
            SectionLabel(text: "Notifications")
                .padding(.bottom, 8)

            // Enable / disable all notifications
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable notifications")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Text("Pre-workout reminders, weekly summary, supplement timing.")
                        .font(.appSmall)
                        .foregroundColor(AppColor.textDimmed)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $bindState.notificationsEnabled)
                    .tint(state.season.color)
                    .labelsHidden()
                    .onChange(of: state.notificationsEnabled) { _, enabled in
                        if enabled {
                            Task {
                                do {
                                    let granted = try await NotificationManager.shared.requestAuthorization()
                                    if !granted {
                                        // Revert — user denied
                                        state.notificationsEnabled = false
                                        notifStatusMessage = "Permission denied. Enable in iOS Settings > Notifications."
                                    } else {
                                        await rescheduleAll()
                                        notifStatusMessage = "Notifications scheduled."
                                    }
                                } catch {
                                    state.notificationsEnabled = false
                                    notifStatusMessage = "Could not request permission."
                                }
                            }
                        } else {
                            Task { await NotificationManager.shared.cancelAll() }
                            notifStatusMessage = "All notifications cancelled."
                        }
                    }
            }

            if state.notificationsEnabled {
                Divider().background(AppColor.border1).padding(.vertical, 8)

                // Workout time picker
                SettingsRow(label: "Workout time") {
                    HStack(spacing: 4) {
                        Stepper("", value: $bindState.workoutTimeHour, in: 4...23)
                            .labelsHidden()
                            .frame(width: 80)
                        Text(String(format: "%02d:00", state.workoutTimeHour))
                            .font(.monoSmall)
                            .foregroundColor(AppColor.textPrimary)
                    }
                }

                Divider().background(AppColor.border1).padding(.vertical, 4)

                // Workout day chips (Mon–Sun)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active days")
                        .font(.appSmall)
                        .foregroundColor(AppColor.textMuted)
                    HStack(spacing: 4) {
                        ForEach(0..<7) { idx in
                            let bit = 1 << idx
                            let isOn = (state.workoutDaysMask & bit) != 0
                            Button {
                                state.workoutDaysMask ^= bit   // toggle the bit
                            } label: {
                                Text(dayLabels[idx])
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isOn ? .black : AppColor.textDimmed)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(isOn ? state.season.color : AppColor.cardBackground2)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isOn ? state.season.color : AppColor.border2, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: isOn)
                        }
                    }
                }

                Divider().background(AppColor.border1).padding(.vertical, 4)

                // Weekly summary toggle
                HStack {
                    Text("Weekly summary (Sun 19:00)")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Spacer()
                    Toggle("", isOn: $bindState.weeklySummaryEnabled)
                        .tint(state.season.color)
                        .labelsHidden()
                }

                Divider().background(AppColor.border1).padding(.vertical, 4)

                // Supplement reminders toggle
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Supplement reminders")
                            .font(.appBody)
                            .foregroundColor(AppColor.textSecondary)
                        Text("Uses your active supplement stack.")
                            .font(.appSmall)
                            .foregroundColor(AppColor.textDimmed)
                    }
                    Spacer()
                    Toggle("", isOn: $bindState.supplementRemindersEnabled)
                        .tint(state.season.color)
                        .labelsHidden()
                }

                Divider().background(AppColor.border1).padding(.vertical, 8)

                // Reschedule all button
                OutlineButton(title: "RESCHEDULE ALL NOW") {
                    Task { await rescheduleAll(); notifStatusMessage = "All notifications rescheduled." }
                }
            }

            if let msg = notifStatusMessage {
                Text(msg)
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textDimmed)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Autoregulation Section

    private var autoregSection: some View {
        @Bindable var bindState = state
        return CardView {
            SectionLabel(text: "Autoregulation")
                .padding(.bottom, 8)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Autoreg suggestions")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Text("Computes next-session weight from last-week RIR vs target. Shown below the last set of each exercise.")
                        .font(.appSmall)
                        .foregroundColor(AppColor.textDimmed)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $bindState.autoregEnabled)
                    .tint(state.season.color)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Travel Mode Section

    private var travelModeSection: some View {
        CardView {
            SectionLabel(text: "Travel Mode")
                .padding(.bottom, 8)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Travel Mode")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Text("While active, exercises swap to BW/hotel-gym variants automatically.")
                        .font(.appSmall)
                        .foregroundColor(AppColor.textDimmed)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $travelEnabled)
                    .tint(AppColor.summer)
                    .labelsHidden()
            }

            if travelEnabled {
                Divider().background(AppColor.border1).padding(.vertical, 6)

                HStack {
                    Text("Travel until")
                        .font(.appSmall)
                        .foregroundColor(AppColor.textMuted)
                    Spacer()
                    DatePicker("", selection: $travelUntil, in: Date()..., displayedComponents: .date)
                        .colorScheme(.dark)
                        .labelsHidden()
                }
            }
        }
    }

    // MARK: - Bloodwork Section

    private var bloodworkSection: some View {
        CardView {
            SectionLabel(text: "Bloodwork")
                .padding(.bottom, 8)

            Button {
                showBloodwork = true
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.fall)
                    Text("View Bloodwork Log")
                        .font(.appBody)
                        .foregroundColor(AppColor.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.textFaint)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showBloodwork) {
                BloodworkView()
                    .environment(state)
            }
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        CardView {
            SectionLabel(text: "Developer")
                .padding(.bottom, 8)

            Button {
                state.onboardingCompleted = false
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.fall)
                    Text("Reset Onboarding")
                        .font(.appBody)
                        .foregroundColor(AppColor.fall)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Notification Scheduling

    /// Cancels all pending notifications then re-schedules based on current prefs.
    private func rescheduleAll() async {
        guard state.notificationsEnabled else { return }
        await NotificationManager.shared.cancelAll()

        // Convert workoutDaysMask (bit 0 = Monday) to Calendar weekday integers
        // (Calendar: 1 = Sunday, 2 = Monday … 7 = Saturday)
        var weekdays: Set<Int> = []
        for bit in 0..<7 {
            if (state.workoutDaysMask & (1 << bit)) != 0 {
                // bit 0 = Monday → weekday 2; bit 6 = Sunday → weekday 1
                let calWeekday = bit == 6 ? 1 : bit + 2
                weekdays.insert(calWeekday)
            }
        }
        await NotificationManager.shared.schedulePreWorkoutReminder(
            at: state.workoutTimeHour,
            minute: state.workoutTimeMinute,
            weekdays: weekdays
        )

        if state.weeklySummaryEnabled {
            await NotificationManager.shared.scheduleWeeklySummary()
        }

        if state.supplementRemindersEnabled {
            let active = SupplementList.all.filter { state.activeSupplementIDs.contains($0.id) }
            await NotificationManager.shared.scheduleSupplementReminders(
                supplements: active,
                userWorkoutHour: state.workoutTimeHour
            )
        }
    }

    // MARK: - Load / Apply

    private func loadFromState() {
        let p = state.userProfile
        bodyweightKgText = p.bodyweightKg.map { String(format: "%.1f", $0) } ?? ""
        heightCmText     = p.heightCm.map { String(format: "%.0f", $0) } ?? ""
        ageText          = p.ageYears.map { "\($0)" } ?? ""
        sexMale          = p.sexMale
        barbellText      = String(format: "%.0f", p.plateProfile.barbellLbs)
        availablePlates  = Set(p.plateProfile.availablePlatesLbs)
        travelEnabled    = state.travelModeUntil != nil && state.travelModeUntil! > Date()
        travelUntil      = state.travelModeUntil ?? Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
    }

    private func applyChanges() {
        var p = state.userProfile
        p.bodyweightKg = Double(bodyweightKgText)
        p.heightCm     = Double(heightCmText)
        p.ageYears     = Int(ageText)
        p.sexMale      = sexMale
        p.plateProfile.barbellLbs        = Double(barbellText) ?? 45
        p.plateProfile.availablePlatesLbs = availablePlates.sorted(by: >)
        state.userProfile = p  // triggers save() via didSet

        state.travelModeUntil = travelEnabled ? travelUntil : nil
    }

    // MARK: - Sub-view helpers

    private func sexPill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .default))
                .foregroundColor(selected ? .black : AppColor.textDimmed)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? state.season.color : AppColor.cardBackground2)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    private func plateName(_ w: Double) -> String {
        w == w.rounded() ? "\(Int(w))" : String(format: "%.2g", w)
    }

    private func formattedNow() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: Date())
    }
}

// MARK: - Settings Row
/// Label on the left, trailing content on the right. Keeps form rows consistent.
private struct SettingsRow<Trailing: View>: View {
    let label: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(label)
                .font(.appBody)
                .foregroundColor(AppColor.textSecondary)
            Spacer()
            trailing()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings TextField Modifier
private extension View {
    func settingsTextField() -> some View {
        self
            .font(.monoSmall)
            .foregroundColor(AppColor.textPrimary)
            .multilineTextAlignment(.trailing)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(AppColor.cardBackground2)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColor.border2, lineWidth: 1)
            )
    }
}
