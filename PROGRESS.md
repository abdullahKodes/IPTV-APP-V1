# IPTV App Progress

Last updated: 2026-06-29

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

### Player Controls

Status: redesigned and ready for Roku visual review.

Completed:
- Rebuilt the playback overlay around icon-first TV controls for rewind, play/pause, forward, restart, and captions.
- Added a real captions on/off action and retained the existing remote playback, seeking, restart, progress, and automatic control-hiding behavior.
- Simplified the player header to the media title only; removed the year/runtime subtitle and the `IPTV MAX` label.
- Follow-up Roku review removed all text beneath the controls, centered play/pause, kept captions at the far right, and reduced the four secondary icon sizes.
- Rewind/forward now seek 30 seconds so their behavior matches the supplied `30` icon artwork.
- Follow-up moved Restart to the far-left side and replaced the subtle focus border with a strong cyan circular focus halo.
- Corrected the reversed rewind/forward arrow artwork while preserving the working 30-second seek behavior.
- Series episode playback now shows compact season/episode context such as `S1-E4` beneath the title; movie playback remains title-only.
- Reduced dynamic Movies/Series list artwork strength so poster cards and focus borders remain visually dominant.
- Backdrop dimming now responds to focus: card and Continue Watching rows receive the quieter treatment while the selected artwork still changes dynamically by title.
- Movies and Series category pills now come from incoming media genres instead of fixed lists.
- Both pages now follow Live TV category overflow behavior: a bounded pill window, left/right focus scrolling, selected-category state, and overflow direction indicators.
- Aligned the category overflow indicator with the shared horizontal center of the Movies/Series card scrollbars.
- Fixed category-pill overlap by reserving a dedicated scrollbar-aligned indicator column and calculating the visible pill window from actual label widths.
- Extended the existing Movies, Series, and Live TV search bars to search category names as well as titles/channels.
- Finishing a category search now jumps focus directly to the best exact or partial category match; selecting it clears the text query and loads the category's complete content.
- Standardized Back behavior across every searchable page: Back clears active results and restores the full page before normal page navigation is allowed.
- Category searches on Movies, Series, and Live TV remember and restore the category that was active before searching; My Playlists now follows the same clear-search-first behavior, while Favorites retains its existing matching behavior.
- Movies and Series now switch to a dedicated results layout while searching: Featured Movie, Continue Watching, and category pills are hidden so only the results heading, count, and matching cards remain.
- Title searches show `SEARCHED MOVIES` or `SEARCHED SERIES`; category searches automatically select the match and show headings such as `ANIMATION SEARCHED`.
- Removed redundant result counts from direct movie/series title searches while retaining counts for category searches, and moved results content closer to the top bar.
- Live TV now keeps focus on the selected category pill after OK instead of jumping into channels or toward the sidebar; Down remains the explicit route into channel cards.
- Locked the quieter dynamic backdrop opacity across content-card focus, preventing brightness jumps between Featured Movie and movie cards or Continue Watching and series cards.
- Fixed the Series poster-to-Continue focus handoff so the selected Continue item and resume focus state drive the backdrop consistently; the same title, such as Ozark, now keeps the same backdrop opacity across both rows.
- Removed Series page state-based backdrop brightness entirely: the page now opens with the same quieter opacity used while browsing Continue Watching and poster cards, for every title.
- Replaced the generic `EPISODES` heading on Series detail with the selected season's provider-supplied name, falling back to `SEASON 1`, `SEASON 2`, and so on.
- Added backend-ready `seasonNames` and `episodeDurations` metadata through Series/Favorites navigation and persistence; episode cards now show their supplied duration beneath the title and vertically center titles when duration is unavailable.
- Removed invented demo episode durations after review; runtimes now appear only when genuine episode metadata is supplied by the IPTV/backend provider.
- Added navigation-state restoration for Movie/Series detail and playback drill-downs: Back now restores the exact prior page instance, preserving focused card, category, scrolling, and search state instead of recreating the page at its sidebar default.
- The same history behavior covers Live TV and Favorites playback/detail returns.
- Restored varied placeholder episode durations when real metadata is absent; provider-supplied `episodeDurations` still takes priority and replaces placeholders automatically.
- Manual Movies/Series category selection now enters the same focused results layout as category search, hiding Featured/Continue sections and making Back restore the previous main page/category state.
- Live TV manual category selection now follows the same return behavior: it remembers the previous category, retains focus on the selected pill, and Back restores the prior/main Live TV view before Home navigation.
- Added a purpose-made Live TV broadcast-studio background with no channel branding or text, composed with dark sidebar/header space and subdued detail behind channel cards.
- Wired the optimized `1280x720` project asset under translucent app-color overlays so channel logos, labels, and focus states remain dominant.
- Replaced the first Live TV concept with a richer second background containing a multi-genre broadcast wall, studio cameras, control-room depth, signal graphics, and reflective lighting while preserving UI-safe dark zones.
- Mirrored the richer Live TV background horizontally and switched the page to the new versioned asset.
- Replaced the mirrored background's large blank side with a full-width continuation of the studio, broadcast screens, cameras, signal graphics, and reflections while keeping the extended area lower contrast.
- Bumped the manifest build version to `00179`.

### Demo Artwork And Detail Pages

Status: ready for Roku review build.

