import SwiftUI

// MARK: - Time Scale

enum TimeScale: String, CaseIterable {
    case week    = "Week"
    case season  = "Season"
    case allTime = "All Time"
}

// MARK: - Hexagon Radar View

/// Canvas-based 6-axis radar chart.
/// Vertices (starting at top, clockwise): Strength, Power, VO2max, Endurance, Recovery, Flexibility.
/// Scale is 0–100 with 5 concentric hexagonal rings at 20/40/60/80/100.
struct HexagonRadarView: View {

    let current: HexagonScore
    let previous: HexagonScore?  // previous season — drawn as a dashed outline
    let seasonColor: Color
    let timeScale: TimeScale     // drives the header label; drawing is identical across scales

    // Axis labels and their corresponding score values in vertex order (top, clockwise).
    private var axes: [(label: String, value: Double)] {
        [
            ("STRENGTH",    current.strength),
            ("POWER",       current.power),
            ("VO2MAX",      current.vo2max),
            ("ENDURANCE",   current.endurance),
            ("RECOVERY",    current.recovery),
            ("FLEXIBILITY", current.flexibility),
        ]
    }

    // Same ordering for the previous-season outline (if provided).
    private var previousValues: [Double] {
        guard let p = previous else { return [] }
        return [p.strength, p.power, p.vo2max, p.endurance, p.recovery, p.flexibility]
    }

