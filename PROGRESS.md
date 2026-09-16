# IPTV App Progress

Last updated: 2026-09-16

## 2026-09-16 Bounded Movies and Series Hero Prefetch

- Focused Movies and Series backdrops were still taking one to three seconds on their first display because the remote image request began only after focus landed on that item. Loading/failed fallback artwork prevented a blank screen but did not start the provider request earlier.
- Added one hidden, bounded `1280x720` prefetch Poster per Movies or Series page. After a catalog response it warms the selected item's explicit remote backdrop; during horizontal navigation it warms only the next item in the movement direction. Existing card-only dimension probes remain separate and continue to reject unsuitable portrait/logo artwork.
- The prefetch node is replaced instead of accumulated, and it is removed on first-page/category reload and page disposal. This caps the added decoded texture footprint to one image per active page and avoids returning to the unbounded-memory crash pattern.
- This improves sequential remote browsing when `backdrop_url` is already present in the catalog row. A first uncached image can still take provider network time, and a backdrop available only from `/channels/{id}` or `/series/{id}` cannot be prefetched until that detail response exposes its URL. The long-term backend path is to include normalized backdrop URLs in list rows and serve Roku-sized cached images through a CDN with effective cache headers.
- Bumped the manifest to build `00281`. The page/UI suite passes 55 checks, backend/navigation passes 87 contracts, keyboard/image loading passes 36 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Immediate Series Default Background During Remote Loading

- A second device check showed the Series list could remain visually plain while a selected remote backdrop was loading, and Series Detail could still display an unresolved remote Poster instead of the packaged fallback. A base layer alone was insufficient because the remote Poster owns its loading surface.
- Extended the shared zoom-poster helper with an optional fallback URI that is assigned to both SceneGraph `loadingBitmapUri` and `failedBitmapUri` before the remote `uri` starts loading.
- Series list and Series Detail hero Posters now use `movies_series_fallback_backdrop_v6.jpg` during remote loading and after a remote image failure. When a row has no card, logo, hero, or backdrop URL, the existing empty-artwork branch also uses the same packaged background. Successful provider backdrops replace the fallback normally.
- This changes only artwork presentation; Series categories, focus, detail loading, season numbers, episodes, and playback remain unchanged.
- Bumped the manifest to build `00280`. The page/UI suite passes 52 checks, backend/navigation passes 87 contracts, keyboard/image loading passes 36 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Series Detail Persistent Artwork Fallback

- Device testing confirmed that Series list rows with no provider poster correctly retain an empty card and the packaged page background, but the Series detail page could become a blank gray surface. The artwork field was sometimes nonempty even though the remote image was slow, broken, or rejected, so the detail renderer chose a remote Poster without keeping the packaged fallback underneath it.
- Series Detail now draws `movies_series_fallback_backdrop_v6.jpg` as the base layer before attempting any remote hero/backdrop. Valid remote artwork still covers the base normally; missing, delayed, failed, or blocked artwork leaves the app fallback visible immediately.
- Added a page contract that verifies the packaged fallback is created before the remote hero branch. Bumped the manifest to build `00279`. The page/UI suite passes 50 checks, backend/navigation passes 87 contracts, keyboard/image loading passes 36 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Series Artwork Extraction and Focused Recovery

- Verified the current backend contract: Series list and detail records expose normalized artwork through `cover_url`, while provider-specific raw values can remain inside the arbitrary `metadata` object. The Roku Task boundary previously discarded aliases such as `cover`, `cover_big`, `series_image`, `stream_icon`, and array-valued `backdrop_path`, leaving valid provider artwork unavailable to the Series mapper.
- The Task now extracts only bounded scalar artwork aliases from the top-level record, `metadata`, and one nested `metadata.info` object. The Series mapper and detail page prefer canonical fields, then use these validated aliases; arbitrary nested provider objects still do not cross into SceneGraph.
- Added a 250 ms focused-Series fallback only when a structured Series list row has no card artwork. It makes one cancellable `/series/{id}` request, updates the card and explicit backdrop if detail data supplies them, and leaves rapid focus changes retryable. It does not preload all detail records in a large account and does not modify season numbers, season routing, episodes, or playback.
- Explicit Series backdrop fields now render immediately. Only an unknown card/cover candidate uses the existing bitmap-dimension eligibility probe, so a declared backend backdrop no longer waits behind the poster classifier.
- If both Series list and detail responses lack a valid artwork URL, the fallback card remains correct and the missing image is provider/backend data rather than a Roku extraction failure.
- Bumped the manifest to build `00278`. The page/UI suite passes 49 checks, backend/navigation passes 87 contracts, keyboard/image loading passes 36 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Movie Preview Retry and Provider Title Recovery

- Follow-up device testing showed some focused backdrops still waiting one to two seconds and some cards remaining on the `Movie` fallback. The focused enrichment implementation had two state defects: hero-probe cleanup recreated the preview Timer and cleared the active Task reference, and a request was marked attempted before it completed, so a focus-change cancellation could permanently block its retry.
- Hero-probe cleanup now touches only the probe. The preview Timer is created once per page, an in-flight request keeps its observer/reference until completion or an explicit cancellation, and cancelled requests remain eligible when focus returns. A completed success or terminal failure remains bounded to one attempt for that loaded row.
- Verified the current public OpenAPI contract: both `ChannelListItemData` and `ChannelDetailData` expose `name`, nullable `tvg_name`, `poster_url`, and `backdrop_url`; no guaranteed `title` field exists. Their arbitrary `metadata` object can still contain original provider names.
- The Task boundary now extracts only bounded scalar aliases such as provider `title`, `o_name`, `original_name`, `movie_name`, and `name` from top-level metadata or one nested `info` object. Nested metadata itself remains excluded. Generic `Movie`, `VOD`, and `Untitled` values are treated as missing so a recovered provider name can replace them.
- A true one-to-two-second first load can still occur when the catalogue row lacks `backdrop_url`: Roku must obtain the detail record and then download the remote image. The long-term backend correction is to denormalize the resolved title and backdrop into each list row during import/detail refresh.
- Bumped the manifest to build `00277`. The page/UI suite passes 45 checks, backend/navigation passes 85 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Movie Title Recovery and Focused Hero Enrichment

- Device review exposed two catalogue/detail differences. Some Movies list rows contained malformed provider names such as `()` or `()-DE-` even when a usable `title` or `tvg_name` existed, and the main page sent explicit backend backdrops through the hidden poster-dimension probe before displaying them.
- Movie mapping now selects the first usable value from `name`, `title`, and `tvg_name`. Punctuation-only or short punctuation-wrapped metadata falls back to a readable `Movie` label and is marked for detail enrichment instead of rendering a blank overlay.
- Explicit `hero_url` and `backdrop_url` values now start loading directly on the Movies page. The dimension probe remains only for poster/card images whose landscape suitability is unknown, preserving the agreed protection against stretching portrait or logo artwork across the background.
- Added a 250 ms focused-item debounce. When the visible catalogue row has no explicit hero or needs a title, one cancellable `/channels/{id}` request enriches that row with detail title, poster, backdrop, description, year, duration, rating, and group data. Fast focus movement cancels obsolete work, successful and failed attempts are bounded to once per loaded row, and page disposal stops the Timer and Task.
- Bumped the manifest to build `00276`. The page/UI suite passes 43 checks, backend/navigation passes 84 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Live TV Decorative Header Filtering

