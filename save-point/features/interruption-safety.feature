@non_interruption @recall
Feature: Protect the engineer's active workflow
  As an engineer
  I want recall prompts only at safe moments
  So that Save Point does not disrupt development

  Background:
    Given a recall question is due
    And the daily limit and minimum gap permit another prompt

  Scenario Outline: Prompt at a natural boundary
    Given no suppression condition is active
    When <boundary> occurs
    Then Save Point may present at most "questions_per_interruption" questions, 1 by default

    Examples:
      | boundary                         |
      | tests finish successfully        |
      | a commit completes               |
      | a pull request opens or merges   |
      | the active repository changes    |
      | a session starts or ends         |
      | a period of inactivity completes |

  Scenario Outline: Suppress during focused or risky work
    Given <condition>
    When a possible boundary occurs
    Then Save Point does not present a recall question

    Examples:
      | condition                            |
      | a command is running                 |
      | the engineer is actively editing     |
      | tests are failing                    |
      | merge conflicts are unresolved       |
      | urgent debugging is active           |
      | the current agent task is incomplete |

  Scenario: Explain the rules at the first interruption
    Given no unsolicited prompt has ever been delivered
    When the first one is delivered
    Then it explains the cadence: at most "daily_limit" per day at natural moments
    And it names the exits: "flow" to pause and "interruptions off" for manual-only

  Scenario: Enforce default interruption limits
    Given the engineer has not customized interruption settings
    Then the daily limit is 3 prompts
    And the minimum gap is 90 minutes
    And each interruption contains 1 question
    And the default snooze is 4 hours
    And the limits are read from "profile.md"

  Scenario: Track delivery limits globally
    Given 2 prompts were delivered today for "payments-service"
    And 1 prompt was delivered today for "catalog-service"
    When another boundary occurs anywhere
    Then the daily limit of 3 is already reached
    And no further unsolicited prompt is delivered today
    And the counts live in "~/.save-point/scheduler.md", not in any repository's files

  Scenario: Reset the daily count on the user's local midnight
    Given "prompt_date" holds the local date of the last delivery
    When the current local date differs from "prompt_date"
    Then "prompts_today" resets to 0
    And a UTC date change alone does not reset the count

  Scenario: Never cap what the engineer invokes
    Given the daily limit is exhausted
    When the engineer runs "/save-point" or "/save-point recall"
    Then due questions are still served
    And the session does not increment "prompts_today"

  Scenario: Turn unsolicited delivery off permanently
    Given "interruption_style" is "manual_only"
    When any boundary occurs
    Then no unsolicited prompt is ever delivered
    And due items surface only when the engineer invokes Save Point

  Scenario: Read only scheduling state at boundaries
    When Save Point checks whether to prompt at a boundary
    Then it reads only "profile.md" frontmatter, "scheduler.md", and each "recall.md" frontmatter
    And dueness is decided by whether "next_due_at" has passed, never by the advisory "due_count"
    And an item is deliverable unsolicited when "pending_evaluation" is false, max("due_at", "snoozed_until") has passed, and "dismissed_on" is not today
    And it does not read any "walkthrough.md"
    And delivery then reads just the due item's section

  Scenario: A host prompt hook surfaces due counts
    Given "scripts/check-due.sh" is registered as a host prompt hook
    When it runs
    Then it reads only "profile.md", "scheduler.md", and "recall.md" frontmatter
    And it stays silent under flow mode, manual-only style, the daily cap, or the minimum gap
    And when recall is due it emits a one-line nudge naming the repositories
    But delivery, suppression, and counter updates remain the skill's job

  Scenario: Host cannot deliver workflow boundaries
    Given the host exposes no accepted workflow boundaries
    When Save Point schedules a future recall item
    Then it keeps the item in "recall.md"
    And it explains that due items will be checked when Save Point is invoked
    But it does not claim that MCP can wake the host
