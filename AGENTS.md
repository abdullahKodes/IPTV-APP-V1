# Project Instructions

This repository is a Roku TV IPTV app built with SceneGraph, BrightScript, and BrighterScript tooling.

## Product Goal

Build a monetizable IPTV app for Roku with a polished TV-first interface, reliable playback, subscription/account flows, ads where allowed, and maintainable channel packaging.

## Engineering Rules

- Prefer Roku SceneGraph components and BrightScript/BrighterScript patterns over web-style abstractions.
- Keep the app remote-control friendly: predictable focus states, large readable text, and fast navigation.
- Never commit secrets, Roku device passwords, signing keys, IPTV provider credentials, API tokens, or payment credentials.
- Put local-only credentials in `.env` or editor/project secrets, using `.env.example` as the template.
- Use `npm.cmd` or package scripts on Windows if PowerShell blocks `npm.ps1`.
- Run `npm run check` before packaging when dependencies are installed.
- Keep user-facing monetization features compliant with Roku policies and the selected payment/ad providers.

## Important Commands

- `npm install` installs local Roku build tooling.
- `npm run check` validates the Roku source.
- `npm run build` stages and creates the channel zip.
- `npm run deploy` deploys to a configured Roku device.
- `npm run package` packages a channel build for signing/release workflows.

## Architecture Notes

- `manifest` controls Roku channel metadata and required libraries.
- `source/main.brs` is the app entry point.
- `components/` contains SceneGraph views and logic.
- `images/` should contain Roku icons and splash artwork before store submission.
- `build/` is generated output and should stay uncommitted.

## Agent Behavior

- Read the local code before making changes.
- Keep changes scoped and explain setup assumptions clearly.
- Ask before installing global tools or changing machine-wide settings.
- For app features, implement the actual usable Roku experience, not placeholder web pages.
