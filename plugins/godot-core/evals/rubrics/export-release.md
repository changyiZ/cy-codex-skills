# Export Release Rubric

Last verified: 2026-03-30

## Routing

- Should trigger only for explicit export, release preparation, or export-specific failure prompts.

## Required workflow checks

- verifies that an export preset is expected and names it when available
- names the output path or calls out that it is missing
- distinguishes `export_presets.cfg` from confidential export credentials
- identifies at least one exact export or smoke command, or states that the project does not provide one

## Risk checks

- names template, SDK, credential, or signing gaps when relevant
- inspects or plans to inspect export logs
- lists target-specific residual risks instead of claiming blanket success
