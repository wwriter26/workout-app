import SwiftUI

// MARK: - Recipe List View
/// Displayed inside the "recipes" sub-tab of PlanView.
struct RecipeListView: View {
    @Environment(AppState.self) private var state
    @State private var showAddRecipe = false
    @State private var expandedBuiltIn: Int? = nil
    @State private var expandedUserRecipe: UUID? = nil

    var body: some View {
        VStack(spacing: 10) {
            // Add custom recipe button
            HStack {
                Spacer()
                Button {
                    showAddRecipe = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("ADD RECIPE")
                            .font(.system(size: 11, weight: .bold, design: .default))
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
            .padding(.bottom, 2)

            // Built-in recipes
            SectionLabel(text: "Built-In Recipes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            ForEach(BuiltInRecipes.all) { recipe in
                RecipeCard(
                    name: recipe.name,
                    prepTime: recipe.prepTime,
                    macros: recipe.macros,
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
            if !state.userRecipes.isEmpty {
                SectionLabel(text: "My Recipes")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                ForEach(state.userRecipes) { recipe in
                    RecipeCard(
                        name: recipe.name,
                        prepTime: recipe.prepTime,
                        macros: recipe.macros,
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
        }
        .sheet(isPresented: $showAddRecipe) {
            AddRecipeView(seasonColor: state.season.color) { newRecipe in
                state.userRecipes.append(newRecipe)
            }
        }
    }
}

// MARK: - Recipe Card
private struct RecipeCard: View {
    let name: String
    let prepTime: String
    let macros: RecipeMacros
    let ingredients: [String]
    let steps: [String]
    let isExpanded: Bool
    let seasonColor: Color
    let onTap: () -> Void

    var body: some View {
        CardView {
            // Header row (always visible)
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

            // Macro tiles (always visible)
            HStack(spacing: 8) {
                MacroTile(value: macros.protein, unit: "P", color: seasonColor)
                MacroTile(value: macros.carbs,   unit: "C", color: AppColor.summer)
                MacroTile(value: macros.fat,     unit: "F", color: AppColor.fall)
            }
            .padding(.top, 8)

            // Expanded detail
            if isExpanded {
                Divider()
                    .background(AppColor.border1)
                    .padding(.vertical, 8)

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
    @State private var ingredients = ""   // one per line
    @State private var steps = ""         // one per line

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
            // Placeholder text via overlay when empty
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
        let ingredientList = ingredients.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let stepList = steps.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        let recipe = UserRecipe(
            name: name.trimmingCharacters(in: .whitespaces),
            prepTime: prepTime.isEmpty ? "—" : prepTime,
            macros: macros,
            ingredients: ingredientList,
            steps: stepList
        )
        onSave(recipe)
        dismiss()
    }
}
