# Godot Official Docs Policy

Use Godot's official documentation and official demo projects as the first source of truth.

Godot does not currently provide an official `llms.txt` entrypoint. This skill supplies a local routing layer so the agent can stay concise while still grounding API decisions in official sources.

## Read Order

1. `references/llm.txt`
   - Use for fast navigation and deciding which official source matters.
2. `references/llm-medium.txt`
   - Use for common implementation patterns and AI-friendly engineering defaults.
3. Official stable docs
   - Default source for supported API facts and behavior.
   - Root: https://docs.godotengine.org/en/stable/
4. Official latest docs
   - Use only when checking unreleased, recently changed, or unstable behavior.
   - Root: https://docs.godotengine.org/en/latest/
5. Official class reference or editor-integrated class reference
   - Use for exact properties, methods, signals, enums, and option names.
   - Class reference root: https://docs.godotengine.org/en/stable/classes/index.html
   - Editor reference overview: https://docs.godotengine.org/en/stable/getting_started/introduction/first_look_at_the_editor.html
6. Official demo projects
   - Use for runnable pattern references, not as the primary API authority.
   - Repo: https://github.com/godotengine/godot-demo-projects
7. Skill engineering references
   - Use local references such as `godot-architecture.md`, `50-testing.md`, `60-decoupling.md`, and `workflows.md` for architecture and validation tradeoffs.
   - Use `80-release-policy.md` when the task needs engine version selection or upgrade guidance.
8. Optional supplemental references
   - Use only when the user explicitly asks for them or when official docs are insufficient for end-to-end shape.

## Source-of-Truth Rules

1. Official Godot docs and official demo projects beat community posts, forum threads, blogs, and videos.
2. If the repository pins a Godot version, the repo version beats generic stable-version advice.
3. Use stable docs by default. `latest` docs do not override stable docs unless the task is explicitly about unreleased or newly changed behavior.
4. Use manual pages for concepts, workflows, and feature overviews.
5. Use the class reference or the editor-integrated class reference for exact API validation.
6. Use demo projects for patterns, scene setup, and runnable examples, then validate final APIs against the docs or class reference.

## Practical Agent Workflow

1. Start with `llm.txt` to narrow the surface area.
2. Read `llm-medium.txt` before drafting a subsystem or code sample.
3. Escalate to the stable docs and class reference for exact interface validation.
4. Check `latest` docs only when the stable docs are missing a recent feature or when the task explicitly targets unreleased behavior.
5. Load local engineering references after the official docs path is clear.
6. Summarize the chosen API in project terms instead of pasting long excerpts.
