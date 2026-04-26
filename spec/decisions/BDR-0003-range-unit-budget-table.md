---
id: BDR-0003
title: Restrict (range x unit) combinations via a safe-budget lookup table
status: accepted
date: 2026-04-21
summary: The UI exposes only those (range x unit) combinations that produce a manageable number of heatmap buckets. "this month + per minute" (~43 200 buckets) and similar blow-ups are hidden.
---

**Feature**: stats/features/heatmap-view.feature
**Rule**: The time unit changes the heatmap bucket size, limited to a safe-budget lookup table

## Context

The heatmap's bucket count grows as the product of range span and unit granularity. At the extremes:

| Range x Unit  | Buckets         |
|---------------|-----------------|
| month x min   | ~43 200         |
| week x min    | ~10 080         |
| month x hour  | ~720            |
| week x hour   | 168             |
| month x day   | ~30             |

Rendering tens of thousands of cells degrades the view from "insightful heatmap" to "illegible pixel soup", and strains SwiftUI. A rule is needed for which combinations to expose.

## Behaviours Considered

### Option A: Expose every combination, let the user pick
Maximum flexibility, worst-case UX and performance. No guardrails mean the user will hit the wall and infer "this app is slow" rather than "I picked a silly combination".

### Option B: Recommend a sensible default per range, but allow override
Cleaner than A, still allows users to foot-gun themselves.

### Option C: Enforce a lookup table of supported combinations; hide the rest
Strict, deterministic, no surprises. Costs the user some edge-case flexibility they are unlikely to need (nobody really wants to view minute-level resolution across a month).

## Decision

**Option C**. The available time units per range are fixed by this table:

| Range       | Offered units         |
|-------------|-----------------------|
| today       | per minute, per hour  |
| yesterday   | per minute, per hour  |
| this week   | per hour, per day     |
| this month  | per hour, per day     |

Combinations outside the table are not shown in the UI. If the user wants finer resolution over a longer span, they should shrink the range.

## Rejected Alternatives

- **Option A** was rejected because the worst combinations are both unhelpful and expensive — exposing them invites bad experiences.
- **Option B** was rejected because the "override" path adds UI surface area (enable-advanced toggle or similar) without a real use case.