- Device review showed Live TV cards named `######## UK ########`, `#US#`, and similar provider decorations. These are Xtream bouquet/country headers imported as `content_type=live` rows, not missing logos for legitimate channels. The previous Roku mapper accepted every active Live row, so the ordinary no-artwork fallback exposed them as channel cards.
- Added a conservative client-side filter before Live rows enter the catalogue. A decoration-dominated name is rejected only when the row also has no valid logo, poster, backdrop, or `tvg_id`. Ordinary names such as `Channel #1`, valid artwork-bearing rows, guide-backed rows, and legitimate channels that simply omit artwork remain browseable.
- Documented that the backend importer should discard these decorative rows during ingestion. The Roku filter fixes existing imported playlists visually, while the backend cleanup is still needed for exact server totals, pagination, and other clients.
- Bumped the manifest to build `00275`. The page/UI suite passes 41 checks, backend/navigation passes 82 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Live TV Artwork Retention and Movie Poster Fallbacks

- Traced the Live TV artwork disappearance after opening a channel and pressing Back to `startBackendLivePlaybackLoad()`. Channels whose list row omitted `stream_url` launched a detail lookup and immediately rebuilt the whole grid, discarding all loaded Poster nodes just before Player navigation. Removed that rebuild, so the retained Live TV page keeps its existing logo textures and focus state while the stream URL resolves.
- Live TV rows now preserve `logo_url`, `poster_url`, and `backdrop_url` independently. Provider poster artwork is rendered with `scaleToFit`, preventing portrait or logo-shaped assets from being cropped in the channel card.
- Movies now accept `cover_url` when `poster_url` is absent and can use a real `backdrop_url` as the card fallback only when neither poster/cover nor logo artwork exists. Poster/cover remains first priority, logo second, and backdrop third. Rows lacking every supported artwork URL still use the app fallback; that remaining case requires provider/backend artwork enrichment rather than another client-side substitution.
- Bumped the manifest to build `00274`. The page/UI suite passes 41 checks, backend/navigation passes 80 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. Physical Roku testing remains required to measure provider image latency and confirm Back retention on the authenticated large Xtream account.
## 2026-09-16 Xtream Category Isolation Across Live TV, Movies, and Series

- Audited category retrieval across all three catalogue pages after a large Xtream account showed irrelevant or confusing category pills. Media rows were already requested with the correct `live`, `movie`, or `series` type, but category metadata was inconsistent: Series fetched the dedicated typed groups endpoint while Movies and Live TV relied on the groups embedded in bootstrap.
- Verified against the current backend OpenAPI contract that `/api/v1/playlists/{playlist_id}/groups` accepts `content_type` and returns group names with `channel_count`.
- Live TV, Movies, and Series now retrieve first-page categories from `/groups?content_type=live`, `/groups?content_type=movie`, and `/groups?content_type=series` respectively. Selecting a displayed category still sends its exact raw backend group value, preserving provider-specific routing while preventing categories from another content type from entering the page.
- Preserved `channel_count` through the bounded SceneGraph task response and hide only groups explicitly reported with zero items. Providers that omit counts remain compatible. Provider-supplied category wording is intentionally retained; physical testing of the authenticated Xtream account is still required to judge those names.
- Bumped the manifest to build `00273`. The page suite passes 38 checks, backend/navigation passes 77 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Movies Hybrid Hero Selection

- Movies previously differed from Series: it rendered only explicit `hero_url`, `backdrop_url`, `background_url`, or `fanart_url` fields and never evaluated a poster-only row for a usable background.
- Movies now follows the same bounded hybrid rule as Series. Explicit background artwork takes priority; otherwise a non-logo card image can qualify only after Roku loads it and confirms it is at least 640x300 with a landscape aspect ratio from 1.45 through 2.4. Portrait, logo, small, failed, and extreme-ratio images retain the packaged default background and right-side fitted artwork.
- Eligibility is cached per URL for the page lifetime. Only one invisible dimension probe exists at a time, focus changes cancel the previous probe, and page disposal removes it. Movie cards and the Featured mini-poster remain on `scaleToFit` and are never changed to zoom.
- The selected qualified hero is passed through the existing Movie Detail navigation fields, keeping the list and detail view consistent without adding a second detail-page probe.
- Added the shared `MediaArtwork.brs` dependency to `MoviesPage.xml` and a regression contract for it. Bumped the manifest to build `00272`. The page suite passes 38 checks, backend/navigation passes 74 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Series Card Crop Rollback and Movies Hero Audit

- Physical Roku review of build `00270` confirmed that filling a portrait Series card with qualified landscape hero artwork crops the image too aggressively. There is no non-distorting display mode that both preserves the entire landscape image and fills a portrait frame.
- Restored every Series grid card to `scaleToFit`. Landscape rows may retain empty space inside the portrait card, but the complete artwork remains visible. The Series hero dimension classifier is unchanged, so eligible landscape artwork can still appear as the full-screen background.
- Kept the Movies Featured mini-poster on `scaleToFit`, which preserves the complete poster/logo in that small slot.
- Audited the Movies data path: the Roku client preserves and renders explicit `hero_url`, `backdrop_url`, `background_url`, and `fanart_url` values. The saved workspace does not contain the Roku registry token or authenticated response for the current Movies playlist, so it cannot count backdrop-bearing rows in that user account. The all-default on-device result is consistent with the M3U import returning poster/logo-only rows; an authenticated backend response audit is required to prove the count across the full catalogue.
- Bumped the manifest to build `00271`. The page suite passes 34 checks, backend/navigation passes 74 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes.
## 2026-09-16 Adaptive Series Card and Featured Movie Poster Scaling

- Physical Roku review showed a landscape Series image correctly qualifying as the full-screen hero while the same image was always rendered with `scaleToFit` in its portrait grid card. The conflicting aspect ratios produced the large empty bands visible in the supplied screenshot.
- Series grid cards now reuse the existing bitmap-dimension eligibility result. When the card URL is the same image already confirmed as a landscape hero, the card uses `scaleToZoom` to fill its frame. Portrait, logo, small, and unclassified artwork continues to use `scaleToFit`, so this does not weaken the agreed hero/background rule or crop logo-only rows.
- The Movies Featured mini-poster still used an unconditional `scaleToZoom`; it now uses `scaleToFit` so the complete provider poster or logo remains visible in that small slot.
- Bumped the manifest to build `00270`. The page suite passes 34 checks, backend/navigation passes 74 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. Physical Roku review remains required to confirm provider-specific artwork composition.
## 2026-09-15 Adaptive Series Hero Selection

- Build `00268` removed every card-to-hero fallback, which prevented blur but also removed clean Series backdrops because the backend's structured Series model exposes only `cover_url`. That single field can contain either a landscape hero-quality image or portrait/logo artwork, so its field name cannot determine placement.
- Added a bounded runtime image probe for only the currently selected Series artwork. After Roku reports the loaded bitmap dimensions, images qualify as heroes only when they are at least 640x300 and have a landscape aspect ratio from 1.45 through 2.4. Small, portrait, square, and extremely wide logo-like images retain the default background and right-side fit treatment.
- Cached each completed eligibility decision for the page lifetime, kept only one active invisible probe, cancelled it when focus selects another candidate, and disposed it when leaving Series. This prevents repeated classification fetches and unbounded SceneGraph/texture growth.
- Corrected Continue Watching Series thumbnails from zoom to `scaleToFit`, so the complete cover/logo is visible in the small card. Structured Series rows now retain an explicit `cover` artwork role; logo-only M3U rows are never probed as heroes.
- Bumped the manifest to build `00269`. The page suite passes 33 checks, backend/navigation passes 74 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. Archive inspection confirms dimension probing, a stable cache, single-probe disposal, Continue Watching fit, and the classifier thresholds. The ZIP is 3,836,745 bytes with SHA-256 `27885A3D29C00A7F2080B4CDF075D6B09BB40E289AACC1D136A61A11B3B9991F`.

