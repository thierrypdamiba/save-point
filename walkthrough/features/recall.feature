@recall @integrity
Feature: Resurface repository knowledge for active recall
  As an engineer
  I want earlier concepts to return over time
  So that I can measure durable unaided understanding

  Scenario: Create a recall item from a completed answer
    Given the engineer completes an answer
    When Walkthrough records it
    Then a recall item links the question to its repository and concept
    And its schedule considers confidence, importance, quality, and prior mistakes

  Scenario: Drill intensively for 30 days
    Given repetition mode is "intensive_30d"
    And the engineer completed a concept today
    When Walkthrough schedules that concept
    Then the concept is due daily through day 30
    And missed or assisted concepts receive priority
    And the item records its "intensive_until" date

  Scenario: Graduate intensive items to adaptive spacing
    Given an intensive recall item has reached day 30
    When Walkthrough reschedules the item
    Then the item switches to adaptive spacing
    And its earlier attempt history remains available to the scheduler

  Scenario: Adapt intervals to performance
    Given repetition mode is "adaptive"
    When Walkthrough reschedules a completed attempt
    Then the interval considers quality, confidence, importance, mistakes, and assistance
    And it uses 1, 7, and 30 days as adjustable anchors

  Scenario: Record unaided recall
    Given a due question from a previously visited repository is shown
    When the engineer answers before opening source material or saved answers
    Then the attempt is recorded as unaided recall
    And the next interval reflects the answer quality and confidence

  Scenario: Record assisted recall
    Given a due question is shown
    When the engineer opens the old repository, saved walkthrough, or another aid before answering
    Then the attempt is recorded as assisted recall
    And reliance on the aid influences the next interval
    But the attempt is not misrepresented as unaided recall

  Scenario Outline: Do not turn deferral into failure
    Given a due question is shown
    When the engineer chooses <action>
    Then no failed recall attempt is recorded

    Examples:
      | action      |
      | "Later"     |
      | "Dismiss"   |
      | "Flow mode" |

  Scenario: Recall while working in another repository
    Given a recall item from "payments-service" is due
    And the engineer is working in "catalog-service"
    When an accepted workflow boundary occurs
    Then Walkthrough may show one question labeled as coming from "payments-service"
    But it does not load "payments-service" files or answers into the active coding context
