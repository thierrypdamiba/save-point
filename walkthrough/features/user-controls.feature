@non_interruption @mvp
Feature: Let the engineer control Walkthrough
  As an engineer
  I want predictable commands and graceful fallbacks
  So that recall remains voluntary

  Scenario: Switch to intensive repetition
    When the engineer runs "/walkthrough repetition intensive"
    Then "repetition_mode" is saved as "intensive_30d"
    And completed concepts are drilled daily for 30 days
    And prior recall history is preserved

  Scenario: Switch to adaptive repetition
    Given repetition mode is intensive
    When the engineer runs "/walkthrough repetition adaptive"
    Then "repetition_mode" is saved as "adaptive"
    And future intervals respond to recall quality and assistance
    And prior recall history is preserved

  Scenario: Enter timed flow mode
    When the engineer runs "/walkthrough flow 4h"
    Then recall interruptions are suppressed for 4 hours
    And manually starting a walkthrough remains available

  Scenario: Inspect personal settings
    Given a user profile exists
    When the engineer runs "/walkthrough settings"
    Then Walkthrough shows the active learning and assistance preferences
    And it does not expose repository answers

  Scenario: Enter flow mode for the day
    When the engineer runs "/walkthrough flow today"
    Then recall interruptions are suppressed until the next local day

  Scenario: Resume interruptions
    Given flow mode is active
    When the engineer runs "/walkthrough resume"
    Then flow mode ends
    And due items wait for the next accepted workflow boundary

  Scenario: Sidecar scheduling is unavailable
    Given the host cannot persist state or schedule background work
    When the engineer uses Walkthrough
    Then the in-session questioning flow remains available
    And Walkthrough states the unavailable capability accurately
    But it does not claim that recall was scheduled or persisted
