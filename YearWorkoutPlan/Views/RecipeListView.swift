import SwiftUI

// MARK: - Filter Chip Model
/// The filter chips shown at the top of RecipeListView.
/// Each chip maps to one or more RecipeTags for OR-logic matching.
private struct FilterChip: Identifiable, Equatable {
    let id: String
    let label: String
    let tags: [RecipeTag]

    static let all: [FilterChip] = [
        FilterChip(id: "all",      label: "All",         tags: []),
        FilterChip(id: "training", label: "Training",     tags: [.trainingDay]),
        FilterChip(id: "rest",     label: "Rest Day",     tags: [.restDay]),
        FilterChip(id: "prewo",    label: "Pre-WO",       tags: [.preWO]),
        FilterChip(id: "postwo",   label: "Post-WO",      tags: [.postWO]),
        FilterChip(id: "prebed",   label: "Pre-Bed",      tags: [.preBed]),
        FilterChip(id: "hiproto",  label: "High Protein", tags: [.highProtein, .eliteProtein]),
        FilterChip(id: "fiber",    label: "High Fiber",   tags: [.highFiber]),
        FilterChip(id: "omega3",   label: "Omega-3",      tags: [.omega3Rich]),
        FilterChip(id: "quick",    label: "Quick (<15m)", tags: [.under5, .under15]),
    ]
}

// MARK: - Recipe List View
/// Displayed inside the "recipes" sub-tab of PlanView.
/// Supports multi-select OR-logic tag filtering and shows elite nutritional badges.
struct RecipeListView: View {
    @Environment(AppState.self) private var state
    @State private var showAddRecipe = false
    @State private var expandedBuiltIn: Int? = nil
    @State private var expandedUserRecipe: UUID? = nil
    /// Multi-select: empty means "All". OR logic — a recipe matches if it shares
    /// any tag with any active chip.
    @State private var activeFilters: Set<String> = []

    // MARK: Filtering + Sorting

    private var filteredBuiltIn: [BuiltInRecipe] {
        let chips = activeTags
        let base = chips.isEmpty
            ? BuiltInRecipes.all
            : BuiltInRecipes.all.filter { recipe in
                chips.contains { tag in recipe.tags.contains(tag) }
            }
        return sortedBuiltIn(base)
    }

    private var filteredUserRecipes: [UserRecipe] {
        let chips = activeTags
        guard !chips.isEmpty else { return state.userRecipes }
        return state.userRecipes.filter { recipe in
            chips.contains { tag in recipe.tags.contains(tag) }
        }
    }

    /// Collapsed set of active RecipeTags from selected filter chips.
    private var activeTags: [RecipeTag] {
        FilterChip.all
            .filter { activeFilters.contains($0.id) }
            .flatMap(\.tags)
    }

    /// Sort: anySeason first, then current-season tagged, then the rest.
    private func sortedBuiltIn(_ recipes: [BuiltInRecipe]) -> [BuiltInRecipe] {
        let currentSeasonTag = currentSeasonTag()
        return recipes.sorted { a, b in
            let aAny = a.tags.contains(.anySeason)
            let bAny = b.tags.contains(.anySeason)
            let aSeason = a.tags.contains(currentSeasonTag)
            let bSeason = b.tags.contains(currentSeasonTag)
            if aAny != bAny { return aAny }
            if aSeason != bSeason { return aSeason }
            return a.id < b.id
        }
    }

    private func currentSeasonTag() -> RecipeTag {
        switch state.season.name {
        case "Spring": return .spring
        case "Summer": return .summer
        case "Fall":   return .fall
        default:       return .winter
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 10) {
            filterChipBar
            addRecipeButton

            // Built-in recipes
            SectionLabel(text: "Built-In Recipes (\(filteredBuiltIn.count))")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            ForEach(filteredBuiltIn) { recipe in
                EnhancedRecipeCard(
                    name: recipe.name,
                    prepTime: recipe.prepTime,
                    macros: recipe.macros,
                    tags: recipe.tags,
                    fiber: recipe.fiber,
                    omega3: recipe.omega3,
                    polyphenolNote: recipe.polyphenolNote,
                    whyElite: recipe.whyElite,
                    ingredients: recipe.ingredients,
                    steps: recipe.steps,
                    isExpanded: expandedBuiltIn == recipe.id,
                    seasonColor: state.season.color,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedBuiltIn = expandedBuiltIn == recipe.id ? nil : recipe.id
                        }
                    }
                )
            }

