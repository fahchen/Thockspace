import SwiftUI

/// Dedicated window for the keystroke-frequency heatmap (F1).
struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var range: StatsRange = .today
    @State private var unit: StatsUnit = .perHour
    @State private var hovered: HeatmapBucket?
    @State private var hoverLocation: CGPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.sectionSpacing) {
            header
            controls
                .glassSection()
            summaryStrip
            heatmap
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            legend
        }
        .frame(minWidth: 680, minHeight: 520)
        .padding(.top, 32)
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
        .onAppear { syncDefaultUnit() }
        .onChange(of: range) { syncDefaultUnit() }
    }

    private var summaryStrip: some View {
        let grid = currentGrid
        let nonZero = grid.rows.flatMap { $0.buckets }.filter { $0.count > 0 }.count
        let peak = grid.rows.flatMap { $0.buckets }.max(by: { $0.count < $1.count })
        let peakFmt = DateFormatter()
        peakFmt.dateFormat = unit == .perDay ? "EEE MMM d" : "EEE HH:mm"
        return HStack(spacing: 10) {
            summaryTile("Peak", value: peak.map { "\($0.count)" } ?? "—",
                        subtitle: peak.map { peakFmt.string(from: $0.start) } ?? "no data")
            summaryTile("Active Buckets", value: "\(nonZero)", subtitle: "of \(grid.rows.flatMap { $0.buckets }.count)")
            summaryTile("Max Intensity", value: "\(grid.maxCount)", subtitle: unit.label.lowercased())
        }
    }

    private func summaryTile(_ label: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .kerning(0.8)
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.Accent.primary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .glassSection()
    }

    private var legend: some View {
        HStack(spacing: 8) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach(0...4, id: \.self) { band in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Cell.color(forBand: band))
                    .frame(width: 14, height: 14)
            }
            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            if hovered == nil {
                Text("Hover cells for exact counts")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.title3)
                .foregroundStyle(Theme.Accent.primary)
            Text("Keystroke Activity")
                .font(.panelTitle)
            Spacer()
            totalChip
        }
    }

    private var totalChip: some View {
        let interval = range.interval()
        let total = appState.recorder.totalCount(from: interval.start, to: interval.end)
        return Text("\(total) keystrokes")
            .font(.caption)
            .glassChip()
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Picker("Range", selection: $range) {
                ForEach(StatsRange.allCases) { r in
                    Text(r.label).tag(r)
                }
            }
            .pickerStyle(.segmented)

            Picker("Unit", selection: $unit) {
                ForEach(StatsBudget.offeredUnits(for: range)) { u in
                    Text(u.label).tag(u)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var heatmap: some View {
        let grid = currentGrid
        return HeatmapContent(
            grid: grid,
            hovered: $hovered,
            hoverLocation: $hoverLocation
        )
        .overlay(alignment: .topLeading) {
            if let loc = hoverLocation, let h = hovered {
                Text(tooltipText(h))
                    .font(.caption)
                    .glassChip()
                    .offset(x: loc.x + 14, y: loc.y + 14)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Helpers

    private var currentGrid: HeatmapGrid {
        let interval = range.interval()
        let counts = appState.recorder.bucketedCounts(
            from: interval.start,
            to: interval.end,
            bucketSeconds: unit.bucketSeconds
        )
        return HeatmapGrid.build(range: range, unit: unit, counts: counts)
    }

    private func syncDefaultUnit() {
        let offered = StatsBudget.offeredUnits(for: range)
        if !offered.contains(unit) {
            unit = StatsBudget.defaultUnit(for: range)
        }
    }

    private func tooltipText(_ bucket: HeatmapBucket) -> String {
        let formatter = DateFormatter()
        switch unit {
        case .perMinute:
            formatter.dateFormat = "EEE HH:mm"
        case .perHour:
            formatter.dateFormat = "EEE HH:00"
        case .perDay:
            formatter.dateFormat = "EEE MMM d"
        }
        return "\(formatter.string(from: bucket.start)) · \(bucket.count) keystrokes"
    }
}

// MARK: - Heatmap rendering

private struct HeatmapContent: View {
    let grid: HeatmapGrid
    @Binding var hovered: HeatmapBucket?
    @Binding var hoverLocation: CGPoint?

    private let cellSpacing: CGFloat = 3
    private let cellMinSize: CGFloat = 6
    private let cellMaxSize: CGFloat = 36
    private let labelWidth: CGFloat = 68

    var body: some View {
        GeometryReader { proxy in
            let cols = grid.rows.first?.buckets.count ?? 0
            let rows = grid.rows.count
            let availW = max(proxy.size.width - labelWidth - 8, 0)
            let availH = max(proxy.size.height - 24, 0)  // reserve bottom for column labels
            let sizeByW = cols > 0
                ? (availW - cellSpacing * CGFloat(cols - 1)) / CGFloat(cols)
                : cellMaxSize
            let sizeByH = rows > 0
                ? (availH - cellSpacing * CGFloat(rows - 1)) / CGFloat(rows)
                : cellMaxSize
            let cellSize = min(cellMaxSize, max(cellMinSize, min(sizeByW, sizeByH)))

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: cellSpacing) {
                    ForEach(grid.rows) { row in
                        HStack(spacing: 10) {
                            Text(row.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: labelWidth, alignment: .leading)
                            HStack(spacing: cellSpacing) {
                                ForEach(row.buckets) { bucket in
                                    Cell(
                                        bucket: bucket,
                                        band: grid.band(for: bucket.count),
                                        size: cellSize
                                    )
                                    .onHover { inside in
                                        if inside {
                                            hovered = bucket
                                        } else if hovered?.id == bucket.id {
                                            hovered = nil
                                            hoverLocation = nil
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !grid.columnLabels.allSatisfy({ $0.isEmpty }) {
                        HStack(spacing: 10) {
                            Color.clear.frame(width: labelWidth)
                            HStack(spacing: cellSpacing) {
                                ForEach(Array(grid.columnLabels.enumerated()), id: \.offset) { _, label in
                                    Text(label)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .frame(width: cellSize)
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 0)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    hoverLocation = point
                case .ended:
                    hoverLocation = nil
                }
            }
        }
    }
}

struct Cell: View {
    let bucket: HeatmapBucket
    let band: Int
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Self.color(forBand: band))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Theme.Accent.primary.opacity(band == 0 ? 0.12 : 0.35), lineWidth: 0.5)
            )
            .frame(width: size, height: size)
    }

    static func color(forBand band: Int) -> Color {
        switch band {
        case 0: return Color.primary.opacity(0.08)
        case 1: return Theme.Accent.primary.opacity(0.30)
        case 2: return Theme.Accent.primary.opacity(0.55)
        case 3: return Theme.Accent.primary.opacity(0.80)
        default: return Theme.Accent.primary
        }
    }
}
