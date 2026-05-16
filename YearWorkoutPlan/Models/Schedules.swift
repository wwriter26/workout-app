import Foundation

// MARK: - Schedule catalogue
// All four season schedules ported verbatim from the JSX and verified against
// year_round_plan_v3.md.  The data intentionally lives here as static constants
// so every view reads from the same source of truth.

enum Schedules {

    // MARK: - Day order
    static let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // MARK: - Spring (Weeks 1–12): VO2 Max + Hypertrophy
    static let spring: [String: Session] = [
        "Mon": Session(
            dayKey: "Mon",
            label: "Lower Power + Plyo + Sprints",
            cnsLoad: .high,
            isCardio: false,
            exercises: [
                Exercise(name: "Box jumps (24–30\")",         sets: 4, reps: "3",       load: "BW max intent",  rir: "—",   rest: "90s"),
                Exercise(name: "Broad jumps",                  sets: 3, reps: "3",       load: "BW",             rir: "—",   rest: "90s"),
                Exercise(name: "Trap bar deadlift (speed)",    sets: 5, reps: "3",       load: "55–60% 1RM",     rir: "4",   rest: "2min"),
                Exercise(name: "Bulgarian split squat",        sets: 3, reps: "8/leg",   load: "DBs",            rir: "2",   rest: "90s"),
                Exercise(name: "Romanian deadlift",            sets: 3, reps: "8",       load: "70% 1RM",        rir: "2",   rest: "90s"),
                Exercise(name: "Pallof press",                 sets: 3, reps: "10/side", load: "Cable light",    rir: "3",   rest: "45s"),
                Exercise(name: "Sprints 4×40m @90% (Green only)", sets: 4, reps: "40m", load: "90%",            rir: "—",   rest: "90s", whoopGreen: true),
            ]
        ),
        "Tue": Session(
            dayKey: "Tue",
            label: "Upper Push (Hypertrophy)",
            cnsLoad: .moderate,
            isCardio: false,
            exercises: [
                Exercise(name: "Bench press",                  sets: 4, reps: "6–8",    load: "75–80% 1RM",  rir: "1–2", rest: "2min"),
                Exercise(name: "Overhead press",               sets: 3, reps: "8–10",   load: "70% 1RM",     rir: "1–2", rest: "90s"),
                Exercise(name: "Incline DB press",             sets: 3, reps: "10–12",  load: "Moderate",    rir: "1",   rest: "75s"),
                Exercise(name: "Cable lateral raise",          sets: 4, reps: "12–15",  load: "Light",       rir: "0–1", rest: "45s"),
                Exercise(name: "Triceps rope pushdown",        sets: 3, reps: "12",     load: "Moderate",    rir: "0–1", rest: "45s"),
                Exercise(name: "Plank → side plank",           sets: 3, reps: "30s ea", load: "BW",          rir: "—",   rest: "30s"),
            ]
        ),
        "Wed": Session(
            dayKey: "Wed",
            label: "VO2 Max — 4×4 Norwegian",
            cnsLoad: .high,
            isCardio: true,
            exercises: [
                Exercise(name: "Warm-up",            sets: 1, reps: "10 min",  load: "~70% HRmax",  rir: "—", rest: "—"),
                Exercise(name: "4×4 intervals",      sets: 4, reps: "4 min",   load: "90–95% HRmax",rir: "—", rest: "3min active"),
                Exercise(name: "Cool-down",          sets: 1, reps: "5 min",   load: "Easy",        rir: "—", rest: "—"),
                Exercise(name: "Core work",          sets: 1, reps: "10 min",  load: "—",           rir: "—", rest: "—"),
            ]
        ),
        "Thu": Session(
            dayKey: "Thu",
            label: "Upper Pull (Hypertrophy)",
            cnsLoad: .moderate,
            isCardio: false,
            exercises: [
                Exercise(name: "Weighted pull-up",             sets: 4, reps: "5–8",   load: "+load",       rir: "1–2", rest: "2min"),
                Exercise(name: "Barbell row",                  sets: 4, reps: "8",     load: "75% 1RM",     rir: "1–2", rest: "90s"),
                Exercise(name: "Chest-supported DB row",       sets: 3, reps: "10–12", load: "Moderate",    rir: "1",   rest: "75s"),
                Exercise(name: "Face pulls",                   sets: 3, reps: "15",    load: "Light",       rir: "0",   rest: "45s"),
                Exercise(name: "Hammer curl",                  sets: 3, reps: "10–12", load: "Moderate",    rir: "0–1", rest: "45s"),
                Exercise(name: "Farmer's carry",               sets: 3, reps: "40m",   load: "Heavy DBs",   rir: "—",   rest: "60s"),
            ]
        ),
        "Fri": Session(
            dayKey: "Fri",
            label: "Lower Hypertrophy",
            cnsLoad: .moderateHigh,
            isCardio: false,
            exercises: [
                Exercise(name: "Back squat",                   sets: 5, reps: "8",     load: "70–75% 1RM", rir: "1–2", rest: "2min"),
                Exercise(name: "Hip thrust",                   sets: 3, reps: "10",    load: "Heavy",      rir: "1",   rest: "90s"),
                Exercise(name: "Walking lunge",                sets: 3, reps: "12/leg",load: "DBs",        rir: "1",   rest: "75s"),
                Exercise(name: "Leg press",                    sets: 3, reps: "10–12", load: "Heavy",      rir: "1",   rest: "90s"),
                Exercise(name: "Lying leg curl",               sets: 3, reps: "12",    load: "Moderate",   rir: "0–1", rest: "60s"),
                Exercise(name: "Standing calf raise",          sets: 4, reps: "12",    load: "Moderate",   rir: "0–1", rest: "45s"),
            ]
        ),
        "Sat": Session(
            dayKey: "Sat",
            label: "Zone 2",
            cnsLoad: .low,
            isCardio: true,
            exercises: [
                Exercise(name: "Zone 2 cardio", sets: 1, reps: "60–75 min", load: "60–70% HRmax", rir: "—", rest: "—"),
            ]
        ),
        "Sun": Session(
            dayKey: "Sun",
            label: "Rest",
            cnsLoad: .rest,
            isCardio: false,
            exercises: []
        ),
    ]

