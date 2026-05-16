import SwiftUI

// MARK: - Mobility Section View
/// Displayed inside the "mobility" sub-tab of PlanView.
struct MobilitySectionView: View {
    @Environment(AppState.self) private var state
    @State private var expandedCategory: Int? = nil

    var body: some View {
        VStack(spacing: 10) {
            dailyCheckOffCard
            limitingJointTrackCard
            dailyRoutineCard
            preActivationCard
            cooldownCard
            librarySection
        }
    }

    // MARK: - Daily Check-Off
    private var dailyCheckOffCard: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    SectionLabel(text: "Today's Mobility")
                    Text(state.isMobilityCompletedToday ? "Completed" : "Not yet done")
                        .font(.appSubhead)
                        .foregroundColor(
                            state.isMobilityCompletedToday ? AppColor.spring : AppColor.textDimmed
                        )
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        state.toggleMobility(for: Date())
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(state.isMobilityCompletedToday
                                  ? state.season.color.opacity(0.2)
                                  : AppColor.cardBackground2)
                            .frame(width: 44, height: 44)
                        Image(systemName: state.isMobilityCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(state.isMobilityCompletedToday
                                             ? state.season.color
                                             : AppColor.textFaint)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(state.isMobilityCompletedToday
                                    ? "Mark mobility incomplete"
                                    : "Mark mobility complete")
            }
        }
    }

    // MARK: - Limiting Joint Track Card

    private var limitingJointTrackCard: some View {
        NavigationLink(destination: LimitingJointTrackView().environment(state)) {
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(text: "Limiting Joint Track")
                        if let activeID = state.activeLimitingJointTrackID,
                           let track = MobilityCatalog.limitingJointTracks.first(where: { $0.id == activeID }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(state.season.color)
                                Text(track.name)
                                    .font(.appBody)
                                    .foregroundColor(state.season.color)
                            }
                        } else {
                            Text("No track selected — tap to choose")
                                .font(.appBody)
                                .foregroundColor(AppColor.textDimmed)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColor.textFaint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily 10-Minute Routine
    private var dailyRoutineCard: some View {
        CardView {
            SectionLabel(text: "Daily 10-Min Routine")
            Text("Do every day — morning or evening")
                .font(.appSmall)
                .foregroundColor(AppColor.textDimmed)
                .padding(.bottom, 8)

            ForEach(Array(MobilityCatalog.dailyRoutine.enumerated()), id: \.offset) { idx, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(state.season.color)
                        .frame(width: 20, alignment: .leading)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(.appSubhead)
                                .foregroundColor(AppColor.textSecondary)
                            Text(item.durationOrReps)
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textDimmed)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColor.cardBackground2)
                                .cornerRadius(4)
                        }
                        Text(item.cue)
                            .font(.appSmall)
                            .foregroundColor(AppColor.textFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 6)
                if idx < MobilityCatalog.dailyRoutine.count - 1 {
                    Divider().background(AppColor.border1)
                }
            }
        }
    }

    // MARK: - Pre-Lift Activation
    private var preActivationCard: some View {
        CardView {
            SectionLabel(text: "Pre-Lift Activation (5 min)")
            Text("Do before every training session")
                .font(.appSmall)
                .foregroundColor(AppColor.textDimmed)
                .padding(.bottom, 8)

            ForEach(MobilityCatalog.preActivation) { item in
                HStack {
                    Text(item.name)
                        .font(.appSubhead)
                        .foregroundColor(AppColor.textSecondary)
                    Spacer()
                    Text("\(item.sets)×\(item.reps)")
                        .font(.monoSmall)
                        .foregroundColor(AppColor.textMuted)
                }
                .padding(.vertical, 8)
                Divider().background(AppColor.border1)
            }
        }
    }

    // MARK: - Post-Lift Cooldown
    private var cooldownCard: some View {
        CardView {
            SectionLabel(text: "Post-Lift Cooldown (5 min)")
            ForEach(Array(MobilityCatalog.cooldownSteps.enumerated()), id: \.offset) { _, step in
                Text("· \(step)")
                    .font(.appBody)
                    .foregroundColor(AppColor.textMuted)
                    .padding(.vertical, 5)
            }
        }
    }

    // MARK: - Mobility Library
    private var librarySection: some View {
        VStack(spacing: 8) {
            SectionLabel(text: "Mobility Library")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            ForEach(MobilityCatalog.categories) { category in
                MobilityCategoryCard(
                    category: category,
                    isExpanded: expandedCategory == category.id,
                    seasonColor: state.season.color,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedCategory = expandedCategory == category.id ? nil : category.id
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Mobility Category Card
private struct MobilityCategoryCard: View {
    let category: MobilityCategory
    let isExpanded: Bool
    let seasonColor: Color
    let onTap: () -> Void

    var body: some View {
        CardView {
            Button(action: onTap) {
                HStack {
                    Text(category.name)
                        .font(.appSubhead)
                        .foregroundColor(AppColor.textPrimary)
                    Spacer()
                    Text("\(category.items.count) exercises")
                        .font(.monoTiny)
                        .foregroundColor(AppColor.textFaint)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColor.textFaint)
                        .padding(.leading, 4)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .background(AppColor.border1)
                    .padding(.top, 8)

                ForEach(Array(category.items.enumerated()), id: \.offset) { idx, item in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(.appSubhead)
                                .foregroundColor(AppColor.textSecondary)
                            Spacer()
                            Text(item.durationOrReps)
                                .font(.monoTiny)
                                .foregroundColor(seasonColor)
                        }
                        Text(item.cue)
                            .font(.appSmall)
                            .foregroundColor(AppColor.textFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                    if idx < category.items.count - 1 {
                        Divider().background(AppColor.border1)
                    }
                }
            }
        }
    }
}
