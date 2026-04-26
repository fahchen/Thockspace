@sounds @mouse
Feature: Mouse Button Sounds
  As the app owner
  I want mouse button clicks to play a mechanical sound like the keyboard does
  So that the whole input experience feels like a single "fancy mechanical" device

  Background:
    Given the app is running with Input Monitoring granted
    And a keyboard profile is loaded

  Rule: Both mouse button-down and button-up trigger a sound, mirroring the keyboard

    Scenario: A left click plays both down and up sounds
      When the user presses and releases the left mouse button
      Then a down-sample is played on press
      And an up-sample is played on release

    Scenario: The up-sample is softer than the down-sample
      When the user presses and releases the left mouse button
      Then the up-sample is played at a lower gain than the down-sample

  Rule: Five mouse buttons are in scope; scroll and move are ignored

    Scenario Outline: Each supported button plays a sound
      When the user presses the <button> mouse button
      Then a sound is played

      Examples:
        | button  |
        | left    |
        | right   |
        | middle  |
        | back    |
        | forward |

    Scenario: Scrolling the wheel plays nothing
      When the user scrolls the mouse wheel
      Then no sound is played

    Scenario: Moving the mouse plays nothing
      When the user moves the mouse across the screen
      Then no sound is played

  Rule: Mouse samples come from the active keyboard profile through a fixed button-to-key map

    Scenario Outline: Mouse buttons borrow keyboard-key samples
      Given the active profile is "<profile>"
      When the user presses the <button> mouse button
      Then the sound played is the "<source key>" sample from profile "<profile>"

      Examples:
        | profile          | button  | source key |
        | cherry-mx-blue   | left    | Space      |
        | cherry-mx-blue   | right   | Return     |
        | cherry-mx-blue   | middle  | Tab        |
        | cherry-mx-blue   | back    | Backspace  |
        | cherry-mx-blue   | forward | Escape     |
        | holy-panda       | left    | Space      |

    Scenario: Switching the profile changes the mouse sound on the next click
      Given the active profile is "cherry-mx-blue"
      And the user has just clicked the left mouse button
      When the user changes the profile to "holy-panda"
      And the user clicks the left mouse button again
      Then the sound played is the "Space" sample from profile "holy-panda"

  Rule: Mouse playback gain is half the current master volume

    Scenario: Mouse clicks play at 50% of master gain
      Given the master volume is set to 1.0
      When the user clicks the left mouse button
      Then the effective playback gain is approximately 0.50

    Scenario: Mouse gain scales proportionally with master volume
      Given the master volume is set to 0.5
      When the user clicks the left mouse button
      Then the effective playback gain is approximately 0.25

  Rule: Global Mute silences both keyboard and mouse

    Scenario: Muting silences mouse clicks
      Given Mute is on
      When the user clicks the left mouse button
      Then no sound is played

    Scenario: There is no independent mouse sound toggle
      When the user opens the menu-bar popover
      Then no control dedicated to mouse sounds is present
      And the existing Mute button applies to both keyboard and mouse

  Rule: Mouse spatial placement is a fixed right-side position; stereo fallback when Spatial Audio is off

    Scenario: With Spatial Audio on, mouse clicks pan to the listener's right
      Given Spatial Audio is enabled
      When the user clicks the left mouse button
      Then the sound is rendered at a fixed right-side 3D position
      And a small per-click position jitter is applied so repeated clicks do not sound identical

    Scenario: With Spatial Audio off, mouse clicks are center-panned stereo
      Given Spatial Audio is disabled
      When the user clicks the left mouse button
      Then the sound is rendered as stereo with no spatial panning

    Scenario: All five mouse buttons share the same spatial position
      Given Spatial Audio is enabled
      When the user presses left, then right, then middle, then back, then forward
      Then every resulting sound is rendered from the same fixed right-side position (subject to jitter)

    Scenario: Left-handed mouse placement is not supported in v1
      When the user opens the menu-bar popover
      Then no "Mouse side" or "Left-handed" control is shown

  Rule: Mouse sounds require no additional macOS permission beyond Input Monitoring

    Scenario: Mouse clicks sound immediately once Input Monitoring is granted
      Given Input Monitoring is granted for the app
      When the user clicks the left mouse button
      Then a sound is played
      And no additional permission prompt is raised

    Scenario: Revoking Input Monitoring silences mouse clicks
      Given Input Monitoring is revoked from the app
      When the user clicks the left mouse button
      Then no sound is played