## 2026-09-15 Series Card-to-Backdrop Promotion Removal

- Physical review of build `00267` showed that Series still promoted card artwork into the hero whenever an explicit backdrop was absent. The structured Series mapper copied `cover_url` into both `heroUrl` and `backdropUrl`, and the M3U Series mapper promoted `poster_url` to `heroUrl`.
- Removed both implicit promotions. Series list and detail pages now use full-screen artwork only when the backend row supplies an explicit backdrop/hero field. Cover, poster, and logo-only rows retain the packaged default background and display their artwork with `scaleToFit` in the right-side slot.
- Preserved valid explicit Series backdrops, including M3U rows with separate poster and backdrop URLs. Series Detail refresh now updates cover artwork independently and updates the hero only from an explicit backend backdrop.
- Movies were intentionally left unchanged for this Series-only correction.
- Bumped the manifest to build `00268`. The page suite passes 29 checks, backend/navigation passes 72 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. Archive inspection confirms both Series card-to-hero fallbacks are absent. The ZIP is 3,836,044 bytes with SHA-256 `C4973918B6AC5B0B027EDFFBDA74999980E5EBAA6492DD6D4EA24FFCCAB5391A`.

## 2026-09-15 Cross-Catalog Artwork Normalization

- Traced the configured AWS OpenAPI schema and the complete SceneGraph mapping path. Channel list/detail models expose separate `logo_url`, `poster_url`, and `backdrop_url`; structured Series exposes `cover_url`. Roku maps every row independently and does not reuse a prior item's image URL.
- Removed the unreliable Movie `poster_url`-as-background guess. Movies now use only an explicit backend backdrop as the full-screen hero. When no backdrop exists, both Movies and Movie Detail retain the packaged default background and fit the available poster/logo in the right-side slot.
- Series cards now use `scaleToFit` instead of cropping every image with `scaleToZoom`. Structured Series `cover_url` remains available for its clean hero treatment. M3U Series rows use an explicit backdrop first, a real poster as hero fallback, and never promote a logo-only row to a full-screen background.
- Added the missing Series main-page right-side fallback artwork and aligned Series Detail and episode thumbnails with bounded pre-URI fit/zoom helpers. This prevents avoidable secondary texture loads while keeping card and detail behavior consistent.
- Repeated card images are now confirmed as a backend/provider-data condition: if several records expose the same `poster_url`, or omit posters and expose one shared `logo_url`, the client has no distinct artwork URL to display. The importer must preserve a distinct `poster_url` per title and a dedicated `backdrop_url` where available; the Roku app now consumes those fields without substituting another row's data.
- Bumped the manifest to build `00267`. The page suite passes 29 checks, backend/navigation passes 71 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. Archive inspection confirms Movies explicit-hero selection, Series card fit, and both Series fallback paths are packaged. The ZIP is 3,836,035 bytes with SHA-256 `FE883C23D428B552E4212B72BB5906372CA289D71EA6FA7EC4428C119F7BB5AB`.

## 2026-09-15 Movie Artwork Role and Detail Hero Correction

- Corrected build `00265`'s list-only card-art fallback, which did not follow the agreed artwork rule and left Movie Detail on a different path.
- Verified the configured AWS OpenAPI contract directly: `ChannelListItemData`, `ChannelDetailData`, and `SyncChannelData` expose `logo_url`, `poster_url`, and `backdrop_url`. The Roku mapper previously collapsed `poster_url` and `logo_url` into one card field and never promoted a provider poster to `heroUrl`, so Movie Detail could not render the same usable background seen on the list.
- Movie mapping now keeps the artwork role explicit. A valid `backdrop_url` is the first hero choice; otherwise a valid `poster_url` can be used as the full-screen hero. A row with only `logo_url` has no hero, so both Movies and Movie Detail retain the packaged default background and fit that logo without cropping in the right-side artwork slot.
- The SceneGraph task boundary now preserves explicit hero/background aliases for forward compatibility, and the detail fetch refreshes poster, logo, hero, and backdrop fields with the same shared normalization used by the catalogue mapper.
- Replaced Movie Detail's post-URI display-mode mutations with bounded `uiPosterFit` and `uiPosterZoom` helpers, preventing a second remote texture load and keeping the fallback logo clean.
- Bumped the manifest to build `00266`. The page suite passes 26 checks, backend/navigation passes 70 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. Archive inspection confirms the mapping and both render paths are packaged. The ZIP is 3,835,973 bytes with SHA-256 `69A36088A3871D64396BDA5E00F1EAED5B21440DFD9B522AC5C1F4CC5A1622C5`.

## 2026-09-15 Movies-Only M3U Classification and List Hero Follow-up

- Physical Roku testing of build `00264` still showed `37 titles`, proving that accepting only missing/unknown row types was incomplete. Generic M3U imports can label movie streams as `live` or `channel`; the Movies mapper was still discarding those rows.
- For a saved playlist explicitly identified as a single-purpose Movies M3U, the source profile is now authoritative: movie, unknown, live, and channel rows are rendered as Movies, while explicit Series rows remain excluded. Xtream and mixed playlists retain strict backend content-type routing.
- The main Movies list now falls back to the exact card artwork when no distinct hero/backdrop exists and renders it with `scaleToFit` inside the reserved hero area. This removes zoom cropping without changing the Movie Detail page.
- Bumped the manifest to build `00265`. The page suite passes 23 checks, backend/navigation passes 69 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. Archive inspection confirms the corrected mapper and list-only hero fallback are packaged. The ZIP is 3,835,641 bytes with SHA-256 `37471C64DF24B98E4971EA96CFDAC064BC39A1962CE090212476A64526A492E6`.
- The Roku client can browse every row returned by backend pagination. If build `00265` still receives only 37 raw rows with no next page, the remaining loss is in the server import and must be diagnosed from the authorized playlist's `records_seen`, `records_inserted`, and pagination response.

## 2026-09-15 Movie Extraction and Card Artwork Correction

- Found why a Movies M3U could show only 37 entries from a 50-row backend page: the movie mapper discarded valid rows when the provider omitted both `content_type` and `media_type`, or returned those fields as `unknown`. The exact provider payload still requires an authenticated device session, but this filtering path accounts for the observed first-page count.
- Single-purpose Movies M3U playlists now retain rows whose type metadata is missing or unknown while continuing to reject rows explicitly identified as Live TV or Series. Mixed and Xtream playlists keep strict content-type routing so content cannot leak between pages.
- Backend movie cards now render validated `poster_url` and `logo_url` artwork with `scaleToFit`, preventing landscape logos and unusual provider artwork from being cropped or appearing zoomed. Hero/backdrop artwork continues to fill its background area.
- Catalogue pagination remains bounded to 50 rows per request and loads later pages as the user browses. This preserves access to the complete catalogue without returning to the large SceneGraph transfers that caused Roku memory instability.
- Bumped the manifest to build `00264`. The cross-page suite passes 21 checks, backend/navigation passes 69 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. The saved ZIP is 3,835,515 bytes with SHA-256 `288C3D4EA1A24924ED87A20B473764601BA876B83BE4008FED51904C7756BC14`, below Roku's 4,000,000-byte upload limit. Physical provider row counts and artwork still require Roku/device verification.

