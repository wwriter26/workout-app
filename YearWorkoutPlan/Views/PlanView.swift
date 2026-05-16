import SwiftUI

// MARK: - Plan View
struct PlanView: View {
    @Environment(AppState.self) private var state

    private let tabs = ["nutrition", "recipes", "mobility", "supplements", "sleep", "whoop", "non-neg"]

    var body: some View {
        @Bindable var bindState = state
        VStack(spacing: 0) {
            // Horizontal-scroll tab strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tabs, id: \.self) { tab in
                        let isSelected = state.planTab == tab
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                state.planTab = tab
                            }
                        } label: {
                            Text(tab.uppercased())
                                .font(.system(size: 11, weight: .semibold, design: .default))
                                .tracking(0.8)
                                .foregroundColor(isSelected ? state.season.color : AppColor.textDimmed)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? state.season.color.opacity(0.13) : AppColor.cardBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? state.season.color : AppColor.border2, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }

            Divider().background(AppColor.border1)

            ScrollView {
                VStack(spacing: 10) {
                    switch state.planTab {
                    case "nutrition":    NutritionTab()
                    case "recipes":      RecipeListView()
                    case "mobility":     MobilitySectionView()
                    case "supplements":  SupplementsTab()
                    case "sleep":        SleepTab()
                    case "whoop":        WhoopTab()
                    default:             NonNegTab()
                    }
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Nutrition Tab
private struct NutritionTab: View {
    @Environment(AppState.self) private var state
    @State private var expandedFoodGroup: String? = nil

    private let mealTiming: [(String, String, String)] = [
        ("7:00 AM",  "Breakfast",          "30–35g protein · Eggs + Greek yogurt"),
        ("12:00 PM", "Lunch",              "30–35g protein · Prepped meal #1"),
        ("3:30 PM",  "Pre-WO Snack",       "20–25g protein · Shake or cottage cheese"),
        ("6–7 PM",   "Post-WO / Dinner",   "35–40g protein · Prepped meal #2"),
        ("~9:30 PM", "Pre-bed Casein",      "30–40g casein · 90 min before lights out"),
    ]

    private let foodGroups: [(String, [String])] = [
        ("Proteins", [
            "Chicken breast", "Lean ground beef (93%)", "Ground turkey",
            "Eggs", "Greek yogurt (non-fat plain)", "Cottage cheese",
            "Whey isolate", "Casein", "Salmon", "White fish (cod, tilapia)",
            "Tuna (canned in water)", "Shrimp", "Lean steak (sirloin, flank)",
            "Tofu", "Tempeh", "Edamame",
        ]),
        ("Carbs — Training Days", [
            "White rice", "Jasmine rice", "Sweet potatoes", "White potatoes",
            "Oats", "Sourdough bread", "Bagels", "Rice cakes",
            "Fruit (bananas, berries, apples, oranges)", "Honey",
            "Dextrose (intra-workout)", "Pasta",
        ]),
        ("Carbs — Rest Days", [
            "Sweet potatoes", "Oats", "Quinoa",
            "Beans (black, kidney, chickpeas)", "Lentils",
            "Berries", "Leafy greens", "Cruciferous veg",
        ]),
        ("Fats", [
            "Olive oil (EVOO)", "Butter (grass-fed)", "Avocado",
            "Almond butter", "Peanut butter (natural)", "Almonds",
            "Walnuts", "Macadamia", "Egg yolks",
            "Fatty fish", "Dark chocolate (85%+)",
        ]),
        ("Vegetables — Year-Round", [
            "Broccoli", "Spinach", "Kale", "Bell peppers",
            "Green beans", "Asparagus", "Brussels sprouts", "Cauliflower",
            "Zucchini", "Carrots", "Tomatoes", "Cucumbers",
            "Onions", "Garlic", "Mushrooms",
        ]),
        ("Sodium / Electrolytes", [
            "Sea salt", "Pickles", "Olives", "Sauerkraut",
            "Miso", "Coconut water", "Mineral water",
        ]),
    ]

    var body: some View {
        // Macro targets by season
        CardView {
            SectionLabel(text: "Macros by Season")
            ForEach(Seasons.all) { s in
                let isCurrent = s.name == state.season.name
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(s.name)
                            .font(.appSubhead)
                            .foregroundColor(s.color)
                        Spacer()
                        if isCurrent {
                            BadgeView("CURRENT",
                                      foreground: s.color,
                                      background: s.color.opacity(0.2))
                        }
                    }
                    Text(s.goal)
                        .font(.appBody)
                        .foregroundColor(AppColor.textDimmed)

                    HStack(spacing: 16) {
                        ForEach([
                            ("Cals", s.calories, "kcal"),
                            ("Prot", s.protein, "g"),
                            ("Carbs", s.carbsTrain, "g"),
                            ("Fat", s.fat, "g"),
                        ], id: \.0) { label, value, unit in
                            VStack(spacing: 2) {
                                Text("\(value)")
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(AppColor.textPrimary)
                                Text("\(unit) \(label)")
                                    .font(.monoTiny)
                                    .foregroundColor(AppColor.textFaint)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(12)
                .background(isCurrent ? s.color.opacity(0.07) : Color(hex: "#111111"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrent ? s.color : AppColor.border1, lineWidth: 1)
                )
                .padding(.top, 10)
            }
        }

        // Meal timing
        CardView {
            SectionLabel(text: "Meal Timing")
            ForEach(mealTiming, id: \.0) { (time, label, note) in
                HStack(alignment: .top, spacing: 12) {
                    Text(time)
                        .font(.monoSmall)
                        .foregroundColor(state.season.color)
                        .frame(width: 60, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                        Text(note)
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textDimmed)
                    }
                }
                .padding(.vertical, 10)
                Divider().background(AppColor.cardBackground2)
            }
        }

        // Recommended foods — expandable by category
        CardView {
            SectionLabel(text: "Recommended Foods")
            Text("Tap a category to expand")
                .font(.appSmall)
                .foregroundColor(AppColor.textFaint)
                .padding(.bottom, 6)

            ForEach(foodGroups, id: \.0) { (group, foods) in
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedFoodGroup = expandedFoodGroup == group ? nil : group
                        }
                    } label: {
                        HStack {
                            Text(group)
                                .font(.appSubhead)
                                .foregroundColor(AppColor.textSecondary)
                            Spacer()
                            Image(systemName: expandedFoodGroup == group ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColor.textFaint)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if expandedFoodGroup == group {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 6
                        ) {
                            ForEach(foods, id: \.self) { food in
                                Text(food)
                                    .font(.appSmall)
                                    .foregroundColor(AppColor.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(AppColor.cardBackground2)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    Divider().background(AppColor.border1)
                }
            }
        }
    }
}

// MARK: - Supplements Tab
private struct SupplementsTab: View {
    @Environment(AppState.self) private var state

    var body: some View {
        CardView {
            ForEach([1, 2, 3], id: \.self) { tier in
                let tierColor: Color = tier == 1 ? state.season.color : tier == 2 ? AppColor.deload : AppColor.textDimmed
                let tierLabel = tier == 1 ? "YEAR-ROUND (STRONG EVIDENCE)"
                              : tier == 2 ? "TEST-DRIVEN"
                              : "SITUATIONAL"

                SectionLabel(text: "TIER \(tier) — \(tierLabel)", color: tierColor)
                    .padding(.top, tier > 1 ? 20 : 0)

                ForEach(SupplementList.all.filter { $0.tier == tier }) { supp in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(supp.name)
                                .font(.appSubhead)
                                .foregroundColor(AppColor.textSecondary)
                            Text(supp.timing)
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textDimmed)
                        }
                        Spacer()
                        Text(supp.dose)
                            .font(.monoSmall)
                            .foregroundColor(AppColor.textMuted)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    Divider().background(AppColor.cardBackground2)
                }
            }

            // Skip callout
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "SKIP THESE", color: AppColor.dangerRed)
                Text(SupplementList.skipList)
                    .font(.appBody)
                    .foregroundColor(AppColor.textDimmed)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#1A0A0A"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "#2D1A1A"), lineWidth: 1)
            )
            .padding(.top, 16)
        }
    }
}

// MARK: - Sleep Tab
private struct SleepTab: View {
    private let nonNegotiables: [(String, String, String)] = [
        ("TARGET",     "8 hours actual sleep",           "Most need 8.5–9 in bed to achieve this"),
        ("SCHEDULE",   "Consistent wake time ±30 min",   "Anchors circadian rhythm — even weekends"),
        ("SCREENS",    "No screens 60 min pre-bed",       "Or use blue-light glasses"),
        ("TEMP",       "Room temp 65–68°F",               "Core temp drop triggers sleep onset"),
        ("DARK",       "Dark room",                       "Blackout curtains or eye mask"),
    ]

    private let habits = [
        "Sunlight on retina within 30 min of waking (10 min outside, even cloudy)",
        "Last solid meal 2–3 hr before bed (digestion fragments sleep)",
        "Casein 90 min before bed (liquid, slow-release)",
        "Alcohol kills HRV — 1 drink within 4 hr of sleep drops recovery 15–20%",
    ]

    var body: some View {
        CardView {
            SectionLabel(text: "Non-Negotiables")
            ForEach(nonNegotiables, id: \.0) { (_, title, sub) in
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                        Text(sub)
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textDimmed)
                    }
                }
                .padding(.vertical, 12)
                Divider().background(AppColor.cardBackground2)
            }

            SectionLabel(text: "Daily Habits")
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(habits, id: \.self) { h in
                Text(h)
                    .font(.appBody)
                    .foregroundColor(AppColor.textMuted)
                    .padding(.vertical, 6)
                Divider().background(Color(hex: "#111111"))
            }

            // Under 6 hours callout
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "UNDER 6 HOURS?", color: AppColor.infoBlue)
                Text("Whoop will likely red. Train Z2 only. Pushing through a sleep deficit costs more progress than accepting it.")
                    .font(.appBody)
                    .foregroundColor(AppColor.textDimmed)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#0A0A1A"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "#1A1A2D"), lineWidth: 1)
            )
            .padding(.top, 16)
        }
    }
}

