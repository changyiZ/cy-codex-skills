# AGENTS.md

## Project overview
- Goal:
- Scope:
- Out of scope:
- Product design source of truth: `<path-to-design-doc>`

## Tech stack
- Languages:
- Frameworks:
- Package/build tools:
- Data/storage:

## Architecture
- Module boundaries:
- Data flow:
- Integration points:

## Commands
- Install: `<command>`
- Dev: `<command>`
- Test: `<command>`
- Build: `<command>`

## Code style
- Formatting/linting:
- Naming conventions:
- File organization rules:

## Patterns to follow
1.
2.
3.

## Things to avoid
1.
2.
3.

## Task linkage
- Work directory: `docs/work/<task-id>-<feature>/`
- Active pointer: `docs/work/.current`
- Required files: `meta.yaml`, `spec.md`, `status.md`, `decisions.md`
- Resolve priority:
  1. user-provided task id/url
  2. `.current` pointer
  3. branch parsing
  4. fallback `TODO-*` task folder

## Knowledge base
- Index: `knowledge/index.md`
- Source registry: `knowledge/sources.yaml`
- Change log: `knowledge/changelog.md`
- Local snapshots: `knowledge/authoritative/`
- Project knowledge: `knowledge/project/`
- Design docs (canonical): `knowledge/project/design/`
- Review cadence: `7` days

## Durable Knowledge Protocol
- Trigger:
  - architecture, command, packaging, or validation changes
  - repeated errors, pitfalls, or workaround patterns
  - new or changed authoritative knowledge sources
  - new durable verification evidence or changed verification status
  - repeated workflow steps that may deserve a reusable skill
- Task-close gate:
  - before marking a task complete, set `knowledge_review_status` in `docs/work/<task>/meta.yaml`
  - allowed values: `pending`, `not_needed`, `updated`, `followup_required`
  - if `followup_required`, record the missing updates in `knowledge_followups`
- Update targets:
  - rules/policy changes -> `AGENTS.md`
  - implementation snapshot changes -> `knowledge/project/current-state.md`
  - durable solution guidance -> `knowledge/project/`
  - source freshness or watch mappings -> `knowledge/sources.yaml`
  - all durable changes -> `knowledge/changelog.md`
- Skill-candidate rule:
  - if a workflow or pitfall-response pattern repeats across at least two tasks or repositories and has stable inputs, outputs, and validation, add it to `skill_candidates` and promote it into the durable-knowledge candidate flow
- Review window:
  - default stale threshold is `7` days unless the repository makes it stricter

## Update protocol
- Trigger:
  - architecture or command changes
  - repeated errors/pattern gaps
  - new or changed authoritative knowledge sources
  - new or changed durable verification conclusions
  - repeated workflow patterns that may deserve a reusable skill
  - task workflow changes
  - design docs added/moved/rewritten
- Workflow:
  1. read existing AGENTS.md
  2. review the active task metadata and durable-knowledge status first
  3. edit impacted sections only
  4. update task linkage and knowledge metadata if needed
  5. append update log entry
- Owner:

## Update log
- YYYY-MM-DD: initialized or updated <sections>, reason: <reason>
