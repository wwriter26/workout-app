import Foundation
import UIKit
import AudioToolbox
import SwiftUI

// MARK: - RestTimer
/// Global singleton that manages a single rest-period countdown.
/// @Observable gives SwiftUI views zero-cost reactivity without Combine.
/// @MainActor ensures all UI-facing properties are read/written on the main thread,
/// which is required for @Observable to drive SwiftUI updates safely.
@Observable
@MainActor
final class RestTimer {

    static let shared = RestTimer()
    private init() {}

    // MARK: - Public state (observed by RestTimerView)
    var isRunning: Bool = false
    var remainingSeconds: Int = 0
    var totalSeconds: Int = 0
    var exerciseName: String? = nil

    // MARK: - Private
    private var task: Task<Void, Never>? = nil

    // MARK: - Public API

    /// Starts (or restarts) the timer with the given duration.
    func start(seconds: Int, exerciseName: String? = nil) {
        task?.cancel()
        self.exerciseName = exerciseName
        self.totalSeconds = seconds
        self.remainingSeconds = seconds
        self.isRunning = true
        task = Task { await tick() }
    }

    /// Adjusts the remaining time by `seconds` (positive = more time, negative = less).
    /// Clamped to 0...3600 so we never go negative or absurdly long.
    func add(seconds: Int) {
        remainingSeconds = min(max(remainingSeconds + seconds, 0), 3_600)
    }

    /// Immediately ends the rest period without firing the end haptic/sound.
    func skip() {
        task?.cancel()
        task = nil
        isRunning = false
        remainingSeconds = 0
        exerciseName = nil
    }

    // MARK: - Private tick loop

    /// 1-second countdown loop using structured concurrency.
    /// We use Task.sleep(nanoseconds:) rather than a Timer so the task is
    /// automatically cancelled when `task?.cancel()` is called from skip()/start().
    private func tick() async {
        while remainingSeconds > 0 {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                // Task was cancelled — exit cleanly without side effects
                return
            }
            // Each tick update is already on @MainActor because the enclosing
            // class is @MainActor — no hop needed.
            withAnimation(.easeInOut(duration: 0.3)) {
                remainingSeconds -= 1
            }
            // Haptic alerts at milestone seconds
            switch remainingSeconds {
            case 10, 5:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case 0:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                playEndChirp()
            default:
                break
            }
        }
        isRunning = false
        exerciseName = nil
    }

    /// Plays system sound 1052 ("DeviceUnlock") at the end of the rest period.
    private func playEndChirp() {
        AudioServicesPlaySystemSound(1052)
    }

    // MARK: - Rest String Parsing

    /// Parses a rest string from the exercise catalogue into a second count.
    ///
    /// Supported formats:
    ///   "90s"     → 90
    ///   "2min"    → 120
    ///   "2-3min"  → 120  (lower bound of range)
    ///   "2:30"    → 150  (minutes:seconds)
    ///   "—"       → 90   (default)
    ///   anything unparseable → 90 (safe default)
    static func parseRestSeconds(_ s: String) -> Int {
        let cleaned = s.trimmingCharacters(in: .whitespaces).lowercased()

        // Bail early on the common non-applicable placeholder
        if cleaned == "—" || cleaned == "-" || cleaned.isEmpty { return 90 }

        // "2:30" format (mm:ss)
        if cleaned.contains(":") {
            let parts = cleaned.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 { return parts[0] * 60 + parts[1] }
        }

        // "X-Ymin" or "X-Ys" range — use lower bound
        // Strip trailing unit, split on "-"
        let noUnit = cleaned
            .replacingOccurrences(of: "min", with: "M")
            .replacingOccurrences(of: "s", with: "S")

        // Check for range (hyphen between digits)
        if let rangeMatch = noUnit.range(of: #"(\d+)[\-–](\d+)"#, options: .regularExpression) {
            let matched = String(noUnit[rangeMatch])
            let digits = matched
                .replacingOccurrences(of: "–", with: "-")
                .split(separator: "-")
                .compactMap { Int($0.filter(\.isNumber)) }
            if let lower = digits.first {
                // Decide unit from original string
                if cleaned.hasSuffix("min") { return lower * 60 }
                return lower  // seconds
            }
        }

        // Single value: extract leading digits then unit
        let digits = cleaned.filter(\.isNumber)
        guard let value = Int(digits), value > 0 else { return 90 }
        if cleaned.contains("min") { return value * 60 }
        return value  // assume seconds
    }
}
