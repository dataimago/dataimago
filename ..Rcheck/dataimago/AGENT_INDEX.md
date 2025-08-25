# AGENT_INDEX.md: AI Agent Coordination for dataimago Package

## 🤖 Agent Capabilities Overview

This document provides a structured index of AI agent capabilities and interaction patterns for the `dataimago` R package. It serves as a coordination file for multiple AI agents working on package development, documentation, and philosophical alignment.

---

## 📋 Package Function Registry

### Documentation Generation Functions

#### `create_quarto_documentation()`
- **Purpose**: Generate ethical AI documentation from R package structure
- **Input Schema**: 
  ```json
  {
    "package_path": "string (directory path)",
    "output_path": "string (directory path, default: 'quarto_website')",
    "include_description": "boolean (default: true)",
    "include_foundation_links": "boolean (default: true)",
    "template": "string (default: 'dataimago')"
  }
  ```
- **Output**: File path to generated api_reference.qmd (invisible)
- **Side Effects**: Creates .qmd files, copies assets, applies dataimago branding
- **AI Context**: Embeds philosophical context into technical documentation
- **MCP Tool Name**: `create_quarto_documentation`

#### Supporting Functions
- `parse_description_file()`: Extract package metadata with ethical context
- `convert_rd_files_to_qmd()`: Convert .Rd files using Rd2md with dataimago annotations
- `update_dataimago_assets()`: Manage visual identity across platforms
- `post_process_md_to_qmd()`: Add philosophical context to generated documentation

---

## 🏗️ Package Structure for AI Navigation

### Primary Directories
```
inst/dataimago/01_Foundations/     # Core philosophical documents
inst/dataimago/02_Manifesto/       # Critical theory frameworks  
inst/dataimago/03_Application_Architecture/  # Technical blueprints
inst/dataimago/04_dataimago_Content/         # Design assets and branding
inst/CLAUDE.md                     # Primary AI context file
inst/AGENT_INDEX.md               # This coordination file
R/documentation_utils.R           # Core function implementations
man/*.Rd                          # Generated function documentation
quarto_website/                   # Website source files
docs/                            # Rendered website output
```

### Content Curation Logic
- **Included in Package**: Essential documents, core functions, key assets
- **Excluded via .Rbuildignore**: AI conversations, development notes, duplicate assets
- **Rationale**: Maintain philosophical depth while ensuring clean package distribution

---

## 🧠 Philosophical Context for AI Reasoning

### Core Principles
1. **Emancipatory Purpose**: All functions should serve human liberation, not domination
2. **Hermeneutic Transparency**: Maintain interpretive clarity in all operations
3. **Positivistic Rigor**: Ensure empirical accuracy and reproducibility
4. **Ethical Reflexivity**: Include affordances for users to interrogate their own usage

### Decision Framework
When evaluating code or documentation changes, ask:
- Does this advance dataimago's emancipatory vision?
- Is the implementation both philosophically sound and technically robust?
- Will this help AI agents understand the "why" behind the "what"?
- Does this maintain consistency with critical theory foundations?

---

## 🔧 MCP Tool Specifications

### Tool Definition Template
```json
{
  "name": "function_name",
  "description": "Brief description with ethical context",
  "parameters": {
    "param_name": {
      "type": "string|number|boolean|array|object",
      "description": "Detailed parameter description",
      "default": "default_value (if applicable)",
      "required": true|false
    }
  },
  "returns": {
    "type": "string|object|null",
    "description": "Return value specification"
  },
  "philosophical_context": "How this tool serves emancipatory goals"
}
```

### Current MCP-Ready Functions
1. **create_quarto_documentation**: Primary documentation generation tool
2. **parse_description_file**: Package metadata extraction (internal)
3. **update_dataimago_assets**: Visual identity management (internal)

### Planned MCP Functions
1. **get_foundation_document**: Retrieve philosophical content programmatically
2. **create_dataimago_app**: Generate ethical AI application skeletons
3. **bootstrap_emancipatory_framework**: Initialize projects with ethical foundations

---

## 📊 Agent Coordination Protocols

### Multi-Agent Collaboration
- **Primary Agent**: Responsible for core development and philosophical alignment
- **Documentation Agent**: Focuses on roxygen2 enhancement and MCP compatibility
- **Testing Agent**: Validates both technical functionality and ethical consistency
- **Foundation Agent**: Manages philosophical content and critical theory integration

### Communication Patterns
- Use standardized parameter naming across all functions
- Maintain consistent error handling and reporting
- Include philosophical context in all technical decisions
- Reference foundation documents when making architectural choices

### Conflict Resolution
When agents disagree on implementation:
1. **Consult Foundation Documents**: Refer to mission, vision, philosophy
2. **Apply Ethical Framework**: Does the solution serve emancipatory goals?
3. **Maintain Technical Rigor**: Ensure robust, replicable implementation
4. **Document Reasoning**: Include philosophical justification in commit messages

---

## 🔍 Quality Assurance for AI Agents

### Technical Validation
- [ ] All functions include comprehensive roxygen2 documentation
- [ ] Parameter types and constraints clearly specified
- [ ] Return values and side effects documented
- [ ] Examples demonstrate typical usage patterns
- [ ] Error conditions and handling documented

### Philosophical Validation
- [ ] Each function includes ethical context in @details section
- [ ] Implementation aligns with dataimago principles
- [ ] Documentation connects technical function to societal purpose
- [ ] Code embodies "hermeneutic transparency"
- [ ] Function serves emancipatory rather than dominating purposes

### MCP Compatibility
- [ ] Function parameters map cleanly to JSON schema
- [ ] Return values are structured and predictable
- [ ] Error messages are informative for debugging
- [ ] Documentation includes AI-friendly usage examples
- [ ] Philosophical context is machine-readable

---

## 🌀 Continuous Evolution

This index file should be updated whenever:
- New functions are added to the package
- MCP tool specifications change
- Philosophical frameworks evolve
- Agent coordination patterns improve
- Package structure modifications occur

**Last Updated**: 2025-07-02
**Version**: 0.0-0.1
**Coordinating Agents**: Claude (primary), dataimago development team

---

*"Every function you write here will one day be called by an AI, reasoning about how to improve schools, policies, or systems. Design accordingly."* - dataimago CLAUDE.md