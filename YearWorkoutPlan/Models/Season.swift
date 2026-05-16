import SwiftUI

// MARK: - Season
/// Represents one of the four 13-week training seasons in the 52-week plan.
/// Week 13 of each season (weeks 13, 26, 39, 52) is a transition/light week.
struct Season: Identifiable, Equatable {
    let id: Int           // 0-based index used for equality checks
    let name: String
    let weekRange: ClosedRange<Int>
    let color: Color
    let accentColor: Color
    let goal: String
    let calories: Int
    let protein: Int
    let carbsTrain: Int
    let carbsRest: Int
    let fat: Int

    // Convenient display colour as hex string (for contexts needing opacity variants)
    var hexColor: String {
        switch name {
        case "Spring":  return "#22C55E"
        case "Summer":  return "#F59E0B"
        case "Fall":    return "#EF4444"
        default:        return "#3B82F6"  // Winter
        }
    }
}

// MARK: - Season Catalogue
enum Seasons {
    static let all: [Season] = [
        Season(
            id: 0,
            name: "Spring",
            weekRange: 1...13,
            color: AppColor.spring,
            accentColor: AppColor.springAccent,
            goal: "VO2 Max + Hypertrophy",
            calories: 3000,
            protein: 135,
            carbsTrain: 375,
            carbsRest: 275,
            fat: 105
        ),
        Season(
            id: 1,
            name: "Summer",
            weekRange: 14...26,
            color: AppColor.summer,
            accentColor: AppColor.summerAccent,
            goal: "Maximal Strength",
            calories: 3100,
            protein: 150,
            carbsTrain: 350,
            carbsRest: 250,
            fat: 110
        ),
        Season(
            id: 2,
            name: "Fall",
            weekRange: 27...39,
            color: AppColor.fall,
            accentColor: AppColor.fallAccent,
            goal: "Aerobic Base + Body Comp",
            calories: 2700,
            protein: 150,
            carbsTrain: 280,
            carbsRest: 200,
            fat: 90
        ),
        Season(
            id: 3,
            name: "Winter",
            weekRange: 40...52,
            color: AppColor.winter,
            accentColor: AppColor.winterAccent,
            goal: "Hypertrophy + Work Capacity",
            calories: 3300,
            protein: 145,
            carbsTrain: 425,
            carbsRest: 325,
            fat: 115
        ),
    ]

    static func season(for week: Int) -> Season {
        all.first { $0.weekRange.contains(week) } ?? all[0]
    }

    static func isDeload(_ week: Int) -> Bool {
        week % 4 == 0
    }

    /// Returns true for transition weeks (last week of each 13-week season).
    /// Weeks 13, 26, 39, 52 are light Z2 + mobility transition weeks.
    static func isTransition(_ week: Int) -> Bool {
        week % 13 == 0
    }
}
