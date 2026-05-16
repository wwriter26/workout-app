import SwiftUI

// MARK: - Bloodwork View

/// Displays a list of past bloodwork entries and provides an entry form sheet.
/// Threshold coloring follows evidence-based reference ranges for athlete health.
struct BloodworkView: View {

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var showEntryForm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()

                if state.bloodworkHistory.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(state.bloodworkHistory.reversed()) { entry in
                                BloodworkEntryCard(entry: entry)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Bloodwork Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColor.textMuted)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEntryForm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(state.season.color)
                    }
                }
            }
            .sheet(isPresented: $showEntryForm) {
                BloodworkEntryForm()
                    .environment(state)
            }
            .preferredColorScheme(.dark)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.system(size: 42))
                .foregroundColor(AppColor.textVeryFaint)

            Text("No bloodwork logged yet")
                .font(.appHeading)
                .foregroundColor(AppColor.textDimmed)

            Text("Track key biomarkers over time to optimise recovery and health.")
                .font(.appBody)
                .foregroundColor(AppColor.textFaint)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            PrimaryButton(title: "ADD ENTRY", color: state.season.color) {
                showEntryForm = true
            }
            .frame(maxWidth: 220)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Entry Card

/// Displays a single bloodwork entry with all non-nil values threshold-coloured.
private struct BloodworkEntryCard: View {

    let entry: BloodworkEntry

