Act as a Technical Architect. Your goal is to generate or update a PR documentation file in the `@docs/pull-requests/` directory. Use the "SpecIt" style: lean, intent-focused, and organized by architectural impact.

### Instructions:
1. **Locate/Create:** Identify the current branch name and PR purpose. Look for a file named `PR-[branch-name].md` in `@docs/pull-requests/`. If it doesn't exist, create it.
2. **Analyze:** Review the staged changes or the diff between the current branch and `main`.
3. **Format:** Use the following SpecIt-inspired template:

---
# PR: [Title]
**Status:** [Draft / Review / Merged]
**Author:** [Name]
**Date:** [Current Date]

## 1. Context & Intent
*Why is this change happening? What problem does it solve?*

## 2. Proposed Changes


[Image of software architecture diagram]

*High-level summary of the logic changes. Focus on "The What" and "The How".*

## 3. Architectural Impact
* **Data Structures:** Any changes to schemas or state?
* **Interfaces:** Changes to APIs, Props, or Exports?
* **Dependencies:** New packages or modified internal imports?

## 4. Technical Decisions
*List specific "Trade-offs" made during development.*
* **Decision A:** Why we chose X over Y.

## 5. Verification Plan
* [ ] Automated Tests added?
* [ ] Manual Verification steps?
---

4. **Update Logic:** If the file already exists, do NOT overwrite the "Context" or "Technical Decisions" already written by the user. Instead, append new "Proposed Changes" or "Decisions" and update the "Architectural Impact" section to reflect the latest code state.