    // MARK: - Summer (Weeks 14–26): Maximal Strength
    static let summer: [String: Session] = [
        "Mon": Session(
            dayKey: "Mon",
            label: "Squat Focus",
            cnsLoad: .high,
            isCardio: false,
            exercises: [
                Exercise(name: "Back squat",            sets: 5, reps: "3",   load: "87% 1RM",  rir: "1–2", rest: "4min"),
                Exercise(name: "Pause squat",           sets: 3, reps: "3",   load: "75% 1RM",  rir: "2",   rest: "3min"),
                Exercise(name: "Front squat",           sets: 3, reps: "5",   load: "70% 1RM",  rir: "2",   rest: "2min"),
                Exercise(name: "Romanian deadlift",     sets: 3, reps: "6",   load: "Heavy",    rir: "2",   rest: "2min"),
                Exercise(name: "Leg curl",              sets: 3, reps: "8",   load: "Moderate", rir: "1",   rest: "90s"),
                Exercise(name: "Standing calf",         sets: 4, reps: "8",   load: "Heavy",    rir: "1",   rest: "60s"),
            ]
        ),
        "Tue": Session(
            dayKey: "Tue",
            label: "Bench Focus",
            cnsLoad: .high,
            isCardio: false,
            exercises: [
                Exercise(name: "Bench press",           sets: 5, reps: "3",   load: "87% 1RM",  rir: "1–2", rest: "4min"),
                Exercise(name: "Pause bench",           sets: 3, reps: "3",   load: "75% 1RM",  rir: "2",   rest: "3min"),
                Exercise(name: "Close-grip bench",      sets: 3, reps: "5",   load: "75% 1RM",  rir: "2",   rest: "2min"),
                Exercise(name: "Weighted dip",          sets: 3, reps: "6–8", load: "+load",    rir: "1",   rest: "2min"),
                Exercise(name: "Cable row",             sets: 3, reps: "10",  load: "Moderate", rir: "1",   rest: "90s"),
                Exercise(name: "Triceps rope",          sets: 3, reps: "12",  load: "Light",    rir: "0",   rest: "45s"),
            ]
        ),
        "Wed": Session(
            dayKey: "Wed",
            label: "Plyo Microdose + Z2",
            cnsLoad: .low,
            isCardio: false,
            exercises: [
                Exercise(name: "Box jumps",             sets: 3, reps: "3",        load: "Explosive intent", rir: "—", rest: "90s"),
                Exercise(name: "Broad jumps",           sets: 3, reps: "3",        load: "Explosive intent", rir: "—", rest: "90s"),
                Exercise(name: "Sprints 4×30m @90%",   sets: 4, reps: "30m",      load: "90%",              rir: "—", rest: "90s"),
                Exercise(name: "Zone 2 cardio",         sets: 1, reps: "30–45 min",load: "60–70% HRmax",     rir: "—", rest: "—"),
            ]
        ),
        "Thu": Session(
            dayKey: "Thu",
            label: "Deadlift Focus",
            cnsLoad: .high,
            isCardio: false,
            exercises: [
                Exercise(name: "Conventional deadlift", sets: 4, reps: "3",  load: "87% 1RM",  rir: "1–2", rest: "4–5min"),
                Exercise(name: "Deficit deadlift",      sets: 3, reps: "5",  load: "70% 1RM",  rir: "2",   rest: "3min"),
                Exercise(name: "Barbell row",           sets: 4, reps: "6",  load: "Heavy",    rir: "2",   rest: "2min"),
                Exercise(name: "Weighted pull-up",      sets: 4, reps: "5",  load: "+load",    rir: "1",   rest: "2min"),
                Exercise(name: "Hammer curl",           sets: 3, reps: "8",  load: "Moderate", rir: "1",   rest: "60s"),
                Exercise(name: "Farmer's carry",        sets: 3, reps: "40m",load: "Heavy",    rir: "—",   rest: "90s"),
            ]
        ),
        "Fri": Session(
            dayKey: "Fri",
            label: "Press Focus",
            cnsLoad: .high,
            isCardio: false,
            exercises: [
                Exercise(name: "Standing OHP",          sets: 5, reps: "3",      load: "85% 1RM",       rir: "1–2", rest: "3min"),
                Exercise(name: "Push press",            sets: 3, reps: "3",      load: "80% 1RM",       rir: "2",   rest: "2–3min"),
                Exercise(name: "Incline DB press",      sets: 3, reps: "6–8",    load: "Moderate-heavy",rir: "1",   rest: "2min"),
                Exercise(name: "Lateral raise",         sets: 4, reps: "12–15",  load: "Light",         rir: "0",   rest: "45s"),
                Exercise(name: "Face pulls",            sets: 3, reps: "15",     load: "Light",         rir: "0",   rest: "45s"),
                Exercise(name: "Pallof press",          sets: 3, reps: "10/side",load: "Cable",         rir: "2",   rest: "45s"),
            ]
        ),
        "Sat": Session(
            dayKey: "Sat",
            label: "Z2 + Mobility",
            cnsLoad: .low,
            isCardio: true,
            exercises: [
                Exercise(name: "Zone 2 cardio",  sets: 1, reps: "45–60 min", load: "60–70% HRmax", rir: "—", rest: "—"),
                Exercise(name: "Mobility/yoga",  sets: 1, reps: "15 min",    load: "—",            rir: "—", rest: "—"),
            ]
        ),
        "Sun": Session(
            dayKey: "Sun",
            label: "Rest",
            cnsLoad: .rest,
            isCardio: false,
            exercises: []
        ),
    ]

