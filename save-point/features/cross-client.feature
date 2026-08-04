@portability @mvp
Feature: Use the same Save Point skill across coding agents
  As an engineer who uses multiple coding agents
  I want one Save Point profile and behavior contract
  So that learning history and preferences do not fragment by client

  Scenario Outline: Load the native Agent Skill
    Given the same Save Point directory is installed for <host>
    When the engineer invokes Save Point
    Then <host> loads the same "SKILL.md" and supporting files
    And state is read from "~/.save-point/"

    Examples:
      | host        |
      | Codex       |
      | Claude Code |
      | Goose       |

  Scenario Outline: Derive one identity for one repository
    Given a repository's canonical remote is <remote>
    When any supported host runs "scripts/derive-repo-id.sh" or follows its algorithm
    Then the canonical identity string is <canonical>
    And the ID is the first 20 hex characters of its SHA-256

    Examples:
      | remote                                  | canonical           |
      | https://GitHub.com/Octo/API.git         | github.com/octo/api |
      | git@github.com:octo/api.git             | github.com/octo/api |
      | ssh://git@github.com:2222/octo/api/     | github.com/octo/api |
      | https://user:token@github.com/octo/api  | github.com/octo/api |
      | https://github.com:8443/octo/api.git    | github.com/octo/api |

  Scenario: Derive identity without an origin remote
    Given a repository has remotes but none named "origin"
    When any supported host derives the repository ID
    Then the bytewise-first remote name's fetch URL is used

  Scenario: Derive identity without any remote
    Given a repository has no remotes
    When any supported host derives the repository ID
    Then the absolute resolved repository root path is used verbatim
    And no lowercasing or normalization is applied to it

  Scenario: Migrate history when identity changes
    Given a repository was quizzed while keyed by its local path
    And it has since gained its first remote
    When Save Point derives an ID that has no directory
    Then it scans existing directories' "canonical_remote" values for the repository's previous identity
    And it offers to migrate the matching directory to the new ID
    And declining starts fresh without deleting the old history

  Scenario: Claude Code activates the MCP skills extension
    Given current Claude Code can connect to the Save Point MCP server
    When it discovers "io.modelcontextprotocol/skills"
    Then it can load Save Point through "skills/list" and "skills/get"
    And it verifies supporting resources against their advertised digests

  Scenario: A legacy MCP host uses compatibility tools
    Given an MCP host can connect to the Save Point MCP server
    But it does not activate the skills extension
    When its task matches Save Point
    Then it may call "list_skills" and "load_skill"
    And the loaded instructions match the native "SKILL.md"

  Scenario: An MCP host invokes the compatibility prompt
    Given the host can connect to the Save Point MCP server
    When the engineer invokes the server's "save-point" prompt
    Then the prompt injects the same Save Point instructions

  Scenario: Clients share runtime state
    Given Codex recorded a confirmed preference in "~/.save-point/profile.md"
    When another supported host starts Save Point
    Then that host honors the preference
    And it does not create a client-specific profile
    And delivery counts in "scheduler.md" span hosts, so the daily limit holds everywhere
