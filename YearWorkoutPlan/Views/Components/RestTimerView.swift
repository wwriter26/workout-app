import SwiftUI

// MARK: - Rest Timer View
/// Bottom-anchored floating card displayed whenever RestTimer.shared.isRunning.
/// Injected as an overlay at the ContentView level so it floats above all tabs.
struct RestTimerView: View {
    // Access the shared singleton directly — no environment injection needed
    // because the timer is a global singleton, not per-view state.
    private var timer: RestTimer { RestTimer.shared }

    let seasonColor: Color

    var body: some View {
        // Only render when the timer is actively running
        if timer.isRunning {
            VStack(spacing: 10) {
                // Exercise name (optional — shown when timer was started with a name)
                if let name = timer.exerciseName {
                    Text(name.uppercased())
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                        .tracking(1.5)
                }

                // Big MM:SS countdown — monospaced so digits don't jump
                Text(formattedTime)
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundColor(countdownColor)
                    // withAnimation is applied to the color change as a value change
                    .animation(.easeInOut(duration: 0.3), value: timer.remainingSeconds)
                    .contentTransition(.numericText())

                // Controls row: -15s | SKIP | +15s
                HStack(spacing: 16) {
                    TimerControlButton(title: "−15s") {
                        RestTimer.shared.add(seconds: -15)
                    }
                    Button {
                        RestTimer.shared.skip()
                    } label: {
                        Text("SKIP")
                            .font(.system(size: 11, weight: .heavy, design: .default))
                            .foregroundColor(.black)
                            .tracking(1.5)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(AppColor.textMuted)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    TimerControlButton(title: "+15s") {
                        RestTimer.shared.add(seconds: +15)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColor.cardBackground)
                    .shadow(color: .black.opacity(0.5), radius: 16, y: -4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(countdownColor.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let m = timer.remainingSeconds / 60
        let s = timer.remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Color shifts from season color → red when ≤ 10 s to signal urgency.
    private var countdownColor: Color {
        timer.remainingSeconds <= 10 ? AppColor.fall : seasonColor
    }
}

// MARK: - Timer Control Button
/// Small muted button used for ±15s adjustments.
private struct TimerControlButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(AppColor.textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppColor.cardBackground2)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColor.border2, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
