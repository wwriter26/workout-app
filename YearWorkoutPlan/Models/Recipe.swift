import SwiftUI

// MARK: - Recipe Tag
/// Structured tagging system for filtering and surfacing recipes in the list view.
/// Using String rawValues means the Codable representation is human-readable
/// in persisted blobs, and new cases can be added without breaking older decoders
/// (decodeIfPresent on the tags array in UserRecipe handles unknown values gracefully).
enum RecipeTag: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    // --- Macro profile ---
    case highProtein    = "highProtein"
    case balanced       = "balanced"
    case lowCarb        = "lowCarb"

    // --- Day type ---
    case trainingDay    = "trainingDay"
    case restDay        = "restDay"
    case preWO          = "preWO"
    case postWO         = "postWO"
    case preBed         = "preBed"

    // --- Season fit ---
    case spring         = "spring"
    case summer         = "summer"
    case fall           = "fall"
    case winter         = "winter"
    case anySeason      = "anySeason"

    // --- Elite nutritional anchors ---
    /// >= 35 g protein per serving
    case eliteProtein   = "eliteProtein"
    /// >= 10 g dietary fiber
    case highFiber      = "highFiber"
    /// >= 1 g EPA+DHA omega-3
    case omega3Rich     = "omega3Rich"
    /// Contains berries, cacao, EVOO, or other high-polyphenol ingredients
    case polyphenolRich = "polyphenolRich"

    // --- Prep time ---
    case under5         = "under5"
    case under15        = "under15"
    case under30        = "under30"
    case over30         = "over30"

    // MARK: Display

    var displayName: String {
        switch self {
        case .highProtein:    return "High Protein"
        case .balanced:       return "Balanced"
        case .lowCarb:        return "Low Carb"
        case .trainingDay:    return "Training"
        case .restDay:        return "Rest Day"
        case .preWO:          return "Pre-WO"
        case .postWO:         return "Post-WO"
        case .preBed:         return "Pre-Bed"
        case .spring:         return "Spring"
        case .summer:         return "Summer"
        case .fall:           return "Fall"
        case .winter:         return "Winter"
        case .anySeason:      return "Any Season"
        case .eliteProtein:   return "35g+ Protein"
        case .highFiber:      return "High Fiber"
        case .omega3Rich:     return "Omega-3"
        case .polyphenolRich: return "Polyphenols"
        case .under5:         return "<5 min"
        case .under15:        return "<15 min"
        case .under30:        return "<30 min"
        case .over30:         return "30+ min"
        }
    }

    /// Badge accent color. Maps to app season palette where meaningful;
    /// neutral grey for generic tags so the season accents remain distinctive.
    var color: Color {
        switch self {
        case .trainingDay, .postWO:       return AppColor.spring
        case .preWO:                      return AppColor.summer
        case .preBed, .restDay:           return AppColor.winter
        case .spring:                     return AppColor.spring
        case .summer:                     return AppColor.summer
        case .fall:                       return AppColor.fall
        case .winter:                     return AppColor.winter
        case .anySeason:                  return AppColor.textMuted
        case .eliteProtein:               return AppColor.summer
        case .highFiber:                  return AppColor.springAccent
        case .omega3Rich:                 return AppColor.winterAccent
        case .polyphenolRich:             return AppColor.deload
        case .highProtein:                return AppColor.summer
        case .balanced, .lowCarb:         return AppColor.textDimmed
        case .under5, .under15, .under30: return AppColor.textDimmed
        case .over30:                     return AppColor.textFaint
        }
    }
}

// MARK: - Recipe Macros
struct RecipeMacros: Codable, Hashable {
    var calories: Int
    var protein: Int    // grams
    var carbs: Int      // grams
    var fat: Int        // grams
}

// MARK: - Built-in Recipe (static, not persisted)
struct BuiltInRecipe: Identifiable {
    let id: Int
    let name: String
    let prepTime: String
    let macros: RecipeMacros
    let ingredients: [String]
    let steps: [String]

    // --- Wave 3 additions ---
    let tags: [RecipeTag]
    /// Dietary fiber in grams.
    let fiber: Int
    /// Combined EPA+DHA in grams; 0 for recipes with negligible fatty fish content.
    let omega3: Double
    /// Non-nil for recipes containing notable polyphenol sources.
    let polyphenolNote: String?
    /// One-line explanation of why this recipe is nutritionally elite.
    let whyElite: String