    var body: some View {
        // Animate the polygon whenever the current score changes.
        // animatableData on the Canvas proxy is not directly accessible, so we
        // drive the animation by wrapping the Canvas in a container with an
        // animation modifier keyed on the score values.
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            // Use 85 % of the smaller dimension as the max radius so labels have room.
            let maxRadius = min(size.width, size.height) * 0.40

            drawGrid(ctx: ctx, center: center, radius: maxRadius)
            drawAxisLines(ctx: ctx, center: center, radius: maxRadius)

            if !previousValues.isEmpty {
                drawPolygon(
                    ctx: ctx,
                    center: center,
                    radius: maxRadius,
                    values: previousValues,
                    fillColor: nil,
                    strokeColor: AppColor.textFaint.opacity(0.6),
                    dashed: true
                )
            }

            drawPolygon(
                ctx: ctx,
                center: center,
                radius: maxRadius,
                values: axes.map(\.value),
                fillColor: seasonColor.opacity(0.25),
                strokeColor: seasonColor,
                dashed: false
            )

            drawLabels(ctx: ctx, center: center, radius: maxRadius, size: size)
        }
        // Animating on `current` changes triggers a re-render with easeInOut.
        .animation(.easeInOut(duration: 0.4), value: current.strength)
        .animation(.easeInOut(duration: 0.4), value: current.power)
        .animation(.easeInOut(duration: 0.4), value: current.vo2max)
        .animation(.easeInOut(duration: 0.4), value: current.endurance)
        .animation(.easeInOut(duration: 0.4), value: current.recovery)
        .animation(.easeInOut(duration: 0.4), value: current.flexibility)
    }

    // MARK: - Drawing helpers

    /// Returns the angle (in radians) for axis `i`.
    /// Axis 0 = top (−90°), then clockwise 60° per step.
    private func angle(for index: Int) -> Double {
        (-90 + Double(index) * 60) * .pi / 180
    }

    /// Point on the unit hexagon for a given axis index and fraction (0…1).
    private func point(center: CGPoint, radius: CGFloat, index: Int, fraction: CGFloat) -> CGPoint {
        let a = angle(for: index)
        return CGPoint(
            x: center.x + radius * fraction * CGFloat(cos(a)),
            y: center.y + radius * fraction * CGFloat(sin(a))
        )
    }

    /// Draws 5 concentric hexagonal grid rings at 20 / 40 / 60 / 80 / 100.
    private func drawGrid(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let rings: [CGFloat] = [0.2, 0.4, 0.6, 0.8, 1.0]
        for fraction in rings {
            var path = Path()
            for i in 0..<6 {
                let pt = point(center: center, radius: radius, index: i, fraction: fraction)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()

            let isMajor = fraction == 1.0
            ctx.stroke(
                path,
                with: .color(AppColor.border2.opacity(isMajor ? 0.8 : 0.4)),
                lineWidth: isMajor ? 1 : 0.5
            )
        }
    }

    /// Draws the 6 radial axis lines from center to each vertex.
    private func drawAxisLines(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        for i in 0..<6 {
            var path = Path()
            path.move(to: center)
            path.addLine(to: point(center: center, radius: radius, index: i, fraction: 1.0))
            ctx.stroke(path, with: .color(AppColor.border2.opacity(0.5)), lineWidth: 0.5)
        }
    }

    /// Draws a filled/stroked polygon connecting the given axis values.
    private func drawPolygon(
        ctx: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        values: [Double],
        fillColor: Color?,
        strokeColor: Color,
        dashed: Bool
    ) {
        guard values.count == 6 else { return }

        var path = Path()
        for (i, value) in values.enumerated() {
            let fraction = CGFloat(max(0, min(value, 100)) / 100)
            let pt = point(center: center, radius: radius, index: i, fraction: fraction)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        if let fill = fillColor {
            ctx.fill(path, with: .color(fill))
        }

        // Dashed stroke requires a stroked copy of the path.
        let style: StrokeStyle = dashed
            ? StrokeStyle(lineWidth: 1.5, dash: [5, 4])
            : StrokeStyle(lineWidth: 2)

        ctx.stroke(path, with: .color(strokeColor), style: style)
    }

    /// Renders axis labels + score values outside each vertex using resolved text.
    /// Keeping text in the Canvas avoids a ZStack overlay, which would misalign on
    /// different device sizes.
    private func drawLabels(
        ctx: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        size: CGSize
    ) {
        // Push labels 16 pt beyond the outermost ring so they clear the hexagon edge.
        let labelRadius = radius + 22

        for (i, axis) in axes.enumerated() {
            let a = angle(for: i)
            let labelCenter = CGPoint(
                x: center.x + labelRadius * CGFloat(cos(a)),
                y: center.y + labelRadius * CGFloat(sin(a))
            )

            // Two lines: axis name on top, score value below.
            let labelText = Text(axis.label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(AppColor.textFaint)

            let scoreText = Text("\(Int(axis.value))")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(seasonColor)

            let resolvedLabel = ctx.resolve(labelText)
            let resolvedScore = ctx.resolve(scoreText)

            let labelSize = resolvedLabel.measure(in: CGSize(width: 60, height: 20))
            let scoreSize = resolvedScore.measure(in: CGSize(width: 30, height: 14))

            // Stack the two text fragments centred on `labelCenter`.
            let totalHeight = labelSize.height + 2 + scoreSize.height
            let labelOrigin = CGPoint(
                x: labelCenter.x - labelSize.width / 2,
                y: labelCenter.y - totalHeight / 2
            )
            let scoreOrigin = CGPoint(
                x: labelCenter.x - scoreSize.width / 2,
                y: labelOrigin.y + labelSize.height + 2
            )

            ctx.draw(resolvedLabel, at: labelOrigin, anchor: .topLeading)
            ctx.draw(resolvedScore, at: scoreOrigin, anchor: .topLeading)
        }
    }
}

// MARK: - Preview

#Preview {
    let score = HexagonScore(
        date: "5/15/2026",
        strength: 68, power: 55, vo2max: 72,
        endurance: 45, flexibility: 60, recovery: 80
    )
    let prev = HexagonScore(
        date: "2/15/2026",
        strength: 56, power: 50, vo2max: 65,
        endurance: 40, flexibility: 55, recovery: 70
    )
    HexagonRadarView(
        current: score,
        previous: prev,
        seasonColor: AppColor.spring,
        timeScale: .season
    )
    .frame(width: 280, height: 280)
    .background(AppColor.cardBackground)
    .preferredColorScheme(.dark)
}
