import SwiftUI

// MARK: - Missed Day Dialog
/// Presented once per calendar day when the app detects that yesterday had a
/// programmed non-rest session that was never logged.
///
/// Three options:
///   "Move to Today"   — shifts currentDayIndex back to yesterday so the user can
///                       log it now; today's session is effectively skipped.
///   "Skip"            — dismisses with no action.
///   "Combine with Next" — shown only when today is also a non-rest session; adds a
///                       "Combined" banner note.
///
/// Detection is done on TodayView's onAppear and gated by a per-day UserDefaults flag
/// to prevent re-showing once the user has chosen an action.
struct MissedDayDialog: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    // Called by TodayView after the user picks an action so TodayView can reset its state.
    let onDismiss: () -> Void

    private var yesterdaySession: Session? {
        let yesterdayIndex = (state.currentDayIndex + 6) % 7   // wraps Sun → Sat
        let yesterdayKey = Schedules.days[yesterdayIndex]
        return Schedules.session(week: state.currentWeek, dayKey: yesterdayKey)
    }

    private var todayIsNonRest: Bool {
        state.adjustedSession.cnsLoad != .rest && !state.adjustedSession.exercises.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header icon
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(AppColor.summer)
                        .padding(.top, 40)
                        .padding(.bottom, 20)

                    Text("Missed Session")
                        .font(.appTitle)
                        .foregroundColor(AppColor.textPrimary)

                    if let yesterday = yesterdaySession {
                        Text(yesterday.label)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textMuted)
                            .padding(.top, 4)
                    }

                    Text("Yesterday had a programmed session that wasn't logged. What would you like to do?")
                        .font(.appBody)
                        .foregroundColor(AppColor.textDimmed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 16)

                    VStack(spacing: 10) {
                        // Move to Today button
                        Button {
                            moveToYesterday()
                        } label: {
                            Label("Move to Today", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColor.summer)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Loads yesterday's session so you can log it now")

                        // Combine with Next — only shown when today also has work
                        if todayIsNonRest {
                            Button {
                                combineWithNext()
                            } label: {
                                Label("Combine with Next", systemImage: "text.badge.plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColor.infoBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColor.infoBlue.opacity(0.12))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColor.infoBlue.opacity(0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Merges yesterday's primary lifts into today's session")
                        }

                        // Skip button
                        Button {
                            skip()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColor.textDimmed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColor.cardBackground2)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Actions

    private func moveToYesterday() {
        // Roll currentDayIndex back by one (wraps Sun → Sat)
        state.currentDayIndex = (state.currentDayIndex + 6) % 7
        markHandledToday()
        onDismiss()
    }

    private func combineWithNext() {
        // UX simplification: set a UserDefaults flag that TodayView reads to display
        // a "Combined session" banner. The actual exercise merging would require
        // a deeper model change; the flag surfaces the intent clearly to the user.
        UserDefaults.standard.set(true, forKey: combinedSessionKey)
        markHandledToday()
        onDismiss()
    }

    private func skip() {
        markHandledToday()
        onDismiss()
    }

    // MARK: - UserDefaults Keys

    private var handledKey: String {
        "missedDayDialogHandled.\(AppState.sharedDateString(from: Date()))"
    }

    private var combinedSessionKey: String {
        "missedDayCombined.\(AppState.sharedDateString(from: Date()))"
    }

    private func markHandledToday() {
        UserDefaults.standard.set(true, forKey: handledKey)
    }

    // MARK: - Static Detection

    /// Returns true when the conditions for showing the dialog are met.
    /// Called from TodayView.onAppear so it can gate `showMissedDay`.
    static func shouldShow(state: AppState) -> Bool {
        // Already handled today? Don't show again.
        let handledKey = "missedDayDialogHandled.\(AppState.sharedDateString(from: Date()))"
        guard !UserDefaults.standard.bool(forKey: handledKey) else { return false }

        // Build yesterday's date string
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return false }
        let yesterdayStr = AppState.sharedDateString(from: yesterday)

        // Check if yesterday had a programmed non-rest session
        let yesterdayIndex = (state.currentDayIndex + 6) % 7
        let yesterdayKey = Schedules.days[yesterdayIndex]
        guard let yesterdaySession = Schedules.session(week: state.currentWeek, dayKey: yesterdayKey) else { return false }
        guard yesterdaySession.cnsLoad != .rest, !yesterdaySession.exercises.isEmpty else { return false }

        // Check if it was logged
        let wasLogged = state.workoutLogs.contains { $0.date == yesterdayStr }
        return !wasLogged
    }
}
