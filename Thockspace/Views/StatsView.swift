import SwiftUI

/// Dedicated window for the keystroke-frequency heatmap (F1).
struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var range: StatsRange = .today
    @State private var unit: StatsUnit = .perHour
    @State private var hovered: HeatmapBucket?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.sectionSpacing) {
            header
            controls
                .glassSection()
            heatmap
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .frame(minWidth: 640, minHeight: 440)
        .glassPanel()
        .onAppear { syncDefaultUnit() }
        .onChange(of: range) { syncDefaultUnit() }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
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
        return VStack(alignment: .leading, spacing: 6) {
            HeatmapContent(grid: grid, hovered: $hovered)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let h = hovered {
                Text(tooltipText(h))
                    .font(.caption)
                    .glassChip()
            } else {
                Text("Hover a cell for details. Empty cells indicate no typing or the app was not running.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
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

    private let cellSpacing: CGFloat = 2
    private let cellMinSize: CGFloat = 4
    private let cellMaxSize: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let cols = grid.rows.first?.buckets.count ?? 0
            let labelWidth: CGFloat = 64
            let available = max(proxy.size.width - labelWidth, 0)
            let cellSize = cols > 0
                ? min(cellMaxSize, max(cellMinSize, (available - cellSpacing * CGFloat(cols - 1)) / CGFloat(cols)))
                : cellMinSize

            VStack(alignment: .leading, spacing: cellSpacing) {
                ForEach(grid.rows) { row in
                    HStack(spacing: 8) {
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
                                    hovered = inside ? bucket : (hovered?.id == bucket.id ? nil : hovered)
                                }
                            }
                        }
                    }
                }

                if !grid.columnLabels.allSatisfy({ $0.isEmpty }) {
                    HStack(spacing: 8) {
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
                }
            }
        }
    }
}

private struct Cell: View {
    let bucket: HeatmapBucket
    let band: Int
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: size, height: size)
    }

    private var color: Color {
        switch band {
        case 0: return Color.secondary.opacity(0.12)
        case 1: return Theme.Accent.primary.opacity(0.25)
        case 2: return Theme.Accent.primary.opacity(0.5)
        case 3: return Theme.Accent.primary.opacity(0.75)
        default: return Theme.Accent.primary
        }
    }
}