            // User recipes
            if !filteredUserRecipes.isEmpty {
                SectionLabel(text: "My Recipes (\(filteredUserRecipes.count))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                ForEach(filteredUserRecipes) { recipe in
                    EnhancedRecipeCard(
                        name: recipe.name,
                        prepTime: recipe.prepTime,
                        macros: recipe.macros,
                        tags: recipe.tags,
                        fiber: recipe.fiber,
                        omega3: recipe.omega3,
                        polyphenolNote: recipe.polyphenolNote,
                        whyElite: recipe.whyElite,
                        ingredients: recipe.ingredients,
                        steps: recipe.steps,
                        isExpanded: expandedUserRecipe == recipe.id,
                        seasonColor: state.season.color,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedUserRecipe = expandedUserRecipe == recipe.id ? nil : recipe.id
                            }
                        }
                    )
                }
            }

            if filteredBuiltIn.isEmpty && filteredUserRecipes.isEmpty {
                Text("No recipes match the selected filters.")
                    .font(.appBody)
                    .foregroundColor(AppColor.textFaint)
                    .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showAddRecipe) {
            AddRecipeView(seasonColor: state.season.color) { newRecipe in
                state.userRecipes.append(newRecipe)
            }
        }
    }

    // MARK: Subviews

    private var addRecipeButton: some View {
        HStack {
            Spacer()
            Button {
                showAddRecipe = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("ADD RECIPE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundColor(state.season.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(state.season.color.opacity(0.13))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(state.season.color.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var filterChipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FilterChip.all) { chip in
                    let isActive = chip.id == "all"
                        ? activeFilters.isEmpty
                        : activeFilters.contains(chip.id)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if chip.id == "all" {
                                activeFilters = []
                            } else {
                                if activeFilters.contains(chip.id) {
                                    activeFilters.remove(chip.id)
                                } else {
                                    activeFilters.insert(chip.id)
                                }
                            }
                        }
                    } label: {
                        Text(chip.label)
                            .font(.monoTiny)
                            .foregroundColor(isActive ? state.season.color : AppColor.textDimmed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isActive ? state.season.color.opacity(0.13) : AppColor.cardBackground)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isActive ? state.season.color.opacity(0.5) : AppColor.border2, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Enhanced Recipe Card
/// Extends the Wave 1 RecipeCard with tag chips, fiber/omega-3 badges,
/// and a "Why this is elite" rationale line.
private struct EnhancedRecipeCard: View {
    let name: String
    let prepTime: String
    let macros: RecipeMacros
    let tags: [RecipeTag]
    let fiber: Int
    let omega3: Double
    let polyphenolNote: String?
    let whyElite: String
    let ingredients: [String]
    let steps: [String]
    let isExpanded: Bool
    let seasonColor: Color
    let onTap: () -> Void

    // Show at most 3 tag chips inline; overflow shown as "+N"
    private var visibleTags: [RecipeTag] { Array(tags.prefix(3)) }
    private var hiddenTagCount: Int { max(0, tags.count - 3) }

    var body: some View {
        CardView {
            // --- Header (always visible) ---
            Button(action: onTap) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textPrimary)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 8) {
                            Label(prepTime, systemImage: "clock")
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textDimmed)
                            Text("·")
                                .foregroundColor(AppColor.textFaint)
                            Text("\(macros.calories) kcal")
                                .font(.monoTiny)
                                .foregroundColor(seasonColor)
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.textFaint)
                }
            }
            .buttonStyle(.plain)

            // --- Macro tiles (always visible) ---
            HStack(spacing: 8) {
                MacroTile(value: macros.protein, unit: "P", color: seasonColor)
                MacroTile(value: macros.carbs,   unit: "C", color: AppColor.summer)
                MacroTile(value: macros.fat,     unit: "F", color: AppColor.fall)
            }
            .padding(.top, 8)

            // --- Elite nutritional badges ---
            eliteBadgeRow

            // --- Tag chips (up to 3 + overflow count) ---
            if !tags.isEmpty {
                tagChipRow
            }

            // --- "Why this is elite" rationale ---
            if !whyElite.isEmpty {
                Text(whyElite)
                    .font(.appSmall)
                    .italic()
                    .foregroundColor(AppColor.textDimmed)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            // --- Expanded detail ---
            if isExpanded {
                Divider()
                    .background(AppColor.border1)
                    .padding(.vertical, 8)

                // Polyphenol sources if present
                if let ppNote = polyphenolNote {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel(text: "Polyphenol sources")
                        Text(ppNote)
                            .font(.appSmall)
                            .foregroundColor(AppColor.deload)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 8)
                }

                SectionLabel(text: "Ingredients")
                    .padding(.bottom, 4)
                ForEach(Array(ingredients.enumerated()), id: \.offset) { _, ingredient in
                    Text("· \(ingredient)")
                        .font(.appBody)
                        .foregroundColor(AppColor.textMuted)
                        .padding(.vertical, 2)
                }

                SectionLabel(text: "Instructions")
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(idx + 1).")
                            .font(.monoSmall)
                            .foregroundColor(seasonColor)
                            .frame(width: 20, alignment: .leading)
                        Text(step)
                            .font(.appBody)
                            .foregroundColor(AppColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    // MARK: Private subviews

    @ViewBuilder
    private var eliteBadgeRow: some View {
        let showFiber  = fiber >= 10
        let showOmega3 = omega3 >= 1.0
        let showPoly   = polyphenolNote != nil

        if showFiber || showOmega3 || showPoly {
            HStack(spacing: 6) {
                if showFiber {
                    EliteBadge(icon: "leaf.fill",   label: "\(fiber)g fiber", color: AppColor.springAccent)
                }
                if showOmega3 {
                    EliteBadge(icon: "drop.fill",   label: String(format: "%.1fg EPA+DHA", omega3), color: AppColor.winterAccent)
                }
                if showPoly {
                    EliteBadge(icon: "star.fill",   label: "Polyphenols", color: AppColor.deload)
                }
                Spacer()
            }
            .padding(.top, 6)
        }
    }

    private var tagChipRow: some View {
        HStack(spacing: 4) {
            ForEach(visibleTags) { tag in
                TagChip(tag: tag)
            }
            if hiddenTagCount > 0 {
                Text("+\(hiddenTagCount)")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textFaint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppColor.cardBackground2)
                    .cornerRadius(4)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Tag Chip
private struct TagChip: View {
    let tag: RecipeTag

    var body: some View {
        Text(tag.displayName)
            .font(.monoTiny)
            .foregroundColor(tag.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(tag.color.opacity(0.12))
            .cornerRadius(4)
    }
}

// MARK: - Elite Badge
private struct EliteBadge: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.monoTiny)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.10))
        .cornerRadius(4)
    }
}

// MARK: - Macro Tile
private struct MacroTile: View {
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)g")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(AppColor.textPrimary)
            Text(unit)
                .font(.monoTiny)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .cornerRadius(6)
    }
}

