import SwiftUI

// MARK: - Recovery Banner
/// Top-of-Today card showing the computed RecoveryScore from HealthKit/Whoop.
/// Three states: green/yellow/red. Includes a manual Whoop override hidden
/// in a DisclosureGroup to keep the primary UI clean.
struct RecoveryBanner: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var bindState = state

        CardView {
            VStack(alignment: .leading, spacing: 10) {
                mainBanner

                // Manual override — kept as a disclosure so it's not the primary action
                DisclosureGroup {
                    whoopManualOverride
                        .padding(.top, 6)
                } label: {
                    Text("Manual override")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                        .tracking(1)
                }
                .tint(AppColor.textFaint)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bandBackgroundColor.opacity(0.08))
        )
    }

    // MARK: - Main Banner Content

    @ViewBuilder
    private var mainBanner: some View {
        if state.latestSnapshot == nil && state.whoopToday == nil {
            // No data at all — prompt HealthKit connection
            noDataView
        } else {
            HStack(alignment: .top, spacing: 12) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(bandBackgroundColor.opacity(0.15))
                        .frame(width: 58, height: 58)
                    VStack(spacing: 1) {
                        Text("\(state.recoveryScore.percent)%")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(bandColor)
                        Text(bandLabel)
                            .font(.system(size: 8, weight: .heavy, design: .default))
                            .foregroundColor(bandColor)
                            .tracking(0.8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(bandLabel)
                        .font(.system(size: 15, weight: .heavy, design: .default))
                        .foregroundColor(bandColor)
                        .tracking(0.5)
                    Text(state.recoveryScore.guidance)
                        .font(.appSmall)
                        .foregroundColor(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(sourceLabel)
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                        .padding(.top, 2)

                    // Red band: show swap-to-Z2 shortcut button
                    if state.recoveryScore.band == .red {
                        Button {
                            state.whoopToday = .red
                        } label: {
                            Text("SWAP TO Z2")
                                .font(.system(size: 10, weight: .heavy, design: .default))
                                .foregroundColor(.black)
                                .tracking(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColor.fall)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - No Data View

    private var noDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Recovery", color: AppColor.textFaint)
            Text("Connect Apple Health to enable recovery scoring")
                .font(.appBody)
                .foregroundColor(AppColor.textDimmed)
            Button {
                Task {
                    try? await HealthKitManager.shared.requestAuthorization()
                    await state.refreshHealthData()
                }
            } label: {
                Text("CONNECT APPLE HEALTH")
                    .font(.system(size: 10, weight: .heavy, design: .default))
                    .foregroundColor(.black)
                    .tracking(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColor.infoBlue)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Whoop Manual Override

    private var whoopManualOverride: some View {
        @Bindable var bindState = state
        return VStack(alignment: .leading, spacing: 6) {
            Text("Set Whoop status manually:")
                .font(.monoTiny)
                .foregroundColor(AppColor.textFaint)
            HStack(spacing: 8) {
                ForEach(WhoopStatus.allCases, id: \.self) { status in
                    let isSelected = state.whoopToday == status
                    Button {
                        state.whoopToday = isSelected ? nil : status
                    } label: {
                        Text(status.label)
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .foregroundColor(isSelected ? status.color : AppColor.textDimmed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(isSelected ? status.color.opacity(0.13) : AppColor.cardBackground2)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? status.color : AppColor.border2, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
        }
    }

    // MARK: - Computed band values

    private var bandColor: Color {
        switch state.recoveryScore.band {
        case .green:  return AppColor.spring
        case .yellow: return AppColor.summer
        case .red:    return AppColor.fall
        }
    }

    private var bandBackgroundColor: Color { bandColor }

    private var bandLabel: String {
        switch state.recoveryScore.band {
        case .green:  return "READY"
        case .yellow: return "MODERATE"
        case .red:    return "RECOVER"
        }
    }

    private var sourceLabel: String {
        // If we have a HealthKit snapshot for today, say so
        let today = AppState.sharedDateString(from: Date())
        if state.healthSnapshots.last(where: { $0.date == today }) != nil {
            return "via Apple Health"
        }
        if state.whoopToday != nil { return "manual (Whoop)" }
        return "no source"
    }
}