Completed:
- Replaced demo Movies/Series card artwork paths with HD poster-card assets and added local real HD landscape hero art for key demo Movies and Series titles.
- Movies and Series list pages now read explicit `heroUrl` artwork first and no longer promote old low-resolution `movie_backdrops` or `series_backdrops` assets into hero backgrounds.
- Movie and Series detail pages now use a single HD landscape hero layer with a smoky left-side readability blend instead of duplicating a vertical poster over another poster background.
- Backend/provider playlist behavior remains dynamic: external entries can still use their supplied backdrop/hero art, while poster-only entries fall back to the IPTV MAX art backdrop rather than stretching a vertical poster full-screen.
- `bsconfig.json` excludes the rejected low-res demo poster/backdrop folders plus `images/demo/downloaded_hero/` from Roku packaging, and `.gitignore` keeps the raw download cache local.
- Bumped manifest build version to `00137`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00137` with no raw download-cache files.
- Follow-up review pass: Movies/Series list and detail pages now show the IPTV MAX art backdrop only when no item hero art is available, use the selected item's own hero by itself when present, and replace visible rectangle smoke bands with reusable alpha-gradient overlay masks.
- Bumped manifest build version to `00138` for the backdrop/smoke-mask follow-up.
- Follow-up review pass: removed the generated-only Neon Horizon movie and Signal House series entries, removed top/bottom detail/list dark bands, simplified Movie detail content to title-first metadata with compact Watch/Favorite actions, and resized shipped demo hero/poster art to Roku display sizes for a smaller package.
- Bumped manifest build version to `00139` for the detail-content and package-size pass.
- Follow-up review pass: lowered Movies/Series list hero opacity only, kept detail hero opacity unchanged, enlarged Movie detail title text, reduced the metadata line, removed the metadata underline, changed Movie detail actions to compact model-style Watch/Favorite pills, removed the visible Movie detail Back control, and replaced right-side detail text branding with the top-left logo.
- Bumped manifest build version to `00140` for the list-opacity and Movie detail polish pass.
- Follow-up correction: made Movie detail layout more visibly different by removing all visible top-bar branding from the detail screen, increasing title size again, moving metadata/description/actions upward, and reducing action-pill fill opacity for a closer reference-style button treatment.
- Bumped manifest build version to `00141` for the stronger Movie detail correction.
- Follow-up correction: made shared labels honor their requested font sizes, enlarged Movie detail title/meta/description text, and changed Movie detail actions to two taller reference-style action tiles with centered icons.
- Series detail now uses the same taller action-tile language and renders episodes per selected season by deriving the selected season's episode count from available series metadata.
- Bumped manifest build version to `00143` for the Movie/Series detail typography and season-wise episode correction.
- Hotfix: reverted the shared Font-node assignment that blanked text on Roku, kept Movie/Series detail emphasis through per-screen label scaling, and bumped manifest build version to `00144`.
- Follow-up detail polish: replaced the square Movie/Series action tiles with horizontal glass action buttons, removed the visible Series detail logo, and restyled Series seasons/episodes as right-side glass panels with chips and episode rows instead of skeleton-looking blocks.
- Bumped manifest build version to `00145` for the detail button and Series detail layout polish.
- Follow-up Series detail redesign: replaced boxed season/episode sections with reference-inspired floating season cards and cinematic episode strips with artwork thumbnails, compact metadata pills, and less visible container chrome.
- Bumped manifest build version to `00146` for the Series detail reference-style redesign.
- Follow-up detail refinement: changed Movie/Series action controls to smaller transparent home-style boxes with green focused styling, moved Series season chips under Resume/Favorite, removed the episode range count, and simplified episode rows to thumbnail plus episode badge/title only.
- Bumped manifest build version to `00147` for the transparent detail controls and simplified Series detail structure.
- Follow-up Series detail correction: reduced Movie/Series action buttons to smaller transparent boxes, aligned Season chips to the app's panel/green-focus color pattern, made Episode rows taller/narrower, changed Episode badges from `E1` to numeric-only labels, switched thumbnails to poster/card artwork, and routed Season-down focus to the first Episode row.
- Bumped manifest build version to `00148` for the Series detail focus and episode-card correction.
- Follow-up Series detail correction: removed episode count and TV rating from the header metadata, changed episode rows to sharp-corner taller/narrower palettes, removed the numeric badge entirely, and made episode titles use season-derived global numbers so changing seasons visibly changes the rendered episodes.
- Bumped manifest build version to `00149` for the Series header and episode rendering correction.

### Demo Playlist Foundation

Status: foundation added.

Completed:
- Replaced the scattered built-in demo playlist cards with one protected `Demo Playlist`.
- `Demo Playlist` now represents the current bundled demo Live TV, Movies, and Series content.
- Added a second protected `Demo Movies` playlist that contains Movies content only so empty Live TV/Series states can be tested.
- Added local active-playlist storage in `components/shared/PlaylistStore.brs`.
- My Playlists now sets the selected playlist as active before opening Live TV.
- Live TV, Movies, and Series now load content through the active playlist instead of directly using global mock catalogs.
- User-added M3U playlists are preserved in My Playlists and now resolve through the shared M3U content parser when a source URL is available.
- Empty states now mention the active playlist and suggest switching or adding a playlist.
- Add Playlist now validates required fields, URL prefixes, and duplicate playlist names before saving.
- Add Playlist field errors now render inside the specific invalid input field.
- The local test M3U URL `https://iptvmax.test/demo-series.m3u` creates a user-added series-only playlist for flow testing before the real parser is implemented.
- Existing test playlists using that URL now infer their series-only profile on load, so they do not need to be re-added.
- Fake series test URL matching is uppercase/Roku-keyboard tolerant and also accepts URLs containing `DEMO-SERIES` or `SERIES.M3U`.
- Fake series detection now also checks the playlist title for `Series`, and the Add Playlist keyboard has an `abc`/`ABC` case toggle.
- My Playlists routes movies-only playlists to Movies first and series-only playlists to Series first.
- Movies no longer shows the Featured Movie panel when the selected playlist has no movies.
- Empty Live TV, Movies, and Series pages now show only the app shell/search plus the empty-state message; category pills, featured panels, content rows, and player panels are hidden when there is no content.
- My Playlists keeps normal playlist cards purple and uses green for the focused card state.
- Added a protected `Empty M3U Playlist` and made it the startup active playlist from `MainScene`, so the app launches into an empty active-content state until the user selects demo/user content.
- Added a first working M3U parser path in `components/shared/MediaData.brs`: it fetches M3U URLs, parses `#EXTINF` entries, classifies streams into Live TV, Movies, or Series, keeps logo/poster URLs where present, and uses each entry stream URL for playback.
- The local test M3U URL `https://iptvmax.test/demo-series.m3u` now flows through M3U parsing and produces series items without needing a real backend.
- Added the local test M3U URL `https://iptvmax.test/demo-movies.m3u` for safe Movies-page testing without a remote provider.
- Added the local test M3U URL `https://iptvmax.test/demo-live.m3u` for safe Live TV testing through the parsed-playlist path.
- Real Live TV from parsed playlist is now testable with the fake Live M3U: adding/selecting it routes to Live TV and renders parsed live channels with stream URLs.
- Add Playlist now makes the newly added playlist active immediately, preventing Live TV from still reading the startup Empty M3U playlist after a new test playlist is saved.
- Fake Live M3U detection has a defensive media fallback for older saved playlist items that may not have a stored `demo_live_m3u` profile.
- Added a protected `Demo Live M3U` playlist card with the fake live URL built in, so Live TV parsed-playlist behavior can be tested without relying on the Add Playlist form.
- Bumped manifest build version to `00075` so Roku replaces the sideloaded app during this test pass.
- Fixed user-added playlist identity collisions by generating stronger unique playlist IDs and repairing duplicate saved IDs on load; this prevents a newly added playlist card from activating an older playlist with the same ID.
- Bumped manifest build version to `00076` for the duplicate-ID fix test pass.
- Made fake test URL matching more tolerant for user-added M3U playlists, including `iptvmax.test` plus the content type, and moved active-playlist selection into `playlistStoreAdd()` itself.
- Fixed parsed Live M3U channel artwork so logo images stay inside the channel rows instead of being used as full card/backdrop art.
- Bumped manifest build version to `00077` for the user-added playlist activation and parsed-live artwork fixes.
- Removed the forced startup active-playlist reset from `MainScene`; first run still falls back to Empty M3U, but user-added/selected playlists now survive app relaunch.
- User-added fake Live M3U playlists now store their own `liveItems` array on the playlist record, and Live TV reads those stored items before URL/profile inference.
- Live TV channel-card/background artwork no longer falls back to `logoUrl`, preventing parsed logo images from stretching across channel rows or the player background.
- Bumped manifest build version to `00078` for the per-playlist live item storage and Live TV artwork containment fixes.
- Removed the remaining indirect Live TV lookup for fake live playlists: Live TV now recognizes the selected playlist's fake live URL/title and returns that playlist's own four live items before parser fallback.
- My Playlists now opens focused on the currently active playlist, so after Add Playlist saves a fresh M3U URL the remote focus lands on the new playlist instead of the startup Empty M3U card.
- Bumped manifest build version to `00080` and confirmed `npm.cmd run check` plus `npm.cmd run build` pass for the fresh-playlist Live TV fix.
- Added a registry repair for blank user-added test M3U records: saved M3U playlists with no URL/profile but test/live markers are normalized back to `https://iptvmax.test/demo-live.m3u`, preventing the active playlist from rendering empty after earlier broken saves.
- Add Playlist now rejects a save if an M3U record reaches the store without a URL, and the Live TV debug line includes playlist title plus URL/profile while this flow is being tested.
- Bumped manifest build version to `00081` and confirmed `npm.cmd run check` plus `npm.cmd run build` pass for the blank-source repair.
- Fixed the actual blank URL/profile root cause: shared field readers now handle BrightScript object-literal lowercase keys such as `sourceurl`, `contentprofile`, `streamurl`, and `itemcount` when code asks for camelCase names like `sourceUrl`.
- Extended the same case-safe field reader pattern to MediaData, Live TV, Movies, Series, My Playlists protected-card checks, and Settings state helpers.
- Bumped manifest build version to `00082`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00082`.
- Reworked Live TV channel artwork treatment: channel rows now keep a stable dark card, use the channel name as the main title, place the logo in a contained mark, and reuse the logo only as a subtle row watermark.
- Reworked the Live TV player/background brand treatment so logo-only channels use restrained brand bands and faint logo marks instead of stretched full-section artwork.
- Bumped manifest build version to `00083`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00083`.
- Removed logo images from all large Live TV background/watermark uses after Roku review; provider logos are now used only inside the small channel-row mark.
- Live TV large/player artwork now uses dynamic demo-style brand colors plus generated initials via `liveBrandText()`, so real playlist logos cannot spread across the whole page.
- Bumped manifest build version to `00084`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00084`.
- My Playlists now sorts the active playlist to the first visible card and focuses it once when the page opens, so the currently active playlist is not buried at the end of the list.
- Live TV large background art now maps real playlist channels to the app's local demo backdrop artwork by category/title instead of using provider logo/card art as the page background.
- Bumped manifest build version to `00085`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00085`.
- Removed the protected built-in `Demo Live M3U` playlist card from the default playlist list while keeping the fake live URL support available for manual test playlists.
- Bumped manifest build version to `00086`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip no longer contains the `Demo Live M3U` default card.
- Replaced the old demo playback URL with reachable public HLS samples and added `demoLivePlaybackUrl()` so Demo Playlist live channels cycle through different sample streams.
- Updated fake live M3U/demo-live playlist records to refresh their stored `liveItems` on load with the new sample stream URLs.
- Live TV and PlayerPage stop/reload the Video node before assigning new content.
- Movies and Series continue to route to `PlayerPage`, now backed by the new demo HLS URL for all demo movie/series items until real provider media is wired.
- Bumped manifest build version to `00087`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00087`.
- Reworked full-screen PlayerPage controls into a cleaner overlay with stronger focused actions and a 10-second inactivity auto-hide timer.
- Changed Live TV browsing so moving through the channel list only moves focus; the inline video now changes only after pressing OK/select on a channel.
- Reshaped the Live TV mini-player viewport from the old ultra-wide frame to a 16:9 frame so sample/live streams fill the intended playback area better.
- Removed the temporary Live TV empty-state debug line from the user-facing screen.
- Bumped manifest build version to `00088`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00088`.
- Corrected the `00088` playback visual regression: full-screen PlayerPage controls now use a cleaner round icon-strip treatment instead of boxy rectangular buttons.
- Live TV now hides the large center play button while video is playing; the lower play/pause control remains the active remote target.
- Demo Playlist Live TV uses the original compact artwork/backdrop layout, while non-demo/user playlists keep the safer real-playlist video layout.
- Bumped manifest build version to `00089`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00089`.
- Reverted full-screen PlayerPage controls back toward the original text-only control strip while preserving the 10-second auto-hide behavior.
- Restored Demo Playlist Live TV channel cards to the previous artwork-card rendering path instead of the contained-logo real-playlist cards.
- Adjusted the Demo Playlist Live TV mini-player video slot to a 16:9 frame inside the existing compact panel to reduce side empty space without changing the page composition.
- Tightened Live TV player remote routing so left/right stays within the player controls except left from the first control, which returns to the channel list; up/down now moves between favorite and play controls predictably.
- Bumped manifest build version to `00090`, confirmed `npm.cmd run check` and `npm.cmd run build` pass, and verified the packaged zip manifest contains `build_version=00090`.
- Fixed a Movies-page crash on empty/test playlists by clamping the focus index before remote key handling.
- Removed render-time remote M3U fetching from content pages; real provider fetches should run through a background Roku Task in the next parser step.
- Improved Movies remote behavior so sidebar up/down stays in the sidebar, right enters content, and left from search/filters/featured/movie cards returns to the Movies sidebar item instead of wrapping awkwardly.
- Tightened Add Playlist URL validation so `http://abc` or any text after only the scheme no longer saves; URLs now need a real host-style address.
- Made sidebar focus stationary across Home, Add Playlist, Live TV, Movies, Series, My Playlists, Profile, Settings, and the shared sidebar helper.
- Replaced the demo Movies poster files with recognizable theatrical poster artwork and added real Series poster assets under `images/demo/series_posters`.
- Movies and Series cards now render contained poster artwork from `posterUrl` first instead of relying on old landscape `card_fill` images, making the next detail-page pass safer to judge visually.
- Fixed poster-card empty space by drawing a dimmed zoomed poster fill behind the uncropped poster on Movies and Series cards.
- Fixed focused background updates by using the currently focused movie/series poster as the page backdrop, including Series Continue Watching focus.
- Corrected the accidental `Get Out`/`Ozark` poster mapping swap.
- Bumped manifest build version to `00092` for the poster fit and focused-backdrop fixes.
- Improved blurry page backgrounds by preferring landscape backdrop assets over portrait posters, adding generated 16:9 Series backdrop images under `images/demo/series_backdrops`, and restoring Get Out to the landscape movie backdrop.
- Bumped manifest build version to `00093` for the backdrop quality pass.
- Matched Movies to the Series backdrop treatment by generating composed 16:9 movie backgrounds under `images/demo/movie_backdrops` and wiring demo movie `backdropUrl` values to those assets.
- Bumped manifest build version to `00094` for the matching Movies/Series background treatment.
- Added runtime composed backdrop rendering for real/provider poster-only Movies and Series items: when no prebuilt composed backdrop exists, the page draws a zoomed backdrop field plus a sharp poster anchor directly from `posterUrl`.
- Bumped manifest build version to `00095` for the dynamic provider-poster backdrop treatment.
- Added dedicated Movie and Series detail pages with cinematic backdrop art, poster display, Watch/Resume actions, back navigation, and placeholder favorite affordances for the later Favorites pass.
- Movies and Series cards now open their detail page first, then launch `PlayerPage` from the selected title's real/provider playback URL and return back to that detail page after playback.
- Bumped manifest build version to `00096` for the Movie/Series detail-page milestone.
- Fixed Movie/Series detail pages so selected-title data is synced before the screen is shown, preventing the initial blank fallback render until the remote moves focus.
- Reworked detail-page backdrop/poster treatment to avoid double-stacking a giant poster over composed artwork while still dynamically anchoring provider poster-only titles.
- Series detail seasons and episode cards now derive from the selected series metadata instead of fixed mock labels.
- Bumped manifest build version to `00097` for the detail-page sync and dynamic Series layout fix.
- Replaced Movie/Series detail action surfaces with direct rectangle/border drawing so focused buttons render reliably on Roku instead of depending on missing rounded-size assets.
- Removed the hard full-height dark overlay bands from detail backdrops; the previous section-like vertical shadows were readability overlays, not source-art bugs.
- Added explicit Series detail focus routing across Back, Resume, Favorite, Season chips, and Episode cards, plus horizontal episode-window scrolling for series with more than four episodes.
- Bumped manifest build version to `00098` for detail button polish, softer backdrop overlays, and Series episode scrolling.
- Upscaled demo Movie poster assets to the same approximate source size as Series posters and regenerated the 16:9 Movie backdrop compositions from those larger files.
- Increased Movies and Series library-page backdrop visibility slightly while keeping Movie/Series detail-page backdrop opacity unchanged.
- Removed the remaining hard-edged local dim rectangles from Movie/Series detail pages so backdrop readability no longer creates visible vertical section bands.
- Bumped manifest build version to `00099` for the Movie HD backdrop and detail-band cleanup pass.
- Stopped Movie/Series pages and detail pages from using local composed backdrop files as the main background layer; they now use the poster as the soft zoomed background with a controlled poster anchor, removing the remaining vertical center seam and fixing the disturbed Movie detail backdrop.
- Bumped manifest build version to `00100` for the composed-backdrop seam removal pass.
- Restored Movies, Series, Movie detail, and Series detail to the earlier composed-backdrop architecture after device review showed the poster-only zoom background changed the intended design too much.
- Bumped manifest build version to `00101` for the backdrop-architecture restore pass.
- Regenerated Movie composed backdrop assets so the right-side poster anchor matches the larger Series backdrop poster scale and placement.
- Bumped manifest build version to `00102` for the Movie backdrop poster-size match pass.
- Polished Movie detail typography by enlarging/recoloring the title, removing the rating from the Movie detail meta line, and increasing description line spacing.
- Restored rounded detail action surfaces with matching generated UI assets and added cleaner detail-only play/favorite/info icons.
- Rebalanced Movie backdrop compositions so the background layer shows more of the poster content with less aggressive crop while keeping the larger right-side poster anchor.
- Bumped manifest build version to `00103` for the Movie detail typography, button, icon, and backdrop-crop polish pass.
- Reduced the Movie detail Back button to the casual app size, removed the unused Details action, separated the movie title color from the section label, and matched Watch/Favorite buttons closer to the featured-card rounded style.
- Bumped manifest build version to `00104` for the final Movie detail action/back/title cleanup pass.
- Matched Movie detail Watch/Favorite controls to the Movies featured-card button styling with wider generated button assets, complete `Watch now` text, app-native play/favorite icons, and removed the static lower Quality/Source/Resume info rail.
- Bumped manifest build version to `00105` for the Movie detail button and lower-rail cleanup pass.
- Changed Movie detail titles to render uppercase and reduced package weight by removing unused reference/design images plus old demo backdrop/card-art folders, then downscaling/compressing active demo posters and backdrops.
- Bumped manifest build version to `00106`; the rebuilt channel zip is now under the 4 MB target.
- Regenerated the Movie Watch/Favorite button asset family with a slimmer 1px border for both normal and focused states.
- Bumped manifest build version to `00107` for the sleeker Movie detail button-border pass.
- Confirmed `npm.cmd run check` and `npm.cmd run build` pass, and the generated zip contains the updated startup/playlist/media files.