    var body: some View {
        CardView {
            SectionLabel(text: entry.date)
                .padding(.bottom, 8)

            // Render only the fields that are non-nil
            VStack(spacing: 6) {
                if let v = entry.ferritinNgMl {
                    metricRow("Ferritin",           value: v, unit: "ng/mL",   color: ferritinColor(v))
                }
                if let v = entry.vitaminDNgMl {
                    metricRow("Vit D 25(OH)D",      value: v, unit: "ng/mL",   color: vitaminDColor(v))
                }
                if let v = entry.omega3IndexPct {
                    metricRow("Omega-3 Index",       value: v, unit: "%",       color: omega3Color(v))
                }
                if let v = entry.fastingGlucoseMgDl {
                    metricRow("Fasting Glucose",     value: v, unit: "mg/dL",   color: glucoseColor(v))
                }
                if let v = entry.hba1cPct {
                    metricRow("HbA1c",               value: v, unit: "%",       color: hba1cColor(v),   format: "%.1f")
                }
                if let v = entry.totalTestosteroneNgDl {
                    metricRow("Total T",             value: v, unit: "ng/dL",   color: totalTColor(v))
                }
                if let v = entry.freeTestosteronePgMl {
                    metricRow("Free T",              value: v, unit: "pg/mL",   color: AppColor.textPrimary)
                }
                if let v = entry.totalCholesterolMgDl {
                    metricRow("Total Cholesterol",   value: v, unit: "mg/dL",   color: AppColor.textPrimary)
                }
                if let v = entry.ldlMgDl {
                    metricRow("LDL",                 value: v, unit: "mg/dL",   color: ldlColor(v))
                }
                if let v = entry.hdlMgDl {
                    metricRow("HDL",                 value: v, unit: "mg/dL",   color: hdlColor(v))
                }
                if let v = entry.hsCRPmgL {
                    metricRow("hs-CRP",              value: v, unit: "mg/L",    color: crpColor(v),     format: "%.2f")
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.appSmall)
                    .foregroundColor(AppColor.textDimmed)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func metricRow(
        _ label: String,
        value: Double,
        unit: String,
        color: Color,
        format: String = "%.0f"
    ) -> some View {
        HStack {
            Text(label)
                .font(.appBody)
                .foregroundColor(AppColor.textSecondary)
            Spacer()
            Text("\(String(format: format, value)) \(unit)")
                .font(.monoSmall)
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Threshold Color Functions

    private func ferritinColor(_ v: Double) -> Color {
        if v < 30  { return AppColor.fall }
        if v < 40  { return AppColor.summer }
        return AppColor.spring  // ≥40 is optimal; >70 is elite — still green
    }

    private func vitaminDColor(_ v: Double) -> Color {
        if v < 30  { return AppColor.fall }
        if v < 40  { return AppColor.summer }
        if v <= 60 { return AppColor.spring }
        return AppColor.summer  // >60 — unnecessarily high
    }

    private func omega3Color(_ v: Double) -> Color {
        if v < 4   { return AppColor.fall }
        if v < 8   { return AppColor.summer }
        return AppColor.spring  // 8–12 optimal
    }

    private func glucoseColor(_ v: Double) -> Color {
        if v > 100 { return AppColor.fall }
        if v >= 90 { return AppColor.summer }
        return AppColor.spring  // <90
    }

    private func hba1cColor(_ v: Double) -> Color {
        if v > 5.7 { return AppColor.fall }
        if v >= 5.4 { return AppColor.summer }
        return AppColor.spring  // <5.4
    }

    private func totalTColor(_ v: Double) -> Color {
        if v < 300  { return AppColor.fall }
        if v < 500  { return AppColor.summer }
        if v <= 900 { return AppColor.spring }
        return AppColor.summer  // >900 — elevated
    }

    private func ldlColor(_ v: Double) -> Color {
        if v > 130 { return AppColor.fall }
        if v > 100 { return AppColor.summer }
        return AppColor.spring  // <100 (≤70 = optimal, still green)
    }

    private func hdlColor(_ v: Double) -> Color {
        if v < 40  { return AppColor.fall }
        if v <= 60 { return AppColor.summer }
        return AppColor.spring  // >60
    }

    private func crpColor(_ v: Double) -> Color {
        if v > 3   { return AppColor.fall }
        if v >= 1  { return AppColor.summer }
        return AppColor.spring  // <1
    }
}

// MARK: - Entry Form

/// Sheet form for entering a new bloodwork result. All biomarker fields are optional.
struct BloodworkEntryForm: View {

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date = Date()

    // Biomarker fields
    @State private var ferritin: String = ""
    @State private var vitaminD: String = ""
    @State private var omega3: String = ""
    @State private var glucose: String = ""
    @State private var hba1c: String = ""
    @State private var totalT: String = ""
    @State private var freeT: String = ""
    @State private var totalCholesterol: String = ""
    @State private var ldl: String = ""
    @State private var hdl: String = ""
    @State private var hsCRP: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()

                Form {
                    dateSection
                    hematologySection
                    metabolicSection
                    hormonalSection
                    lipidsSection
                    inflammationSection
                    notesSection
                }
                .scrollContentBackground(.hidden)
                .background(AppColor.appBackground)
            }
            .navigationTitle("New Bloodwork Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColor.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(state.season.color)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Form Sections

    private var dateSection: some View {
        Section {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .colorScheme(.dark)
                .foregroundColor(AppColor.textSecondary)
        } header: {
            sectionHeader("Date")
        }
    }

    private var hematologySection: some View {
        Section {
            biomarkerRow("Ferritin", placeholder: "50", unit: "ng/mL", binding: $ferritin)
            biomarkerRow("Vit D 25(OH)D", placeholder: "50", unit: "ng/mL", binding: $vitaminD)
            biomarkerRow("Omega-3 Index", placeholder: "8.0", unit: "%", binding: $omega3)
        } header: {
            sectionHeader("Iron & Vitamins")
        }
    }

    private var metabolicSection: some View {
        Section {
            biomarkerRow("Fasting Glucose", placeholder: "85", unit: "mg/dL", binding: $glucose)
            biomarkerRow("HbA1c", placeholder: "5.2", unit: "%", binding: $hba1c)
        } header: {
            sectionHeader("Metabolic")
        }
    }

    private var hormonalSection: some View {
        Section {
            biomarkerRow("Total Testosterone", placeholder: "600", unit: "ng/dL", binding: $totalT)
            biomarkerRow("Free Testosterone", placeholder: "12", unit: "pg/mL", binding: $freeT)
        } header: {
            sectionHeader("Hormonal")
        }
    }

    private var lipidsSection: some View {
        Section {
            biomarkerRow("Total Cholesterol", placeholder: "180", unit: "mg/dL", binding: $totalCholesterol)
            biomarkerRow("LDL", placeholder: "100", unit: "mg/dL", binding: $ldl)
            biomarkerRow("HDL", placeholder: "60", unit: "mg/dL", binding: $hdl)
        } header: {
            sectionHeader("Lipids")
        }
    }

    private var inflammationSection: some View {
        Section {
            biomarkerRow("hs-CRP", placeholder: "0.5", unit: "mg/L", binding: $hsCRP)
        } header: {
            sectionHeader("Inflammation")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Context, lab name, etc.", text: $notes, axis: .vertical)
                .font(.appBody)
                .foregroundColor(AppColor.textSecondary)
                .lineLimit(2...5)
        } header: {
            sectionHeader("Notes")
        }
    }

    // MARK: - Row & Header Helpers

    private func biomarkerRow(
        _ label: String,
        placeholder: String,
        unit: String,
        binding: Binding<String>
    ) -> some View {
        HStack {
            Text(label)
                .font(.appBody)
                .foregroundColor(AppColor.textSecondary)
            Spacer()
            TextField(placeholder, text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
                .font(.monoSmall)
                .foregroundColor(AppColor.textPrimary)
            Text(unit)
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
                .frame(width: 44, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.monoTiny)
            .foregroundColor(AppColor.textFaint)
    }

    // MARK: - Save

    private func save() {
        let entry = BloodworkEntry(
            date:                    AppState.sharedDateString(from: selectedDate),
            ferritinNgMl:            Double(ferritin),
            vitaminDNgMl:            Double(vitaminD),
            omega3IndexPct:          Double(omega3),
            fastingGlucoseMgDl:      Double(glucose),
            hba1cPct:                Double(hba1c),
            totalTestosteroneNgDl:   Double(totalT),
            freeTestosteronePgMl:    Double(freeT),
            totalCholesterolMgDl:    Double(totalCholesterol),
            ldlMgDl:                 Double(ldl),
            hdlMgDl:                 Double(hdl),
            hsCRPmgL:                Double(hsCRP),
            notes:                   notes
        )
        state.bloodworkHistory.append(entry)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    BloodworkView()
        .environment(AppState())
}
