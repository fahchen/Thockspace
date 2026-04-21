import Foundation

/// Preset ranges available in the heatmap view (BDR-0006 defers custom
/// arbitrary ranges).
enum StatsRange: String, CaseIterable, Identifiable {
    case today
    case yesterday
    case thisWeek
    case thisMonth

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }

    /// Compute the half-open [start, end) interval for this range relative
    /// to `now`, in the user's current calendar and time zone.
    func interval(now: Date = .init(), calendar: Calendar = .current) -> DateInterval {
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        case .yesterday:
            let today = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -1, to: today)!
            return DateInterval(start: start, end: today)
        case .thisWeek:
            // ISO-like: week starts Monday. Use calendar's weekOfYear with Monday as firstWeekday.
            var cal = calendar
            cal.firstWeekday = 2  // Monday
            let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start
                ?? calendar.startOfDay(for: now)
            let end = cal.date(byAdding: .day, value: 7, to: weekStart)!
            return DateInterval(start: weekStart, end: end)
        case .thisMonth:
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start
                ?? calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            return DateInterval(start: monthStart, end: end)
        }
    }
}

/// Display unit selectable by the user. Determines heatmap bucket size.
enum StatsUnit: String, CaseIterable, Identifiable {
    case perMinute
    case perHour
    case perDay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .perMinute: return "Per Minute"
        case .perHour: return "Per Hour"
        case .perDay: return "Per Day"
        }
    }

    var bucketSeconds: Int {
        switch self {
        case .perMinute: return 60
        case .perHour: return 3600
        case .perDay: return 86_400
        }
    }
}

/// BDR-0003 safe-budget lookup. Determines which (range × unit)
/// combinations are exposed in the UI.
enum StatsBudget {
    static func offeredUnits(for range: StatsRange) -> [StatsUnit] {
        switch range {
        case .today, .yesterday:  return [.perMinute, .perHour]
        case .thisWeek:           return [.perHour, .perDay]
        case .thisMonth:          return [.perHour, .perDay]
        }
    }

    static func defaultUnit(for range: StatsRange) -> StatsUnit {
        switch range {
        case .today, .yesterday: return .perHour
        case .thisWeek:          return .perHour
        case .thisMonth:         return .perDay
        }
    }
}

/// One cell in the heatmap grid.
struct HeatmapBucket: Identifiable, Hashable {
    let id: Int                  // bucket start (epoch seconds)
    let start: Date
    let end: Date
    let count: Int
}

/// 2D heatmap layout: rows are days, columns are time-buckets within a day.
struct HeatmapGrid {
    let rows: [Row]
    let columnLabels: [String]
    let range: StatsRange
    let unit: StatsUnit
    let maxCount: Int
    /// Sorted non-zero counts used to compute quantile colour bands.
    let quantileThresholds: [Int]

    struct Row: Identifiable {
        let id: Date           // day start
        let label: String      // Mon / Tue / ...
        let buckets: [HeatmapBucket]
    }

    /// Place a raw per-bucket count map into the 2D grid.
    /// `counts` is keyed by bucket start (epoch seconds).
    static func build(
        range: StatsRange,
        unit: StatsUnit,
        counts: [Int: Int],
        calendar: Calendar = .current
    ) -> HeatmapGrid {
        let interval = range.interval(calendar: calendar)
        let bucketSize = unit.bucketSeconds

        // Decide day partitioning — every range slices into day rows.
        var rows: [Row] = []
        let rowStart = calendar.startOfDay(for: interval.start)
        var cursor = rowStart
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE\nMMM d"
        while cursor < interval.end {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: cursor)!
            let rowIntervalStart = max(cursor, interval.start)
            let rowIntervalEnd = min(dayEnd, interval.end)

            var buckets: [HeatmapBucket] = []
            // Snap to bucket boundaries
            let firstBucketStart = Int(rowIntervalStart.timeIntervalSince1970) / bucketSize * bucketSize
            let lastBucketEnd = Int(rowIntervalEnd.timeIntervalSince1970)
            var bucketEpoch = firstBucketStart
            while bucketEpoch < lastBucketEnd {
                let bStart = Date(timeIntervalSince1970: TimeInterval(bucketEpoch))
                let bEnd = Date(timeIntervalSince1970: TimeInterval(bucketEpoch + bucketSize))
                let count = counts[bucketEpoch] ?? 0
                buckets.append(HeatmapBucket(id: bucketEpoch, start: bStart, end: bEnd, count: count))
                bucketEpoch += bucketSize
            }

            rows.append(Row(
                id: cursor,
                label: dayFormatter.string(from: cursor),
                buckets: buckets
            ))
            cursor = dayEnd
        }

        // Column labels come from the bucket size
        let columnLabels = columnLabels(for: unit, rowWidth: rows.first?.buckets.count ?? 0)

        // Quantile thresholds: compute over all non-zero buckets in the grid
        let nonZero = rows.flatMap { $0.buckets }.map(\.count).filter { $0 > 0 }.sorted()
        let thresholds = quantileThresholds(sortedNonZeroCounts: nonZero)
        let maxCount = nonZero.last ?? 0

        return HeatmapGrid(
            rows: rows,
            columnLabels: columnLabels,
            range: range,
            unit: unit,
            maxCount: maxCount,
            quantileThresholds: thresholds
        )
    }

    /// Map a count to one of five bands (0 ... 4).
    /// 0 = empty (no count), 1-4 = quartiles of non-zero counts.
    func band(for count: Int) -> Int {
        guard count > 0 else { return 0 }
        for (i, t) in quantileThresholds.enumerated() {
            if count <= t { return i + 1 }
        }
        return quantileThresholds.count + 1  // should not happen unless thresholds empty
    }

    // MARK: - Private helpers

    private static func columnLabels(for unit: StatsUnit, rowWidth: Int) -> [String] {
        switch unit {
        case .perDay:
            return (0..<rowWidth).map { _ in "" }
        case .perHour:
            // 24 hours in a day, label every 6
            return (0..<rowWidth).map { i in i % 6 == 0 ? String(format: "%02d", i) : "" }
        case .perMinute:
            // 1440 minutes in a day, label every 60 (on the hour)
            return (0..<rowWidth).map { i in i % 60 == 0 ? "\(i / 60)" : "" }
        }
    }

    /// Four thresholds dividing sorted non-zero counts into quartiles.
    /// Returns an ascending list [q1, q2, q3, q4_max]. A count <= thresholds[i]
    /// lands in band i+1. Bucket with 0 counts → band 0 (empty).
    private static func quantileThresholds(sortedNonZeroCounts: [Int]) -> [Int] {
        guard !sortedNonZeroCounts.isEmpty else { return [] }
        let n = sortedNonZeroCounts.count
        // Quartile positions: floor((k / 4) * n) - 1, clamped
        func pick(_ k: Int) -> Int {
            let idx = min(max((k * n) / 4 - 1, 0), n - 1)
            return sortedNonZeroCounts[idx]
        }
        // Thresholds for bands 1..4
        return [pick(1), pick(2), pick(3), sortedNonZeroCounts.last!]
    }
}
