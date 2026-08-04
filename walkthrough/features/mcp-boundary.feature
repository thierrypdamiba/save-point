@architecture @privacy
Feature: Distribute Walkthrough as a skill over MCP
  As a Walkthrough user
  I want the skill and its templates supplied by an MCP catalog
  So that behavior can be installed without coupling runtime state to the server

  Scenario: Advertise the skills extension
    When an MCP client discovers the Walkthrough catalog
    Then the server advertises "io.modelcontextprotocol/skills" under capability extensions
    And it supports MCP protocol version "2026-07-28"
    And it retains the legacy initialization path

  Scenario: List the complete skill
    When the client calls "skills/list"
    Then the catalog contains the "walkthrough" skill
    And its frontmatter matches "SKILL.md"
    And every supporting file has a SHA-256 digest

  Scenario: Read every listed resource
    Given a resource is listed for the "walkthrough" skill
    When the client calls "resources/read" with its URI
    Then exactly that resource is returned
    And its bytes match the advertised digest

  Scenario: Navigate supporting directories
    Given the server advertises skills extension directory reading
    When the client calls "resources/directory/read" for a skill directory
    Then it receives only the direct child files and directories
    And directories use MIME type "inode/directory"

  Scenario: Keep runtime state out of MCP
    Given the Walkthrough skill is active
    When it persists a profile, answer, or recall schedule
    Then it writes a Markdown file beneath "~/.walkthrough/"
    And it does not require a stateful MCP tool

  Scenario: Support hosts without native extension activation
    When an MCP client lists ordinary tools and prompts
    Then it can discover read-only "list_skills" and "load_skill" tools
    And it can discover the "walkthrough" prompt
    And all three surfaces serve the same skill content

  Scenario: MCP is unavailable after local installation
    Given the skill already exists in the local skills directory
    And the MCP catalog is disconnected
    When the engineer starts Walkthrough
    Then the Markdown-backed workflow remains available
