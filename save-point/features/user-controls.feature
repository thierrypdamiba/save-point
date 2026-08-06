@non_interruption @mvp
Feature: Let the engineer control Save Point
  As an engineer
  I want predictable commands and graceful fallbacks
  So that recall remains voluntary

  Scenario: Switch to intensive repetition
    When the engineer runs "/save-point repetition intensive"
    Then "repetition_mode" is saved as "intensive_30d"
    And completed concepts are drilled daily for 30 days
    And Save Point confirms raising "daily_limit" so drilling can fit under the caps
    And prior recall history is preserved

  Scenario: Switch to adaptive repetition
    Given repetition mode is intensive
    When the engineer runs "/save-point repetition adaptive"
    Then "repetition_mode" is saved as "adaptive"
    And future intervals respond to recall quality and assistance
    And prior recall history is preserved

  Scenario: Check due items on demand
    When the engineer runs "/save-point recall"
    Then due questions are served across all repositories, unless "cross_repo_recall" is "off"
    And delivery caps and flow mode do not block the user-invoked check
    And "prompts_today" is not incremented

  Scenario: Enter timed flow mode
    When the engineer runs "/save-point flow 4h"
    Then unsolicited recall prompts are suppressed for 4 hours across all repositories
    And "flow_until" is recorded in "scheduler.md" as a UTC instant
    And manually starting a playthrough remains available

  Scenario: Enter flow mode for the day
    When the engineer runs "/save-point flow today"
    Then unsolicited recall prompts are suppressed until the next local midnight
    And the local midnight is stored as a UTC instant

  Scenario: Resume interruptions
    Given flow mode is active
    When the engineer runs "/save-point resume"
    Then flow mode ends
    And due items wait for the next accepted workflow boundary
    And the command is about flow mode, not resuming a session — bare "/save-point" does that

  Scenario: Switch to manual-only recall permanently
    When the engineer runs "/save-point interruptions off"
    Then "interruption_style" is saved as "manual_only"
    And no unsolicited prompt is delivered until "/save-point interruptions on"
    And due items still surface whenever the engineer invokes Save Point

  Scenario: Inspect personal settings
    Given a user profile exists
    When the engineer runs "/save-point settings"
    Then Save Point shows the active learning and assistance preferences
    And it does not expose repository answers

  Scenario: Every command works as conversation
    When the engineer says "pause questions until tomorrow"
    Then Save Point applies the matching command behavior
    And it never requires the engineer to edit configuration files

  Scenario: Sidecar scheduling is unavailable
    Given the host cannot persist state or schedule background work
    When the engineer uses Save Point
    Then the in-session questioning flow remains available
    And Save Point states the unavailable capability accurately
    But it does not claim that recall was scheduled or persisted