// MARK: - Whoop Tab
private struct WhoopTab: View {
    private let trendRules: [(String, String)] = [
        ("3+ red days in 7",           "Unscheduled deload week — non-negotiable"),
        ("HRV down 10%+ for 5+ days",  "Cut a hard session, replace with Z2"),
        ("Mostly yellow, 1–2 greens",  "Functional overreaching — stay the course"),
        ("All green for 7+ days",      "Under-stimulating — add a set or interval"),
    ]

    var body: some View {
        CardView {
            SectionLabel(text: "Decision Matrix")
            ForEach(WhoopStatus.allCases, id: \.self) { status in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.label)
                            .font(.appSubhead)
                            .foregroundColor(status.color)
                        Text(status.description)
                            .font(.appBody)
                            .foregroundColor(AppColor.textMuted)
                    }
                }
                .padding(.vertical, 12)
                Divider().background(AppColor.cardBackground2)
            }

            SectionLabel(text: "Weekly Trend Rules")
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(trendRules, id: \.0) { (signal, action) in
                VStack(alignment: .leading, spacing: 4) {
                    Text("→ \(signal)")
                        .font(.appBody)
                        .foregroundColor(AppColor.summer)
                    Text(action)
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textDimmed)
                }
                .padding(.vertical, 10)
                Divider().background(AppColor.cardBackground2)
            }

            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "What Whoop Won't Tell You")
                Text("Soreness in a specific muscle group, joint/tendon irritation (shows up before HRV does), mental fatigue from non-training stress — adjust these manually.")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textDimmed)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#111111"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColor.border2, lineWidth: 1)
            )
            .padding(.top, 16)
        }
    }
}

