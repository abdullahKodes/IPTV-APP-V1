# IPTV App Progress

Last updated: 2026-06-12

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

### Branding and Roku Store Assets

Status: updated and ready for Roku visual review.

Completed:
- Replaced the Roku splash screen with the latest supplied `IPTV Max` splash artwork.
- Replaced the top-bar brand mark with the latest supplied dark full logo.
- Rebuilt Roku app-view/channel icons from `roku view 2.png`.
- Updated the manifest title to `IPTV Max`.
- Confirmed `npm.cmd run check` passes.
- Confirmed `npm.cmd run build` creates `build\roku-iptv-app.zip`.

Needs future review:
- Confirm splash brightness and logo scale on the actual Roku device.
- Confirm Roku app-view tile crops correctly in the device app grid and any store preview.

### Other Pages

Status: Live TV, Series, and Movies have received polish passes; remaining pages still need page-by-page design work.

### Live TV Page

Status: completed for now, ready for Roku visual review.

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
- Final channel-card text pass reduced title/subtitle sizes and widened the text area so channel names and current programs can display in full instead of truncating.
- Rebuilt the live badge and player-control assets so badge text and player icons render cleanly on Roku.
- Adjusted focus routing so player controls can move to the center play control.

Needs future review:
- Test on actual Roku/TV for text sizing, focus contrast, and spacing.
- Confirm the target-inspired player panel reads well from couch distance.
- Confirm channel list focus and category focus feel natural with the Roku remote.

### Series Page

Status: polish pass completed, ready for Roku visual review.

Completed:
- Restyled the Series sidebar to match the newer app contrast and active-state treatment.
- Added a top search box and in-app search keyboard.
- Added genre/category pills with selected and focused states.
- Reworked Continue Watching and Popular Series cards into the newer dark-panel style.
- Added basic filtering by search text and genre.
- Tightened category pill sizes to supported rounded assets and kept the same purple/green focus treatment.
- Aligned Series focus routing so Search, genre pills, Continue Watching, and Popular Series move predictably with the Roku remote.
- Compared against the newly supplied Series/Movies design references and widened the Series layout: one-row category filters, no cramped center divider, wider card spacing, and poster-style Popular Series cards while keeping the app color contrast.
- Fixed Series category focus to match Live TV's green focus treatment, and restored rounded focus borders for Continue Watching and Popular Series cards using supported Roku rounded assets.
- Reviewed the newer `series design.png` reference and repaired Series spacing: category pills now use one clean row, Continue Watching cards are wider, and Popular Series card sections avoid square edges inside the rounded card.
- Tuned Series after Roku review: category pills were reduced slightly, Continue Watching cards were scaled back, Continue Watching focus now uses green with no persistent selected state, and Popular Series cards now keep a visible rounded border against the background.
- Final Series polish pass reduced category width further, added more space between Continue Watching cards, removed persistent Continue Watching selection, and replaced Popular Series square overlays with composite rounded card assets.
- Tuned Popular Series cards again: reduced card size, softened card borders, and adjusted abbreviation badge colors for stronger contrast against each card background.
- Further reduced Popular Series cards, removed heavy normal borders, and changed abbreviation letters to light text so labels like OZ and CR stay readable.
- Reworked Popular Series cards into compact Continue Watching-style horizontal cards, with explicit high-contrast abbreviation badges and manifest build version `00021` so Roku replaces the sideloaded app.
- Added exact `210x86` rounded assets for Popular Series normal/focus states so the cards use a soft Continue Watching-style border and full green card focus on Roku; manifest build version is now `00022`.
- Restored the previous vertical Popular Series card style at a smaller `200x176` size, keeping soft borders, full-card green focus, readable abbreviation badges, and manifest build version `00023`.
- Regenerated Popular Series poster assets at the active `200x208` size using the same Home card palette: `purpleSoft`/`purpleActive` and `greenSoft`/`greenActive`; manifest build version is now `00024`.
- Reverted the Popular Series text/info area to the previous dark panel color and kept color only in the upper non-text card area; manifest build version is now `00025`.
- Restored Popular Series card height to `200x176`, returning the text/info palette to the shorter previous height while keeping the upper icon area in the Home purple/green colors; manifest build version is now `00026`.
- Restored Popular Series card dimensions and text spacing to the GitHub-tracked `200x208` layout while keeping the upper icon area colored and the info area dark; manifest build version is now `00027`.
- Regenerated Popular Series card assets with the GitHub-tracked `200x208` size and title spacing intact, but moved the color split lower so the dark text palette is shorter; manifest build version is now `00028`.
- Restored the previous stable Popular Series implementation from commit `231fb43`, using `series_card_tiny_*` assets again so the rounded card background renders instead of floating icons; manifest build version is now `00029`.
- Restored the exact Popular Series card code and `series_card_poster_*` assets from commit `63aab03 fixing cards issue`; manifest build version is now `00030`.
- Increased Popular Series poster cards slightly to `200x190`, adjusted title/meta/genre spacing, and regenerated the upper color panels with Home `purpleSoft`/`greenSoft`; manifest build version is now `00031`.
- Confirmed `npm.cmd run check` passes.
- Confirmed `npm.cmd run build` creates `build\roku-iptv-app.zip`.

Needs future review:
- Test Series page focus movement on actual Roku.
- Confirm search keyboard behavior and card text sizing from couch distance.

### Movies Page

Status: first polish pass completed; backend-readiness pass started with dynamic catalog rendering.

