import SwiftUI

// MARK: - Schedule View
struct ScheduleView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var bindState = state
        ScrollView {
            VStack(spacing: 10) {
                weekSelectorCard
                overviewGrid
                dayCards
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Week Selector
    private var weekSelectorCard: some View {
        @Bindable var bindState = state
        let sw = state.scheduleWeek
        let sSeason = Seasons.season(for: sw)
        let isDeload = Seasons.isDeload(sw)
        let isTransition = Seasons.isTransition(sw)

        return CardView {
            SectionLabel(text: "Week Selector")
            HStack(spacing: 12) {
                IconButton(symbol: "−") {
                    state.scheduleWeek = max(1, state.scheduleWeek - 1)
                }
                VStack(spacing: 4) {
                    Text("WK \(sw)")
                        .font(.monoBig)
                        .foregroundColor(AppColor.textPrimary)
                    SectionLabel(text: "\(sSeason.name) · \(sSeason.goal)", color: sSeason.color)
                    if isTransition {
                        BadgeView("TRANSITION",
                                  foreground: AppColor.infoBlue,
                                  background: AppColor.infoBlue.opacity(0.13))
                    } else if isDeload {
                        BadgeView("DELOAD",
                                  foreground: AppColor.deload,
                                  background: AppColor.deloadBg)
                    }
                }
                .frame(maxWidth: .infinity)
                IconButton(symbol: "+") {
                    state.scheduleWeek = min(52, state.scheduleWeek + 1)
                }
            }
            .padding(.top, 8)

            // Season quick-jump buttons
            HStack(spacing: 4) {
                ForEach(Seasons.all) { season in
                    Button {
                        state.scheduleWeek = season.weekRange.lowerBound
                    } label: {
                        Text(season.name)
                            .font(.system(size: 10, weight: .bold, design: .default))
                            .foregroundColor(season.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(season.color.opacity(0.1))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(season.color.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
        }
    }

    // MARK: - 52-Week Overview Grid
    private var overviewGrid: some View {
        let sw = state.scheduleWeek
        return CardView {
            SectionLabel(text: "52-Week Overview")
            // 13 columns × 4 rows = 52 cells; ~16pt height, ~3pt spacing fits cleanly
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 13),
                spacing: 3
            ) {
                ForEach(1...52, id: \.self) { wk in
                    let wSeason = Seasons.season(for: wk)
                    let isTransition = Seasons.isTransition(wk)
                    let isDeload = Seasons.isDeload(wk)
                    let isSelected = wk == sw
                    Button {
                        state.scheduleWeek = wk
                    } label: {
                        Rectangle()
                            // Transition weeks get a distinct blue tint; deload weeks get the rest/grey;
                            // normal weeks get the season colour at half opacity.
                            .fill(
                                isTransition ? AppColor.infoBlue.opacity(0.55) :
                                isDeload     ? AppColor.cnsRest :
                                               wSeason.color.opacity(0.5)
                            )
                            .frame(height: 16)
                            .cornerRadius(3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Week \(wk)\(isTransition ? ", Transition" : isDeload ? ", Deload" : "")")
                }
            }
            .padding(.top, 8)

            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Seasons.all) { s in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(s.color)
                                .frame(width: 10, height: 10)
                            Text(s.name)
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textMuted)
                        }
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppColor.cnsRest)
                            .frame(width: 10, height: 10)
                        Text("Deload")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textMuted)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppColor.infoBlue.opacity(0.55))
                            .frame(width: 10, height: 10)
                        Text("Transition")
                            .font(.monoTiny)
                            .foregroundColor(AppColor.textMuted)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Day Cards
    private var dayCards: some View {
        let schedule = Schedules.schedule(for: state.scheduleWeek)
        return ForEach(Schedules.days, id: \.self) { day in
            if let session = schedule[day] {
                ScheduleDayCard(day: day, session: session)
            }
        }
    }
}

// MARK: - Schedule Day Card
private struct ScheduleDayCard: View {
    let day: String
    let session: Session

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left CNS accent bar
            Rectangle()
                .fill(cnsColor(session.cnsLoad))
                .frame(width: 3)
                .cornerRadius(2)
                .padding(.vertical, 1)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel(text: day)
                        Text(session.label)
                            .font(.appSubhead)
                            .foregroundColor(AppColor.textSecondary)
                    }
                    Spacer()
                    BadgeView(
                        session.cnsLoad.displayName,
                        foreground: cnsColor(session.cnsLoad),
                        background: cnsColor(session.cnsLoad).opacity(0.13)
                    )
                }

                if !session.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(session.exercises.prefix(4)) { ex in
                            Text("· \(ex.name) — \(ex.sets)×\(ex.reps)")
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textDimmed)
                        }
                        if session.exercises.count > 4 {
                            Text("+\(session.exercises.count - 4) more")
                                .font(.monoTiny)
                                .foregroundColor(AppColor.textFaint)
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(AppColor.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColor.border1, lineWidth: 1)
        )
    }
}
