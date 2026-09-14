# AWS backend integration

The app uses `https://16-192-92-41.sslip.io/api/v1`. The hostname is temporary; change the origin in `components/shared/BackendApi.brs` when the production hostname is ready. Paths already contain `/api/v1`.

The supplied desktop API guide and the running service's public `/openapi.json` were compared on 2026-09-14. Public HTTPS checks returned health HTTP 200 and playlists HTTP 401 with the documented JSON envelope. TLS verification was enabled. No live account, playlist, refresh job, or Roku deployment was created during this integration.

## Client behavior

- Saved tokens, recovery codes, user IDs, and unmatched local playlist rows survive authentication failures and migration. A 401 never clears credentials or silently creates another user. A 404 never recreates a playlist. Existing-user recovery remains explicit. Anonymous bootstrap is limited to an installation with no saved identity or backend playlists.
- Live TV and Movies start with bootstrap and continue through `/playlists/{id}/channels`. Series uses `/playlists/{id}/series`, `/series/{id}`, and season-filtered `/series/{id}/episodes`.
- Catalog requests use 50 records per page and explicit `has_next`. Three catalog pages (at most 150 records) are retained. Left from the first retained item fetches an earlier page. Empty mixed-content pages can advance with OK; the app does not crawl the full library looking for matches.
- Xtream Live TV uses `content_type=live`; Movies uses `movie`. Generic M3U Live TV keeps broad channel reads and filters item types locally so `unknown` channels remain usable. Its API total may include non-live records. Series grouping depends on the backend's dedicated series records; flat legacy M3U episode channels are not presented as invented series/seasons.
- Category and search filters are sent to the server, with a 350 ms debounce and cancellation of obsolete requests. Category labels come from bootstrap/groups. Existing layouts and navigation structure are retained.
- Series uses actual season numbers, including season 0 and noncontiguous seasons. More than eight seasons scroll through the existing tab positions. Only one season's episode page is retained. A playable page is requested only on Watch, and the selected episode's stable ID and stream URL are used for playback/progress.
- Movie detail resolves metadata and playback through `/channels/{id}`. Artwork, overview, duration, rating, episode numbers, and provider duration fields survive the Task boundary. MP4/MKV and MPEG-TS URLs are no longer always marked HLS; actual codec/container support still depends on the Roku device.
- My Playlists polls pending imports through a Timer and Task, two seconds after each response, stopping on terminal status. Refresh conflicts reuse a returned running job. Failed/cancelled jobs show a retry instruction. Cached content remains available during refresh.
- Requests and JSON parsing run in SceneGraph Tasks. GET failures have up to three attempts with bounded backoff, slower for HTTP 429. Mutations are not automatically retried. Diagnostics record HTTP status and request ID, not arbitrary response bodies or provider URLs. Xtream username/password input and the Task request are cleared after submission completes.

## Validation

Run `npm.cmd run check` serially. This project's compiler configuration also creates `build/roku-iptv-app.zip`; inspect the ZIP separately before device testing.

The contract fixtures execute the actual BrightScript request, compaction, mapping, pagination, retention, and series-selection helpers in an off-device interpreter:

```powershell
npm.cmd install --prefix build/contract-runtime --no-audit --no-fund --ignore-scripts brs
node tests/run-backend-contract.cjs
```

The interpreter and generated harness stay under ignored `build/`; they are not app dependencies or package contents. These tests cannot simulate SceneGraph networking, poster loading, Roku remote timing, or video decoding.

## Remaining live verification

No existing test token/recovery identity or Roku device was supplied. Therefore survival of Railway users/playlists on AWS, provider request blocking fixes, full Xtream import counts, real series metadata, and actual playback remain unverified. Public health/unauthenticated responses do not establish that the old database was migrated.

Use an existing Roku installation without resetting its registry. Verify `/auth/me` and `/playlists` with its existing identity, then inspect the selected playlist bootstrap/import job totals. If access fails, determine whether the old database and authentication secrets were migrated before using recovery; do not create replacement accounts/playlists to hide the failure. Check one live stream, one movie, and episodes in two different seasons, including paging forward/back and returning from playback. Compare backend import totals with the authorized provider's totals without loading the complete catalog into Roku memory.
