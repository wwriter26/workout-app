import Foundation

// MARK: - Supplement
struct Supplement: Identifiable {
    let id: Int
    let name: String
    let dose: String
    let timing: String
    let tier: Int   // 1 = year-round, 2 = test-driven, 3 = situational
}

// MARK: - Supplement Catalogue
enum SupplementList {
    static let all: [Supplement] = [
        Supplement(id: 0, name: "Creatine monohydrate", dose: "5g",          timing: "Anytime daily",          tier: 1),
        Supplement(id: 1, name: "Whey protein",         dose: "25–30g",      timing: "Post-WO or to fill macros",tier: 1),
        Supplement(id: 2, name: "Casein",               dose: "30–40g",      timing: "90 min pre-bed",         tier: 1),
        Supplement(id: 3, name: "Omega-3 (EPA/DHA)",    dose: "2–3g",        timing: "With a meal",            tier: 1),
        Supplement(id: 4, name: "Beta-alanine",         dose: "3.2g daily",  timing: "Split doses",            tier: 1),
        Supplement(id: 5, name: "Vitamin D3",           dose: "2000–6000 IU",timing: "Test-driven",            tier: 2),
        Supplement(id: 6, name: "Electrolytes",         dose: "Per label",   timing: "Sessions >45 min",       tier: 3),
        Supplement(id: 7, name: "Magnesium glycinate",  dose: "200mg",       timing: "Pre-bed (if sleep poor)", tier: 3),
        Supplement(id: 8, name: "Ashwagandha",          dose: "600mg/day",   timing: "Fall season only",       tier: 3),
    ]

    static let bigLifts = ["Back squat", "Bench press", "Conventional deadlift", "Standing OHP"]

    static let skipList = "BCAAs · test boosters · glutamine · HMB · ZMA · fat burners · most pre-workouts"
}