## 2026-09-15 Catalog Navigation Crash Prevention

- Reduced a navigation memory risk in `MainScene`: top-level navigation history retained entire SceneGraph page nodes, including rendered poster trees, catalogue arrays, timers, and backend tasks. A subsequent physical-device retest still crashed when Series opened, proving this mitigation was not the Series crash's root fix.
- Changed top-level history to retain lightweight route entries while preserving full page nodes only for immediate Detail/Player Back behavior. Route history is capped at eight entries.
- Added explicit disposal for Live TV, Movies, and Series when leaving them through top-level navigation. Disposal stops query/playback tasks and timers, releases paged catalogues and caches, and clears rendered nodes before the next catalogue screen is created.
- Added BrightScript contracts for Live TV to Series, general catalogue switching, Detail Back retention, and history bounds. All 61 backend/navigation contracts and the Restore keyboard contract pass; `npm.cmd run check` passes in both the worktree and saved project. The saved build `00256` ZIP is 3,833,313 bytes, contains the lifecycle module, and remains below Roku's 4,000,000-byte upload limit.

## 2026-09-15 Series Provider Artwork Crash Hardening

- Hardened the Series provider-artwork path and shared Poster loader. A later physical-device retest crashed when Movies opened from Live TV, proving artwork was not the common page-opening failure.
- Updated the shared Poster helpers to set target-sized `loadWidth` and `loadHeight` before assigning every HTTP/HTTPS `uri`, following Roku's documented texture-memory guidance. This protects every page from oversized provider artwork rather than handling only the current playlist.
- Removed the logo-to-backdrop fallback. Provider logos remain available on cards, while the Series list background now uses packaged artwork unless a packaged full-screen asset is explicitly supplied.
- Added bounded URL validation for Series artwork and rejected unsupported schemes. Added contracts proving a provider logo cannot become a backdrop or full-screen image.
- Bumped the manifest to build `00257`. All 64 backend/navigation contracts, 35 keyboard/image-loading contracts, and `npm.cmd run check` pass. The saved ZIP is 3,833,954 bytes; archive inspection confirms load bounds precede remote `uri`, the Series full-screen guard is packaged, and the build remains below Roku's 4,000,000-byte upload limit.

## 2026-09-15 SceneGraph Catalogue Transfer Bounds

- Found the shared Movies/Series page-opening weakness in `BackendApiTask`: requests specified a 50-row page, but responses were trusted without enforcing that bound. Provider arrays, nested metadata, and long strings could all be copied into the SceneGraph response field, causing a large cross-thread allocation before either destination page rendered.
- Enforced a maximum of 50 catalogue records per task response, 200 compact group names, 100 seasons, six nested levels for non-catalogue envelopes, and bounded strings. Catalogue rows now copy only approved scalar fields, dropping arbitrary nested provider structures.
- Added hostile fixtures with 75 catalogue records and 250 nested group records to verify the SceneGraph boundary remains bounded. All 67 backend/navigation contracts, 35 keyboard/image-loading contracts, and `npm.cmd run check` pass. The saved build `00258` ZIP is 3,834,343 bytes; archive inspection confirms the 50-row bound, compact groups, and scalar-only catalogue fields are packaged below Roku's 4,000,000-byte upload limit.
- Added BrightScript exception containment around catalogue Task processing and Live TV/Movies/Series startup. Unforeseen provider/runtime errors now print their diagnostic to the Roku debugger and show a Back-safe customer message instead of escaping page initialization and terminating the channel.
- Bumped the manifest to `00259`. All 67 backend/navigation contracts, 35 keyboard/image-loading contracts, and `npm.cmd run check` pass. The saved ZIP is 3,834,986 bytes; archive inspection confirms the Task exception guard, 50-row response bound, and Movies startup guard are packaged below Roku's 4,000,000-byte limit.

## 2026-09-15 Catalogue Page Startup Race

- The build `00259` Roku screenshot proved the exception guard worked but showed its plain emergency view. Tracing the guarded startup path found that Live TV, Movies, and Series started their asynchronous `BackendApiTask` before categories, focus indexes, windows, and the first render were initialized.
- A fast backend response could therefore invoke the observer and render a partially initialized page. All catalogue pages now complete and render their normal initial UI before starting the Task, so Movies/Series retain the previous full page experience while loading.
- Bumped the manifest to `00260`. The three-page startup contract, all 67 backend/navigation contracts, all 35 keyboard/image-loading contracts, and `npm.cmd run check` pass. The saved ZIP is 3,835,225 bytes and packages the render-before-Task order below Roku's 4,000,000-byte upload limit.

## 2026-09-15 Cross-Page Empty State, Hero, and Focus Recovery

