import Foundation

// MARK: - Supplement
/// A single supplement entry in the evidence-based catalog.
/// `bwScaledDoseFn` is intentionally non-Codable — it's a pure function that
/// derives a dose string from bodyweight kg at display time. The base `dose`
/// string is always stored and shown as a fallback.
struct Supplement: Identifiable {
    let id: Int
    let name: String
    /// Human-readable base dose (e.g. "0.1 g/kg" or "5g"). Always displayed.
    let dose: String
    /// When present, called with bodyweight in kg to produce a personalised
    /// dose string (e.g. "~9,000 mg for 90 kg"). Displayed alongside baseDose.
    let bwScaledDoseFn: ((Double) -> String)?
    let timing: String
    /// 1 = year-round, 2 = context-dependent, 3 = situational
    let tier: Int
    /// Evidence grade + key citation, e.g. "A+ — Kreider 2017 ISSN; 500+ RCTs"
    let evidence: String
    /// One-line "why this matters" — shown in PlanView beneath the name.
    let rationale: String
    /// Optional safety note shown in red. Nil when no warnings apply.
    let cautions: String?

    init(
        id: Int,
        name: String,
        dose: String,
        bwScaledDoseFn: ((Double) -> String)? = nil,
        timing: String,
        tier: Int,
        evidence: String,
        rationale: String,
        cautions: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dose = dose
        self.bwScaledDoseFn = bwScaledDoseFn
        self.timing = timing
        self.tier = tier
        self.evidence = evidence
        self.rationale = rationale
        self.cautions = cautions
    }
}

// MARK: - Supplement Catalogue
enum SupplementList {

    // MARK: Tier 1 — Year-round, evidence A
    // These have the strongest mechanistic + RCT support. Appropriate for nearly
    // all healthy adults engaged in structured resistance + cardio training.

