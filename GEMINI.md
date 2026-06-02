# Antigravity Project Brief

Use this project as a Roku TV IPTV app workspace.

Follow the shared rules in `AGENTS.md`. In Antigravity, open this folder as its own Project so agent permissions, terminal approvals, and context are isolated to this app.

Default assumptions:

- Target platform: Roku OS / SceneGraph.
- Toolchain: Node.js, BrighterScript, roku-deploy.
- Local OS: Windows.
- Secrets: never write real credentials into source files.
- Monetization: plan for subscriptions, ads, and compliant account management, but do not fake provider integrations.

Before major changes, check:

- Roku packaging constraints in `manifest`.
- SceneGraph focus behavior.
- Playback reliability for HLS streams.
- Store-readiness requirements: icons, splash screens, privacy policy links, auth/subscription flow, and content rights.