- Replaced the first-level blank `could not be loaded` startup response with a normal-page recovery path. If initial page construction throws, Live TV, Movies, and Series retry their complete layout while suppressing a second backend Task start; the dark emergency screen remains only as the final guard if the normal renderer itself fails twice.
- Unified mismatched and empty playlist behavior by section: Live TV shows `No live channels in this playlist.`, Movies shows `No movies in this playlist.`, and Series shows `No series in this playlist.` while retaining the normal sidebar, top bar, search, and Back behavior.
- Restored Series hero artwork by allowing validated HTTP/HTTPS full-screen artwork and reusing the provider poster when no separate series backdrop is supplied. Remote images retain target `loadWidth` and `loadHeight` bounds before the URI is assigned.
- Removed post-URI Poster display-mode mutations from Live TV, Movies, and Series card/hero rendering. Zoom/fill mode and remote load bounds are now configured before the URI, preventing the avoidable second artwork load that contributed to focus stalls.
- Bumped the manifest to `00261`. The cross-page suite passes 12 checks, backend/navigation passes 67 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` compiles and packages successfully. The saved ZIP is 3,835,118 bytes with SHA-256 `91317DEE36744B332A758F8E50AFFF4E8CF2BEC68B85EFF2BE4007CA9ABF7E84`, below Roku's 4,000,000-byte upload limit. Physical Roku focus timing and provider artwork rendering still require device verification.

## 2026-09-15 Live TV to Series Empty Pagination Fix

- Found the wrong `Press OK for more` message in Series, where empty backend results with a next-page cursor intercepted OK before the focused control could activate. This made a Live TV playlist enter a hidden pagination action and appear to lag or change focus unpredictably.
- Series no longer exposes or handles manual OK-to-page behavior on an empty catalogue. A Live TV profile ends on the normal `No series in this playlist.` page, so OK follows the visibly focused control.
- Restricted the channel-to-Series fallback to actual Series profiles. When an actual Series M3U has no matching rows on an early channel page, later pages advance automatically without moving focus.
- Bumped the manifest to `00262`. The cross-page suite passes 15 checks, all 67 backend/navigation contracts and 35 keyboard/image-loading contracts remain green, and `npm.cmd run check` passes. The saved ZIP is 3,835,176 bytes with SHA-256 `D5E29A4E791E28868A43C9983F4F7D2D9D5F6FADBB75722F40B8F7DDA0CA605E`.

## 2026-09-15 Movies and Series Category Transition Loader

- Fixed the brief stale-category frame shown when entering a Movies/Series category or pressing Back. Both pages now clear the prior result rows and set their loading state before the transition render, then retain the loader until the full replacement catalogue arrives.
- Preserved the selected category index while the all-content request loads, so Back returns focus to the category pill the user selected.
- Cleaned movie artwork mapping: validated `poster_url` remains a filled poster, while a `logo_url` used only as fallback is tagged for `scaleToFit` and rendered without cropping. Full-size posters and hero artwork retain their existing crop treatment.
- Added pre-URI `uiPosterFit` load bounds and regression coverage for the loader transition and poster-versus-logo mapping. Actual provider image contents and aspect ratios still require Roku/device verification with the user playlist.
- Bumped the manifest to `00263`. The cross-page suite passes 20 checks, backend/navigation passes 68 contracts, keyboard/image loading passes 35 contracts, and `npm.cmd run check` passes. The saved ZIP is 3,835,355 bytes with SHA-256 `E9886CB90565A56FD45D69AAD3C6D24F7F027DB04FF2E5567F4375CD21EF9604`.

## 2026-09-15 Restore Account Keyboard Coverage

- Fixed the custom Restore Account recovery-code keyboard, whose hard-coded key list omitted both `O` and `Z`.
- Restored the complete uppercase alphabet while preserving the 10-column focus grid and the existing hyphen, Delete, Clear, and Done actions.
- Added a BrightScript regression contract that verifies all `A`-`Z` keys appear exactly once and that directional focus can enter, leave, and return from `Z`.
- Bumped the manifest build version to `00255`. The keyboard contract, all 57 backend/navigation contracts, and `npm.cmd run check` pass. The saved-project ZIP is 3,832,285 bytes, contains both missing letters in the packaged source, and remains below Roku's 4,000,000-byte upload limit.

Read this file before starting a new session. Update it only after a meaningful milestone is completed, such as finishing a screen, fixing a major workflow, committing/pushing, or changing project structure. Do not update it for every tiny visual tweak.

## Project Context

- Roku IPTV app built with SceneGraph, BrightScript, and BrighterScript.
- Main install/build clone used by GitHub Desktop is usually:
  `C:\Users\M Abdullah\Documents\GitHub\IPTV-APP-V1`
- Saved project used for the latest AWS integration and package is:
  `C:\Users\M Abdullah\MY APP\Working\IPTV APP`
- Standard validation/build commands:
  - `npm.cmd run check`
  - `npm.cmd run build`
- Latest verified installable zip path:
  `C:\Users\M Abdullah\MY APP\Working\IPTV APP\build\roku-iptv-app.zip`

## 2026-09-15 Live TV Category Results Navigation

- Live TV now uses the same browse/results state model as Movies and Series. Selecting a category opens a channel-only results view with the category pills hidden and focus on the first result. Pressing Back requests the complete unfiltered catalogue, redraws the category pills, and restores focus to the category that opened the results instead of resetting to the first pill.
- Focus routing no longer targets the hidden category row while results are active: Up from the first channel goes to Search, and Right/Down from the sidebar or Search enters the channel results. Returning to the full catalogue also allows normal pagination even though the remembered category pill remains selected for focus restoration.
- Validation: all 57 BrightScript backend/navigation contract assertions pass, and `npm.cmd run check` passes in worktree `84c7`.

## 2026-09-15 Roku Installer Package Fix

- The generated channel ZIP was structurally valid but had grown to 8,493,743 bytes, exceeding Roku certification requirement 3.7 of 4 MB or less. The manifest also remained on build `00253` across multiple rebuilt archives, which could trigger Roku's identical-version sideload rejection.
- Replaced the oversized Add Playlist and splash RGB PNG files with visually verified optimized JPEG versions, losslessly preserved required transparency while palette-optimizing card/logo UI artwork, recompressed bundled demo artwork, and excluded obsolete background generations from `bsconfig.json`. Active file paths were updated in `AddPlaylistPage.brs` and `manifest`.
- Bumped the manifest build to `00254`. The rebuilt worktree ZIP is 3,813,446 bytes, has `manifest` at the archive root, passes `npm.cmd run check`, and remains under 4,000,000 bytes with margin for the Roku installer.
- Delivered and rebuilt the saved-project ZIP at 3,832,246 bytes. It excludes the versioned original-artwork backup, contains build `00254`, and has SHA-256 `14822EC7C782A5C2AB55CFDC4207A4DAC478E5B499D01D3A27B1819058F71C75`.

## 2026-09-14 AWS Backend Integration

- Delivered the integration to the saved project at `C:\Users\M Abdullah\MY APP\Working\IPTV APP`; the same changes remain in Codex worktree `84c7`. Files were checked against their starting versions before delivery, with no conflicting or unrelated edits overwritten. Changes remain uncommitted.
- Replaced the Railway origin with `https://16-192-92-41.sslip.io`. Compared the supplied API guide against the live OpenAPI schema. This temporary hostname will need replacement when the production domain is ready.
- Live TV/Movies use bootstrap and 50-record channel pages; Series uses the dedicated series endpoint. Pagination follows `has_next`, retains at most three catalog pages, and fetches earlier pages again when browsing back. Search/category filters run on the backend with debouncing and cancellation of obsolete requests. This supersedes the August cursor-sync browsing implementation below.
- Series details now use actual season records and season-filtered episode pages, including specials, noncontiguous season numbers, and more than eight seasons. Watch requests playable episode URLs on demand; playback/progress uses stable episode IDs instead of treating series as individual channels or dividing flat episodes into guessed seasons.
- Preserved movie/series artwork and metadata through Task responses, corrected playback format selection, added pending-import polling and running-job conflict handling, and cleared Xtream credentials from submission inputs after completion.
- Authentication failures retain saved tokens, recovery codes, and identity. Missing playlists are not silently recreated, and unmatched local playlist rows survive migration. No live accounts, playlists, import jobs, or Roku deployments were created during this work.
- Validation completed: 30 actual BrightScript contract assertions passed in the worktree; the delivered test sources are identical. Final `npm.cmd run check` passed serially in the saved project. Its ZIP was inspected for the AWS endpoint and series integration, with development/test/environment files excluded. Public HTTPS health returned 200 and unauthenticated playlists returned the expected 401 envelope.
- Focus performance follow-up fixed two client-side regressions: hidden My Playlists pages no longer poll imports or redraw every two seconds while retained in navigation history, and shared focus updates no longer rebuild every button or allocate accumulating animation nodes per remote press. Keyboard focus continues to update only the previous/current key. A 100-move BrightScript test kept a stable node count with no animation-node growth.
- Startup follow-up removed an invalid SceneGraph-node equality comparison from `uiClear()` that caused a runtime error before the first page rendered and left Roku on the splash screen.
- Live TV category normalization now also splits semicolon-delimited names returned by the AWS bootstrap/groups response, trims whitespace, and deduplicates labels case-insensitively. Values such as `Outdoor;Sports` and `Public;Sports` now produce the separate `Outdoor`, `Sports`, and `Public` category pills. A Roku runtime follow-up added explicit string bounds for leading, trailing, repeated, and whitespace-only group segments so malformed provider categories are ignored instead of crashing the page.
- Search crash follow-up made deleting the final character bounds-safe on the Live TV, Movies, and Series keyboards. Backend category/search query values now use string URL escaping directly, avoiding `roUrlTransfer` work on the page thread when a completed search is submitted.
- Backend category routing now keeps a concise first category label for compound M3U groups while submitting the exact raw group back to AWS, so pills such as `Outdoor` correctly load channels stored under `Outdoor;Sports`. The Series page now falls back once from an empty structured `/series` response to series/episode channel rows for M3U imports; these rows use the existing single-item detail/playback path, while structured series keep the full seasons/episodes API flow.
- Movies and Series category transitions now retain the current rows and focus model while the debounced backend request runs. Category-result pages show loading instead of a false `No matching` state, and Back preserves the selected category pill through the unfiltered reload instead of falling back to the Movies/Series sidebar button.
- Single-purpose Movies M3U playlists no longer send the strict `content_type=movie` filter that excluded provider rows imported by AWS as `unknown`. They page through all imported channel rows, but only records explicitly typed as movies or clearly inferred from movie metadata/URL patterns are admitted to Movies. Explicit live/series records and unidentifiable rows are excluded. The same strict page isolation now applies to Series fallback and Live TV mapping; Xtream and mixed playlists retain server-side type filtering.
- Movies and Series now separate the remembered category pill from the active backend filter. Back from category results requests the complete `All` catalogue while retaining the selected category index solely for focus restoration, so the main page shows all content with focus on the category that was just exited.
- App-wide crash hardening now treats provider responses, decoded registry state, and navigation payloads as untrusted at every page boundary. `BackendApiTask` discards non-object rows before passing catalog data into SceneGraph; shared response, pagination, mapping, and catalog-window helpers fail closed on malformed shapes; playlist, media, progress, favorite, settings, entitlement, and parental-control readers validate record types before field access; Movies/Series/Live TV and their detail/player paths reject invalid records; and stream-format detection safely handles empty or unusually short URLs. This specifically prevents Series startup from crashing while restoring malformed legacy progress/playlist data or consuming malformed structured Series/season responses. Hostile fixtures mix nulls, strings, numbers, arrays, malformed pagination, short URLs, and valid records without losing valid content. The BrightScript contract suite now has 57 passing assertions, and `npm.cmd run check` passes in the worktree.
- Delivered ZIP: `C:\Users\M Abdullah\MY APP\Working\IPTV APP\build\roku-iptv-app.zip`. The final saved-project `npm.cmd run check` passed after the focus fixes. Integration notes: [AWS backend integration](docs/aws-backend-integration.md).
- Still unverified: migration of existing Railway users/playlists to AWS, full provider import totals and host-blocking fixes, real provider series metadata, Roku navigation timing, and actual playback. These require an existing authorized identity and Roku testing. Do not reset identity or recreate data merely to bypass authentication failure.

