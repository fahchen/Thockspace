---
id: BDR-0006
title: Defer custom arbitrary date ranges to a later version
status: deferred
date: 2026-04-21
summary: v1 offers only the four preset ranges (today, yesterday, this week, this month). Custom start/end date pickers are deferred.
---

## Scope

**Feature**: stats/features/heatmap-view.feature
**Rule**: The user picks a preset time range

## Reason

The user confirmed presets are enough ("时段我无所谓, 你这几个可以的"). A date-picker UI, input validation, and the range x unit budget calculations for arbitrary spans all add complexity that is not justified in v1. If a concrete need for arbitrary ranges arises later (e.g., yearly review, compare-two-weeks), revisit this decision.
