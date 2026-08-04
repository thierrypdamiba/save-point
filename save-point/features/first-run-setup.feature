@onboarding @tuning
Feature: Configure Save Point before the first quiz
  As a new Save Point user
  I want an optional setup session
  So that questions and assistance behave the way I prefer

  Scenario: Offer setup before the first repository question
    Given no user profile exists, or the existing profile's "setup_status" is "unset"
    When the engineer starts Save Point
    Then Save Point offers a short setup session
    And "Skip" is presented with equal prominence
    And no repository question is asked until the engineer chooses

  Scenario: Configure one preference at a time
    Given the engineer accepts setup
    When Save Point configures their profile
    Then it asks exactly five questions, one at a time
    And it asks for their primary goal
    And it asks what to do when they say "I don't know"
    And it asks for difficulty
    And it asks for preferred depth
    And it asks when feedback should be given
    And each question presents the legal values documented in the profile template
    But it does not ask about repetition mode

  Scenario Outline: Configure I-don't-know behavior
    Given the engineer is selecting an "I don't know" policy
    When they select <policy>
    Then Save Point saves <policy> as the default response to uncertainty

    Examples:
      | policy                 |
      | explain immediately    |
      | give a hint            |
      | show a source trail    |
      | offer a choice         |
      | skip and revisit later |
      | progressive            |

  Scenario: Confirm before saving setup
    Given the engineer has answered the setup questions
    When Save Point presents a concise profile summary
    Then the engineer may confirm or revise it
    And "profile.md" is written only at confirmation, with "setup_status" set to "confirmed"
    And an abandoned setup leaves no confirmed profile, so setup is offered again next time

  Scenario: Skip first-time setup
    Given no user profile exists
    When the engineer skips setup
    Then "profile.md" is written with the template defaults and "setup_status" set to "skipped"
    And Save Point offers a choice when the engineer says "I don't know"
    And repetition mode is adaptive
    And it does not offer setup again automatically
    And "/save-point setup" remains available

  Scenario: Offer intensive drilling when the choice is informed
    Given "intensive_offered" is false in the profile
    When the first session reaches its closing save point
    Then Save Point offers 30-day intensive drilling once
    And "intensive_offered" is set true whatever the answer, so no session offers it again
    And accepting triggers the same raised "daily_limit" confirmation as any switch to intensive

  Scenario: Reconfigure later
    Given a user profile exists
    When the engineer runs "/save-point setup"
    Then Save Point starts the setup session with current values
    And changes do not affect historical attempt labels
