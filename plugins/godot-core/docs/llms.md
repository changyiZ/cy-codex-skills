# LLM Docs Guide

Last verified: 2026-03-30

Primary sources:
- https://pixijs.com/llms
- https://developers.openai.com/codex/concepts/customization/#skills
- https://developers.openai.com/codex/skills/#best-practices

This plugin mirrors the layered-document idea popularized by Pixi's `llms` pages, but the content is Godot- and Codex-specific.

## File roles

- `llms.txt`: shortest routing and source-policy summary
- `llms-medium.txt`: medium-detail workflow defaults and skill boundaries
- `llms-full.txt`: fuller context pack for agents that need more plugin detail

## Why the split exists

Codex and similar tools work better when the first layer is compact. The smaller files give a quick route into the plugin without forcing every turn to load long prose.

## What these files are not

- They are not a replacement for the Godot manual.
- They are not a mirror of the class reference.
- They are not a substitute for project-specific `AGENTS.md`.

## Update rule

When changing any `llms` file:

1. Re-check the linked official sources first.
2. Keep version statements and docs roots aligned across all three files.
3. Update the `Last verified` date everywhere you changed source-dependent facts.
