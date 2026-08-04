@portability @mvp
Feature: Use the same Walkthrough skill across coding agents
  As an engineer who uses multiple coding agents
  I want one Walkthrough profile and behavior contract
  So that learning history and preferences do not fragment by client

  Scenario Outline: Load the native Agent Skill
    Given the same Walkthrough directory is installed for <host>
    When the engineer invokes Walkthrough
    Then <host> loads the same "SKILL.md" and supporting files
    And state is read from "~/.walkthrough/"

    Examples:
      | host        |
      | Codex       |
      | Claude Code |
      | Goose       |

  Scenario: Claude Code activates the MCP skills extension
    Given current Claude Code can connect to the Walkthrough MCP server
    When it discovers "io.modelcontextprotocol/skills"
    Then it can load Walkthrough through "skills/list" and "skills/get"
    And it verifies supporting resources against their advertised digests

  Scenario: A legacy MCP host uses compatibility tools
    Given an MCP host can connect to the Walkthrough MCP server
    But it does not activate the skills extension
    When its task matches Walkthrough
    Then it may call "list_skills" and "load_skill"
    And the loaded instructions match the native "SKILL.md"

  Scenario: An MCP host invokes the compatibility prompt
    Given the host can connect to the Walkthrough MCP server
    When the engineer invokes the server's "walkthrough" prompt
    Then the prompt injects the same Walkthrough instructions

  Scenario: Clients share runtime state
    Given Codex recorded a confirmed preference in "~/.walkthrough/profile.md"
    When another supported host starts Walkthrough
    Then that host honors the preference
    And it does not create a client-specific profile
