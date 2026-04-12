# Reference Policy

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/plugins/build
- https://developers.openai.com/codex/concepts/customization/#skills
- https://developers.openai.com/codex/concepts/customization/#mcp
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/
- https://github.com/godotengine/godot-demo-projects
- https://pixijs.com/llms

This plugin uses the following source precedence.

## 1. OpenAI official Codex docs

Use these for:

- plugin packaging
- marketplace behavior
- skill structure
- MCP boundaries
- evaluation and routing expectations

These docs outrank local skill habits when there is any conflict about how Codex plugins or skills should be authored.

## 2. Godot official stable docs and class reference

Use these for:

- engine behavior
- supported API facts
- export behavior
- platform compatibility
- command-line export facts

Use `latest` docs only when explicitly checking unreleased behavior. Stable docs win by default.

## 3. Godot official tutorials and demo projects

Use these for:

- runnable patterns
- scene composition examples
- signal-driven communication examples
- broader project structure references

Tutorials and demo projects are examples, not substitutes for the class reference.

## 4. Pixi `llms` pages

Use these only for document structure decisions:

- short routing index
- medium context layer
- fuller context pack
- human landing page

Do not treat Pixi content as a source for Godot engineering facts.

## 5. Local `godot-*` skills in `/Users/cY/dev/skills`

Use these as:

- already-tested workflow ideas
- reusable phrasing candidates
- local engineering defaults that still need revalidation

If a local rule does not map cleanly to an official source or official runnable example, keep it marked as a heuristic or TODO instead of promoting it to hard plugin guidance.
