@architecture @privacy
Feature: Distribute Save Point as a skill over MCP
  As a Save Point user
  I want the skill and its templates supplied by an MCP catalog
  So that behavior can be installed without coupling runtime state to the server

  Scenario: Advertise the skills extension
    When an MCP client discovers the Save Point catalog
    Then the server advertises "io.modelcontextprotocol/skills" under capability extensions
    And it supports MCP protocol version "2026-07-28"
    And it retains the legacy initialization path

  Scenario: List the complete skill
    When the client calls "skills/list"
    Then the catalog contains the "save-point" skill
    And its frontmatter matches "SKILL.md"
    And every supporting file has a SHA-256 digest

  Scenario: Read every listed resource
    Given a resource is listed for the "save-point" skill
    When the client calls "resources/read" with its URI
    Then exactly that resource is returned
    And its bytes match the advertised digest

  Scenario: Navigate supporting directories
    Given the server advertises skills extension directory reading
    When the client calls "resources/directory/read" for a skill directory
    Then it receives only the direct child files and directories
    And directories use MIME type "inode/directory"

  Scenario: Keep runtime state out of MCP
    Given the Save Point skill is active
    When it persists a profile, answer, or recall schedule
    Then it writes a Markdown file beneath "~/.save-point/"
    And it does not require a stateful MCP tool

  Scenario: Support hosts without native extension activation
    When an MCP client lists ordinary tools and prompts
    Then it can discover read-only "list_skills" and "load_skill" tools
    And it can discover the "save-point" prompt
    And all three surfaces serve the same skill content

  Scenario: Initialize templates without a local skill directory
    Given the skill was loaded over MCP with "load_skill"
    And no local skill directory exists
    When Save Point initializes files under "~/.save-point/"
    Then it reads the "assets/" templates with "resources/read"
    And runtime state still lives beneath "~/.save-point/", never in MCP

  Scenario: MCP is unavailable after local installation
    Given the skill already exists in the local skills directory
    And the MCP catalog is disconnected
    When the engineer starts Save Point
    Then the Markdown-backed workflow remains available
