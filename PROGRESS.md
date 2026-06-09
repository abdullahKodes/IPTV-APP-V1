# IPTV App Progress

Last updated: 2026-06-09

Read this file before starting a new session. Update it only after a meaningful milestone is completed, such as finishing a screen, fixing a major workflow, committing/pushing, or changing project structure. Do not update it for every tiny visual tweak.

## Project Context

- Roku IPTV app built with SceneGraph, BrightScript, and BrighterScript.
- Main install/build clone used by GitHub Desktop is usually:
  `C:\Users\M Abdullah\Documents\GitHub\IPTV-APP-V1`
- Working/scratch folder is:
  `C:\Users\M Abdullah\MY APP\Working\IPTV APP`
- Standard validation/build commands:
  - `npm.cmd run check`
  - `npm.cmd run build`
- Installable zip path:
  `C:\Users\M Abdullah\Documents\GitHub\IPTV-APP-V1\build\roku-iptv-app.zip`

## Current Design Progress

### Home Page

Status: mostly approved.

Completed:
- Home layout and sidebar styling are in a usable polished direction.
- Four center action buttons use custom icons from project assets.
- Home tile focus behavior was adjusted so focused state is visually clearer.
- Home page should not be changed unless explicitly requested.

Important note:
- Do not casually edit Home page while polishing other screens.

### Add Playlist Page

Status: in active polish.

Completed:
- Sidebar was restyled to match the Home page style while keeping Add Playlist page options.
- Removed QR/scan panel and tip panel.
- Center form was widened and centered.
- Title was enlarged.
- M3U/Xtreme mode buttons were made equal width and no longer shift on focus.
- Mode button focused border was aligned with the Add Playlist button border color.
- Input placeholders were removed.
- Input labels use the same green title color as sidebar option text.
- Inputs are focusable and open an on-screen keyboard with OK.
- Back closes the keyboard before leaving the page.
- Add Playlist button no longer changes text to `Playlist Added`.
- Xtreme Account fields were made more compact and less crowded.
- Focused borders were regenerated slimmer.

Needs future review:
- Visually test the on-screen keyboard on Roku.
- Confirm Add Playlist and Xtreme Account button icon/text alignment on actual TV.
- Confirm Xtreme Account layout is not too low after latest compacting.

### Other Pages

Status: Live TV has received a first polish pass; remaining pages still need page-by-page design work.

### Live TV Page

Status: first polish pass completed, ready for Roku visual review.

Completed:
- Compared the current Roku screenshot with the target Live TV reference screenshot.
- Reworked the page into a cleaner three-column TV layout: app sidebar, channel list, and large player area.
- Restyled the Live TV sidebar to match the newer Home/Add Playlist sidebar contrast and focus treatment.
- Added a search box treatment in the top bar area.
- Darkened channel cards and reduced the previous bright blue block look.
- Rebuilt the player area with a darker premium panel, live badge, play affordance, progress bar, and EPG strip.
- Confirmed `npm.cmd run check` passes.
- Confirmed `npm.cmd run build` creates `build\roku-iptv-app.zip`.
- Cleaned the player controls to icon-only buttons, restored the video viewport to a supported fitted frame, and fixed focus routing so Search is reachable from Live TV content.
- Increased Live TV channel card height, reduced channel title/subtitle text, made channel Up navigation stay in the content area, and removed button outlines from player icon controls.

Needs future review:
- Test on actual Roku/TV for text sizing, focus contrast, and spacing.
- Confirm the target-inspired player panel reads well from couch distance.
- Confirm channel list focus and category focus feel natural with the Roku remote.

Screens still expected to need design pass:
- My Playlists
- Series
- Movies
- Settings

## Current Implementation Notes

- `components/pages/AddPlaylistPage.brs` owns Add Playlist layout and local sidebar rendering.
- `components/shared/AppUi.brs` has a `noFocusShift` option so selected controls can stay still on focus.
- `components/shared/AppUi.brs` also supports optional `labelX`, `labelW`, and `labelAlign` for row buttons.
- Add Playlist input fields use local in-page state in `m.inputs`.
- Add Playlist keyboard is a custom overlay drawn in BrightScript, not a native Roku text field.
- `components/MainScene.brs` routes Back to the current page first so page overlays can close before navigation.

## Milestone Update Rules

Update this file when:
- A screen is considered done or ready for review.
- A major bug is fixed, especially navigation/focus/input/playback.
- A build is confirmed working on Roku.
- Code is committed/pushed.
- Project structure changes.

Do not update this file for:
- Single color tweaks.
- One-off spacing changes.
- Failed experiments that are reverted.
- Temporary builds.

## Git Notes

- Avoid committing secrets, device passwords, provider credentials, signing keys, or payment credentials.
- Keep `build/` generated output uncommitted unless the user explicitly asks otherwise.
- Before committing, check `git status --short` and avoid staging unrelated files.
- The user may have local dirty files in the working/scratch folder. Do not revert unrelated user changes.
