@sounds @packs
Feature: Custom Sound Pack Import
  As the app owner
  I want to add my own sound packs by dropping folders onto the app
  So that I can use packs from mechvibes.com, friends, or my own builds without waiting for an app update

  Background:
    Given the menu-bar popover is open
    And the packs directory is "~/Library/Application Support/Thockspace/packs"

  Rule: Packs are imported by dragging a folder onto the popover drop target

    Scenario: Dropping a valid Mechvibes pack imports it
      Given a folder named "holy-panda-modded" containing a valid "config.json" and .wav samples
      When the user drags the folder onto the popover drop target
      Then the pack appears in the profile picker
      And the pack can be selected

    Scenario: Dropping a single file is not an import
      Given a single file "click.wav"
      When the user drags the file onto the popover drop target
      Then nothing is imported
      And the user is shown an import rejection reason

  Rule: Only Mechvibes-format packs with .wav samples are supported

    Scenario: A valid Mechvibes multi-file pack imports cleanly
      Given a pack whose "config.json" declares "key_define_type": "multi" and references .wav samples that all exist
      When the user drops the folder onto the popover
      Then the pack imports successfully
      And every referenced sample is loaded

    Scenario: A pack referencing only .ogg samples imports with a warning and plays no sound
      Given a pack whose "config.json" is valid but all referenced samples are .ogg files
      When the user drops the folder onto the popover
      Then the pack is imported with a warning that no samples could be loaded
      And selecting the pack produces no sound for any input

  Rule: Import copies the folder into the managed packs directory; the source is not tracked afterwards

    Scenario: After import, the source folder can be safely deleted
      Given the user has just imported a pack from "~/Downloads/holy-panda-modded"
      When the user deletes "~/Downloads/holy-panda-modded"
      Then the imported pack still appears and plays correctly

    Scenario: The imported pack lives under the managed packs directory
      When the user imports a folder named "my-pack"
      Then a directory "~/Library/Application Support/Thockspace/packs/my-pack" exists
      And its contents mirror the dropped folder

  Rule: The pack id is the folder name under the packs directory; the display name is the config.json "name" field or, absent that, the folder name

    Scenario: Display name comes from config.json when present
      Given the imported folder is "holy-panda-modded" and its config.json "name" is "Holy Panda Modded v2"
      When the profile picker is shown
      Then the pack row reads "Holy Panda Modded v2"

    Scenario: Display name falls back to folder name when config.json has no "name"
      Given the imported folder is "holy-panda-modded" and its config.json has no "name" field
      When the profile picker is shown
      Then the pack row reads "holy-panda-modded"

    Scenario: The persisted selection uses the folder name
      Given the user selects an imported pack
      When the app is quit and relaunched
      Then the same pack is active, identified by its folder name

  Rule: On id collision, the destination folder name is suffixed until unique

    Scenario: Dropping the same folder name twice creates a suffixed copy
      Given the packs directory already contains "holy-panda"
      When the user drops another folder also named "holy-panda"
      Then a new directory "holy-panda-2" is created under the packs directory
      And the source folder is not modified

    Scenario: Suffix increments past conflicts
      Given the packs directory already contains "holy-panda" and "holy-panda-2"
      When the user drops another folder named "holy-panda"
      Then a new directory "holy-panda-3" is created

  Rule: Import validation is tiered — structural errors reject; partial errors warn

    Scenario: A folder without config.json is rejected
      Given a folder with no "config.json"
      When the user drops it onto the popover
      Then an alert explains the structural error
      And nothing is copied into the packs directory

    Scenario: A folder with unparseable config.json is rejected
      Given a folder whose "config.json" is not valid JSON
      When the user drops it onto the popover
      Then an alert explains the structural error
      And nothing is copied into the packs directory

    Scenario: A pack with some missing samples imports with a warning
      Given a folder whose "config.json" is valid but 3 referenced .wav files are missing
      When the user drops it onto the popover
      Then the pack is imported
      And a warning notes the 3 missing samples
      And the pack plays sound for the keys whose samples loaded successfully

  Rule: The profile picker shows bundled packs first, then imported packs alphabetically

    Scenario: Picker order is deterministic
      Given the imported packs, by display name, are "Zebra" and "Alpha"
      When the profile picker is opened
      Then the rows appear in this order: "Cherry MX Blue", "Holy Panda", "Cherry MX Red", "Alpha", "Zebra"

    Scenario: The three bundled packs are always present
      Given the packs directory is empty
      When the profile picker is opened
      Then the rows shown are "Cherry MX Blue", "Holy Panda", "Cherry MX Red"

  Rule: A dedicated "Manage Packs" window lists imported packs for deletion; bundled packs are not shown

    Scenario: Manage Packs lists only imported packs
      Given there are two imported packs and three bundled packs
      When the user opens "Manage Packs" from the popover
      Then the window lists exactly the two imported packs
      And the three bundled packs are not shown

    Scenario: Bundled packs are not removable
      When the user opens "Manage Packs" with no imported packs
      Then the list is empty

  Rule: Deleting the currently-active imported pack is allowed with a confirmation; playback falls back to Cherry MX Blue

    Scenario: Non-active delete asks for simple confirmation
      Given the active profile is "cherry-mx-blue"
      And an imported pack "my-pack" exists
      When the user triggers delete on "my-pack"
      Then a confirmation dialog asks "Remove 'my-pack'?"
      And on confirm, the pack directory is removed
      And the active profile is unchanged

    Scenario: Active delete warns about fallback
      Given the active profile is "my-pack"
      When the user triggers delete on "my-pack"
      Then the confirmation dialog mentions that playback will switch to Cherry MX Blue
      And on confirm, the pack directory is removed
      And the active profile becomes "cherry-mx-blue"

  Rule: The packs directory is scanned on app launch and after in-app mutations; external Finder changes are picked up only on relaunch

    Scenario: In-app import updates the picker immediately
      When the user imports a pack
      Then the new pack appears in the profile picker without restarting the app

    Scenario: In-app delete updates the picker immediately
      When the user deletes an imported pack through Manage Packs
      Then the pack disappears from the profile picker without restarting the app

    Scenario: Finder-level additions require a relaunch
      Given the user copies a valid pack folder into the packs directory using Finder while the app is running
      When the user opens the profile picker
      Then the new pack is not yet listed
      When the user quits and relaunches the app
      Then the new pack is listed
