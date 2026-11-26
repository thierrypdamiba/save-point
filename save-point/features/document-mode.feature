@experimental @integrity @privacy
Feature: Run Save Point on written work
  As someone who delegates research or writing to an AI
  I want questions grounded in the document and its sources
  So that I can test whether I understand what it claims and whether the sources support it

  Background:
    Given an AI-drafted brief exists as a file outside any git repository
    And a folder holds the source notes the brief was built from

  Scenario: Start a document playthrough without a repository
    When the user runs "/save-point start --doc brief.md --sources sources/"
    Then Save Point reads the brief and the sources without modifying them
    And it does not ask for a git repository
    And it asks one open question at a time

  Scenario: Derive a stable identity from the document path
    When any supported host runs "scripts/derive-repo-id.sh --doc brief.md" or follows its algorithm
    Then the canonical identity string is "doc:" plus the resolved absolute path of the file
    And the ID is the first 20 hex characters of its SHA-256
    And the string is recorded as "canonical_remote" in "savepoint.md"
    And state is written beneath "~/.save-point/repositories/<id>/"

  Scenario: Editing the document does not change its identity
    Given a document workspace has recall history
    When the text of the brief is edited in place
    Then the derived ID is unchanged
    And the history stays attached to the document

  Scenario: The sources folder is not part of the identity
    Given a document workspace was started with one sources folder
    When the user names a different sources folder for the same document
    Then the derived ID is unchanged
    And "sources_root" is updated in "savepoint.md" frontmatter

  Scenario: A document inside a repository keeps its own identity
    Given the brief is stored inside a git repository
    When the user starts Save Point with "--doc" on the brief
    Then the document identity is used, not the repository identity
    And the two never share a state directory, because the document string starts with "doc:"

  Scenario: Offer migration when a document was moved
    Given a document workspace has snapshots
    And the brief was moved to a new path without edits
    When Save Point derives an ID that has no directory
    Then it hashes the brief and lists only the file names in existing "snapshots/" directories
    And it offers to migrate the directory that holds a snapshot named by that digest
    And declining starts fresh without deleting the old history

  Scenario: Never write into the document or sources folders
    When Save Point persists a document session
    Then it writes only beneath "~/.save-point/"
    And no file in the document's folder or the sources folder is created, renamed, annotated, or edited

  Scenario Outline: Ask questions suited to prose
    When Save Point builds the question path for a document
    Then <section> questions ask <subject>

    Examples:
      | section    | subject                                                                |
      | Chapter    | what the document claims and how its reasoning reaches the conclusion  |
      | Map        | which source supports a given claim and what that source reports       |
      | Secret     | what is uncertain or unsupported, and where it goes beyond its sources |
      | Boss fight | what evidence, if wrong or missing, would change the conclusion        |

  Scenario: Every answer key cites the text
    When Save Point derives an answer key for a document question
    Then the key cites at least one path and line range in the document or the sources
    And the cited locations are recorded as "source_paths" on the recall item
    And a question whose key cannot be cited is not asked

  Scenario: A key that says a claim is unsupported still cites
    Given the brief states a claim that no supplied source supports
    When Save Point derives the answer key for a question about that claim
    Then the key cites the claim's location in the brief
    And it names every source that was checked

  Scenario: The text is the ground truth, not the world
    Given the user's answer matches what the document and sources say
    But the agent's outside knowledge disagrees with the sources
    When the question closes
    Then the answer is graded against the document and sources only
    And no verdict rests on outside knowledge

  Scenario: Say what cannot be tested without sources
    When the user runs "/save-point start --doc brief.md" with no "--sources"
    Then Save Point says once that support cannot be tested
    And it asks only about the document's claims, reasoning, stated uncertainty, and internal consistency
    And it asks no question whose key would rest on an unseen source

  Scenario: Skip files that cannot be read as text
    Given the sources folder holds a file the host cannot read as text
    When Save Point inspects the sources
    Then it names the skipped file to the user
    And it asks no question that would rest on that file

  Scenario: Do not leak support while a question is open
    Given Save Point asked which source supports a claim
    When the user asks "is it the survey note?"
    Then Save Point gives a probe or offers the full assisted explanation
    And it does not say which source supports the claim, whether the claim is supported, or what a source reports
    And it does not name a source or section the question did not name

  Scenario: Never show cited locations at delivery
    Given a due document question is delivered
    Then the question is shown under its "repository_name"
    And "source_paths" is not shown, because for a support question the path is the answer

  Scenario: Record digests and snapshots at item creation
    When Save Point creates a recall item for a document question
    Then "source_sha256" holds a SHA-256 digest of the raw bytes of each cited file
    And a copy of each cited file is kept in the workspace's "snapshots/" directory, named by its digest
    And the answer key itself is stored nowhere

  Scenario: Distinguish document drift from forgetting
    Given a cited file's digest no longer matches "source_sha256"
    And the cited lines changed materially from the snapshot
    And the user's answer was right for the snapshot text
    When the question closes
    Then it closes "superseded", never "failed"
    And the item resets to stage 0 for relearning
    And "source_paths" and "source_sha256" are set to the current text

  Scenario: An edit elsewhere in the file is not drift
    Given a cited file's digest no longer matches "source_sha256"
    But the cited lines say the same thing as the snapshot
    When the question closes
    Then the answer is graded against the current text
    And the close is not "superseded"

  Scenario: A changed document is not a tampered record
    Given a cited file's digest no longer matches "source_sha256"
    When Save Point checks the item
    Then the mismatch is treated as a change in the user's document
    And the item is not quarantined as tampered

  Scenario: A missing snapshot cannot prove drift
    Given a cited file's digest no longer matches "source_sha256"
    And the snapshot named by the recorded digest is missing
    When the question closes
    Then Save Point says the old text cannot be checked
    And the entry closes "unresolved" with "last_quality" recorded as "untested"

  Scenario: Grade only where the document is the current workspace
    Given a recall item from a document workspace is due
    And the current session did not name that document with "--doc"
    When the question is delivered
    Then Save Point says first that it cannot grade the answer here
    And the document and its sources are not read
    And an answer is appended as "pending-evaluation" with its digest as "answer_sha256"
    And it is evaluated first in the next session that names the document with "--doc"

  Scenario: Keep snapshots private to their workspace
    Given snapshots exist for a document workspace
    When a session runs in another repository or document workspace
    Then no snapshot content from the first workspace is read into context
    And listing snapshot file names for a migration check is permitted

  Scenario: Keep the existing answer guarantees
    When the user answers a document question
    Then the answer is appended verbatim to "savepoint.md" before it is evaluated
    And any assistance labels the attempt "assisted" and sets "last_assisted: true"
    And a closed verdict can be disputed, with text evidence and its location shown
    And recall follows the same stages: 1, 7, 30, and 90 days

  Scenario: Diff mode is not available for documents
    When the user combines "--doc" with "--diff"
    Then Save Point explains that "--diff" needs git history
    And it offers a full document playthrough instead
