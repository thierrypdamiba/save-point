@privacy @mvp
Feature: Isolate Walkthrough state from repositories and coding agents
  As an engineer
  I want recall data kept separate
  So that historical knowledge does not contaminate active coding work

  Scenario: Store repository state globally
    Given Walkthrough has derived a collision-resistant repository ID
    When Walkthrough persists session state
    Then it writes beneath "~/.walkthrough/repositories/<repository-id>/"
    And it does not write into the source repository

  Scenario: Keep state categories separate
    When Walkthrough persists a repository session
    Then user-authored prose is stored in "walkthrough.md"
    And questions and schedules are stored in "recall.md"
    And internal answer keys are not included in "walkthrough.md"
    And answer text is not included in "recall.md"

  Scenario: Prevent cross-context answer leakage
    Given stored answers exist for "payments-service"
    And the engineer is working with a coding agent in "catalog-service"
    When the coding agent handles its active task without invoking Walkthrough
    Then it does not read the old repository's Walkthrough Markdown
    And stored answers and old repository files are not added to its context
    And the coding agent's task state is unchanged

  Scenario: Distinguish repositories with the same folder name
    Given two repositories have the same local folder name
    But they have different canonical remotes
    When Walkthrough derives their repository identities
    Then their global storage locations are different