    // MARK: - Fall (Weeks 27–39): Aerobic Base + Body Comp
    static let fall: [String: Session] = [
        "Mon": Session(
            dayKey: "Mon",
            label: "Full-body A",
            cnsLoad: .moderate,
            isCardio: false,
            exercises: [
                Exercise(name: "Back squat",        sets: 4, reps: "6",  load: "—", rir: "2",   rest: "2min"),
                Exercise(name: "Bench press",       sets: 4, reps: "6",  load: "—", rir: "2",   rest: "2min"),
                Exercise(name: "Barbell row",       sets: 4, reps: "8",  load: "—", rir: "2",   rest: "90s"),
                Exercise(name: "Romanian deadlift", sets: 3, reps: "8",  load: "—", rir: "2",   rest: "90s"),
                Exercise(name: "Lateral raise",     sets: 3, reps: "15", load: "—", rir: "0–1", rest: "45s"),
                Exercise(name: "Face pulls",        sets: 3, reps: "15", load: "—", rir: "0",   rest: "45s"),
                Exercise(name: "EZ-bar curl",       sets: 2, reps: "10", load: "—", rir: "1",   rest: "45s"),
                Exercise(name: "Triceps rope",      sets: 2, reps: "12", load: "—", rir: "1",   rest: "45s"),
            ]
        ),
        "Tue": Session(
            dayKey: "Tue",
            label: "Zone 2",
            cnsLoad: .low,
            isCardio: true,
            exercises: [
                Exercise(name: "Zone 2 cardio", sets: 1, reps: "60 min", load: "60–70% HRmax", rir: "—", rest: "—"),
            ]
        ),
        "Wed": Session(
            dayKey: "Wed",
            label: "Threshold Intervals",
            cnsLoad: .high,
            isCardio: true,
            exercises: [
                Exercise(name: "Warm-up",                sets: 1, reps: "10 min", load: "~70% HRmax",   rir: "—", rest: "—"),
                Exercise(name: "5×3 min threshold",      sets: 5, reps: "3 min",  load: "~95% HRmax",   rir: "—", rest: "2min easy"),
                Exercise(name: "Cool-down",              sets: 1, reps: "5 min",  load: "Easy",          rir: "—", rest: "—"),
            ]
        ),
        "Thu": Session(
            dayKey: "Thu",
            label: "Full-body B",
            cnsLoad: .moderate,
            isCardio: false,
            exercises: [
                Exercise(name: "Trap bar deadlift",      sets: 4, reps: "5",      load: "—",    rir: "2", rest: "2min"),
                Exercise(name: "Weighted pull-up",       sets: 4, reps: "6",      load: "+load",rir: "2", rest: "2min"),
                Exercise(name: "Overhead press",         sets: 3, reps: "6",      load: "—",    rir: "2", rest: "90s"),
                Exercise(name: "Bulgarian split squat",  sets: 3, reps: "10/leg", load: "—",    rir: "1", rest: "75s"),
                Exercise(name: "Incline DB press",       sets: 3, reps: "10",     load: "—",    rir: "1", rest: "75s"),
                Exercise(name: "Hammer curl",            sets: 2, reps: "10",     load: "—",    rir: "1", rest: "60s"),
                Exercise(name: "Skull crusher",          sets: 2, reps: "12",     load: "—",    rir: "1", rest: "60s"),
            ]
        ),
        "Fri": Session(
            dayKey: "Fri",
            label: "Zone 2",
            cnsLoad: .low,
            isCardio: true,
            exercises: [
                Exercise(name: "Zone 2 cardio", sets: 1, reps: "75 min", load: "60–70% HRmax", rir: "—", rest: "—"),
            ]
        ),
        "Sat": Session(
            dayKey: "Sat",
            label: "Long Zone 2",
            cnsLoad: .low,
            isCardio: true,
            exercises: [
                Exercise(name: "Zone 2 cardio", sets: 1, reps: "90+ min", load: "60–70% HRmax", rir: "—", rest: "—"),
            ]
        ),
        "Sun": Session(
            dayKey: "Sun",
            label: "Rest or Yoga",
            cnsLoad: .rest,
            isCardio: false,
            exercises: []
        ),
    ]