    init(
        id: Int,
        name: String,
        prepTime: String,
        macros: RecipeMacros,
        ingredients: [String],
        steps: [String],
        tags: [RecipeTag] = [],
        fiber: Int = 0,
        omega3: Double = 0,
        polyphenolNote: String? = nil,
        whyElite: String = ""
    ) {
        self.id = id
        self.name = name
        self.prepTime = prepTime
        self.macros = macros
        self.ingredients = ingredients
        self.steps = steps
        self.tags = tags
        self.fiber = fiber
        self.omega3 = omega3
        self.polyphenolNote = polyphenolNote
        self.whyElite = whyElite
    }
}

// MARK: - User Recipe (Codable, persisted via AppState)
/// Wave 3 adds optional nutritional fields. `decodeIfPresent` guarantees that
/// blobs saved before Wave 3 decode without throwing — all new fields default.
struct UserRecipe: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var prepTime: String
    var macros: RecipeMacros
    var ingredients: [String]
    var steps: [String]

    // --- Wave 3 additions (all optional/defaulted for backward compat) ---
    var tags: [RecipeTag]
    var fiber: Int
    var omega3: Double
    var polyphenolNote: String?
    var whyElite: String

    init(
        id: UUID = UUID(),
        name: String,
        prepTime: String,
        macros: RecipeMacros,
        ingredients: [String],
        steps: [String],
        tags: [RecipeTag] = [],
        fiber: Int = 0,
        omega3: Double = 0,
        polyphenolNote: String? = nil,
        whyElite: String = ""
    ) {
        self.id = id
        self.name = name
        self.prepTime = prepTime
        self.macros = macros
        self.ingredients = ingredients
        self.steps = steps
        self.tags = tags
        self.fiber = fiber
        self.omega3 = omega3
        self.polyphenolNote = polyphenolNote
        self.whyElite = whyElite
    }

    // Custom decoder: decode new fields with decodeIfPresent so pre-Wave-3
    // persisted blobs continue to load successfully. New fields default gracefully.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,            forKey: .id)
        name         = try c.decode(String.self,          forKey: .name)
        prepTime     = try c.decode(String.self,          forKey: .prepTime)
        macros       = try c.decode(RecipeMacros.self,    forKey: .macros)
        ingredients  = try c.decode([String].self,        forKey: .ingredients)
        steps        = try c.decode([String].self,        forKey: .steps)
        tags         = (try? c.decodeIfPresent([RecipeTag].self, forKey: .tags)) ?? []
        fiber        = (try? c.decodeIfPresent(Int.self,         forKey: .fiber)) ?? 0
        omega3       = (try? c.decodeIfPresent(Double.self,      forKey: .omega3)) ?? 0
        polyphenolNote = try? c.decodeIfPresent(String.self,     forKey: .polyphenolNote)
        whyElite     = (try? c.decodeIfPresent(String.self,      forKey: .whyElite)) ?? ""
    }
}