Completed:
- Reworked Movies into the newer content-page style used by Live TV and Series.
- Restyled the Movies sidebar to match the newer contrast and active-state treatment.
- Added a top search box and in-app search keyboard.
- Added genre/category pills with selected and focused states.
- Rebuilt the featured movie panel with darker premium styling, resume text, rating, and progress strip.
- Reworked movie cards into compact dark panels with consistent green focus borders.
- Added basic filtering by search text and genre.
- Compared against the newly supplied Movies design reference and reshaped Movies closer to it: one-row category filters, wide featured strip with Watch Now action, and four poster-style movie cards using the existing app contrast/focus colors.
- Fixed Movies category focus to match Live TV's green focus treatment, and restored rounded focus borders for the featured/movie cards using supported Roku rounded assets.
- Confirmed `npm.cmd run check` passes.
- Confirmed `npm.cmd run build` creates `build\roku-iptv-app.zip`.
- Converted Movies from inline demo cards to a backend-shaped movie catalog in `components/shared/MediaData.brs`.
- Movies now renders a four-card visible window from the filtered catalog instead of assuming the full movie list fits on screen.
- Movie card focus can move through a larger dataset with left/right navigation while the visible card window slides.
- Movie cards now support future `posterUrl`, `backdropUrl`, `streamUrl`, ratings, resume progress, featured flags, and playlist IDs while keeping safe local fallbacks when artwork URLs are empty.
- Added a selected/featured backdrop hook so future backend artwork can tint the page background at low opacity without changing the approved layout skeleton.
- Confirmed `npm.cmd run check` passes after the backend-readiness pass.
- Confirmed `npm.cmd run build` creates `build\roku-iptv-app.zip` after the backend-readiness pass.
- Fixed the first dynamic Movies Roku review pass: simplified the scrolling indicator, removed card-level resume bars from the movie library row, made card focus state single/clearer, and made OK on a movie promote it into the featured panel.
- Confirmed `npm.cmd run check` and `npm.cmd run build` pass after the Movies focus/scrolling fixes.
- Reworked the Movies scrolling affordance into a vertical scrollbar beside the movie row, removed the remaining focused-card underline that looked like a resume bar, added local seeded demo poster/backdrop images under `images/demo/`, and cleaned old test files from `build/` before creating a fresh zip.
- Bumped manifest build version to `00037` so Roku sideload refreshes the changed Movies page.
- Confirmed `build/` now only contains `roku-iptv-app.zip` after the final fresh build.
- Tweaked Movies poster cards after Roku screenshot review: enlarged the poster-driven area, tightened the title/meta palette, slightly enlarged the featured poster, and bumped manifest build version to `00038`.
- Filled the Movies card poster region with zoomed/scaled artwork, muted the movie card category/meta line so focused titles stand apart, increased selected backdrop visibility, and bumped manifest build version to `00039`.
- Generated exact card-ratio demo artwork under `images/demo/card_art/`, wired movie cards to use those filled card images, changed the focused background to use the same card image as the focused movie, and bumped manifest build version to `00040`.
- Generated wider `images/demo/card_fill/` assets, reduced card image inset to nearly edge-to-edge, forced card artwork to `scaleToFill`, and bumped manifest build version to `00041`.
- Generated transparent rounded card-slot PNGs under `images/demo/card_slot/`, inset movie artwork safely inside the card frame, redrew the card frame above poster artwork, added a green rounded border behind the Featured poster, and bumped manifest build version to `00042`.
- Reworked Movies cards away from the old Series card PNGs: movie artwork now clips into a fixed poster window, text sits in a separate dark strip, transparent rounded frame overlays guarantee visible normal/focus borders, the Featured poster uses an explicit green frame asset, unused card-slot assets were removed, and manifest build version is now `00043`.
- Reworked Movies cards again after Roku review into narrower rounded poster tiles with wider spacing, softer normal outlines, a less heavy focused card, neutral Featured poster framing, and manifest build version `00044`.
- Corrected the Movies card shape after Roku review: Featured poster artwork now fills its neutral frame, library cards returned to wider `200x190` rounded tiles, card artwork uses the landscape `cardUrl` first, stale narrow tile assets were removed, and manifest build version is now `00045`.
- Added poster corner masks so the Featured poster and the top image area of Movies cards no longer show sharp rectangular corners; manifest build version is now `00046`.
- Centered the Featured poster vertically inside its panel, softened its frame color to match the panel outline, reduced focused Movies card border thickness, and expanded movie-card artwork closer to the card edges; manifest build version is now `00047`.
- Split Movies card fill and border into separate assets so the rounded outline renders above artwork, added backend-safe movie field helpers for missing/null title/genre/year/rating/art fields, guarded activation against invalid focus indexes, and bumped manifest build version to `00048`.
- Fixed custom focus rendering so `mode: "manual"` no longer receives an extra shared rounded overlay, preventing double borders on Movies cards and other manually drawn controls; manifest build version is now `00049`.
- Capped Movies search text length to avoid unbounded keyboard input growth during backend-scale browsing; manifest build version is now `00050`.

Needs future review:
- Test Movies page focus movement on actual Roku.
- Confirm movie card text sizing and featured panel spacing from couch distance.
- Confirm search keyboard behavior on Roku.

Screens still expected to need design pass:
- My Playlists
- Settings

## Current Implementation Notes

- `components/pages/AddPlaylistPage.brs` owns Add Playlist layout and local sidebar rendering.
- `components/pages/SeriesPage.brs` owns the current Series page layout, genre filtering, and search keyboard.
- `components/shared/MediaData.brs` owns backend-shaped mock movie data for the dynamic Movies page until real backend or playlist parsing replaces it.
- `components/shared/AppUi.brs` owns the shared top bar and now uses `pkg:/images/logo_full_dark_modified.png`.
- Roku manifest app-view assets are `images/icon_focus_hd.png`, `images/icon_side_hd.png`, and `images/splash_screen_hd.png`.
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
