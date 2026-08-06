@mvp @integrity
Feature: Start a repository playthrough
  As an engineer using AI-assisted development
  I want questions grounded in the repository
  So that I can test whether I understand the system

  Background:
    Given the current directory is a source repository
    And Save Point has read-only access to it

  Scenario Outline: Start at an explicit experience level
    When the engineer runs "/save-point start --level <level>"
    Then Save Point inspects the repository without modifying it
    And it creates a question path appropriate for "<level>"
    And it asks one open question at a time

    Examples:
      | level        |
      | new-engineer |
      | maintainer   |
      | operator     |

  Scenario: Quiz on a change instead of the whole repository
    Given the engineer just merged an AI-assisted change
    When the engineer runs "/save-point start --diff"
    Then Save Point inspects only the change since the last merge
    And questions cover what changed, why, what it touches, and what could break
    And the session is scoped to minutes, not a full curriculum

  Scenario: Organize questions as a playthrough
    When Save Point creates a question path
    Then major flows and subsystems are grouped as "Chapters"
    And data movement and component relationships are grouped as "Maps"
    And non-obvious invariants and historical decisions are grouped as "Secrets"
    And incidents, edge cases, and failures are grouped as "Boss fights"
    And synthesis questions are grouped as "New Game+", unlocked when every chapter reaches solid

  Scenario: Show the shape of the journey
    When a playthrough session starts
    Then Save Point presents the world map, such as "4 chapters, 2 secrets, 1 boss fight"
    And it announces chapter transitions, boss fights, and uncovered secrets as they arrive
    And at each chapter boundary and session end it shows a save point: what closed, chapter status, and what is due next
    But question content and answer keys stay private

  Scenario: Give every question a stable identity
    When Save Point creates a question
    Then the question gets an ID of "q" plus a per-repository ordinal
    And the ID never changes, even when the wording is later rotated

  Scenario: Resume without repeating covered ground
    Given recall items exist from an earlier session
    When a new session builds the question path from current source
    Then concepts already covered by items in "recall.md" are skipped

  Scenario: Repository scope is unavailable
    Given the current directory is not a source repository
    When the engineer starts Save Point
    Then Save Point explains that a repository is required for new questions
    And due recall items are still offered
    And it does not invent repository questions