// MARK: - Add Recipe View
struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    let seasonColor: Color
    let onSave: (UserRecipe) -> Void

    @State private var name = ""
    @State private var prepTime = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var ingredients = ""
    @State private var steps = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        fieldGroup("Recipe Name") {
                            inputField("e.g. Post-Workout Rice Bowl", text: $name)
                        }
                        fieldGroup("Prep Time") {
                            inputField("e.g. 15 min", text: $prepTime)
                        }
                        fieldGroup("Macros") {
                            HStack(spacing: 8) {
                                inputField("Cals",    text: $calories).frame(maxWidth: .infinity)
                                inputField("Protein", text: $protein).frame(maxWidth: .infinity)
                                inputField("Carbs",   text: $carbs).frame(maxWidth: .infinity)
                                inputField("Fat",     text: $fat).frame(maxWidth: .infinity)
                            }
                        }
                        fieldGroup("Ingredients (one per line)") {
                            multilineInput("Chicken breast\nWhite rice\n...", text: $ingredients)
                        }
                        fieldGroup("Steps (one per line)") {
                            multilineInput("Cook rice.\nSeason chicken.\n...", text: $steps)
                        }

                        PrimaryButton(title: "SAVE RECIPE", color: seasonColor) {
                            saveRecipe()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1 : 0.4)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(seasonColor)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func fieldGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: title)
            content()
        }
    }

    private func inputField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.appBody)
            .foregroundColor(AppColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColor.cardBackground)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.border2, lineWidth: 1))
    }

    private func multilineInput(_ placeholder: String, text: Binding<String>) -> some View {
        TextEditor(text: text)
            .font(.appBody)
            .foregroundColor(AppColor.textPrimary)
            .frame(minHeight: 100)
            .padding(8)
            .background(AppColor.cardBackground)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.border2, lineWidth: 1))
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.appBody)
                        .foregroundColor(AppColor.textVeryFaint)
                        .padding(12)
                        .allowsHitTesting(false)
                }
            }
    }

    private func saveRecipe() {
        let macros = RecipeMacros(
            calories: Int(calories) ?? 0,
            protein:  Int(protein)  ?? 0,
            carbs:    Int(carbs)    ?? 0,
            fat:      Int(fat)      ?? 0
        )
        let ingredientList = ingredients
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let stepList = steps
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let recipe = UserRecipe(
            name: name.trimmingCharacters(in: .whitespaces),
            prepTime: prepTime.isEmpty ? "—" : prepTime,
            macros: macros,
            ingredients: ingredientList,
            steps: stepList
            // Wave 3 fields default: tags=[], fiber=0, omega3=0, polyphenolNote=nil, whyElite=""
            // Tag editing for user recipes is a Wave 4 TODO.
        )
        onSave(recipe)
        dismiss()
    }
}
