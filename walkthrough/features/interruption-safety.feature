@non_interruption @recall
Feature: Protect the engineer's active workflow
  As an engineer
  I want recall prompts only at safe moments
  So that Walkthrough does not disrupt development

  Background:
    Given a recall question is due
    And the daily limit and minimum gap permit another prompt

  Scenario Outline: Prompt at a natural boundary
    Given no suppression condition is active
    When <boundary> occurs
    Then Walkthrough may present at most one recall question

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
    Then Walkthrough does not present a recall question

    Examples:
      | condition                            |
      | a command is running                 |
      | the engineer is actively editing     |
      | tests are failing                    |
      | merge conflicts are unresolved       |
      | urgent debugging is active           |
      | the current agent task is incomplete |

  Scenario: Enforce default interruption limits
    Given the engineer has not customized interruption settings
    Then the daily limit is 3 prompts
    And the minimum gap is 90 minutes
    And each interruption contains 1 question
    And the default snooze is 4 hours

  Scenario: Host cannot deliver workflow boundaries
    Given the host exposes no accepted workflow boundaries
    When Walkthrough schedules a future recall item
    Then it keeps the item in "recall.md"
    And it explains that due items will be checked when Walkthrough is invoked
    But it does not claim that MCP can wake the host
