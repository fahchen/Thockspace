import Foundation
import CoreGraphics

/// Persistent per-minute count store for all `keyDown` events (keyboard
/// and mouse synthetic codes alike). Recording is decoupled from Mute
/// (BDR-0005) — only the audio pipeline honours Mute.
///
/// On-disk format: a single JSON object at
/// `~/Library/Application Support/Thockspace/stats.json`, keyed by
/// epoch-minute as stringified integer. Per-minute totals rather than
/// raw samples keep the file compact (~8 MB/year for heavy typing) and
/// let queries be O(range-in-minutes).
@MainActor
final class StatsRecorder: ObservableObject {
    /// minute-since-epoch → count
    @Published private(set) var buckets: [Int: Int] = [:]

    private let fileURL: URL
    private let flushInterval: TimeInterval = 5
    private var dirty = false
    private var flushTimer: Timer?

    init() {
        self.fileURL = Self.defaultURL()
        load()
        startFlushTimer()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: NSNotification.Name("NSApplicationWillTerminateNotification"),
            object: nil
        )
    }

    // Timer lives for the full app lifetime; deinit is effectively unreachable.

    /// Record one keystroke event. Call only for `isDown == true` events,
    /// keyboard and mouse alike (the caller filters).
    func recordKeyDown(at date: Date = .init()) {
        let minute = Self.minuteKey(for: date)
        buckets[minute, default: 0] += 1
        dirty = true
    }

    // MARK: - Query

    /// Sum of counts within the closed-open interval [start, end).
    func totalCount(from start: Date, to end: Date) -> Int {
        let lo = Self.minuteKey(for: start)
        let hi = Self.minuteKey(for: end)
        var total = 0
        for (k, v) in buckets where k >= lo && k < hi {
            total += v
        }
        return total
    }

    /// Per-bucket counts rolled up to the given bucket size in seconds.
    /// Result key: bucket start (epoch seconds), value: count.
    func bucketedCounts(
        from start: Date,
        to end: Date,
        bucketSeconds: Int
    ) -> [Int: Int] {
        let startSec = Int(start.timeIntervalSince1970)
        let endSec = Int(end.timeIntervalSince1970)
        let bucketSize = max(60, bucketSeconds)  // never finer than a minute
        let bucketsPerSecond = 60

        var out: [Int: Int] = [:]
        // Walk minute-keys in range; round down to bucket start
        let loMin = startSec / 60
        let hiMin = (endSec + 59) / 60
        for minuteKey in loMin..<hiMin {
            guard let count = buckets[minuteKey], count > 0 else { continue }
            let minuteEpochSec = minuteKey * 60
            let bucketStart = (minuteEpochSec / bucketSize) * bucketSize
            out[bucketStart, default: 0] += count
        }
        _ = bucketsPerSecond  // silence unused
        return out
    }

    // MARK: - Persistence

    private func startFlushTimer() {
        let timer = Timer.scheduledTimer(
            withTimeInterval: flushInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.flushIfNeeded()
            }
        }
        self.flushTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func flushIfNeeded() {
        guard dirty else { return }
        dirty = false
        save()
    }

    @objc private nonisolated func appWillTerminate() {
        Task { @MainActor in
            self.save()
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else {
            return
        }
        var out: [Int: Int] = [:]
        out.reserveCapacity(raw.count)
        for (k, v) in raw {
            if let key = Int(k) { out[key] = v }
        }
        buckets = out
    }

    private func save() {
        var raw: [String: Int] = [:]
        raw.reserveCapacity(buckets.count)
        for (k, v) in buckets {
            raw[String(k)] = v
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: raw, options: [])
            let fm = FileManager.default
            try fm.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[Thockspace] Failed to persist stats: \(error)")
        }
    }

    // MARK: - Helpers

    private static func minuteKey(for date: Date) -> Int {
        Int(date.timeIntervalSince1970) / 60
    }

    private static func defaultURL() -> URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Thockspace", isDirectory: true)
            .appendingPathComponent("stats.json")
    }
}
