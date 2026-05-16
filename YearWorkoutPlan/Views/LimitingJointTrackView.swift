import SwiftUI

// MARK: - Limiting Joint Track View
/// Lets the user choose one of the three quarterly 12-week mobility focus tracks.
/// Displayed as a sub-section in MobilitySectionView (and linked from MobilitySectionView).
struct LimitingJointTrackView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ZStack {
            AppColor.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    headerCard
                    ForEach(MobilityCatalog.limitingJointTracks) { track in
                        TrackCard(
                            track: track,
                            isActive: state.activeLimitingJointTrackID == track.id,
                            seasonColor: state.season.color,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    state.activeLimitingJointTrackID = track.id
                                }
                            },
                            onDeselect: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    state.activeLimitingJointTrackID = nil
                                }
                            }
                        )
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Limiting Joint Track")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Choose One Track / Quarter")
                Text("Identify your weakest joint from the last movement screen. Run the matching track 2–3× per week as an add-on to your daily 10-min routine. Re-test at week 6 and week 12.")
                    .font(.appSmall)
                    .foregroundColor(AppColor.textDimmed)
                    .fixedSize(horizontal: false, vertical: true)

                if let activeID = state.activeLimitingJointTrackID,
                   let track = MobilityCatalog.limitingJointTracks.first(where: { $0.id == activeID }) {
                    Divider().background(AppColor.border1).padding(.vertical, 4)
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColor.spring)
                        Text("Active: \(track.name)")
                            .font(.appSubhead)
                            .foregroundColor(AppColor.spring)
                    }
                }
            }
        }
    }
}

// MARK: - Track Card
private struct TrackCard: View {
    let track: LimitingJointTrack
    let isActive: Bool
    let seasonColor: Color
    let onSelect: () -> Void
    let onDeselect: () -> Void

    @State private var isExpanded = false

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                // Header row: name, frequency badge, expand chevron
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(track.name)
                                .font(.appSubhead)
                                .foregroundColor(isActive ? seasonColor : AppColor.textPrimary)

                            // Frequency badge
                            Text("\(track.frequencyPerWeek)x/week")
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textDimmed)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColor.cardBackground2)
                                .cornerRadius(4)
                        }

                        Text("Target: \(track.targetTest)")
                            .font(.appSmall)
                            .foregroundColor(AppColor.textDimmed)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColor.textFaint)
                    }
                    .buttonStyle(.plain)
                }

                // Expanded: exercises + PNF note
                if isExpanded {
                    Divider().background(AppColor.border1).padding(.vertical, 4)

                    // PNF note
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PNF Protocol")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textFaint)
                            .tracking(0.5)
                        Text(track.pnfNote)
                            .font(.appSmall)
                            .foregroundColor(AppColor.deload)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 4)

                    // Weekly protocol exercises
                    ForEach(Array(track.weeklyProtocol.enumerated()), id: \.offset) { idx, item in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(idx + 1)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(isActive ? seasonColor : AppColor.textFaint)
                                .frame(width: 18, alignment: .leading)
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
                        .padding(.vertical, 4)
                        if idx < track.weeklyProtocol.count - 1 {
                            Divider().background(AppColor.border1)
                        }
                    }
                }

                // Action button
                Divider().background(AppColor.border1).padding(.top, 4)

                if isActive {
                    Button(action: onDeselect) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                            Text("ACTIVE — TAP TO DESELECT")
                                .font(.system(size: 11, weight: .heavy, design: .default))
                                .tracking(0.5)
                        }
                        .foregroundColor(seasonColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(seasonColor.opacity(0.12))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onSelect) {
                        Text("SELECT THIS TRACK")
                            .font(.system(size: 11, weight: .heavy, design: .default))
                            .tracking(0.5)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColor.textMuted)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay(alignment: .leading) {
            // Coloured left bar for the active track
            if isActive {
                Rectangle()
                    .fill(seasonColor)
                    .frame(width: 3)
                    .cornerRadius(2)
                    .padding(.vertical, 1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LimitingJointTrackView()
            .environment(AppState())
    }
}
