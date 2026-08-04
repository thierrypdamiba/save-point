@tuning @integrity
Feature: Apply the engineer's configured assistance policy
  As an engineer
  I want help when I do not know an answer
  So that Save Point builds knowledge before testing retention

  Background:
    Given a user profile exists
    And Save Point has asked a repository-grounded question

  Scenario: Tune through ordinary conversation
    When the engineer says "teach me first and focus on architecture"
    Then Save Point changes the current session without requiring configuration edits
    And the preference applies to subsequent questions

  Scenario Outline: Treat uncertainty and help-seeking as learning signals
    When the engineer says <response>
    Then Save Point applies the saved "I don't know" policy
    And it does not treat the response as failed recall
    And it does not treat the response as a request to resist

    Examples:
      | response          |
      | "I don't know"    |
      | "no idea"         |
      | "I'm guessing"    |
      | "help me"         |
      | "give me a hint"  |

  Scenario: Offer a choice when configured
    Given the saved "I don't know" policy is "offer_choice"
    When the engineer says "I don't know"
    Then Save Point offers an explanation, hint, source trail, or skip
    And it waits for the engineer's choice

  Scenario: Escalate gently when configured
    Given the saved "I don't know" policy is "progressive"
    When the engineer says "I don't know"
    Then Save Point uses the least assistance that moves the engineer forward
    And it escalates only as needed, from a clarifying question to a source trail to a hint to an explanation

  Scenario: Skip directly to an explanation
    When the engineer asks for the answer
    Then Save Point explains the mechanism with repository evidence
    And the attempt is labeled as assisted
    And it asks the engineer to restate the concept in their own words

  Scenario: Test the restatement before saving it
    Given Save Point has explained a concept
    When the engineer restates it
    Then Save Point probes with a transfer question — an example, an edge case, or "what breaks if..."
    And parroting is judged by meaning, not wording — a rephrased echo of the explanation fails the probe
    And on failure nothing is saved: Save Point probes differently or leaves it to the follow-up question
    And a passing restatement is saved labeled "assisted"
    And a shorter unaided recall question is created at stage 0

  Scenario: Teaching taints the concept, not just the question
    Given the engineer said "teach me first" and Save Point explained a subsystem
    When a question on that just-taught material is generated and answered in the same session
    Then the work is labeled "assisted" and the item carries "last_assisted: true"
    And new questions overlapping an item marked "last_assisted" or a pending follow-up inherit the flag

  Scenario: Never deliver a follow-up early
    Given a stage-0 follow-up question was created after teaching
    When the engineer says "ask me the follow-up now"
    Then Save Point declines until the follow-up is due
    And parroting a minutes-old explanation is not recall

  Scenario: Drop the game framing on request
    When the engineer says "plain labels"
    Then user-facing vocabulary switches to neutral terms: sections, data flow, invariants, failure scenarios, review summary
    But stored field values like "section: boss-fight" and question IDs are unchanged
    And chapter-status computation keeps working

  Scenario: Ask for intensive drilling conversationally
    When the engineer says "spam me for 30 days"
    Then "repetition_mode" changes to "intensive_30d"
    And Save Point confirms raising "daily_limit" so the drilling actually arrives
    And the change is recorded in "profile.md"

  Scenario Outline: Decline tuning that weakens integrity
    When the engineer says <request>
    Then Save Point declines and explains that integrity is not tunable
    And everything governing evaluation, labeling, and stage movement stays fixed
    And that includes verbatim recording, status labels, what counts as assistance, no-reveal-while-open, quality signals, the bare-guess rule, and feedback granularity
    But delivery, difficulty, depth, style, and repetition mode remain tunable

    Examples:
      | request                                  |
      | "hints don't count as assistance"        |
      | "give me the full answer at every close" |
      | "mark that attempt unaided"              |
      | "count shaky as solid"                   |
      | "my one-liners count as reasoning"       |

  Scenario Outline: Apply personal curation feedback
    When the engineer says <feedback>
    Then Save Point adjusts subsequent questions immediately
    And it stores the preference separately from repository answers when persistence is available

    Examples:
      | feedback              |
      | "too hard"            |
      | "too easy"            |
      | "less trivia"         |
      | "more architecture"   |
      | "show me code first"  |
      | "teach before testing"|