    // MARK: - Winter (Weeks 40–52): Hypertrophy + Work Capacity
    static let winter: [String: Session] = [
        "Mon": Session(
            dayKey: "Mon",
            label: "Push",
            cnsLoad: .moderate,
            isCardio: false,
            exercises: [
                Exercise(name: "Bench press",               sets: 4, reps: "8",  load: "—", rir: "1–2", rest: "2min"),
                Exercise(name: "Incline DB press",          sets: 4, reps: "10", load: "—", rir: "1",   rest: "90s"),
                Exercise(name: "Seated DB OHP",             sets: 3, reps: "10", load: "—", rir: "1",   rest: "90s"),
                Exercise(name: "Cable lateral raise",       sets: 4, reps: "15", load: "—", rir: "0",   rest: "45s"),
                Exercise(name: "Cable fly",                 sets: 3, reps: "12", load: "—", rir: "0",   rest: "60s"),
                Exercise(name: "Triceps rope",              sets: 4, reps: "12", load: "—", rir: "0",   rest: "45s"),
                Exercise(name: "Overhead triceps ext",      sets: 3, reps: "12", load: "—", rir: "0",   rest: "45s"),
            ]
        ),
        "Tue": Session(
            dayKey: "Tue",
            label: "Pull",
            cnsLoad: .moderate,
            isCardio: false,
            exercises: [
                Exercise(name: "Weighted pull-up",          sets: 4, reps: "6–8",  load: "+load", rir: "1–2", rest: "2min"),
                Exercise(name: "Barbell row",               sets: 3, reps: "8",    load: "—",     rir: "1–2", rest: "90s"),
                Exercise(name: "Lat pulldown",              sets: 3, reps: "10",   load: "—",     rir: "1",   rest: "75s"),
                Exercise(name: "Chest-supported row",       sets: 3, reps: "12",   load: "—",     rir: "1",   rest: "75s"),
                Exercise(name: "Face pulls",                sets: 3, reps: "15",   load: "—",     rir: "0",   rest: "45s"),
                Exercise(name: "Barbell curl",              sets: 4, reps: "10",   load: "—",     rir: "0",   rest: "45s"),
                Exercise(name: "Incline DB curl",           sets: 3, reps: "12",   load: "—",     rir: "0",   rest: "45s"),
            ]
        ),
        "Wed": Session(
            dayKey: "Wed",
            label: "Legs",
            cnsLoad: .high,
            isCardio: false,
            exercises: [
                Exercise(name: "Back squat",                sets: 4, reps: "6–8",  load: "—", rir: "1–2", rest: "2–3min"),
                Exercise(name: "Romanian deadlift",         sets: 3, reps: "8",    load: "—", rir: "1",   rest: "2min"),
                Exercise(name: "Leg press",                 sets: 3, reps: "12",   load: "—", rir: "1",   rest: "90s"),
                Exercise(name: "Walking lunge",             sets: 3, reps: "12/leg",load: "—",rir: "1",   rest: "75s"),
                Exercise(name: "Leg curl",                  sets: 4, reps: "10",   load: "—", rir: "0",   rest: "60s"),
                Exercise(name: "Standing calf",             sets: 4, reps: "10",   load: "—", rir: "0",   rest: "45s"),
                Exercise(name: "Seated calf",               sets: 3, reps: "15",   load: "—", rir: "0",   rest: "45s"),
            ]
        ),
        "Thu": Session(
            dayKey: "Thu",
            label: "Upper Hypertrophy",
            cnsLoad: .moderate,
            isCardio: false,
            exercises: [
                Exercise(name: "Incline barbell press",     sets: 4, reps: "8",  load: "—", rir: "1", rest: "2min"),
                Exercise(name: "Pendlay row",               sets: 3, reps: "8",  load: "—", rir: "1", rest: "90s"),
                Exercise(name: "Arnold press",              sets: 3, reps: "10", load: "—", rir: "1", rest: "75s"),
                Exercise(name: "Cable row",                 sets: 3, reps: "12", load: "—", rir: "0", rest: "60s"),
                Exercise(name: "Lateral raise",             sets: 4, reps: "12", load: "—", rir: "0", rest: "45s"),
                Exercise(name: "EZ-bar curl",               sets: 3, reps: "10", load: "—", rir: "0", rest: "45s"),
                Exercise(name: "Skull crusher",             sets: 3, reps: "10", load: "—", rir: "0", rest: "45s"),
            ]
        ),
        "Fri": Session(
            dayKey: "Fri",
            label: "Lower Hypertrophy",
            cnsLoad: .moderateHigh,
            isCardio: false,
            exercises: [
                Exercise(name: "Front squat",               sets: 4, reps: "8",      load: "—", rir: "1", rest: "2min"),
                Exercise(name: "Hip thrust",                sets: 4, reps: "10",     load: "—", rir: "1", rest: "90s"),
                Exercise(name: "Bulgarian split squat",     sets: 3, reps: "10/leg", load: "—", rir: "1", rest: "75s"),
                Exercise(name: "Hack squat or leg press",   sets: 3, reps: "12",     load: "—", rir: "0", rest: "75s"),
                Exercise(name: "Lying leg curl",            sets: 4, reps: "12",     load: "—", rir: "0", rest: "60s"),
                Exercise(name: "Glute-ham raise",           sets: 3, reps: "10",     load: "—", rir: "0", rest: "60s"),
                Exercise(name: "Calf raise",                sets: 4, reps: "12",     load: "—", rir: "0", rest: "45s"),
            ]
        ),
        "Sat": Session(
            dayKey: "Sat",
            label: "Z2 + Mobility",
            cnsLoad: .low,
            isCardio: true,
            exercises: [
                Exercise(name: "Zone 2 cardio", sets: 1, reps: "60 min",  load: "60–70% HRmax", rir: "—", rest: "—"),
                Exercise(name: "Mobility/yoga", sets: 1, reps: "15 min",  load: "—",            rir: "—", rest: "—"),
            ]
        ),
        "Sun": Session(
            dayKey: "Sun",
            label: "Rest",
            cnsLoad: .rest,
            isCardio: false,
            exercises: []
        ),
    ]

