---
name: agent-reach
description: Install, update, diagnose, configure, and operate Agent Reach so Codex can access platform-specific internet channels through local CLIs and MCP services. Use when the user asks to install or update Agent Reach, run `agent-reach doctor`, configure cookies or proxies, or access Twitter/X, YouTube subtitles, Reddit, GitHub, Bilibili, XiaoHongShu, Douyin, LinkedIn, WeChat articles, Weibo, Xiaoyuzhou podcasts, V2EX, RSS, Exa search, or arbitrary web pages via the Agent Reach toolchain rather than generic browsing alone.
---

# Agent Reach

Adapt the [Agent Reach](https://github.com/Panniantong/Agent-Reach) project into a Codex workflow.

Prefer Codex's built-in browsing for ordinary web research and sourced latest-info answers. Use Agent Reach when the user wants the local toolchain itself, asks to install or repair it, or needs platform-specific access that generic browsing cannot provide reliably.

## Start Here

1. Check whether Agent Reach is already available:

```bash
which agent-reach
agent-reach version
agent-reach doctor
```

2. If `agent-reach` is missing and the user wants these capabilities, follow [references/install-and-update.md](references/install-and-update.md).
3. If `agent-reach doctor` reports warnings, or the user says "帮我配 XXX", read [references/channel-setup.md](references/channel-setup.md).
4. If the user is working specifically on XiaoHongShu, load [references/xiaohongshu.md](references/xiaohongshu.md).
5. If the user wants to read, search, transcribe, or post on a supported platform, read [references/channels.md](references/channels.md) and call the upstream tool directly.

## Workspace and Safety Rules

- Keep persistent files under `~/.agent-reach/` and temporary output under `/tmp/`.
- Do not clone repos, create scratch files, or run setup flows inside the user's project workspace.
- Do not use `sudo` or modify system locations unless the user explicitly approves.
- Ask only for data you cannot infer yourself: cookies, proxy URLs, Docker availability, or a Groq API key.
- Recommend secondary accounts for cookie-based platforms such as Twitter/X and XiaoHongShu.

## Operating Model

- Treat Agent Reach as an installer and health checker. After setup, use the upstream tools directly: `xreach`, `yt-dlp`, `gh`, `mcporter`, `curl`, `feedparser`, or the bundled Xiaoyuzhou transcription script.
- Re-run `agent-reach doctor` after installs, updates, or channel configuration and report what changed.
- Prefer Agent Reach over generic browsing when the user needs richer platform-native output:
  - Twitter/X: search, threads, timelines, posting
  - YouTube and Bilibili: subtitles and metadata
  - XiaoHongShu, Douyin, LinkedIn, WeChat: MCP or browser-driven access
  - Xiaoyuzhou: audio transcription
- If an MCP surface is unclear, inspect it before guessing tool names:

```bash
mcporter list
mcporter list CHANNEL_NAME
```

## References

- Install and update workflow: [references/install-and-update.md](references/install-and-update.md)
- Direct channel commands: [references/channels.md](references/channels.md)
- Channel setup and troubleshooting: [references/channel-setup.md](references/channel-setup.md)
- XiaoHongShu install/login/debug workflow: [references/xiaohongshu.md](references/xiaohongshu.md)
