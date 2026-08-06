@stats
Feature: Show progress statistics with every question
  As an engineer
  I want each question to carry my session and lifetime numbers
  So that I can see the playthrough building something durable

  Background:
    Given a user profile exists with "question_stats" set to "on"

  Scenario: Every question carries a stats line
    When Save Point presents a question, new or recall
    Then one line above the question shows the session tally and this repository's lifetime numbers
    And the session tally counts this session's closes by outcome
    And the lifetime numbers cover closes to date and the current recall state: items in rotation, stages, latest qualities
    And the line stays one line

  Scenario: Lifetime numbers come from the script, not memory
    When a session starts
    Then the lifetime baseline is read once via "scripts/stats.sh"
    And session increments are added on top of that baseline
    And the numbers shown never contradict what the state files hold

  Scenario: Lifetime scope is the current repository only
    Given recall items exist for other repositories
    When the stats line is composed
    Then it aggregates nothing from other repositories' state files
    And cross-repository reads stay limited to the scheduling frontmatter, as elsewhere

  Scenario: Deferred feedback freezes quality numbers
    Given feedback timing is "end_of_section"
    When questions close during a section
    Then the stats line updates counts that reveal no verdict, such as questions closed
    And quality-derived numbers stay frozen at their section-start values until the section boundary
    And a ticking solid counter never leaks a verdict the engineer chose to defer

  Scenario: An open question changes nothing
    Given a question is open
    When the stats line is shown with a follow-up probe
    Then no number has changed since the question was presented

  Scenario: First session shows an honest zero
    Given no savepoint or recall state exists for the repository
    When the first question is presented
    Then the lifetime side says this is the first session
    And no numbers are invented

  Scenario: Plain labels apply to the stats line
    Given the engineer said "plain labels"
    When the stats line is composed
    Then it uses neutral vocabulary consistent with the rest of the session

  Scenario: Turn the stats line off and on conversationally
    When the engineer says "stats off"
    Then "question_stats" is saved as "off" in the profile
    And questions are presented without the stats line
    And a later "stats on" restores it

  Scenario: Stats report status, never content
    When the stats line is composed
    Then it contains counts only — no question text, no answer text, no answer-key fact
    And an "unresolved" count is a status tally, not a verdict on any guess