    // MARK: - Transition Week (weeks 13, 26, 39, 52)
    // All 7 days are light: Zone 2 cardio + mobility only.
    static let transition: [String: Session] = {
        let transitionDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return Dictionary(uniqueKeysWithValues: transitionDays.map { day in
            (day, Session(
                dayKey: day,
                label: "Transition Week — Z2 + Mobility",
                cnsLoad: .low,
                isCardio: true,
                exercises: [
                    Exercise(name: "Zone 2 cardio", sets: 1, reps: "30–45 min",
                             load: "60–70% HRmax", rir: "—", rest: "—"),
                    Exercise(name: "Mobility/yoga",  sets: 1, reps: "15–20 min",
                             load: "—",             rir: "—", rest: "—"),
                ]
            ))
        })
    }()

    // MARK: - Lookup
    /// Returns the session schedule for the given week.
    /// Transition weeks (13, 26, 39, 52) always return the light Z2+mobility schedule.
    static func schedule(for week: Int) -> [String: Session] {
        if Seasons.isTransition(week) { return transition }
        switch week {
        case 1...13:  return spring
        case 14...26: return summer
        case 27...39: return fall
        default:      return winter
        }
    }

    static func session(week: Int, dayKey: String) -> Session? {
        schedule(for: week)[dayKey]
    }
}
