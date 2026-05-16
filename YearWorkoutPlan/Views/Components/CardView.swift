import SwiftUI

// MARK: - Card Container
/// Standard dark card used everywhere in the app.
struct CardView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColor.border1, lineWidth: 1)
        )
    }
}

// MARK: - Badge
struct BadgeView: View {
    let text: String
    let foreground: Color
    let background: Color

    init(_ text: String, foreground: Color, background: Color) {
        self.text = text
        self.foreground = foreground
        self.background = background
    }

    var body: some View {
        Text(text)
            .font(.monoTiny)
            .fontWeight(.bold)
            .foregroundColor(foreground)
            .tracking(1.2)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(background)
            .cornerRadius(4)
    }
}

// MARK: - Section Label
struct SectionLabel: View {
    let text: String
    var color: Color = AppColor.textFaint

    var body: some View {
        Text(text)
            .font(.monoLabel)
            .foregroundColor(color)
            .tracking(1.5)
            .textCase(.uppercase)
    }
}

// MARK: - Icon Button (+ / -)
struct IconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundColor(AppColor.textMuted)
                .frame(width: 40, height: 40)
                .background(AppColor.cardBackground2)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColor.border2, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .default))
                .foregroundColor(.black)
                .tracking(1.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Outline Button
struct OutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundColor(AppColor.textMuted)
                .tracking(1.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColor.border2, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CNS Color Helper
func cnsColor(_ load: CNSLoad) -> Color {
    switch load {
    case .high:         return AppColor.cnsHigh
    case .moderateHigh: return AppColor.cnsModerateHigh
    case .moderate:     return AppColor.cnsModerate
    case .low:          return AppColor.cnsLow
    case .rest:         return AppColor.cnsRest
    }
}

// MARK: - Set Toggle Button
struct SetToggle: View {
    let index: Int
    let isDone: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(isDone ? "✓" : "\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isDone ? color : AppColor.textFaint)
                .frame(width: 36, height: 36)
                .background(isDone ? color.opacity(0.15) : AppColor.cardBackground2)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isDone ? color : AppColor.border2, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mono Input Field
struct MonoTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .decimalPad

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .font(.monoSmall)
            .foregroundColor(AppColor.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AppColor.cardBackground2)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColor.border2, lineWidth: 1)
            )
    }
}

// MARK: - Progress Bar
struct SeasonProgressBar: View {
    let percent: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.border2)
                    .frame(height: 4)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(percent, 1.0), height: 4)
                    .animation(.easeOut(duration: 0.3), value: percent)
            }
        }
        .frame(height: 4)
    }
}