    static let all: [Supplement] = [

        // --- Tier 1 ---

        Supplement(
            id: 0,
            name: "Creatine monohydrate",
            dose: "0.1 g/kg",
            bwScaledDoseFn: { bw in
                // 0.1 g/kg expressed in mg for precision display
                let mg = Int(bw * 0.1 * 1000)
                return "\(mg) mg for \(Int(bw)) kg"
            },
            timing: "Anytime daily",
            tier: 1,
            evidence: "A+ — Kreider 2017 ISSN; 500+ RCTs",
            rationale: "Strength, lean mass, cognition, bone density. The single best-supported supplement."
        ),

        Supplement(
            id: 1,
            name: "Omega-3 EPA+DHA",
            dose: "2–3 g combined",
            timing: "With fat meal",
            tier: 1,
            evidence: "A — Heaton 2017; Smith 2011",
            rationale: "Target Omega-3 Index 8–12%. DOMS, MPS in older adults, cardiovascular, neuroprotection."
        ),

        Supplement(
            id: 2,
            name: "Vitamin D3 + K2-MK7",
            dose: "70 IU/kg D3 + 100–200 mcg K2",
            bwScaledDoseFn: { bw in
                // 70 IU/kg is a common population-level starting dose before
                // titration to serum 25(OH)D 40–60 ng/mL
                let iu = Int(bw * 70)
                return "~\(iu) IU D3 for \(Int(bw)) kg"
            },
            timing: "AM with fat",
            tier: 1,
            evidence: "A — Holick 2007; Ekwaru 2014",
            rationale: "Titrate to serum 25(OH)D 40–60 ng/mL. Bone, immune, mood, testosterone support."
        ),

        Supplement(
            id: 3,
            name: "Whey isolate (convenience)",
            dose: "25–50 g",
            timing: "When protein target is hard to hit",
            tier: 1,
            evidence: "A — Morton 2018",
            rationale: "Convenience only — food first. DIAAS 1.09. Not necessary if dietary protein is adequate."
        ),

        Supplement(
            id: 4,
            name: "Magnesium glycinate",
            dose: "200–400 mg",
            timing: "Pre-bed",
            tier: 1,
            evidence: "A for deficiency; B for sleep",
            rationale: "~50% of Americans deficient. Sleep architecture, recovery, BP. Never oxide form.",
            cautions: "Glycinate or threonate form only — oxide has poor bioavailability and causes GI distress."
        ),

        // --- Tier 2 — Context-dependent, evidence B+ ---
        // Strong mechanistic rationale; benefits depend on training modality, diet,
        // or physiological context. Not universally necessary.

        Supplement(
            id: 5,
            name: "Beta-alanine",
            dose: "3.2–6.4 g/day split",
            timing: "Daily with meals",
            tier: 2,
            evidence: "A — Saunders 2017 BJSM",
            rationale: "1–4 min max efforts: high-rep sets, sprints, 400–1500m. Meaningless for pure strength work.",
            cautions: "Paresthesia (tingling) is harmless but uncomfortable — split doses to minimise it."
        ),

        Supplement(
            id: 6,
            name: "L-Citrulline malate",
            dose: "6–8 g",
            timing: "60 min pre-workout",
            tier: 2,
            evidence: "B — Trexler 2019 JSCR",
            rationale: "Pump, rep volume at fatigue threshold. Better bioavailability than arginine."
        ),

        Supplement(
            id: 7,
            name: "Caffeine",
            dose: "3–6 mg/kg",
            bwScaledDoseFn: { bw in
                let lo = Int(bw * 3)
                let hi = Int(bw * 6)
                return "\(lo)–\(hi) mg for \(Int(bw)) kg"
            },
            timing: "30–60 min pre-workout",
            tier: 2,
            evidence: "A+ — Grgic 2020 BJSM",
            rationale: "Strength, power, and endurance all improved. Cycle regularly to preserve response.",
            cautions: "Hard cutoff 8–10 h before bed. Half-life 5–6 h. Avoid daily use to prevent tolerance."
        ),

        Supplement(
            id: 8,
            name: "Ashwagandha KSM-66",
            dose: "600 mg/day",
            timing: "AM or split AM+PM",
            tier: 2,
            evidence: "B — Lopresti 2019",
            rationale: "Cortisol modulation, sleep quality, possibly testosterone in stressed males. Fall season ideal."
        ),

        Supplement(
            id: 9,
            name: "Taurine",
            dose: "1–3 g",
            timing: "Pre-workout or pre-bed",
            tier: 2,
            evidence: "B — Waldron 2018 Sports Med",
            rationale: "Endurance performance, cardiovascular support, sleep. Synergises with caffeine pre-workout."
        ),

        Supplement(
            id: 10,
            name: "Glycine",
            dose: "3 g",
            timing: "Pre-bed",
            tier: 2,
            evidence: "B — Yamadera 2007",
            rationale: "Sleep onset acceleration via core temperature drop. Pairs well with magnesium glycinate."
        ),

        // --- Tier 3 — Situational ---
        // Narrow use-cases; relevant only in specific training contexts or seasons.

        Supplement(
            id: 11,
            name: "Sodium bicarbonate",
            dose: "0.2–0.3 g/kg",
            bwScaledDoseFn: { bw in
                let lo = Int(bw * 0.2 * 1000)
                let hi = Int(bw * 0.3 * 1000)
                return "\(lo)–\(hi) mg for \(Int(bw)) kg"
            },
            timing: "60–180 min pre-exercise",
            tier: 3,
            evidence: "B — efficacy for 1–7 min max efforts",
            rationale: "Acid buffer for high-intensity bouts. Use enteric capsules to avoid GI distress."
        ),

        Supplement(
            id: 12,
            name: "Beetroot / dietary nitrate",
            dose: "6–12 mmol NO3-",
            timing: "2–3 h pre-exercise",
            tier: 3,
            evidence: "B — endurance, altitude, team sports",
            rationale: "Concentrated shot or 500 ml juice. Strongest at altitude and in aerobic events."
        ),

        Supplement(
            id: 13,
            name: "Tart cherry",
            dose: "480 mg extract or 8–12 oz juice",
            timing: "Pre-bed or post-workout",
            tier: 3,
            evidence: "B — DOMS, sleep",
            rationale: "Anti-inflammatory polyphenols + melatonin precursors. Best in high-volume training blocks."
        ),

        Supplement(
            id: 14,
            name: "Collagen + Vitamin C",
            dose: "15 g collagen + 50 mg C",
            timing: "60 min pre rehab or tendon work",
            tier: 3,
            evidence: "B — Shaw 2017 AJCN",
            rationale: "Tendon and ligament collagen synthesis. Use before jump training or injury rehab only."
        ),

        Supplement(
            id: 15,
            name: "Electrolytes",
            dose: "300–700 mg sodium",
            timing: "Sessions >45 min or hot weather",
            tier: 3,
            evidence: "A for prolonged sweat losses",
            rationale: "Pinch of sea salt + lemon water suffices for most. Sodium is the rate-limiting ion."
        ),
    ]

    // MARK: Big lifts — used elsewhere for PR tracking
    static let bigLifts = ["Back squat", "Bench press", "Conventional deadlift", "Standing OHP"]

    // MARK: Skip list
    /// Products with insufficient or negative evidence. Shown as a callout in PlanView.
    static let skipList = "BCAAs · glutamine · T boosters (Tribulus, ZMA, D-AA, Tongkat) · fat burners · mega-dose Vit C/E around training · NMN/NR (unproven endpoints) · HMB (oversold)"
}
