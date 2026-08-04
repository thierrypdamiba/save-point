@tuning @integrity
Feature: Apply the engineer's configured assistance policy
  As an engineer
  I want help when I do not know an answer
  So that Walkthrough builds knowledge before testing retention

  Background:
    Given a user profile exists
    And Walkthrough has asked a repository-grounded question

  Scenario: Tune through ordinary conversation
    When the engineer says "teach me first and focus on architecture"
    Then Walkthrough changes the current session without requiring configuration edits
    And the preference applies to subsequent questions

  Scenario Outline: Treat uncertainty as a learning signal
    When the engineer says <response>
    Then Walkthrough applies the saved "I don't know" policy
    And it does not treat the response as failed recall

    Examples:
      | response        |
      | "I don't know"  |
      | "no idea"       |
      | "I'm guessing"  |
      | "help me"       |

  Scenario: Offer a choice when configured
    Given the saved "I don't know" policy is "offer a choice"
    When the engineer says "I don't know"
    Then Walkthrough offers an explanation, hint, source trail, or skip
    And it waits for the engineer's choice

  Scenario: Skip directly to an explanation
    When the engineer asks for the answer
    Then Walkthrough explains the mechanism with repository evidence
    And the attempt is labeled as assisted
    And it asks the engineer to restate the concept in their own words

  Scenario: Convert teaching into later recall
    Given Walkthrough has explained a concept
    When the engineer restates it in their own words
    Then the restatement is saved as user-authored knowledge
    And a shorter unaided recall question is created for later

  Scenario Outline: Apply personal curation feedback
    When the engineer says <feedback>
    Then Walkthrough adjusts subsequent questions immediately
    And it stores the preference separately from repository answers when persistence is available

    Examples:
      | feedback              |
      | "too hard"            |
      | "too easy"            |
      | "less trivia"         |
      | "more architecture"   |
      | "show me code first"  |
      | "teach before testing"|
