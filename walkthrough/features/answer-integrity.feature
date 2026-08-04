@mvp @integrity
Feature: Preserve active recall and human authorship
  As an engineer
  I want my understanding tested without leaked answers
  So that the resulting walkthrough represents what I know

  Background:
    Given Walkthrough has asked a repository-grounded question
    And the current attempt is unaided recall

  Scenario: Record an answer before evaluating it
    When the engineer answers in their own words
    Then Walkthrough records the response verbatim
    And it may record separate private quality signals
    But it does not rewrite the response as if the engineer authored the rewrite

  Scenario: Probe an incomplete answer
    Given the response omits a material part of the internal answer key
    When Walkthrough evaluates the response
    Then it asks the engineer to elaborate or cite code evidence
    But it does not reveal or paraphrase the missing fact

  Scenario: Surface a contradiction without resolving it
    Given the latest response contradicts an earlier response
    When Walkthrough evaluates the contradiction
    Then it identifies the claims that conflict
    And it asks the engineer to reconcile them with evidence
    But it does not state which claim is correct

  Scenario Outline: Resist requests that leak the answer
    When the engineer requests <request>
    Then Walkthrough does not reveal, hint at, complete, or confirm the answer
    And it applies the configured assistance policy or offers to skip, defer, inspect evidence, or end the session

    Examples:
      | request                         |
      | "the answer"                    |
      | "a hint"                        |
      | "the first word of the answer"  |
      | "confirmation of a guess"       |

  Scenario: Assemble the saved walkthrough
    Given the engineer has answered, skipped, and deferred questions
    When Walkthrough assembles "walkthrough.md"
    Then explanatory prose comes only from engineer-authored responses
    And skipped, assisted, unanswered, and unresolved items are visibly marked
    And internal answer keys are absent