Next:
- Test startup on Roku: Home should launch with `Empty M3U Playlist` active, and Live TV/Movies/Series should show clean empty states until another playlist is selected.
- Test Demo Playlist selection on Roku.
- Test Demo Movies selection: Movies should show content; Live TV and Series should show empty states.
- Test fake Live M3U selection: add `https://iptvmax.test/demo-live.m3u`, select it from My Playlists, confirm Live TV shows only those parsed channels, then press OK on a channel to play its parsed stream URL.
- Implement a dedicated background `M3uSyncTask` so real provider M3U URLs are fetched/parsing outside page render, then saved into the active-playlist content model.
- Expand parser coverage for provider-specific M3U edge cases and add Xtreme API parsing into the same active-playlist content model.
- Add Favorites behavior to the existing favorite affordances across Movie/Series detail and playback screens when that roadmap item resumes.
- Add parental lock and continue-watching persistence after the detail pages are verified on device.

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
- Add Playlist submit now saves M3U/Xtreme entries into the shared playlist store and returns to My Playlists.

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

Status: Live TV, Series, Movies, My Playlists, and Settings have received polish passes.

### Settings Page

Status: first polish and backend-readiness pass completed; redesigned after Roku screenshot review and ready for another device pass.

Completed:
- Rebuilt Settings toward the supplied dark IPTV Max reference with stacked settings panels, TV-readable typography, stable focus states, and no embedded profile card.
- Corrected the first Settings Roku review issue: removed the fake top design tabs, restored the shared app `uiTopBar`, added the normal left app navigation, and respaced rows/controls so labels and toggles no longer collide.
- Corrected the second Settings Roku review issue: replaced the cramped stacked form with a low-density two-column dashboard, compact square switches, shorter value selectors, and separated Playback/App/Account panels so options cannot visually mix together.
- Corrected the third Settings Roku review issue: generated rounded panel/control assets, rounded Settings and Account sections, rounded menu boxes, reduced switch size, separated title/subtitle text hierarchy, removed My Profile from Account, and thinned focused borders.
- Corrected the fourth Settings Roku review issue: removed the Settings page sidebar from the render path, enlarged the Settings title and removed its subtitle, gave Playback/App/Account distinct section colors, reduced row subtitle prominence, added real dropdown overlays for selectable settings, and replaced App version with Clear cache in Account.
- Corrected the fifth Settings Roku review issue: moved panels back to the earlier positions, made Playback/App section colors match, reduced row subtitle size further, vertically centered selector text, strengthened Account row pill opacity, added a local cache icon, and slimmed the Back button padding/border.
- Corrected the sixth Settings Roku review issue: Account rows now have centered titles with no subtitles, no visible inner-row borders, stronger non-purple row fills, improved bottom spacing, and dedicated local sync/cache/logout account icons.
- Corrected the seventh Settings Roku review issue: restored visible Account row pills without normal borders by adding the missing `panelSoft/panelSoft` asset, removed Playback/App row subtitles, vertically centered setting titles, and restored the Back button to a dark normal background.
- Corrected the eighth Settings Roku review issue: fixed the actual Account-row asset-size mismatch by adding the exact `298x46` and `298x42` row assets so the Account pills render on Roku, with slightly taller rows and better vertical centering.
- Corrected the ninth Settings Roku review issue: changed Account row pills to a darker `bg2` tone with no normal border and green focus, replaced switches with larger mobile-style pill tracks and circular thumbs, and downloaded Google Material Symbols source SVGs for the account icon set before rasterizing local PNGs.
- Corrected the tenth Settings Roku review issue: reduced the mobile-style switch size to a smaller `50x26` track with a `20x20` thumb and regenerated Account icons from the downloaded Google Material Symbols SVG path data.
- Added persistent settings storage in `components/shared/SettingsStore.brs` using Roku registry-backed values for default quality, caption mode, autoplay, notifications, app language, parental lock, sync status, sign-in state, and profile identity metadata.
- Added a Roku certification-informed caption mode selector with system default, on, off, instant replay, and on-mute options.
- Made Account actions functional: Sync all playlists reads the shared playlist store and updates persisted sync status, App version reads `roAppInfo`, and Sign out uses a native confirmation dialog.
- Added a separate `ProfilePage` and changed all `My Profile` sidebar entries to navigate there instead of Settings.
- Bumped manifest build version to `00072`.
- Confirmed `npm.cmd run check` passes.
- Confirmed `npm.cmd run build` creates `build\roku-iptv-app.zip`.
- Applied the 2026-06-23 Roku visual-review fixes to Series: selected artwork now covers the full viewport behind a translucent top bar/sidebar, search/category pills have balanced vertical spacing and softer opacity, Popular Series cards draw a single artwork surface instead of repeating poster art, and Series detail typography/overlays were reduced for clearer hierarchy.
- Applied the follow-up 2026-06-23 list-page fixes to Series: category pill text was shifted for better visual centering, top/sidebar/pill opacity was reduced further, Continue Watching cards now use the softer Featured-card opacity style, Popular Series cards now render as full poster-only cards, and scrollbars are more transparent.
- Applied the second follow-up 2026-06-23 list-page fixes to Series: category pills now use tighter text-sized visual widths, search opacity now matches the lighter top bar treatment, sidebar rows/profile are manually drawn with lower opacity and no blue profile border, Popular Series now shows five rounded poster cards, and scrollbar opacity was reduced further.
- Applied the third follow-up 2026-06-23 list-page fixes to Series: shared labels now honor requested font sizes, Popular Series cards are slightly larger with thicker focused borders, card corner masks were removed after poor rendering, poster fallback was removed from the page background to prevent image-over-image repetition, and scrollbars now draw as plain rectangles without cap dots.
- Emergency-fixed the 2026-06-23 text rendering regression from build `00111`: removed the shared `uiLabel` custom Font assignment because it blanked labels on the Roku device, and bumped manifest build version to `00112`.
- Applied the fourth follow-up 2026-06-23 list-page fixes: added a safe scaled-label helper without custom Font nodes, reduced Movies Featured badge/text and metadata visually, softened Movies/Series backgrounds to reduce image-over-image repetition and dark banding, enlarged poster cards slightly, made focused card borders thicker, tuned profile button vertical spacing, reduced Series Continue Watching subtitle/button text, restored rounded scrollbar thumbs with plain tracks, and bumped manifest build version to `00113`.
- Applied the 2026-06-24 list-page follow-up: tightened Movies/Series category pills, slightly reduced the Movies Featured Watch Now control, added a little more poster-card spacing, replaced repeated full-screen selected backdrops with one muted base image plus a right-side selected-art overlay, matched Series section spacing to Movies, extended the Home background under the top/sidebar shell, and bumped manifest build version to `00114`.
- Corrected the `00114` list-page background regression in build `00115`: restored Movies/Series to selected movie/series backdrops instead of the Home artwork, removed the extra right-side duplicate backdrop layer, and returned poster-card horizontal spacing to the previous tighter layout.
- Refined the Movies/Series dynamic background treatment in build `00116`: generated lightweight poster-derived full-screen background assets, kept one selected poster overlay on the right, and stopped drawing the composed backdrop as both the full-screen background and right-side artwork.
- Tuned the `00116` background split in build `00117`: full-screen Movies/Series background art now stretches with `scaleToFill`, while the right-side overlay uses the earlier composed selected-art placement and softer opacity.
- Corrected the build `00117` background disturbance in build `00118`: regenerated Movies/Series full-screen background assets from the cleaner composed-backdrop area instead of stretched poster crops, reduced center background intensity, and standardized sidebar text so normal sidebar labels are white while focused/active labels use the cyan border color.
- Reverted the sidebar text-color experiment in build `00119` back to the previous soft-green normal and white focused/active behavior, and replaced the problematic title-derived Movies/Series base backgrounds with a generated cinematic AI-style background asset while keeping the selected title artwork on the right.
- Corrected build `00119` in build `00120`: Movies/Series list pages no longer use the old composed `movie_backdrops`/`series_backdrops` artwork for the right-side overlay; the list pages now use the generated cinematic base background plus a clean selected poster overlay.
- Corrected build `00120` in build `00121`: removed the separate right-side poster overlay entirely on Movies/Series list pages and returned to a single full-screen selected title image as the only page background layer.
- Corrected build `00121` in build `00122`: Movies/Series list pages now use one stretched full-screen cinematic base background plus one large right-side selected poster layer, avoiding the old composed backdrop repetition while keeping the right poster treatment.
- Reworked the rejected build `00122` background treatment in build `00123`: replaced the weak dark background with a newly generated full-screen cinematic AI background, kept the selected poster as a smaller integrated right-side hero accent, and applied the same non-repeating treatment to Movies and Series.
- Replaced the still-too-generic build `00123` backdrop in build `00124`: generated a purpose-built IPTV media-room background with floating channel tiles, streaming light paths, and a right-side media-wall zone, then wired Movies and Series to use that IPTV-specific artwork.
- Tuned the visually loud build `00124` backdrop in build `00125`: lowered the IPTV artwork strength, moved the selected poster into a larger center-right hero position with softened edge blending, and temporarily reused the same IPTV backdrop on Home.
- Reworked build `00125` into build `00126`: generated a softer IPTV-branded backdrop, added a subtle crisp `IPTV MAX` background wordmark in code, and changed Movies/Series selected artwork from portrait poster overlays to larger centered wide hero images using title backdrop/card art.
- Corrected build `00126` in build `00127`: removed the duplicate selected-art glow layer so Movies/Series draw only one centered wide hero image, replaced the background with a new IPTV artwork file that has the `IPTV MAX` styling baked into the image, and removed the separate code-drawn background wordmark.
- Corrected build `00127` in build `00128`: stopped using composed backdrop art for Movies/Series list-page heroes, so selected artwork now draws once as a single wide full-height background layer from card/poster art, and removed the Home `QUICK ACCESS` heading.
- Updated build `00129` after Roku review: Movies/Series list heroes now use the original poster first, centered full-height with blended edges and visible branded background on both sides; movie demo card URLs were changed away from old `card_fill` dummy artwork; Movie and Series detail pages now share the same IPTV-branded background treatment.
- Tuned build `00130` after Roku review: widened the selected poster hero slightly, added top/bottom breathing room, removed the dark edge-mask bands, and aligned the list/detail hero positioning so transitions feel consistent.
- Verified the packaged zip contains `components/MainScene.*`, `components/pages/SettingsPage.*`, `components/pages/ProfilePage.*`, and `components/shared/SettingsStore.brs`.

