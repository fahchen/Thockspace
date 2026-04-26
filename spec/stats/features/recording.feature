@stats @recording
Feature: Keystroke Recording
  As the app owner
  I want every relevant input event to be counted and stored locally
  So that I can later reflect on my own typing activity without anything leaving the device

  Rule: Each OS keyDown event counts as one keystroke

    Scenario: A single key press records one keystroke
      Given the app is running with Input Monitoring granted
      When the user presses the letter "a" once
      Then one keystroke is recorded

    Scenario: Auto-repeat while holding a key records one keystroke per OS event
      Given the app is running with Input Monitoring granted
      And the OS is configured to emit auto-repeat keyDown events
      When the user holds the letter "a" long enough to generate 10 auto-repeat events
      Then 10 keystrokes are recorded

    Scenario: Releasing a key adds no keystroke
      Given the app is running with Input Monitoring granted
      When the user releases a previously pressed key
      Then no additional keystroke is recorded

  Rule: Modifier key down-transitions count; up-transitions do not

    Scenario: Pressing a modifier alone records one keystroke
      Given the app is running with Input Monitoring granted
      When the user presses Shift alone
      Then one keystroke is recorded

    Scenario: Releasing a modifier records nothing
      Given the app is running with Input Monitoring granted
      And Shift is currently held
      When the user releases Shift
      Then no additional keystroke is recorded

    Scenario: Pressing a modifier and then a character records two keystrokes
      Given the app is running with Input Monitoring granted
      When the user presses Shift and then the letter "A" while still holding Shift
      Then two keystrokes are recorded

  Rule: Mouse button-down events are stored alongside keyboard events via synthetic codes

    Scenario Outline: Mouse button presses are recorded as keystrokes
      Given the app is running with Input Monitoring granted
      When the user presses the <button> mouse button
      Then one keystroke is recorded with the synthetic code "<code>"

      Examples:
        | button  | code          |
        | left    | mouse-left    |
        | right   | mouse-right   |
        | middle  | mouse-middle  |
        | back    | mouse-back    |
        | forward | mouse-forward |

    Scenario: Mouse keystrokes share the same store as keyboard keystrokes
      Given the app is running with Input Monitoring granted
      When the user types the letter "a" and then clicks the left mouse button
      Then the heatmap totals include both events

  Rule: Recording is independent of the mute state

    Scenario: Muting the app does not pause recording
      Given the app is running with Input Monitoring granted
      And the app is muted
      When the user types the letter "a"
      Then one keystroke is recorded
      And no sound is played

  Rule: Samples are retained permanently

    Scenario: A keystroke recorded long ago remains visible
      Given a keystroke was recorded 30 days ago
      When the user opens the stats view with range "this month"
      Then that keystroke is included in the bucket totals

    Scenario: Restarting the app preserves previously recorded samples
      Given the app has recorded keystrokes during a prior run
      When the app is quit and relaunched
      Then all previously recorded samples are still present

  Rule: No data is recorded or backfilled while the app is not running

    Scenario: Hours when the app was quit show zero
      Given the app was quit from 10:00 to 14:00 today
      When the user opens the stats view with range "today" and unit "per hour"
      Then the buckets for 10:00 through 13:00 each show a count of 0

    Scenario: The app never fabricates missing data
      Given there are gaps in the recorded history
      When the user opens any stats view
      Then no interpolation, estimation, or backfill is applied to missing buckets
