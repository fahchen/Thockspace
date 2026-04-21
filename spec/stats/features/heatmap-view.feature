@stats @heatmap
Feature: Keystroke Heatmap View
  As the app owner
  I want to explore my typing activity through a heatmap with a chosen time range and time unit
  So that I can spot patterns in when and how much I type

  Background:
    Given the app has recorded keystrokes across many days and hours

  Rule: The heatmap lays out days as rows and time buckets as columns

    Scenario: A multi-day range shows one row per day
      When the user opens the stats view with range "this week" and unit "per hour"
      Then the heatmap shows 7 rows, one per day of the week
      And each row contains 24 columns, one per hour

    Scenario: A single-day range degrades to a single-row strip
      When the user opens the stats view with range "today" and unit "per hour"
      Then the heatmap shows exactly 1 row
      And the row contains 24 columns

    Scenario: Hovering a cell reveals the exact bucket count and time range
      Given the stats view is open
      When the user hovers over a cell in the heatmap
      Then a tooltip shows the bucket's start-to-end time range and the exact count

  Rule: The user picks a preset time range

    Scenario Outline: Available preset ranges
      When the user selects the range "<range>"
      Then the heatmap shows activity for <range description>

      Examples:
        | range      | range description                                        |
        | today      | the current local day from 00:00 until now               |
        | yesterday  | the previous local day from 00:00 to 23:59               |
        | this week  | the 7 days from Monday 00:00 of the current ISO week     |
        | this month | from the 1st 00:00 of the current month until now        |

    Scenario: Custom arbitrary date ranges are not offered in v1
      When the user opens the stats view
      Then no date picker is shown for choosing arbitrary start and end dates

  Rule: The time unit changes the heatmap bucket size, limited to a safe-budget lookup table

    Scenario Outline: Only budget-safe (range x unit) combinations are offered
      When the user selects the range "<range>"
      Then the offered time units are <offered units>
      And units outside the offered list are hidden or disabled

      Examples:
        | range      | offered units          |
        | today      | per minute, per hour   |
        | yesterday  | per minute, per hour   |
        | this week  | per hour, per day      |
        | this month | per hour, per day      |

    Scenario: Switching to a coarser unit collapses columns
      Given the heatmap is showing "this week" with unit "per hour" (7 rows by 24 columns)
      When the user switches the unit to "per day"
      Then the heatmap redraws as 7 rows by 1 column

    Scenario: Combinations outside the safe-budget table cannot be reached
      When the user opens the stats view with range "this month"
      Then "per minute" is not among the offered time units

  Rule: Color intensity is derived from quantiles of the currently displayed data

    Scenario: Zero-count buckets use an empty color
      Given a bucket has a count of 0
      When the heatmap is rendered
      Then that bucket is shown in the empty color with no intensity

    Scenario: Non-zero buckets are colored across four quantile bands
      Given the heatmap has many non-zero buckets with varied counts
      When the heatmap is rendered
      Then non-zero buckets are placed into one of four intensity bands by quantile

    Scenario: Switching the range recomputes the color scale
      Given the heatmap is rendered for range "today"
      And a specific bucket X is shown in the highest intensity band
      When the user switches the range to "this month" while X remains in view
      Then the color of X may change because quantiles are recomputed for the new view

  Rule: The stats view lives in its own window, not inside the menu-bar popover

    Scenario: Opening stats launches a dedicated window
      Given the menu-bar popover is shown
      When the user activates the "Open Stats" action
      Then a new application window is shown containing the heatmap
      And the menu-bar popover itself continues to show only the compact settings