// MARK: - Built-in Recipe Catalogue
enum BuiltInRecipes {
    static let all: [BuiltInRecipe] = [

        // MARK: - Existing 6 (updated with Wave 3 metadata)

        BuiltInRecipe(
            id: 0,
            name: "Power Breakfast Bowl",
            prepTime: "5 min",
            macros: RecipeMacros(calories: 600, protein: 40, carbs: 65, fat: 22),
            ingredients: [
                "1 cup non-fat plain Greek yogurt",
                "½ cup rolled oats",
                "½ cup mixed berries (fresh or frozen)",
                "1 tbsp honey",
                "1 tbsp almond butter",
            ],
            steps: [
                "Mix oats into Greek yogurt in a bowl.",
                "Top with berries.",
                "Drizzle honey and almond butter over the top.",
                "Optional: microwave 60s for warm oats, then add yogurt cold.",
            ],
            tags: [.trainingDay, .balanced, .anySeason, .under5, .polyphenolRich],
            fiber: 8,
            omega3: 0,
            polyphenolNote: "Berries: anthocyanins",
            whyElite: "Fast-digesting carbs + casein/whey blend from yogurt. Anthocyanins from berries support overnight DOMS resolution."
        ),

        BuiltInRecipe(
            id: 1,
            name: "Chicken Rice Power Plate",
            prepTime: "20 min",
            macros: RecipeMacros(calories: 750, protein: 50, carbs: 85, fat: 18),
            ingredients: [
                "6 oz chicken breast",
                "1 cup jasmine rice (dry weight ½ cup)",
                "1 cup broccoli florets",
                "1 tbsp olive oil",
                "1 tbsp low-sodium soy sauce",
                "Salt, pepper, garlic powder to taste",
            ],
            steps: [
                "Cook rice per package directions.",
                "Season chicken with salt, pepper, and garlic powder.",
                "Heat olive oil in a skillet over medium-high heat.",
                "Cook chicken 5–6 min per side until internal temp reaches 165°F.",
                "Steam or microwave broccoli 3–4 min until tender.",
                "Slice chicken; plate with rice and broccoli. Drizzle soy sauce.",
            ],
            tags: [.trainingDay, .highProtein, .anySeason, .under30, .eliteProtein],
            fiber: 5,
            omega3: 0,
            whyElite: "Classic lean-mass staple: 50g complete protein, high-GI post-training carbs, low fat."
        ),

        BuiltInRecipe(
            id: 2,
            name: "Steak & Sweet Potato",
            prepTime: "25 min",
            macros: RecipeMacros(calories: 820, protein: 55, carbs: 70, fat: 30),
            ingredients: [
                "6 oz sirloin or flank steak",
                "1 medium sweet potato (~8 oz)",
                "1 cup asparagus spears",
                "1 tbsp grass-fed butter",
                "Salt, pepper, garlic to taste",
            ],
            steps: [
                "Pierce sweet potato; microwave 5–7 min until soft, or bake 400°F for 45 min.",
                "Season steak generously with salt, pepper, and garlic.",
                "Sear steak in a cast iron skillet over high heat, 3–4 min per side for medium-rare.",
                "Rest steak 5 min before slicing.",
                "Sauté asparagus in butter 3–4 min until tender-crisp.",
                "Plate steak, sweet potato (split and topped with remaining butter), and asparagus.",
            ],
            tags: [.trainingDay, .highProtein, .winter, .summer, .under30, .eliteProtein],
            fiber: 8,
            omega3: 0,
            whyElite: "Heme iron + zinc + B12 from sirloin. Beta-carotene from sweet potato for immune support."
        ),

        BuiltInRecipe(
            id: 3,
            name: "Salmon Bowl",
            prepTime: "20 min",
            macros: RecipeMacros(calories: 700, protein: 45, carbs: 55, fat: 30),
            ingredients: [
                "5 oz wild-caught salmon fillet",
                "¾ cup jasmine rice (dry weight ~⅓ cup)",
                "½ avocado, sliced",
                "1 cup baby spinach",
                "1 tsp sesame oil",
                "1 tbsp low-sodium soy sauce",
                "Sesame seeds, green onion (optional garnish)",
            ],
            steps: [
                "Cook rice per package directions.",
                "Season salmon with salt, pepper, and a splash of soy sauce.",
                "Pan-sear salmon skin-side up in a skillet 3–4 min, flip, cook 2–3 min until flakes easily.",
                "Assemble bowl: rice base, spinach, avocado slices, flaked salmon.",
                "Drizzle sesame oil and remaining soy sauce. Top with sesame seeds and green onion.",
            ],
            tags: [.trainingDay, .highProtein, .fall, .anySeason, .under30, .eliteProtein, .omega3Rich],
            fiber: 6,
            omega3: 1.5,
            whyElite: "1.5g EPA+DHA per serving. Combines anti-inflammatory omega-3s with complete protein and monounsaturated fat."
        ),

        BuiltInRecipe(
            id: 4,
            name: "Pre-Workout Oats",
            prepTime: "5 min",
            macros: RecipeMacros(calories: 450, protein: 25, carbs: 65, fat: 8),
            ingredients: [
                "½ cup rolled oats",
                "1 banana, sliced",
                "1 scoop whey protein (vanilla or unflavored)",
                "¼ tsp cinnamon",
                "1 tsp honey",
                "¾ cup water or unsweetened almond milk",
            ],
            steps: [
                "Combine oats and liquid in a bowl; microwave 2 min, stir halfway.",
                "Let cool slightly (1–2 min) — mix in whey after cooling to preserve protein integrity.",
                "Top with banana slices, cinnamon, and honey.",
                "Consume 60–90 min before training.",
            ],
            tags: [.preWO, .balanced, .anySeason, .under5],
            fiber: 7,
            omega3: 0,
            whyElite: "Optimised carb timing for pre-WO glycogen loading with 25g fast protein."
        ),

        BuiltInRecipe(
            id: 5,
            name: "Pre-Bed Casein Pudding",
            prepTime: "3 min",
            macros: RecipeMacros(calories: 350, protein: 35, carbs: 15, fat: 15),
            ingredients: [
                "1.5 scoops micellar casein protein (chocolate or vanilla)",
                "1 tbsp almond butter",
                "8 oz unsweetened almond milk",
                "Handful of ice cubes",
                "Optional: ¼ tsp cinnamon or cocoa powder",
            ],
            steps: [
                "Add all ingredients to a blender.",
                "Blend 30–60 seconds until smooth and thick.",
                "Pour into a glass or bowl — consistency should be pudding-like (add less liquid for thicker).",
                "Consume 60–90 min before bed for overnight muscle protein synthesis.",
            ],
            tags: [.preBed, .highProtein, .anySeason, .under5, .eliteProtein],
            fiber: 4,
            omega3: 0,
            whyElite: "Micellar casein digests over 5–7 h, sustaining leucine above MPS threshold through sleep."
        ),

        // MARK: - 7 New Elite Recipes (Wave 3)

        BuiltInRecipe(
            id: 6,
            name: "Salmon + Lentil + Beet Bowl",
            prepTime: "25 min",
            macros: RecipeMacros(calories: 780, protein: 45, carbs: 60, fat: 26),
            ingredients: [
                "5 oz wild-caught salmon fillet",
                "½ cup green or brown lentils (dry), rinsed",
                "1 medium roasted beet, sliced",
                "1 cup arugula",
                "2 tbsp walnuts, roughly chopped",
                "1 tbsp extra-virgin olive oil",
                "1 tsp lemon juice",
                "Salt, pepper, cumin to taste",
            ],
            steps: [
                "Simmer lentils in salted water 18–20 min until tender; drain and season with cumin, salt, and a splash of EVOO.",
                "Season salmon with salt, pepper, and lemon juice. Pan-sear 3–4 min per side.",
                "Arrange arugula and lentils in a bowl. Top with flaked salmon and beet slices.",
                "Scatter walnuts and drizzle remaining EVOO and lemon juice.",
                "Season to taste. Serve warm or at room temperature.",
            ],
            tags: [.trainingDay, .highProtein, .fall, .winter, .under30, .eliteProtein, .highFiber, .omega3Rich, .polyphenolRich],
            fiber: 14,
            omega3: 2.5,
            polyphenolNote: "Beets: nitrate + betalains; walnuts: ellagitannins; EVOO: oleocanthal",
            whyElite: "Top-decile omega-3 + dietary nitrate for performance + polyphenols for recovery."
        ),

        BuiltInRecipe(
            id: 7,
            name: "Pasture Egg + Black Bean Breakfast Skillet",
            prepTime: "12 min",
            macros: RecipeMacros(calories: 620, protein: 38, carbs: 52, fat: 24),
            ingredients: [
                "3 pasture-raised eggs",
                "½ cup canned black beans, rinsed",
                "½ cup cherry tomatoes, halved",
                "¼ cup white onion, diced",
                "1 cup baby spinach",
                "1 tbsp extra-virgin olive oil",
                "½ tsp smoked paprika",
                "Salt, pepper, hot sauce to taste",
                "Optional: 1 oz feta or cotija cheese",
            ],
            steps: [
                "Heat olive oil in a non-stick skillet over medium heat. Sauté onion 3–4 min until soft.",
                "Add black beans, tomatoes, and paprika. Cook 2 min, stirring occasionally.",
                "Push mixture to edges of pan; crack eggs into the centre.",
                "Cover and cook eggs to preference (soft-set 3 min, firm 5 min).",
                "Add spinach in the last minute, letting it wilt around the edges.",
                "Season and top with hot sauce and optional cheese.",
            ],
            tags: [.trainingDay, .balanced, .anySeason, .under15, .eliteProtein, .highFiber],
            fiber: 12,
            omega3: 0.4,
            // Choline note: pasture eggs deliver ~150mg choline each; 3 eggs = ~450mg
            polyphenolNote: "Tomatoes: lycopene; spinach: lutein + zeaxanthin",
            whyElite: "~450 mg choline (most adults deficient), folate, lutein from eggs + resistant starch from black beans."
        ),

        BuiltInRecipe(
            id: 8,
            name: "Greek Yogurt + Berry + Chia Parfait",
            prepTime: "5 min",
            macros: RecipeMacros(calories: 520, protein: 35, carbs: 55, fat: 14),
            ingredients: [
                "1.5 cups non-fat plain Greek yogurt",
                "1 cup mixed berries (blueberry, raspberry, blackberry)",
                "2 tbsp chia seeds",
                "1 tbsp cacao nibs",
                "1 tbsp honey or pure maple syrup",
                "¼ cup granola (low sugar) for crunch",
            ],
            steps: [
                "Layer half the Greek yogurt in a wide bowl or jar.",
                "Add a layer of mixed berries and half the chia seeds.",
                "Repeat with remaining yogurt, berries, and chia.",
                "Top with cacao nibs, granola, and a drizzle of honey.",
                "Eat immediately for crunch, or refrigerate 30 min for a thicker chia-set texture.",
            ],
            tags: [.postWO, .highProtein, .anySeason, .under5, .eliteProtein, .highFiber, .polyphenolRich],
            fiber: 15,
            omega3: 2.2, // ALA from chia (conversion to EPA/DHA is low; noted in rationale)
            polyphenolNote: "Berries: anthocyanins; cacao nibs: flavanols",
            whyElite: "Fast + slow casein blend post-lift. Anthocyanins accelerate recovery; prebiotic chia gum feeds gut microbiome."
        ),

        BuiltInRecipe(
            id: 9,
            name: "Sardine + White Bean Toast",
            prepTime: "8 min",
            macros: RecipeMacros(calories: 580, protein: 38, carbs: 48, fat: 20),
            ingredients: [
                "1 tin sardines in olive oil (3.75 oz), drained",
                "½ cup canned white beans (cannellini), rinsed",
                "2 slices sourdough bread, toasted",
                "1 tbsp extra-virgin olive oil",
                "1 tsp Dijon mustard",
                "1 tbsp fresh lemon juice",
                "Fresh parsley, red pepper flakes to taste",
                "Optional: 1 soft-boiled egg",
            ],
            steps: [
                "Mash white beans with a fork, season with salt, pepper, and half the lemon juice.",
                "Spread bean mash over toasted sourdough.",
                "Top with sardines. Drizzle EVOO, remaining lemon juice, and Dijon.",
                "Finish with parsley, red pepper flakes, and optional sliced soft-boiled egg.",
            ],
            tags: [.balanced, .anySeason, .under15, .eliteProtein, .highFiber, .omega3Rich],
            fiber: 12,
            omega3: 1.5,
            polyphenolNote: "EVOO: oleocanthal; parsley: apigenin",
            whyElite: "Peter Attia's top-3 longevity food. Calcium (bones), B12, K2, and full omega-3 spectrum in a quick format."
        ),

        BuiltInRecipe(
            id: 10,
            name: "Bison + Sweet Potato + Kimchi Bowl",
            prepTime: "25 min",
            macros: RecipeMacros(calories: 760, protein: 45, carbs: 65, fat: 22),
            ingredients: [
                "5 oz ground bison (or lean ground beef)",
                "1 large sweet potato, cubed",
                "½ cup kimchi",
                "1 cup broccolini, roughly chopped",
                "1 tbsp coconut oil",
                "1 tbsp low-sodium soy sauce or tamari",
                "1 tsp ginger, grated",
                "1 clove garlic, minced",
                "Sesame seeds to garnish",
            ],
            steps: [
                "Toss sweet potato cubes with ½ tbsp coconut oil; roast at 425°F for 20 min until caramelised.",
                "Meanwhile, sauté broccolini in remaining oil over medium-high heat 4–5 min.",
                "Add bison, garlic, and ginger to the pan. Cook until no longer pink, breaking into crumbles.",
                "Deglaze with soy sauce. Toss to combine with broccolini.",
                "Build bowl: sweet potato base, bison and broccolini, kimchi on the side.",
                "Garnish with sesame seeds. Serve warm — kimchi goes on cold to preserve probiotics.",
            ],
            tags: [.trainingDay, .highProtein, .winter, .summer, .under30, .eliteProtein, .highFiber, .polyphenolRich],
            fiber: 11,
            omega3: 0,
            polyphenolNote: "Broccolini: sulforaphane precursors (glucoraphanin); kimchi: fermented probiotics; ginger: gingerols",
            whyElite: "Heme iron + zinc from bison + beta-carotene + live probiotics from kimchi — a gut–muscle axis meal."
        ),

        BuiltInRecipe(
            id: 11,
            name: "Tofu + Edamame + Soba Bowl",
            prepTime: "22 min",
            macros: RecipeMacros(calories: 690, protein: 42, carbs: 70, fat: 18),
            ingredients: [
                "8 oz extra-firm tofu, pressed and cubed",
                "1 cup shelled edamame (frozen, thawed)",
                "3 oz dry soba noodles (100% buckwheat)",
                "1 cup shredded red cabbage",
                "1 tbsp sesame oil",
                "2 tbsp low-sodium tamari",
                "1 tbsp rice vinegar",
                "1 tsp sesame seeds",
                "Green onion, chili flakes to garnish",
            ],
            steps: [
                "Press tofu 10 min between paper towels; cube and pan-fry in sesame oil over medium-high heat until golden, ~5 min per side.",
                "Cook soba noodles 5 min in boiling water; drain and rinse under cold water to prevent sticking.",
                "Whisk tamari, rice vinegar, and a drizzle of sesame oil into a dressing.",
                "Toss noodles and edamame with half the dressing.",
                "Build bowl: noodles, tofu, cabbage, edamame.",
                "Drizzle remaining dressing, top with sesame seeds, green onion, and chili flakes.",
            ],
            tags: [.trainingDay, .highProtein, .anySeason, .under30, .eliteProtein, .highFiber],
            fiber: 14,
            omega3: 0,
            polyphenolNote: "Soy isoflavones (tofu + edamame); rutin + quercetin (buckwheat soba); anthocyanins (red cabbage)",
            whyElite: "Plant-complete protein via soy + buckwheat amino acid pairing. Magnesium-rich buckwheat supports recovery."
        ),

        BuiltInRecipe(
            id: 12,
            name: "Chicken Thigh + Quinoa + Roasted Brassica Plate",
            prepTime: "28 min",
            macros: RecipeMacros(calories: 790, protein: 45, carbs: 68, fat: 28),
            ingredients: [
                "5 oz boneless skinless chicken thigh",
                "½ cup quinoa (dry), rinsed",
                "1 cup Brussels sprouts, halved",
                "½ pomegranate, arils removed (~¼ cup arils)",
                "1 tbsp extra-virgin olive oil",
                "1 tsp smoked paprika",
                "Salt, pepper, garlic powder",
                "Fresh parsley or mint to garnish",
            ],
            steps: [
                "Preheat oven to 425°F. Toss Brussels sprouts with EVOO, salt, and pepper. Roast 18–20 min until charred at edges.",
                "Season chicken thighs with smoked paprika, garlic powder, salt, and pepper.",
                "Sear chicken thighs in an oven-safe skillet over medium-high heat 3 min per side; finish in oven 10 min to 165°F internal.",
                "Cook quinoa per package directions (2:1 water ratio, 15 min simmer).",
                "Plate quinoa, sliced chicken, and Brussels sprouts. Scatter pomegranate arils and fresh herbs.",
                "Drizzle any pan juices over the plate.",
            ],
            tags: [.trainingDay, .highProtein, .fall, .winter, .under30, .eliteProtein, .highFiber, .polyphenolRich],
            fiber: 12,
            omega3: 0,
            polyphenolNote: "Brussels sprouts: glucosinolates + sulforaphane; pomegranate: urolithin precursors (ellagitannins); EVOO: oleocanthal",
            whyElite: "Pomegranate ellagitannins convert to urolithin A (mitophagy support). Sulforaphane activates Nrf2 detox enzymes."
        ),
    ]
}
