# YearWorkoutPlan — Apple Watch Companion Scaffold

This document explains the value proposition, manual Xcode setup steps, proposed
file structure, shared model targets, and WatchConnectivity sync design for the
YearWorkoutPlan watchOS companion app.

---

## Why a watchOS Companion Is High-Value

1. **Set logging via Digital Crown + side button.** Scrolling the Crown to select
   reps and tapping the side button to confirm is the fastest possible logging UX
   — faster than reaching for a phone while holding equipment. Removes a real-world
   friction point that causes users to skip logging sets.

2. **Rest timer on wrist.** The phone screen stays free for technique video or
   programming notes. Haptic taps at rest-complete are more useful in a noisy gym
   than any audio cue.

3. **Live HR streaming during workouts.** The Watch's optical HR sensor streams
   continuously. The companion can flag when heart rate is unexpectedly high
   (suggesting the user is under-resting) or low (suggesting the load is too easy)
   — closing the autoregulation loop in real time.

4. **Glance complication.** Today's session name and completion percentage visible
   from the watch face with a wrist raise. No unlock needed.

---

## Manual Xcode Steps to Add the watchOS Target

Actual target creation requires the Xcode UI. Follow these steps:

1. Open `YearWorkoutPlan.xcodeproj` in Xcode.
2. Go to **File → New → Target**.
3. In the template picker, select **watchOS → App** and click **Next**.
4. Set:
   - **Product Name:** `YearWorkoutPlan Watch`
   - **Bundle Identifier:** `com.yourteam.YearWorkoutPlan.watchkitapp`
     (replace `com.yourteam` with your actual team prefix)
   - **Interface:** SwiftUI
   - **Language:** Swift
5. When Xcode asks "Activate scheme?", click **Activate**.
6. Xcode will create a `YearWorkoutPlan Watch` target with a default `ContentView`.
   Delete the default ContentView.swift and replace with the files listed below.

---

## Proposed Initial Files for the Watch Target

### `WatchApp/WatchApp.swift` — Entry Point
```swift
import SwiftUI

@main
struct YearWorkoutPlanWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchTodayView()
        }
    }
}
```

### `WatchApp/Views/WatchTodayView.swift` — Current Exercise + Rest Timer
Displays:
- Today's session name and the current exercise (shared via WatchConnectivity).
- A prominent rest timer counting down from the target rest period.
- A "DONE" button to log the current set and advance to the next.

See skeleton code at the bottom of this document.

### `WatchApp/Views/WatchSetLogger.swift` — Crown Scroll Reps + Side Button Log
- Digital Crown scrolls through rep counts (1–20).
- Side button (Digital Crown press) confirms and sends the logged set to the iPhone.
- Small haptic feedback on log confirmation.

---

## Files to Share via Target Membership

In Xcode's File Inspector (right panel), add these files to the Watch target by
ticking the checkbox under "Target Membership":

| File | Why shared |
|------|------------|
| `Models/Exercise.swift` | `Exercise` and `Session` types used to display today's workout |
| `Models/Schedules.swift` | Needed to reconstruct today's session on-watch (fallback if WatchConnectivity fails) |
| `Models/WorkoutLog.swift` | `SetLog` type used when sending completed sets back to iPhone |
| `Models/Season.swift` | Season name and color for UI theming |
| `Models/AppState.swift` | Needs review — the full AppState is iOS-heavy (`@Observable`, HealthKit calls). Consider extracting a `SharedWorkoutState` struct containing only `currentWeek`, `currentDayIndex`, `adjustedSession`, and `completedSets` for safe sharing. The Watch target should NOT compile `HealthKitManager`, `PhotoManager`, or `NotificationManager`. |

---

## WatchConnectivity Sync Design

Use `WCSession` (WatchConnectivity framework) for bidirectional communication.

### iPhone → Watch (deliver today's session)

Send on:
- App launch
- When `currentWeek` or `currentDayIndex` changes
- Every midnight to refresh for the new day

Message payload (send as `applicationContext`):
```json
{
  "sessionLabel": "Lower Power + Plyo + Sprints",
  "exercises": [...],
  "currentWeek": 7,
  "currentDayIndex": 0,
  "completedSets": { "0-0": true, "0-1": false }
}
```

Use `WCSession.default.updateApplicationContext(_:)` rather than `sendMessage(_:)` —
application context survives the Watch app being killed, whereas `sendMessage`
requires the Watch to be reachable.

### Watch → iPhone (receive completed sets)

When the user logs a set on the Watch, call `WCSession.default.sendMessage(_:replyHandler:errorHandler:)` with:
```json
{
  "action": "logSet",
  "exerciseIndex": 2,
  "setIndex": 1,
  "weight": "185",
  "reps": "6",
  "rir": "2"
}
```

The iPhone handler calls `state.logWeights["2-1-w"] = "185"` etc., then saves.

---

## WatchTodayView Skeleton

```swift
import SwiftUI
import WatchConnectivity

struct WatchTodayView: View {
    // Delivered via WatchConnectivity and stored in a lightweight @Observable
    @State private var sessionLabel = "Loading..."
    @State private var exercises: [String] = []
    @State private var currentExerciseIndex = 0
    @State private var restSecondsRemaining: Int? = nil

    private var currentExercise: String {
        exercises.indices.contains(currentExerciseIndex)
            ? exercises[currentExerciseIndex]
            : "—"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(sessionLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(currentExercise)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let seconds = restSecondsRemaining {
                Text("\(seconds)s rest")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(seconds > 30 ? .green : .orange)
            }

            HStack(spacing: 16) {
                Button("PREV") {
                    currentExerciseIndex = max(0, currentExerciseIndex - 1)
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                Button("DONE") {
                    // Send set log to iPhone via WCSession.sendMessage
                    // Start rest timer based on exercise.rest string
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("WatchSessionUpdated")
            )
        ) { notification in
            // Decode payload and update sessionLabel, exercises
        }
    }
}
```

---

## Next Steps After Target Creation

1. Add a WatchConnectivity session manager class (shared or separate) and wire it
   to `AppState` on the iPhone side.
2. Add the Watch target complication widget (`WidgetKit` on watchOS 7+) for the
   watch face glance.
3. Add `NSHealthShareUsageDescription` to the Watch target's Info.plist if you want
   independent HR access from the Watch (vs. relying on iPhone proxy).
4. Test on a real device — the WatchConnectivity flow cannot be reliably tested in
   the iOS Simulator.
