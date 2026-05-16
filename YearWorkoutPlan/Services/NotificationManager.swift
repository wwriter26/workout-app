import UserNotifications
import Foundation

// MARK: - NotificationManager
/// Centralised wrapper around UNUserNotificationCenter.
///
/// Design decisions:
/// - `@MainActor` because UNUserNotificationCenter's completion-handler-based APIs
///   don't require a specific thread, but this singleton is mutated and read from
///   the UI layer (SettingsView). Keeping it on the main actor avoids any data-race
///   risk on the stored `authorized` flag.
/// - All scheduling is fire-and-forget (`async` without `throws`) so callers never
///   need a try/catch for a non-critical scheduling step.
/// - The category identifier `"YWFitness"` is registered once and reused for all
///   notifications so future interactive notification actions can share it.
@MainActor
final class NotificationManager {

    // MARK: Shared instance
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    // Category used for all app notifications — enables future interactive actions.
    private static let categoryID = "YWFitness"

    private init() {}

    // MARK: - Authorization

    /// Requests .alert + .sound + .badge authorization.
    /// Returns `true` if the user granted permission, `false` otherwise.
    /// Callers may silently ignore the result; no UI is driven from this return value.
    @discardableResult
    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }

    // MARK: - Pre-Workout Reminder

    /// Schedules a repeating pre-workout reminder on the given weekdays (1 = Sunday … 7 = Saturday,
    /// matching Calendar.component(.weekday) values).
    func schedulePreWorkoutReminder(at hour: Int, minute: Int, weekdays: Set<Int>) async {
        // Remove existing workout reminders before re-scheduling so we never stack duplicates.
        let existingIDs = (1...7).map { "yw.workout.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: existingIDs)

        guard !weekdays.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to train"
        content.body = "Your workout is scheduled — let's go."
        content.sound = .default
        content.categoryIdentifier = Self.categoryID

        for weekday in weekdays {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.weekday = weekday      // 1 = Sunday … 7 = Saturday

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true                // fires every matching weekday
            )
            let request = UNNotificationRequest(
                identifier: "yw.workout.\(weekday)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    // MARK: - Weekly Summary

    /// Schedules a repeating Sunday 19:00 weekly summary notification.
    func scheduleWeeklySummary() async {
        center.removePendingNotificationRequests(withIdentifiers: ["yw.weekly.summary"])

        let content = UNMutableNotificationContent()
        content.title = "Weekly check-in"
        content.body = "How was training this week? Log RPE, mood, and review your summary."
        content.sound = .default
        content.categoryIdentifier = Self.categoryID

        // Sunday = weekday 1 in Calendar convention
        var components = DateComponents()
        components.weekday = 1
        components.hour = 19
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "yw.weekly.summary",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    // MARK: - Supplement Reminders

    /// Maps supplement timing strings to a wall-clock hour (and derives time from the
    /// user's configured workout hour for pre-workout supplements).
    ///
    /// Mapping logic:
    ///   "AM", "AM with fat", "AM or split"                    → 8:00
    ///   "Pre-bed", "90 min pre-bed", "Pre-workout or pre-bed" → 21:00
    ///   "Pre-workout", "30–60 min pre-workout", "60 min…"     → workoutHour - 1
    ///   Everything else (Anytime, With fat meal, splits…)     → 12:00
    func scheduleSupplementReminders(supplements: [Supplement], userWorkoutHour: Int) async {
        // Clear all existing supplement reminders first.
        let existingIDs = SupplementList.all.map { "yw.supplement.\($0.id)" }
        center.removePendingNotificationRequests(withIdentifiers: existingIDs)

        for supplement in supplements {
            let hour = timingHour(for: supplement.timing, workoutHour: userWorkoutHour)

            let content = UNMutableNotificationContent()
            content.title = "Supplement reminder"
            content.body = "\(supplement.name) — \(supplement.dose)"
            content.sound = .default
            content.categoryIdentifier = Self.categoryID

            var components = DateComponents()
            components.hour = hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "yw.supplement.\(supplement.id)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    // MARK: - Cancellation

    /// Cancels every pending notification this app has scheduled.
    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    /// Cancels a single pending notification by identifier.
    func cancelByIdentifier(_ id: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Private Helpers

    /// Determines the clock hour for a supplement's timing string.
    private func timingHour(for timing: String, workoutHour: Int) -> Int {
        let t = timing.lowercased()

        // Pre-bed bucket
        if t.contains("pre-bed") || t.contains("pre bed") || t.contains("90 min pre") {
            return 21
        }

        // AM bucket
        if t.hasPrefix("am") || t.contains("am with") {
            return 8
        }

        // Pre-workout bucket — schedule 1 hour before the user's preferred workout time
        if t.contains("pre-wo") || t.contains("pre wo") ||
           t.contains("pre-workout") || t.contains("pre workout") ||
           t.contains("30-60 min pre") || t.contains("60 min pre") {
            return max(6, workoutHour - 1)
        }

        // Default: midday for "Anytime daily", "With fat meal", split doses, etc.
        return 12
    }
}
