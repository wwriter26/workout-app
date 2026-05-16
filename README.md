# YearWorkoutPlan

A full-featured iOS training app mirroring the JH-TRAIN React reference, built in SwiftUI for the 48-week year-round workout and nutrition plan.

## Quick start

```
open /Users/williamwriter/Desktop/Coding/YearWorkoutPlan/YearWorkoutPlan.xcodeproj
```

## Run on iPhone

1. Connect your iPhone via USB.
2. In Xcode, select your device in the run destination picker (top centre toolbar).
3. Go to **Signing & Capabilities** tab in the YearWorkoutPlan target settings and choose your Apple ID signing team.
4. Hit **Run** (Cmd+R).

Free account note: iOS apps sideloaded with a free Apple developer account expire after 7 days and need to be rebuilt. A paid developer account removes this limit.

## What's in the app

- **Today** — Season badge, deload indicator, bodyweight logger, Whoop recovery 3-button toggle (green/yellow/red auto-adjusts session), per-set completion toggles with quick weight+RIR log, save session button, week + day adjuster.
- **Schedule** — Week selector with season quick-jumps, 48-week coloured overview grid, 7 day-cards with CNS load indicators and truncated exercise lists.
- **Log** — Full set-by-set workout logger, PR tiles for the 4 big lifts, past session history, JSON export via share sheet.
- **Stats** — Swift Charts line chart for lift progress by week, bar chart for last 20 bodyweight entries, 7-day average + week-over-week delta, season macro tiles.
- **Plan** — Horizontal tab strip: Nutrition (macro table + meal timing), Supplements (tier 1/2/3 + skip list), Sleep (non-negotiables + daily habits), Whoop (decision matrix + weekly trend rules), Non-Neg (3 non-negotiables + adjustment rules table).

## Architecture

- iOS 17+, Swift 5.9, SwiftUI
- @Observable + UserDefaults (Codable) for persistence — offline-only, no network
- Swift Charts for Stats tab
- No third-party dependencies

## File structure

    YearWorkoutPlan/
    ├── YearWorkoutPlanApp.swift
    ├── ContentView.swift
    ├── Models/
    │   ├── Season.swift
    │   ├── Exercise.swift
    │   ├── Schedules.swift
    │   ├── AppState.swift
    │   ├── WorkoutLog.swift
    │   └── Supplement.swift
    ├── Views/
    │   ├── TodayView.swift
    │   ├── ScheduleView.swift
    │   ├── LogView.swift
    │   ├── StatsView.swift
    │   ├── PlanView.swift
    │   └── Components/CardView.swift
    └── Theme/
        └── Theme.swift