Needs future review:
- Test Settings and Profile focus movement on actual Roku.
- Confirm the new full-width Settings layout matches the supplied reference from couch distance.
- Wire Profile manage-subscription and sign-in/account actions to the selected backend/payment provider.

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
- Applied the 2026-06-23 Roku visual-review fixes to Movies: selected artwork now extends under the top bar/sidebar, search and category pills use balanced supported rounded-control sizes with lower opacity, the Featured card/badge/meta hierarchy was softened, movie cards were widened and changed to a single scaled artwork surface, and Movie detail typography/overlays were reduced. Manifest build version is now `00108`.
- Applied the follow-up 2026-06-23 list-page fixes to Movies: category pill text was shifted for better visual centering, top/sidebar/pill opacity was reduced further, Featured badge was restored to badge styling instead of button styling, Featured metadata was reduced again, movie cards now use actual poster artwork as full poster-only cards with no text strip, scrollbars are more transparent, and manifest build version is now `00109`.
- Applied the second follow-up 2026-06-23 list-page fixes to Movies: category pills now use tighter text-sized visual widths, search opacity now matches the lighter top bar treatment, sidebar rows/profile are manually drawn with lower opacity and no blue profile border, Featured card width was shortened with smaller metadata, movie rows now show five rounded poster cards, scrollbar opacity was reduced further, and manifest build version is now `00110`.
- Applied the third follow-up 2026-06-23 list-page fixes to Movies: shared labels now honor requested font sizes so Featured metadata actually shrinks, Featured card and badge were shortened again, movie cards are slightly larger with thicker focused borders, card corner masks were removed after poor rendering, poster fallback was removed from the page background to prevent image-over-image repetition, scrollbars now draw as plain rectangles without cap dots, and manifest build version is now `00111`.
- Applied the 2026-06-24 Movies/Series/Home list-shell follow-up in build `00114`: category pills and the Featured Watch Now button were tightened, poster-card spacing was increased slightly, Movies/Series now use a single muted full-screen base background with only the selected art on the right, Series vertical spacing was matched closer to Movies, and Home artwork now extends under the top/sidebar shell.
- Corrected the `00114` Movies/Series background treatment in build `00115`: Movies/Series no longer show the Home background, selected page artwork is dynamic again, the extra duplicate right-side backdrop layer was removed, and poster-card spacing was restored to the previous tighter row.
- Added build `00116` background separation for Movies/Series: new lightweight `movie_backgrounds` and `series_backgrounds` assets provide the single full-screen dynamic image, while poster art renders once as the right-side overlay to avoid repeated composed artwork.
- Tuned build `00117` so the full-screen dynamic background stretches instead of zooming/cropping, and restored the right overlay to the earlier composed-backdrop placement/opacity.
- Updated build `00118` after Roku review: regenerated the dynamic background layer from the cleaner backdrop crop, lowered its visual intensity, and changed sidebar text behavior across pages from green-normal/white-focused to white-normal/cyan-focused.
- Updated build `00119` after Roku review: reverted sidebar text behavior to the previous green-normal/white-focused treatment and switched Movies/Series to a generated cinematic base background so the center art no longer looks like broken or repeated title artwork.
- Updated build `00120` after Roku review: removed old composed backdrop artwork from the Movies/Series list-page right overlay and replaced it with clean poster-only artwork over the generated cinematic base.
- Updated build `00121` after Roku review: removed the separate right poster overlay and restored Movies/Series list pages to one full-screen selected background image only.
- Updated build `00122` after Roku review: restored the right-side poster treatment while using a single stretched cinematic base background instead of zoomed or repeated title artwork.
- Updated build `00123` after Roku review: replaced the rejected dark background with a generated cinematic full-screen background and reduced the right poster into an integrated hero accent on both Movies and Series.
- Updated build `00124` after Roku review: replaced the generic cinematic backdrop with a purpose-made IPTV media-room artwork that visually supports Live TV, VOD, Series, playlists, and streaming signals.
- Updated build `00125` after Roku review: pushed the IPTV backdrop behind the UI, enlarged and centered the selected poster treatment with softened edges, and applied the IPTV backdrop to Home for visual consistency.
- Updated build `00126` after Roku review: replaced the busy IPTV backdrop with a softer branded IPTV background, added a low-opacity `IPTV MAX` wordmark, and made the selected title art a wide centered hero layer behind Movies/Series content.
- Updated build `00127` after Roku review: removed repeated/duplicated hero artwork by deleting the extra selected-art glow layer, widened the single centered hero image, and changed Home/Movies/Series to a new IPTV MAX art backdrop with the brand styling embedded in the asset.
- Updated build `00128` after Roku review: removed the right-side composed-backdrop repetition by using card/poster art before fallback backdrop art for the selected hero layer, expanded that single hero image to the full content height, and removed `QUICK ACCESS` from Home.
- Updated build `00129` after Roku review: enlarged the selected poster hero vertically to touch top/bottom while narrowing it so the IPTV background remains visible on both sides, switched Movies demo cards away from `card_fill` assets to real posters, and applied the same IPTV/poster background treatment to detail pages.
- Updated build `00130` after Roku review: changed the hero poster position to `390,24,730,672` on Movies/Series and both detail pages, removed the dark side/top/bottom masks that created visible bands, and kept only a light whole-poster blend overlay for softer integration.
- Updated build `00131` after Roku review: widened the list/detail hero poster slightly to `370,28,770,664`, removed the remaining center dark background slab, and replaced hard poster edges with narrow fade strips so the poster sits over the IPTV backdrop instead of looking pasted on.
- Updated build `00132` after Roku review: increased list hero poster opacity to `0.44`, increased detail hero poster opacity to `0.46`, and centered the detail-page poster at `255,28,770,664` while keeping the dynamic selected-item poster source.
- Updated build `00133` after Roku review: made the Movies/Series list and detail hero poster body opaque enough to stop the IPTV background bleeding through it, while retaining the edge fade treatment.
- Updated build `00134` after Roku review: moved the Movie/Series detail hero poster to a right-biased position at `400,28,770,664`, leaving visible space on the right while keeping the list-page hero position unchanged.
- Updated build `00135` after demo-art review: added dedicated `1920x1080` demo hero assets under `images/demo/hero`, added original demo titles `Neon Horizon` and `Signal House`, and wired `heroUrl` through Movies/Series list and detail navigation so demo heroes no longer stretch the small poster-card artwork.
- Updated build `00136` after demo-art review: replaced demo movie/series card URLs with `720x1080` HD poster assets, regenerated demo heroes from those HD posters plus the IPTV backdrop instead of the old duplicate-composed backdrop folders, and changed list/detail hero rendering to full-screen smoke-blended artwork so visible poster rectangle edges are not drawn.