## 2026-08-13 Backend Playlist Pagination And Counts

- Backend-managed playlists now load Live TV, Movies, and Series as separate page-specific data instead of dumping one playlist section into every page. Movies and Series request typed sync rows, Xtream Live TV requests live rows, and generic M3U Live TV keeps broad sync compatibility while client-side mapping filters obvious movie/series/live rows by `content_type`, `media_type`, and safe source hints.
- Live TV, Movies, and Series now use cursor pagination for large playlists: the first page renders quickly, additional pages append only when browsing near the end, and duplicate-page guards prevent repeated backend pages from inflating the lists.
- Header counts are now separated from loaded rows. When backend sync metadata includes `total_count`, `total`, `total_items`, `active_channel_count`, or `channel_count`, the page displays that exact total while still loading content in pages; if the backend does not expose an exact total yet, the UI shows a loaded count with `+` while more pages exist.
- Live TV scroll responsiveness was improved for large playlists by caching filtered channel results and skipping category parsing on the common All-channels/no-search path, so Down/Up focus movement no longer rebuilds the full channel list on every press.
- Validation: `npm.cmd run check` passes and creates `build\roku-iptv-app.zip`.
- Roku tests still needed: verify a large mixed playlist on device, confirm Live TV/Movie/Series totals match backend extraction totals, scroll near page boundaries to confirm load-more behavior stays smooth, and play sample items from each section.

## Current Design Progress

