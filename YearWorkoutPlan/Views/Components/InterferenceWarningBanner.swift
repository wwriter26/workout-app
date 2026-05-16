import SwiftUI

// MARK: - Interference Warning Banner
/// An amber dismissable banner shown under the session card when today's training
/// pairs high-CNS lifting with HIIT/sprint work in a way that risks performance
/// degradation and overreaching.
///
/// Show conditions (OR logic — banner appears if either is true):
///   1. Today is heavy AND tomorrow is also heavy (back-to-back CNS days).
///   2. Today's session contains BOTH heavy lifting AND HIIT/sprint exercises
///      (e.g. Spring Monday: Lower Power + Sprints).
///
/// Dismissal is stored in UserDefaults keyed by today's date string so the banner
/// re-appears the next calendar day if the condition is still true.
struct InterferenceWarningBanner: View {
    @Environment(AppState.self) private var state

    // Compute once so we don't re-check on every render
    private var shouldShow: Bool {
        guard !isDismissedToday else { return false }
        return isInterferenceConditionMet
    }

    var body: some View {
        if shouldShow {
            bannerContent
        }
    }

    // MARK: - Banner

    private var bannerContent: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.summer)

            VStack(alignment: .leading, spacing: 4) {
                Text("Interference risk")
                    .font(.appSubhead)
                    .foregroundColor(AppColor.summer)
                Text("Heavy session today. Separate any HIIT by 6+ hours, ideally tomorrow's not hard.")
                    .font(.appSmall)
                    .foregroundColor(AppColor.textDimmed)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.textFaint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss interference warning")
        }
        .padding(12)
        .background(AppColor.summer.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColor.summer.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Logic

    /// Whether today's session meets the interference criterion.
    private var isInterferenceConditionMet: Bool {
        let session = state.adjustedSession

        // Condition 1: today is heavy AND tomorrow is also heavy
        let todayIsHeavy = isHeavy(session.cnsLoad)
        let tomorrowIsHeavy: Bool = {
            let tomorrowIndex = (state.currentDayIndex + 1) % 7
            let tomorrowKey = Schedules.days[tomorrowIndex]
            if let tomorrow = Schedules.session(week: state.currentWeek, dayKey: tomorrowKey) {
                return isHeavy(tomorrow.cnsLoad)
            }
            return false
        }()

        if todayIsHeavy && tomorrowIsHeavy { return true }

        // Condition 2: today contains BOTH heavy lift AND HIIT/sprint exercises
        let exercises = session.exercises.map { $0.name.lowercased() }
        let hasHeavyLift = todayIsHeavy
        let hasHIIT = exercises.contains { name in
            name.contains("interval") || name.contains("sprint") ||
            name.contains("plyo") || name.contains("vo2") ||
            name.contains("threshold") || name.contains("4×4") ||
            name.contains("box jump") || name.contains("broad jump")
        }
        return hasHeavyLift && hasHIIT
    }

    private func isHeavy(_ load: CNSLoad) -> Bool {
        load == .high || load == .moderateHigh
    }

    // MARK: - Dismissal (UserDefaults)

    private var dismissKey: String {
        "interferenceWarningDismissed.\(AppState.sharedDateString(from: Date()))"
    }

    private var isDismissedToday: Bool {
        UserDefaults.standard.bool(forKey: dismissKey)
    }

    private func dismiss() {
        UserDefaults.standard.set(true, forKey: dismissKey)
    }
}