Needs future review:
- Test Movies page focus movement on actual Roku.
- Confirm movie card text sizing and featured panel spacing from couch distance.
- Confirm search keyboard behavior on Roku.

### My Playlists Page

Status: first polish pass completed; ready for Roku visual review.

Completed:
- Compared the current Roku screenshot with the supplied target My Playlists design reference.
- Rebuilt My Playlists into the target-inspired structure: shared app shell, title/summary header, add/search actions, three-column playlist cards, status pills, card refresh/delete actions, and footer sync summary.
- Kept the app's existing purple/green contrast and added a subtle live-channel badge backdrop from the Live TV assets.
- Added `components/shared/PlaylistStore.brs` as a local persistence layer for backend-shaped playlist records.
- My Playlists now loads dynamically from the shared playlist store, supports search with the custom Roku keyboard, refreshes playlist sync state, deletes playlists, and opens playlists into Live TV.
- Add Playlist now writes new M3U/Xtreme accounts into the same store so user-added playlists appear on My Playlists.
- Bumped manifest build version to `00051`.
- Confirmed `npm.cmd run check` passes.
- Confirmed `npm.cmd run build` creates `build\roku-iptv-app.zip`.
- Verified the packaged zip contains `components/MainScene.*`, `components/pages/MyPlaylistsPage.*`, `components/shared/PlaylistStore.brs`, and the updated manifest.
- Fixed first Roku review issues on My Playlists: moved Search into the top bar, made cards taller with supported thin rounded card assets, moved Live TV artwork into each card instead of the page background, reduced border weight, and bumped manifest build version to `00052`.
- Simplified My Playlists cards after Roku review: compact `260x152` cards, status moved to top-left, removed card icons/channel counts/REF action, showed playlist type only, reduced update text size, matched sidebar behavior to other pages, and bumped manifest build version to `00053`.
- Added My Playlists scrolling/dynamic behavior after Roku review: larger scaled cards, 10 demo playlists aligned with app sections, sleek scrollbar, full Delete pill, delete confirmation overlay, corrected Delete/right focus routing, removed the card-left artifact, and bumped manifest build version to `00054`.
- Refined My Playlists cards after Roku review: slightly larger cards, stronger card artwork, purple Active pills, rounded Delete button with cleaner color/focus shape, and native Roku delete confirmation dialog; manifest build version is now `00055`.
- Tuned My Playlists card layering after Roku screenshot review: artwork now fills the card background, status pills share one rounded `100x40` shape with distinct colors, Delete keeps a stable rounded fill while only the border changes on focus, and manifest build version is now `00056`.
- Restored stronger My Playlists card artwork after Roku screenshot review, switched status pills to the Movies featured-badge styling, changed playlist title color only, moved a smaller Watch Now-style Delete button fully inside the card, and bumped manifest build version to `00057`.
- Tightened My Playlists remote/focus behavior after Roku review: centered status text inside badges, reduced Delete button size/text with its own stable focus state, strengthened focused-card contrast, fixed left/right card-grid navigation, and bumped manifest build version to `00058`.
- Final small My Playlists polish pass: reduced status badge size, moved Delete upward with smaller text and Watch Now-style focus asset swap, matched focused-card overlay opacity to Live TV channel-list focus, thinned the scrollbar, and bumped manifest build version to `00059`.
- Fixed My Playlists top-row focus routing so Up from playlist cards reaches Add Playlist instead of skipping to Search, softened the focused-card shell overlay while keeping the Live TV channel-list tint value, and bumped manifest build version to `00060`.
- Fixed My Playlists header focus routing so Add Playlist can move Up to Search and Search can move Down to Add Playlist, changed the search placeholder to `Search My Playlist`, reduced focused-card overlay opacity, and bumped manifest build version to `00061`.

