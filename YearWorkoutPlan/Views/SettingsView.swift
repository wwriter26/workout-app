import SwiftUI

// MARK: - Settings View
/// User profile, plate configuration, HealthKit controls, autoregulation toggle,
/// and travel mode. Presented as a sheet from the top bar gear icon.
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

    private let standardPlates: [Double] = [45, 35, 25, 10, 5, 2.5, 1.25]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        profileSection
                        plateSection
                        healthKitSection
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
