import SwiftUI

// MARK: - Mood Slider Card
/// Daily subjective wellness input: Mood, Energy, Sleep Quality.
/// If already logged today, shows the logged time and allows re-logging.
struct MoodSliderCard: View {
    @Environment(AppState.self) private var state

    @State private var mood: Double = 7
    @State private var energy: Double = 7
    @State private var sleepQuality: Double = 3
    @State private var isCollapsed: Bool = false

    private var todayEntry: MoodEntry? {
        let today = AppState.sharedDateString(from: Date())
        return state.moodEntries.last(where: { $0.date == today })
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                headerRow

                if !isCollapsed {
                    sliders
                    saveButton
                }
            }
        }
        .onAppear {
            // Pre-fill with today's values if already logged
            if let entry = todayEntry {
                mood = Double(entry.mood)
                energy = Double(entry.energy)
                sleepQuality = Double(entry.sleepQuality)
                isCollapsed = true  // default to collapsed once logged
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCollapsed.toggle()
            }
        } label: {
            HStack {
                SectionLabel(text: "Mood & Energy")

                Spacer()

                if let entry = todayEntry {
                    // Show summary when collapsed
                    HStack(spacing: 8) {
                        moodChip(label: "M", value: entry.mood, color: moodColor(entry.mood))
                        moodChip(label: "E", value: entry.energy, color: energyColor(entry.energy))
                        moodChip(label: "S", value: entry.sleepQuality, color: AppColor.winter)
                    }
                }

                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.textFaint)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sliders

    private var sliders: some View {
        VStack(spacing: 14) {
            WellnessSlider(
                label: "Mood",
                value: $mood,
                range: 1...10,
                displayValue: Int(mood),
                color: moodColor(Int(mood))
            )
            WellnessSlider(
                label: "Energy",
                value: $energy,
                range: 1...10,
                displayValue: Int(energy),
                color: energyColor(Int(energy))
            )
            WellnessSlider(
                label: "Sleep Quality",
                value: $sleepQuality,
                range: 1...5,
                displayValue: Int(sleepQuality),
                color: AppColor.winter
            )
        }
        .padding(.top, 4)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        HStack {
            if let entry = todayEntry {
                // Show logged time
                let loggedTime = formattedTime(entry.date)
                Text("Logged · \(loggedTime)")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textDimmed)
                Spacer()
            }

            Button {
                state.logMood(
                    mood: Int(mood),
                    energy: Int(energy),
                    sleepQuality: Int(sleepQuality)
                )
                withAnimation(.easeInOut(duration: 0.2)) { isCollapsed = true }
            } label: {
                Text(todayEntry == nil ? "SAVE" : "RE-LOG")
                    .font(.system(size: 11, weight: .heavy, design: .default))
                    .foregroundColor(.black)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColor.summer)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func moodChip(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
            Text("\(value)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }

    private func moodColor(_ v: Int) -> Color {
        switch v {
        case 8...10: return AppColor.spring
        case 5...7:  return AppColor.summer
        default:     return AppColor.fall
        }
    }

    private func energyColor(_ v: Int) -> Color { moodColor(v) }

    /// Returns the current time as "HH:MM" (the date key is from today anyway).
    private func formattedTime(_ dateStr: String) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: Date())
    }
}

// MARK: - Wellness Slider
/// Labelled slider row used in MoodSliderCard.
private struct WellnessSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayValue: Int
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.appSmall)
                .foregroundColor(AppColor.textMuted)
                .frame(width: 80, alignment: .leading)

            Slider(value: $value, in: range, step: 1)
                .tint(color)

            Text("\(displayValue)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 24, alignment: .trailing)
        }
    }
}
