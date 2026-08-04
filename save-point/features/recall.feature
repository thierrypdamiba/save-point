@recall @integrity
Feature: Resurface repository knowledge for active recall
  As an engineer
  I want earlier concepts to return over time
  So that I can measure durable unaided understanding

  Scenario: Create a recall item from a completed answer
    Given the engineer completes an answer
    When Save Point records it
    Then a recall item links the question to its repository and concept
    And the item starts at stage 0 with a 1-day interval, whatever the close quality
    And importance is assigned at creation: 4-5 for load-bearing paths, 3 by default, 1-2 for details

  Scenario: Schedule an untested outcome
    Given a question closes as a bare guess, or work ends by skip or defer
    When the item is updated with "last_quality: untested"
    Then the item keeps its current stage
    And "due_at" is set to that moment plus the current stage's interval

  Scenario Outline: Apply deterministic adaptive transitions
    Given repetition mode is "adaptive"
    And a recall item is at stage <stage>
    When a subsequent close has quality <quality> and assistance <assisted>
    Then the first matching rule applies and the item moves to stage <next>
    And stages 0 through 3 map to intervals of 1, 7, 30, and 90 days

    Examples:
      | stage | quality | assisted | next |
      | 0     | solid   | false    | 1    |
      | 1     | solid   | false    | 2    |
      | 2     | solid   | false    | 3    |
      | 3     | solid   | false    | 3    |
      | 2     | solid   | true     | 2    |
      | 2     | shaky   | false    | 2    |
      | 2     | failed  | false    | 1    |
      | 0     | failed  | false    | 0    |
      | 1     | failed  | true     | 0    |

  Scenario: Assistance since the last close blocks advancement
    Given a concept was explained after its question closed
    And the item is marked "last_assisted: true"
    When the next close is solid
    Then the item keeps its current stage
    And the flag is cleared for the following interval

  Scenario: Cap high-importance items at stage 2
    Given a recall item has importance 4 or 5
    When a solid unaided close would advance it to stage 3
    Then the item stays at stage 2
    And it continues to return roughly every 30 days

  Scenario: Drill intensively for 30 days
    Given repetition mode is "intensive_30d"
    And the engineer completed a concept today
    When Save Point schedules that concept
    Then the concept is due daily through day 30
    And the item records its "intensive_until" date
    And rotated question wording keeps the same question ID

  Scenario: Order delivery the same way in every mode
    Given more items are deliverable than will be served
    When Save Point selects questions to deliver
    Then it delivers "failed" items first, then "assisted" items, then the oldest due items
    And the same order applies in adaptive and intensive modes

  Scenario: Graduate intensive items to adaptive spacing
    Given an intensive recall item has reached day 30
    When Save Point reschedules the item
    Then the item switches to adaptive spacing at its current stage
    And its earlier attempt history remains available to the scheduler

  Scenario: Record unaided recall
    Given a due question from a previously visited repository is shown
    When the engineer answers before opening source material or saved answers
    Then the attempt is recorded as unaided recall
    And Save Point asks lightly whether the answer came from memory, since out-of-session aids are self-reported

  Scenario: Record assisted recall
    Given a due question is shown
    When the engineer opens the old repository, saved walkthrough, or another aid before answering
    Then the attempt is recorded as assisted recall
    And the item does not advance a stage
    But the attempt is not misrepresented as unaided recall

  Scenario Outline: Do not turn deferral into failure
    Given a due question is shown
    When the engineer chooses <action>
    Then no failed recall attempt is recorded

    Examples:
      | action      |
      | "Later"     |
      | "Dismiss"   |
      | "Flow mode" |

  Scenario: Snooze re-offers after the configured delay
    Given a due question is shown
    When the engineer chooses "Later"
    Then "snoozed_until" is set on the item using "default_snooze"
    And the item is not offered again until that instant passes

  Scenario: Dismissal waits for the next day
    Given a due question is shown
    When the engineer dismisses it
    Then "dismissed_on" records the local date
    And the item stays due for invoked recall
    But it is not delivered unsolicited until the next local day

  Scenario: Evaluate recall inside the question's repository
    Given a due question belongs to the repository the engineer is working in
    When the engineer answers
    Then Save Point re-derives the answer key from current source before judging
    And the current code is the ground truth, even if it changed since the question was written

  Scenario: Disclose deferred grading before the answer, not after
    Given a recall item from "payments-service" is due
    And the engineer is working in "catalog-service"
    When the question is delivered
    Then Save Point says first that it cannot grade the answer here
    And it offers the choice to answer now or defer
    And choosing defer records a dismissal

  Scenario: Defer evaluation outside the question's repository
    Given a recall item from "payments-service" is due
    And the engineer is working in "catalog-service"
    When the engineer chooses to answer
    Then the answer is blindly appended to the "payments-service" walkthrough headed "pending-evaluation" with the attempt's classification
    And the item records "pending_evaluation: true" and the answer's digest as "answer_sha256"
    And "last_assisted" is set true only if the attempt was assisted, and an existing true is never cleared
    And the "recall.md" frontmatter summary is refreshed — a permitted scan
    And this is not a close: no quality signal, no verdict, no feedback, and no reschedule
    And the item is excluded from all delivery until evaluated
    And assistance beyond defer or skip is unavailable, and Save Point says it awaits in the origin repository
    And no "payments-service" files or answers are loaded into the active coding context

  Scenario: Evaluate pending answers on return
    Given "payments-service" has answers labeled "pending-evaluation"
    When a Save Point session starts inside "payments-service"
    Then only the pending entries are read, and they are evaluated first against current source
    And an answer that no longer matches its "answer_sha256" closes as "unresolved"
    And each other evaluation is that question's close: feedback, quality signal, relabel to the classification recorded in its heading
    And the next interval anchors at evaluation time