Needs future review:
- Test My Playlists on actual Roku for card text scale, action focus movement, and search keyboard behavior.
- Confirm local registry persistence is enough until the real backend/API integration is selected.

Screens still expected to need design pass:
- None currently known; continue Roku-device visual review page by page.

## Current Implementation Notes

- `components/pages/AddPlaylistPage.brs` owns Add Playlist layout and local sidebar rendering.
- `components/pages/MyPlaylistsPage.brs` owns the polished playlist manager layout, search keyboard, and card actions.
- `components/shared/PlaylistStore.brs` owns local playlist persistence and demo playlist fallbacks until a real backend or playlist parser replaces it.
- `components/shared/SettingsStore.brs` owns local registry-backed settings/profile state until the real account backend replaces it.
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

## 2026-06-26 Series Detail Polish

- Reworked Movie and Series detail action buttons into larger transparent card-style controls using the app green focus treatment.
- Reworked Series detail seasons into stronger app-colored buttons and made OK/down on a season move focus directly into the first episode row.
- Reworked Series episode rows into narrower rounded palettes with larger episode titles, rounded thumbnail frames, season-wise episode numbering, and vertical up/down episode navigation.
- Bumped Roku manifest build version to `00150` for the detail-page focus and styling pass.

## 2026-06-26 Series Detail Selection Follow-up

