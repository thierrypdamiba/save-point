@onboarding @tuning
Feature: Configure Walkthrough before the first quiz
  As a new Walkthrough user
  I want an optional setup session
  So that questions and assistance behave the way I prefer

  Scenario: Offer setup before the first repository question
    Given no user profile exists
    When the engineer starts Walkthrough
    Then Walkthrough offers a short setup session
    And "Skip" is presented with equal prominence
    And no repository question is asked until the engineer chooses

  Scenario: Configure one preference at a time
    Given the engineer accepts setup
    When Walkthrough configures their profile
    Then it asks one question at a time
    And it asks for their primary goal
    And it asks what to do when they say "I don't know"
    And it asks for difficulty and depth
    And it asks when feedback should be given
    And it asks whether repetition should be intensive for 30 days or adaptive

  Scenario Outline: Configure I-don't-know behavior
    Given the engineer is selecting an "I don't know" policy
    When they select <policy>
    Then Walkthrough saves <policy> as the default response to uncertainty

    Examples:
      | policy                 |
      | explain immediately    |
      | give a hint            |
      | show a source trail    |
      | offer a choice         |
      | skip and revisit later |

  Scenario: Confirm before saving setup
    Given the engineer has answered the setup questions
    When Walkthrough presents a concise profile summary
    Then the engineer may confirm or revise it
    And the profile is not persisted until they confirm
    And the confirmed profile is written to "~/.walkthrough/profile.md"

  Scenario: Skip first-time setup
    Given no user profile exists
    When the engineer skips setup
    Then Walkthrough starts with conservative defaults
    And it offers a choice when the engineer says "I don't know"
    And repetition mode is adaptive
    And it does not offer setup again automatically
    And "/walkthrough setup" remains available

  Scenario: Reconfigure later
    Given a user profile exists
    When the engineer runs "/walkthrough setup"
    Then Walkthrough starts the setup session with current values
    And changes do not affect historical attempt labels