- Movies and Series now use a shared optimized `movies_series_fallback_backdrop_v6.jpg` media-wall fallback when provider hero/backdrop artwork is missing, with a straight right-side poster screen designed for dynamic artwork.
- Poster-only Movies/Series items now embed the selected poster into that screen area on both list and detail pages, drawn before the page scrims with larger fill-style scaling and subtle backing/glass shadows so it reads as part of the media wall instead of a floating overlay.
- Experimental v3 fallback backdrops add center/right Movies/Series word art, move fallback poster anchors farther right, enlarge them again, and add a poster-only demo Series item for fallback review.
- Experimental v4 fallback backdrops align Movies/Series typography to the same bold block style, add more subtle left-side texture, enlarge/lower fallback poster anchors, and soften their drop shadows.
- Movies/Series fallback backdrops were converted from large PNGs to optimized JPGs so focus changes load the fallback background immediately instead of appearing late on Roku.
- Movies Featured now behaves as a stable session spotlight: active backend flags use optional priority/expiry metadata, followed by recently added, newest-year, and first-playable fallbacks; the card opens details and no longer arbitrarily features the second M3U item.
- Restored the Movies Featured card's internal `watch` focus action so category pills, Featured, and movie cards keep their original remote-control focus routing while the visible CTA still opens details.
- Live TV now uses a purpose-made teal/emerald broadcast-studio background with separately colored screens, reflections, and studio accents instead of a flat recolor.
- Add Playlist Back behavior is source-aware: opening it from Home now returns to Home, while playlist edit/manage flows keep their existing playlist return targets.
- Backend Swagger playlists can now be linked into the Roku app from Settings via the backend recovery code; My Playlists auto-loads backend playlists on open, then merges them into the local card list. The Swagger account tested on 2026-07-27 contains Series Test, Weather Test, and Science; all imports completed with zero failed records. The app now preserves backend `content_type` on channel rows, and Movies/Series request typed sync rows while Live TV still accepts unknown rows for category-style live playlists.
- Paid-plan onboarding now creates/shows an account recovery code before playlist setup. Monthly/Yearly in mock billing mode activates the local entitlement, calls backend anonymous auth when available, saves returned auth data locally, then shows a recovery-code page with a `Set Up Playlist` button and a `Did you save your recovery code?` Yes/No warning; No stays on the code page, Yes opens Add Playlist. If backend auth is unavailable, the page shows a mock recovery code so the UI flow remains testable.
- Welcome `Restore Subscription` now opens a recovery-code keyboard and calls `/api/v1/auth/recover`; successful restore saves the returned backend token and uses the current mock entitlement restore until backend subscription/plan status is exposed. Settings account recovery copy was changed from Swagger wording to customer-facing recovery wording.
- Recovery restore is now centered in Profile -> Manage Subscription: the `Restore` action opens the recovery-code keyboard and calls `/api/v1/auth/recover`, while the duplicate visible recovery button was removed from Settings.
- Screenshot follow-up tightened recovery UI: the post-purchase recovery-code page now uses a taller contained panel with split instruction copy, and restore-code keyboards no longer show duplicate instruction lines.
- Added a customer feedback flow under Settings: the new Feedback page lets users choose a category, type a message with the Roku keyboard, and submit it to the backend `/api/v1/support/reports` endpoint using the saved bearer auth session.
- Feedback UI follow-up removed the page sidebar, re-centered the form, replaced the music-note-looking feedback icon with the info icon, and switched category buttons to rounder supported pill assets.
- Feedback page polish removed the icon from `Send Feedback`, made category button widths follow their labels, and replaced the message-field square focus outline with the rounded field focus treatment.
- Feedback page Roku review follow-up changed Settings Feedback to a bell icon, moved category chips to pill-style action surfaces with text-based widths, and removed the dark green message-field focus tint.
- Feedback page button follow-up matched category controls to the same pill artwork family as `Send Feedback`, widened the panel to preserve button rounding, changed Settings Feedback to a heart icon, and switched message focus to a rounded purple-line treatment.
- Feedback category buttons now use tighter label-based pill widths with smaller gaps, selected chips use the filled pill state, `Send Feedback` is centered in the form, and message focus uses a subtle rounded inner surface instead of a color tint.
- Feedback page latest Roku polish uses compact category pills with separate selected/focused states, a taller message area and panel, and a transparent rounded teal focus outline around the message box only.
- Feedback page screenshot follow-up restored the Settings Feedback bell icon, moved `Send Feedback` back to the left side of the form, and replaced the message box with exact-size rounded normal/focused field assets so the teal focus border is thinner and aligned.
- Feedback page buttons now animate with same-size focus-layer opacity fades on category pills and `Send Feedback`, avoiding any scale/widening behavior on Roku.
- Feedback `Send Feedback` now uses a filled purple button base with a purple focused overlay instead of the teal/green action styling.
- Feedback `Send Feedback` now uses the same Add Playlist submit button artwork, and Feedback Back now bubbles to MainScene history so Settings does not loop back into Feedback.
- Feedback button shape polish replaced stretched submit/category artwork with exact-size rounded assets, giving `Send Feedback` a sleeker blue-purple border and keeping the long `Complaint` pill consistent with the other category buttons.
- Feedback button asset follow-up removed the inner highlight line from category/submit pills and matched `Send Feedback` normal/focused colors to the category button family.
- Feedback wording polish changed visible categories to `Suggestion`, `Playback`, `App Bug`, `Complaint`, and `Other`, and renamed the action to `Send Message` so it does not sound tied only to a feedback category.
- On-screen keyboards now share corrected bottom-row arrow navigation, so uneven action rows no longer block Down movement; on text keyboards `V/B` go to `SPACE`, `N/M` to `DEL`, `/` or `,` to `CLEAR`, and `:`/`-`/`?`/`!` to `DONE`.
- Keyboard bottom-row navigation now remembers the source key for a Down jump, so pressing Up from `SPACE`/`DEL`/`CLEAR`/`DONE` returns to the exact key that moved down there.
- Live TV now splits backend semicolon group titles such as `Documentary;Education;Science` into separate category memberships, so a channel appears under each relevant pill instead of creating one oversized combined pill. The category row also stops drawing before the right edge to prevent overflow on TV.
- Backend Series and Movies poster cards now keep the full remote logo/poster artwork underneath while drawing a compact taller bottom title strip. Title placement stays low on the card, and focused card titles switch to the same green accent as the focus border.
- Player playback settings now sync the Subtitles row with the active Roku subtitle track name instead of leaving it on `Off` while captions are visibly applied.
- Player subtitle labels now avoid raw Roku track ids such as `webvtt/1`, keeping a friendly selected subtitle name or falling back to stable labels such as `Subtitle 1`; quality selection now assigns ContentNode `MaxBandwidth` directly with lower 720p/480p caps so adaptive streams can be capped more reliably.
- Series detail now only lowers the fallback card-poster anchor when no provider hero/backdrop is available; the visible episode-area veil was removed and Movie detail is unchanged.

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
- Title searches show `SEARCHED MOVIES` or `SEARCHED SERIES`; category searches automatically select the match and show the category name without adding `SEARCHED`.
- Typed title/channel search now ignores the currently selected category on Movies, Series, and Live TV, so searches such as `Cops` or `Nosey` can match anywhere in the active playlist.
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
- Manual Movies/Series category selection now enters the same focused results layout as category search, hiding Featured/Continue sections, showing only the category name, and making Back return focus to the selected category pill instead of the search bar.
- Movies, Series, and Live TV now keep Back focus mode-specific: category selection/category search returns focus to the selected category pill, while title/channel search returns focus to the search bar.
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

## 2026-07-15 Subscription Onboarding Polish

- Reworked the current Welcome subscription screen into a TV-first paywall layout with a `SUBSCRIPTION` badge, concise headline, fuller premium-benefit bullets, and plan cards for Free Trial, Monthly, and Yearly options.
- Replaced the earlier empty plan rows with card-style plan controls using app-matched room artwork, rounded card artwork, blue rounded right-side badges, and the shared green focus behavior.
- Tuned the focus treatment to stay recognizable on Roku: low-opacity green focused fill, rounded green border, centered badge labels, and reduced focused artwork strength so the selected card remains readable.
- Restored the full `Restore Subscription` button label and kept it in the plan stack for future Roku entitlement restoration.
- Current frontend flow remains mock/frontend-ready until Roku Pay product catalog and backend entitlement validation are connected.

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
- Live TV category pill follow-up in build `00211`: matched Live TV category pill height, text vertical alignment, and focus hitbox to the Movies/Series category pills while keeping the same widths and selected/focused color behavior.
- Add Playlist title follow-up in build `00212`: increased the Add/Edit Playlist page title size slightly for stronger TV readability without moving the form controls.
- Favorites phase in build `00213`: added Live TV channel favorite/unfavorite support from the channel grid with visible heart badges and `*` remote hint, made Favorites refresh after returning from details/player, improved true-empty/search-empty states, and persisted full favorite metadata for dynamic playlists instead of only title/id.
- Live TV favorites hint follow-up in build `00214`: shortened and reduced the favorite hint text, moved the Live TV heading/count upward, and lowered the channel grid slightly so the title, hint, and cards have cleaner vertical spacing.
- Live TV/Favorites navigation follow-up in build `00215`: moved the favorite hint to the right near the channel count with `Press * to favorite/remove favorite` wording, restored the original Live TV card row spacing, and made Back from Favorites return to the page that opened Favorites instead of always falling through to Home.
- Global navigation follow-up in build `00216`: nudged the Live TV channel count upward for clearer separation from the favorite hint and changed normal top-level navigation to preserve history so repeated Back walks through Live TV, Movies, Series, Favorites, Settings, Profile, My Playlists, and Home in reverse order instead of prematurely falling back to Home.
- Live TV focus follow-up in build `00217`: fixed stale sidebar/search focus painting by tying those surfaces to the Live TV `focusArea`, and slimmed Live TV category pills slightly so they no longer read taller than Movies/Series on Roku.
- Favorites/empty Live TV follow-up in build `00218`: Live TV favorites now always use the packaged Live TV broadcast backdrop instead of channel/provider artwork as the full-page background, and empty Live TV playlists now use the neutral IPTV MAX art backdrop with only the empty-state message instead of the full Live TV channel artwork/chrome.
- Empty/Favorites/back navigation follow-up in build `00219`: removed the remaining Live TV title from empty live playlists, removed the heart icon from empty Favorites, fixed empty Favorites focus movement between Search and sidebar, and corrected global route history so normal top-level navigation no longer pops prior pages as if it were a Detail/Player return.
- Empty-page consistency follow-up in build `00220`: Live TV, Movies, Series, and Favorites empty states now use a blank dark background instead of fallback artwork, and their empty-state text is aligned to the same shared coordinates.
- Movies visual follow-up in build `00221`: aligned the Featured Movie Watch Now pill to the Continue Watching Resume button style/centering, and replaced square movie-card outlines with rounded poster masks/frames so card corners render cleanly.
- Movies card rollback in build `00222`: restored the previous movie-card poster/border rendering after the rounded mask made card corners look cut, while keeping the Featured Movie Watch Now alignment/style fix.
- Keyboard UI follow-up in build `00223`: replaced the cramped equal-width keyboard action row with reusable wider Space/Del/Clear/Done controls, switched Space to a simple icon mark, and applied the updated keyboard styling across Search and Add Playlist keyboards.
- Keyboard fit follow-up in build `00224`: tightened keyboard key width/gaps so the full row fits inside the overlay panel, lowered key labels slightly for better optical centering, and made the Space icon wider/flatter.
- Keyboard layout follow-up in build `00225`: enlarged the keyboard overlay panel, switched the search/input field to a rounded surface, added case toggle support to search keyboards, centered Space between three left-side and three right-side action keys, and moved the Space icon upward.
- Keyboard completion follow-up in build `00226`: added the missing Clear action to the Add/Edit Playlist field keyboard so it matches the completed action-row behavior used by the search keyboards.
- Pre-subscription cleanup in build `00240`: removed the inactive Notifications row from the Home screen, tightened the Home side-nav row order, and removed the no-card/free-trial note from the Welcome screen while leaving Settings unchanged.

