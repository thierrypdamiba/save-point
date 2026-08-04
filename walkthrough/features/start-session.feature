@mvp @integrity
Feature: Start a repository walkthrough
  As an engineer using AI-assisted development
  I want questions grounded in the repository
  So that I can test whether I understand the system

  Background:
    Given the current directory is a source repository
    And Walkthrough has read-only access to it

  Scenario Outline: Start at an explicit experience level
    When the engineer runs "/walkthrough start --level <level>"
    Then Walkthrough inspects the repository without modifying it
    And it creates a question path appropriate for "<level>"
    And it asks one open question at a time

    Examples:
      | level        |
      | new-engineer |
      | maintainer   |
      | operator     |

  Scenario: Organize questions as a walkthrough
    When Walkthrough creates a question path
    Then major flows and subsystems are grouped as "Chapters"
    And data movement and component relationships are grouped as "Maps"
    And non-obvious invariants and historical decisions are grouped as "Secrets"
    And incidents, edge cases, and failures are grouped as "Boss fights"
    And synthesis and evidence-heavy questions are grouped as "New Game+"

  Scenario: Repository scope is unavailable
    Given the current directory is not a source repository
    When the engineer starts Walkthrough
    Then Walkthrough explains that a repository is required
    And it does not invent repository questions