- Added the pasted play and heart icons as UI detail action assets and wired them into Movie and Series detail action buttons.
- Changed Series season behavior so moving across season buttons only moves focus; pressing OK or Down commits the selected season and then jumps to the first episode.
- Adjusted Series episode rows upward and rightward, reduced row height, kept rounded row/thumb treatment, added a small season subtitle, and reset each season to `Episode 1`.
- Bumped Roku manifest build version to `00151` for the season-selection and episode-row follow-up.

## 2026-06-26 Detail Rhythm Follow-up

- Moved Movie and Series detail action buttons upward, reduced them back to rounded pill controls, and removed the inner icon chip so the pasted icons sit alone.
- Reworked Series season focus so season movement does not rerender episodes until OK/Down commits the season; season buttons can now wrap onto a second row for larger season counts.
- Shifted Series episode rows farther right and upward, brightened the `EPISODES` heading, reduced row height, removed thumbnail outline frames, and kept the small season subtitle under each episode title.
- Bumped Roku manifest build version to `00152` for the detail rhythm and remote-focus update.

## 2026-06-26 Series Detail Spacing Follow-up

- Lowered the Series seasons block to create clearer spacing below the Resume/Favorite buttons.
- Split selected-season styling from focused-season styling, with selected seasons using a subtler purple treatment and focus using the app green treatment.
- Increased visible Series episode rows from four to five and added a sleek transparent episode scrollbar for longer seasons.
- Bumped Roku manifest build version to `00153` for the season spacing and episode scrollbar pass.

## 2026-06-26 Series Episode Data Follow-up

- Moved Series season buttons farther below the `SEASONS` heading and pushed the episode scrollbar farther away from the episode cards with lower opacity.
- Added `detailEpisodeNames` and `detailActiveEpisodeTitle` detail fields so backend-provided episode names can render in episode rows, with `Episode 1`, `Episode 2`, etc. as fallback labels.
- Bumped Roku manifest build version to `00154` for the season spacing, scrollbar opacity, and episode-title data hook.

## 2026-07-01 Phase 1 First-Run Onboarding

- Added a first-launch `WelcomePage` with Start 7-Day Trial, Add Playlist, and Buy Subscription choices plus a purpose-built IPTV onboarding background.
- Added registry-backed onboarding completion and trial-start state. Trial activation selects the protected Demo Playlist, which remains available after future upgrades.
- Add Playlist completes onboarding only after a playlist is successfully saved; leaving setup early returns to Welcome.
- Buy Subscription records purchase intent and shows an honest Roku-billing handoff without granting a fake entitlement or charging the user.
- Bumped the manifest to `00180`; `npm.cmd run check` passes and the fresh package includes the new screen, onboarding store, background, and updated manifest.
- Roku follow-up in build `00181`: replaced the hard center split with the detail-page smoke blend, reduced Welcome to 7-Day Free Trial and Buy Subscription, made both button surfaces use verified packaged assets, reduced supporting typography, and routed Buy Subscription directly to Add Playlist for the current phase.
- Roku follow-up in build `00182`: reduced both Welcome controls to compact app-style buttons, restored purple-normal/green-focused behavior, enlarged button titles, removed trailing arrows, and restored the single no-card-required trial note.
- Roku follow-up in build `00183`: moved Welcome controls to a balanced `380x72` size, reduced title scale, applied the transparent rounded Movie/Series detail-button surface behavior, increased spacing before the no-card note, and introduced a versioned onboarding background with three subtly distributed `IPTV MAX` television tiles while retaining the detail-page smoke blend.
- Roku follow-up in build `00184`: shifted Welcome button text farther inward, replaced the heavy cyan outlines with subtle rounded transparent surfaces in both normal and focused states, and changed the trial note to the white `No card information is required for the free trial.` copy.
- Roku follow-up in build `00185`: restored the more rounded detail-page button shape with reduced normal/focus opacity for sleeker borders, while changing the no-card trial note to the shared muted subtitle color.