## 2026-07-15 Subscription V1 Polish

- Built the onboarding subscription screen around a simple left-aligned plan-card layout with first-card default focus, longer benefit copy, rounded artwork cards, and updated mock prices of `$3.49` monthly and `$12.99` yearly.
- Cleaned `SubscriptionPage` toward a v1 customer-facing Manage Subscription screen: removed Review States, direct Monthly/Annual mock shortcuts, and duplicate Restore; the account action panel now explains the plan flow and keeps View Plans as the only action.

## 2026-07-16 Roku Pay-Ready Foundation

- Created the Roku Developer beta app in the dashboard as `IPTV MAX`; beta Channel ID is `874326` and access code is `5C2XCT9`.
- Added Roku Pay-ready placeholder billing config in `EntitlementStore.brs` using `iptvmax_premium`, `iptvmax_monthly`, and `iptvmax_yearly`, while keeping local mock mode as the default until payout enrollment and product catalog approval are complete.
- Added a `ChannelStore` node to `WelcomePage` and wired the live-flow structure for `getCatalog`, `doOrder`, and `getAllPurchases`, including catalog-unavailable, product-not-found, canceled/interrupted, purchase-failed, restore-failed, and no-subscription-found states.
- Mapped Roku purchase status into app entitlement states: `active`, `trial`, `grace`, `on_hold`, and `canceled`; grace allows access, while on-hold/canceled/no-subscription routes users back to the subscription screen.
- Updated `MainScene` routing so app pages require a valid entitlement instead of relying only on onboarding completion. `WelcomePage` and `SubscriptionPage` remain reachable without entitlement.
- Bumped the manifest build version to `00247`; `npm.cmd run check` passes and creates `build\roku-iptv-app.zip`.
- Still left for real Roku Pay: complete private payout/tax enrollment, create approved Product Catalog products/purchase options, enable billing testing/test users, switch billing mode from mock to live, and test purchase/restore on a Roku device.

## 2026-07-16 Sidebar Navigation Cleanup

- Changed Add Playlist so its sidebar no longer highlights My Playlists while the playlist form is open.
- Kept My Playlists as a Home/My Playlists hub entry, while Live TV, Movies, Series, Favorites, Settings, Profile, and Add Playlist now show a first-row Home shortcut instead of a My Playlists shortcut.
- Kept the current section highlighted on browse pages and preserved the existing profile row/focus structure.
- Added a dedicated Home sidebar icon asset and wired the Home sidebar rows to use it instead of the temporary IPTV image icon.
- Bumped the manifest build version to `00250`; validation is required before Roku testing.

## 2026-07-16 Pre-Backend Subscription QA

- Expanded `SubscriptionPage` while billing remains in mock mode, then simplified it back to customer-facing actions only: View Plans and Restore.
- Kept Restore wired to the local Roku Pay-ready test state, while removing visible Grace, On Hold, Canceled, and Clear Access controls until real Roku Pay recovery rules are needed.
- Added clear test-mode messaging and feedback after Restore.
- Bumped the manifest build version to `00252`; validation is required before Roku testing.

## 2026-07-20 Parental Control V1

- Replaced the mock Settings parental-lock toggle with a real local PIN flow: first use creates and confirms a 4-digit PIN, and later enable/disable actions require the saved PIN.
- Added `components/shared/ParentalControlStore.brs` for registry-backed PIN verification, local lock state, and the temporary restricted demo category rule.
- Added a MainScene parental gate overlay so restricted Movies/Series detail pages and playback are blocked before navigation continues.
- While the backend is not ready, `Drama` is the restricted demo VOD category and `Sports` is the restricted demo Live TV category so behavior can be tested with existing demo metadata.
- Added a visible Settings > Change PIN action that verifies the current PIN before accepting and confirming a new 4-digit PIN.
- Added a short-lived unlock behavior: after entering the correct PIN for a restricted title, playing that same title from its detail page does not ask again, but returning to Movies/Series/Favorites/Home clears the unlock so reopening restricted content asks for the PIN again.
- Reused the existing keyboard key styling for the PIN keypad and kept the overlay independent from missing generated rounded-panel assets.
- Polished the PIN entry indicators from bright square `*` fields into rounded dark slots with a small filled dot, matching both Settings PIN setup/change and the MainScene parental gate.
- Tuned PIN overlay typography with explicit Roku font sizes so the title uses size `26`, while the subtitle and the text beneath the PIN slots use size `18` in both Settings and the MainScene parental gate.
- Shortened PIN overlay subtitles so Roku renders complete text without trailing ellipses.
- Updated the Change PIN current-PIN subtitle to `Enter your Current Pin`.
- Switched the PIN dialog background to a rounded `panel`/green-focus asset so corners are rounded while preserving the previous dialog fill color.
- Strengthened the rounded input field border in the app keyboard overlays for Add Playlist and search across Live TV, Movies, Series, Favorites, and My Playlists.
- Rounded the main on-screen keyboard overlay panel corners across Add Playlist and all search keyboards while preserving the existing dark panel color.
- Thinned the rounded keyboard overlay border for a sleeker TV look.
- Validation: `npm.cmd run check` passes and creates `build\roku-iptv-app.zip`.
- Roku tests needed: create a PIN from Settings, confirm mismatch handling, disable/enable with correct and incorrect PINs, change the PIN and verify the old PIN no longer works, verify non-Drama VOD and non-Sports Live TV open normally, verify Drama Movies/Series ask for PIN before detail, verify Sports Live TV asks for PIN before playback, verify Back cancels the prompt, verify playback from an unlocked restricted detail page does not ask a second time, then Back to Movies/Series and reopen the same Drama title to confirm it asks again.
