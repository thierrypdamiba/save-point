@mvp @integrity
Feature: Preserve active recall and human authorship
  As an engineer
  I want my understanding tested without leaked answers
  So that the resulting walkthrough represents what I know

  Background:
    Given Save Point has asked a repository-grounded question
    And the current attempt is unaided recall

  Scenario: Record an answer before evaluating it
    When the engineer answers in their own words
    Then Save Point appends the response verbatim to "walkthrough.md" immediately, headed with the provisional status "open"
    And the close, skip, or defer relabels the heading to the final status
    And an interrupted session loses no recorded answers
    But it does not rewrite the response as if the engineer authored the rewrite

  Scenario: Probe an incomplete answer while the question is open
    Given the response omits a material part of the internal answer key
    When Save Point evaluates the response
    Then it asks the engineer to elaborate or cite code evidence
    And it names the gap only in terms the question's own wording already contains
    But it does not reveal or paraphrase the missing fact
    And it does not deliver a verdict while the question is open

  Scenario: Surface a contradiction without resolving it
    Given the latest response contradicts an earlier response
    When Save Point evaluates the contradiction
    Then it identifies the claims that conflict
    And it asks the engineer to reconcile them with evidence
    But it does not state which claim is correct

  Scenario: Deliver the verdict at question close
    Given feedback timing is "after_each"
    When the engineer finalizes a reasoned answer and the question closes
    Then Save Point states the recorded signal plainly: "solid", "shaky", or "failed"
    And it says which of the question's stated areas were covered, missed, or wrong
    And it may say a claim conflicts with the code without saying what the code does
    But it does not supply any missing fact

  Scenario: Close a bare guess without a verdict
    Given the engineer finalizes an answer with no grounded reasoning
    When the question closes
    Then the entry is labeled "unresolved" with "last_quality" recorded as "untested"
    And no verdict or coverage feedback is given
    And a guess cannot buy a confirmation

  Scenario: Pretext reasoning does not upgrade a guess
    Given the engineer asked "is it X?" and was probed
    When they finalize "X, because the config handles it" without code evidence
    Then the close is treated as a bare guess
    And reasoning earns a verdict only when grounded in code, behavior, or mechanism

  Scenario: Bound serial hypothesis-testing
    Given the engineer revises an open answer through successive guesses
    When Save Point recognizes verdict-fishing
    Then it probes once, then requires finalize, skip, or assistance
    And while open it flags contradictions only between the engineer's own claims

  Scenario: Teach freely after a close without corrupting the record
    Given a question has closed
    When the engineer asks to be taught the topic
    Then Save Point explains freely with code evidence
    And the closed attempt keeps its recorded label and signal
    And the item is marked "last_assisted: true" so the next attempt cannot advance the stage
    And the gap becomes a new stage-0 follow-up question

  Scenario: A vindicated dispute costs nothing
    Given a question closed with a verdict the engineer contests
    When the engineer runs "/save-point dispute" for it
    Then Save Point re-derives the answer key and shows its evidence openly
    And if the verdict was wrong, an "amended" entry with the corrected signal is appended under the same question ID
    And the schedule is recomputed as if the original close had carried the corrected signal
    And no assistance is recorded
    But the original entry is never rewritten

  Scenario: A failed dispute converts the shown evidence to assistance
    Given a question closed with a correct verdict
    When the engineer disputes it and the verdict stands
    Then the item is marked "last_assisted: true", since the evidence was revealed
    And the record is unchanged

  Scenario: A pre-due re-answer has no scheduling effect
    Given a question closed and its next due date has not arrived
    When the engineer answers it again
    Then there is no close, no quality signal, and no scheduling effect
    And the re-answer is "assisted" work
    And "last_assisted" is cleared only by the close of a due attempt

  Scenario: Aggregate feedback at the section boundary
    Given feedback timing is "end_of_section"
    When a chapter of questions completes
    Then Save Point gives the close feedback for the chapter's questions together
    And no per-question verdict was given while questions were open

  Scenario: A full explanation is always available at a price
    When the engineer requests "the answer"
    Then Save Point offers the full explanation
    And accepting converts the attempt to "assisted"
    But nothing is revealed while the attempt would stay unaided

  Scenario Outline: Never serve fragments or confirmations
    When the engineer requests <request>
    Then Save Point gives a probe or offers the full assisted explanation
    And the requested fragment or confirmation is never given

    Examples:
      | request                        |
      | "the first word of the answer" |
      | "confirmation of a guess"      |

  Scenario: Outside edits are detected best-effort, not prevented
    Given any agent-maintained field outside "profile.md" was altered outside a session
    When the alteration is apparent — a digest mismatch, an impossible value, or a label contradicting session history
    Then Save Point marks the affected item "unresolved" rather than trusting the edit
    And a pending answer whose text no longer matches its "answer_sha256" closes as "unresolved"
    And user edits are honored as-is only in "profile.md"
    And nothing prevents edits — the record's integrity is a mirror for the user, not a proof for an auditor

  Scenario: Skip before any answer exists
    Given a question was asked and no answer text was given
    When the engineer skips it
    Then a recall item is created or kept so the question returns
    But no "walkthrough.md" entry is written, since there is nothing verbatim to record

  Scenario: Assemble the saved walkthrough
    Given the engineer has answered, skipped, and deferred questions
    When Save Point updates "walkthrough.md"
    Then explanatory prose comes only from engineer-authored responses
    And every item carries one status from the walkthrough template's list, honestly applied
    And internal answer keys are absent