## 2026-07-01 Phase 2 Playlist Lifecycle

- Extended Add Playlist into a reusable Add/Edit flow with one-shot edit routing, prefilled M3U/Xtreme fields, duplicate-name validation that excludes the current record, secure password display, a visible validation state, and protected built-in playlist safeguards.
- Added playlist update, lookup, pending-edit, and detailed refresh-result helpers to `PlaylistStore.brs`.
- Replaced the card-level Delete-only action with a unified Manage flow. User playlists now offer Refresh, Edit, Delete, and Cancel; protected Demo playlists expose Refresh and Cancel only.
- Refresh now shows a temporary Syncing state, validates locally available M3U/Xtreme details, reports honest success/failure feedback, and leaves provider content synchronization marked as pending until backend integration.
- My Playlists now identifies the active playlist directly on its card, reports lifecycle feedback, preserves delete confirmation, and falls back safely to Empty M3U Playlist when the active user playlist is removed.
- Bumped the manifest to `00186` for the complete local playlist-lifecycle pass.
- Roku review follow-up in build `00187`: restored My Playlists to clean activation-only cards with no per-card Manage/Delete action, added a dedicated `Manage Playlists` header button beside Add Playlist, and created `ManagePlaylistsPage` for scrolling playlist rows with Refresh, Edit, and Delete actions. Protected built-in playlists expose Refresh only, edits return to the management page, and Add/Edit Back behavior now returns to the appropriate playlist screen.
- Roku review follow-up in build `00188`: changed both My Playlists header actions to transparent rounded detail-style controls, removed the Manage Playlists icon, and added explicit Search/Manage/Add/card-grid focus routes so the Manage action follows the app's normal green focus behavior reliably.
- Roku review follow-up in build `00189`: swapped the My Playlists header order to Add Playlist then Manage Playlists, removed the visible Back control from Manage Playlists while retaining Roku Back behavior, widened status badges so `Protected` renders fully, and made Refresh/Edit/Delete visible on every row. Edit/Delete remain safely locked for built-in playlists and display an explanatory inline message when selected.
- Temporary Roku test build `00190`: unlocked Edit/Delete only for Empty M3U Playlist, added a persistent deleted-empty override with Demo Playlist as the active fallback, retained protection for Demo Playlist/Demo Movies, and changed management badge widths to follow label length with explicit inner padding.
- Final Phase 2 build `00191`: restored the original Empty M3U Playlist regardless of the temporary deletion marker, re-protected every built-in playlist, and made Refresh/Edit/Delete widths derive from their own label text with right-aligned dynamic placement. Corrected My Playlists to show exactly one Active badge, use Ready for other connected records, report active/ready/offline totals honestly, and avoid invented last-sync times. Completed a final static audit of add/edit validation, password masking, active selection, refresh feedback, protected actions, user deletion fallback, scrolling, focus routing, and Add/Edit return destinations.
- Roku visual follow-up in build `00192`: lowered Refresh/Edit/Delete labels inside their 40px management controls to balance top and bottom spacing and optically center the text.

## 2026-07-01 Phase 3 Playback Foundation

- Added explicit `playbackMediaType` routing through Live TV, Movies, Series, detail pages, Favorites, MainScene, and PlayerPage so Live and VOD behavior no longer depends on return-page guessing.
- Rebuilt PlayerPage around preparing, buffering, playing, paused, reconnecting, finished, and terminal error states.
- Added two automatic reconnect attempts, then a focused Retry Stream / Go Back error screen with friendly network, timeout, empty-stream, unsupported-format, and DRM messages.
- Split controls by media type: Live playback now shows Live plus Play/Pause and Audio/Subtitle controls, while VOD retains Restart, 30-second seek, Play/Pause, progress, and track controls.
- Integrated saved caption mode and guarded quality preference application. Added a custom Options/track menu using Roku Video fields for available audio/subtitle tracks and track selection.
- Preserved automatic control hiding, restored controls on remote input, retained exact prior-page restoration, and added a Replay / Go Back completion screen.
- Verified all three bundled HLS manifests respond successfully, all player assets exist, and `npm.cmd run check` creates build `00193`.

## 2026-07-02 Phase 3 Final Player Review

- Finalized distinct Live/VOD overlays, one red top-right Live badge, larger safely positioned titles, an animated circular buffering indicator, matching transport icons, and compact Playback Settings.
- Added focused Captions, Audio, Subtitles, and Quality controls with nested dropdowns, eight-item scrolling windows, range feedback, demo-only track previews, saved quality limits, and VOD position restoration after quality changes.
- Corrected Roku track selection to use `Track` for audio and `TrackName` for subtitles, restored automatic audio selection from Default, enabled seamless HLS audio switching where supported, and preserved parent-row focus when leaving submenus.
- Kept retry/error/completion handling, control auto-hide, prior-page restoration, Live/VOD classification, and protected invalid position/duration reads intact.
- Final audit resolved a missing normal-row asset reference, verified every direct PlayerPage package asset, confirmed all three demo HLS manifests return HTTP 200, and produced build `00205`.

## 2026-07-02 Phase 4 Continue Watching and Resume

- Added registry-backed playback progress keyed by playlist, media type, and media ID, capped to the 40 most recent records per playlist.
- PlayerPage now saves VOD progress every 10 seconds and on pause/back, resumes movies and the exact saved series episode, preserves position through quality changes, and removes completed/restarted entries.
- Movie and Series detail actions now change between Play/Watch and Resume from real saved progress. Series detail restores the saved season and episode selection.
- Replaced hard-coded Series Continue Watching percentages with recent saved entries, a real progress bar, episode context, an empty state, and playlist-isolated ordering.
- Removed all `22 min left`-style demo copy because it could become inaccurate; Continue Watching now relies on progress rather than estimated remaining time.
- Added page-refresh hooks so detail and Series pages update immediately after returning from playback.
- Bumped the manifest to `00206`; final validation and package verification are required before handoff.
- Roku follow-up in build `00207`: capped Series Continue Watching to the five most recent records per playlist with oldest-entry eviction, aligned season/progress/Resume content farther left, increased progress-to-button spacing without changing bottom padding, and removed the square focus tint so focused cards retain rounded corners.
- Roku visual follow-up in build `00208`: aligned the season label, progress bar, and Resume button with the series-title column, and rebuilt Continue Watching focus as a rounded low-opacity green layer plus the existing green focus border.
- Player settings cleanup in build `00209`: removed the duplicate Captions row, leaving Audio, Subtitles, and Quality. Subtitle selection still enables captions automatically, while Off disables them.
- Series navigation follow-up in build `00210`: removed horizontal wrapping from Popular Series and Continue Watching, routed Left from each first card to the Series sidebar item, kept Right on each last card in place, and made Up from Continue Watching visibly focus the selected category pill.
