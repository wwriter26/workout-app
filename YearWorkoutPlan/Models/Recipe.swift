import Foundation

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
    let prepTime: String    // e.g. "5 min"
    let macros: RecipeMacros
    let ingredients: [String]
    let steps: [String]
}

// MARK: - User Recipe (Codable, persisted via AppState)
struct UserRecipe: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var prepTime: String
    var macros: RecipeMacros
    var ingredients: [String]   // one item per line
    var steps: [String]         // one step per item
}

// MARK: - Built-in Recipe Catalogue
enum BuiltInRecipes {
    static let all: [BuiltInRecipe] = [
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
            ]
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
            ]
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
            ]
        ),
        BuiltInRecipe(
            id: 3,
            name: "Salmon Bowl",
            prepTime: "20 min",
            macros: RecipeMacros(calories: 700, protein: 45, carbs: 55, fat: 30),
            ingredients: [
                "5 oz salmon fillet",
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
            ]
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
                "Let cool slightly (1–2 min) — mix in whey after cooling to preserve protein.",
                "Top with banana slices, cinnamon, and honey.",
                "Consume 60–90 min before training.",
            ]
        ),
        BuiltInRecipe(
            id: 5,
            name: "Pre-Bed Casein Pudding",
            prepTime: "3 min",
            macros: RecipeMacros(calories: 350, protein: 35, carbs: 15, fat: 15),
            ingredients: [
                "1.5 scoops casein protein (chocolate or vanilla)",
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
            ]
        ),
    ]
}
