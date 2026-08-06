@privacy @mvp
Feature: Isolate Save Point state from repositories and coding agents
  As an engineer
  I want recall data kept separate
  So that historical knowledge does not contaminate active coding work

  Scenario: Store repository state globally
    Given Save Point has derived a collision-resistant repository ID
    When Save Point persists session state
    Then it writes beneath "~/.save-point/repositories/<repository-id>/"
    And it does not write into the source repository

  Scenario: Keep state categories separate
    When Save Point persists a repository session
    Then user-authored prose is stored in "savepoint.md"
    And questions and schedules are stored in "recall.md"
    And global delivery state is stored in "~/.save-point/scheduler.md"
    And internal answer keys are not included in "savepoint.md"
    And answer text is not included in "recall.md"

  Scenario: Prevent cross-context answer leakage
    Given stored answers exist for "payments-service"
    And the engineer is working with a coding agent in "catalog-service"
    When the coding agent handles its active task without invoking Save Point
    Then it does not read the old repository's Save Point Markdown
    And stored answers and old repository files are not added to its context
    And the coding agent's task state is unchanged

  Scenario: Scope the no-read rule precisely
    Given a due item from another repository is being delivered
    When Save Point reads that repository's "recall.md" for the due item
    Then the read is permitted
    And blindly appending to that repository's "savepoint.md" is permitted
    But reading that repository's "savepoint.md" content is not

  Scenario: Distinguish repositories with the same folder name
    Given two repositories have the same local folder name
    But they have different canonical remotes
    When Save Point derives their repository identities
    Then their global storage locations are different
