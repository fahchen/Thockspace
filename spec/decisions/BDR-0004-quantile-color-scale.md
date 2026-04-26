---
id: BDR-0004
title: Use quantile-based color scale for the heatmap, recomputed per view
status: accepted
date: 2026-04-21
summary: Non-zero buckets are placed in four quantile bands of the currently displayed data; zero-count buckets use an empty color. Switching range or unit recomputes quantiles.
---

**Feature**: stats/features/heatmap-view.feature
**Rule**: Color intensity is derived from quantiles of the currently displayed data

## Context

The user explicitly asked for a "GitHub-style" heatmap. GitHub's contribution graph uses a quantile-approximate color scale over 5 levels (empty + 4 intensity bands), re-anchored to the user's own activity. The behaviour of the color scale — fixed or relative, per-view or global — needs a definition so that ticking through ranges and units is interpretable.

## Behaviours Considered

### Option A: Absolute, fixed thresholds
Example: 0-10 pale, 10-100 mid, >100 dark. Comparable across views, but fails for users whose activity sits entirely below or above the chosen thresholds — their heatmap becomes one flat color.

### Option B: Auto-normalize to the max in the current view (linear scale)
Every view "uses" the full color range. Simple. But one extreme outlier (e.g., a long coding burst) crushes everything else into the lightest band.

### Option C: Quantile-based (zero + 4 non-zero quantiles), recomputed per view
GitHub-style. Robust to outliers because each quantile band always contains roughly a quarter of the non-zero buckets. Always uses the full color range. Recomputing per view means the same bucket may be shaded differently when the range or unit changes.

## Decision

**Option C**. Zero-count buckets use the empty color. Non-zero buckets are distributed across four quantile bands computed from the buckets currently visible in the heatmap. Switching range or time unit triggers a recomputation.

The cost of this choice — that a given bucket's color is context-dependent — is accepted. Tooltips show the exact count (see the heatmap feature), which resolves any ambiguity.

## Rejected Alternatives

- **Option A** was rejected because a single user's typing volume is the wrong thing to compare across weeks; thresholds that work in week view crush today view.
- **Option B** was rejected because it is too sensitive to single bursts and fails to reveal the everyday pattern.
