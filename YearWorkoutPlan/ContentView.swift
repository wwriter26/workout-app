import SwiftUI

// MARK: - Content View
// Root container: sticky header + scrollable body + custom tab bar.
// The AppState is now injected from YearWorkoutPlanApp so the singleton lives at
// the app level (not recreated on ContentView re-init).
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky top bar
                topBar

                // Screen content
                Group {
                    switch appState.selectedTab {
                    case .today:    TodayView()
                    case .schedule: ScheduleView()
                    case .log:      LogView()
                    case .stats:    StatsView()
                    case .plan:     PlanView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Tab bar height placeholder so content doesn't go underneath
                Color.clear.frame(height: 56 + (UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.safeAreaInsets.bottom ?? 0))
            }

            // Custom bottom tab bar overlaid at the bottom
            bottomTabBar

            // Rest timer overlay — global so it persists when switching tabs.
            // Sits above the tab bar (padding pushes it clear of the bar) but
            // below any sheets, which is the correct z-order for a floating HUD.
            RestTimerView(seasonColor: appState.season.color)
                .padding(.bottom, 64)  // clear the 56 pt tab bar + safe area gap
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(appState)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Logo
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                HStack(spacing: 0) {
                    Text("W-")
                        .font(.system(size: 18, weight: .heavy, design: .default))
                        .foregroundColor(AppColor.textPrimary)
                        .tracking(-0.5)
                    Text("FIT")
                        .font(.system(size: 18, weight: .heavy, design: .default))
                        .foregroundColor(appState.season.color)
                        .tracking(-0.5)
                }
                Text("v4")
                    .font(.monoTiny)
                    .foregroundColor(AppColor.textFaint)
                    .tracking(1.5)
            }

            Spacer()

            HStack(spacing: 12) {
                // Settings gear icon — added in Wave 2A
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppColor.textFaint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")

                // Season pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.season.color)
                        .frame(width: 8, height: 8)
                    Text(appState.season.name.uppercased())
                        .font(.monoLabel)
                        .foregroundColor(appState.season.color)
                        .tracking(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColor.appBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.cardBackground)
                .frame(height: 1)
        }
    }

    // MARK: - Bottom Tab Bar

    private var bottomTabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "#1A1A1A"))
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        appState.selectedTab = tab
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 18, weight: .regular))
                            Text(tab.label)
                                .font(.monoTiny)
                                .tracking(0.5)
                        }
                        .foregroundColor(appState.selectedTab == tab
                                         ? appState.season.color
                                         : AppColor.textFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: appState.selectedTab)
                }
            }
            .padding(.bottom, 4)
            .background(Color(hex: "#0D0D0D"))
        }
        .background(Color(hex: "#0D0D0D").ignoresSafeArea(edges: .bottom))
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
