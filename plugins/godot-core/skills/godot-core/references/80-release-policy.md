# 80-release-policy.md - Version and Support Policy

This reference defines how the skill chooses a Godot version, when it recommends the latest stable release, and what to do when an engine upgrade is in scope.

The `80` prefix is only a local ordering label in this skill's `references/` folder. It is not a Godot or standards-based version number.

## Principles

1. Respect repository-locked engine version unless upgrade is explicitly requested.
2. Within a minor series, prefer latest patch before deep debugging.
3. Use supported branches for active development whenever possible.

## Default Recommendation

If repository does not lock version, recommend `Godot 4.6.1-stable`.
When this skill is updated again, refresh this value to the current latest stable patch release.

## Upgrade Safety

When performing version upgrade:
1. Include migration notes
2. Re-run validation chain
3. Test core gameplay path and export path