// MARK: - Non-Negotiables Tab
private struct NonNegTab: View {
    @Environment(AppState.self) private var state

    private let adjustmentRules: [(String, String)] = [
        ("Bodyweight off-target 2 weeks",              "Adjust calories ±150 kcal"),
        ("Strength regression 2 sessions (outside Fall)", "Check sleep + protein. Deload if both fine."),
        ("3+ Whoop reds in 7 days",                    "Mandatory deload week"),
        ("HRV down 10%+ for 5+ days",                  "Cut hard session → Z2"),
        ("Joint/tendon irritation 3+ days",             "Swap exercise. Don't push through."),
    ]

    var body: some View {
        CardView {
            SectionLabel(text: "The 3 Non-Negotiables")
            let items: [(String, String, String)] = [
                ("1", "Hit protein",            "\(state.season.protein)g/day this season"),
                ("2", "Train 4+ days/week",     "Whoop-adjusted. Never to 0."),
                ("3", "8 hours actual sleep",   "Not time in bed — Whoop distinguishes."),
            ]
            ForEach(items, id: \.0) { (num, title, sub) in
                HStack(alignment: .top, spacing: 12) {
                    Text(num)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(state.season.color)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                        Text(sub)
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textDimmed)
                    }
                }
                .padding(.vertical, 14)
                Divider().background(AppColor.cardBackground2)
            }
        }

        CardView {
            SectionLabel(text: "Adjustment Rules")
            ForEach(adjustmentRules, id: \.0) { (signal, action) in
                VStack(alignment: .leading, spacing: 4) {
                    Text("IF: \(signal)")
                        .font(.appBody)
                        .foregroundColor(AppColor.summer)
                    Text("→ \(action)")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textMuted)
                }
                .padding(.vertical, 10)
                Divider().background(AppColor.cardBackground2)
            }
        }
    }
}
