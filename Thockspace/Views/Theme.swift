import SwiftUI

/// Global design tokens for the Liquid Glass aesthetic.
/// Reused across the popover (SettingsView), the stats window (F1),
/// and the Manage Packs window (F3).
enum Theme {
    enum Metric {
        static let panelPadding: CGFloat = 18
        static let sectionSpacing: CGFloat = 14
        static let rowSpacing: CGFloat = 10
        static let panelCorner: CGFloat = 22
        static let chipCorner: CGFloat = 14
        static let controlCorner: CGFloat = 12
    }

    enum Accent {
        /// 墨青 — muted sumi-ink indigo. Quiet, refined, reads well on washi-toned glass.
        static let primary = Color(red: 0.36, green: 0.45, blue: 0.52)
        /// 朱砂 — cinnabar red, the seal-ink hue; used sparingly for mute/warning state.
        static let muteActive = Color(red: 0.72, green: 0.32, blue: 0.28)
    }
}

// MARK: - Glass surfaces

extension View {
    /// Top-level panel surface — e.g. the popover body, or a full window content.
    func glassPanel() -> some View {
        self
            .padding(Theme.Metric.panelPadding)
            .glassEffect(
                .regular,
                in: .rect(cornerRadius: Theme.Metric.panelCorner)
            )
    }

    /// Grouped section inside a panel — e.g. a picker block, a slider row group.
    func glassSection() -> some View {
        self
            .padding(12)
            .glassEffect(
                .regular.tint(.clear),
                in: .rect(cornerRadius: Theme.Metric.chipCorner)
            )
    }

    /// Small inline chip — e.g. status badge, key hint.
    func glassChip() -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassEffect(
                .regular,
                in: .capsule
            )
    }
}

// MARK: - Typography

extension Font {
    static var panelTitle: Font { .system(size: 15, weight: .semibold, design: .default) }
    static var sectionLabel: Font { .caption.weight(.medium) }
    static var panelBody: Font { .system(size: 13, weight: .regular) }
}
