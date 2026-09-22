sub main()
    m.failures = 0
    check(not backendApiTaskResponseOk(200, invalid), "empty JSON is not success")
    check(not backendApiTaskResponseOk(200, {data: {}}), "success flag required")
    check(not backendApiTaskResponseOk(200, {success: true, data: []}), "invalid data shape rejected")
    check(not backendApiTaskResponseOk(401, {success: true, data: {}}), "HTTP failure overrides success flag")
    livePage = {kind: "live"}
    historyEntry = navigationHistoryEntry("LiveTvPage", livePage, "SeriesPage")
    check(historyEntry.page = invalid, "Live TV to Series history does not retain the Live TV node")
    historyEntry = navigationHistoryEntry("MoviesPage", {kind: "movies"}, "SeriesPage")
    check(historyEntry.page = invalid, "catalog-to-catalog history stays lightweight")
    historyEntry = navigationHistoryEntry("SeriesPage", {kind: "series"}, "SeriesDetailPage")
    check(historyEntry.page <> invalid, "Series detail retains its immediate source page for Back")
    history = [{name: "1"}, {name: "2"}, {name: "3"}]
    history = navigationTrimHistory(history, 2)
    check(history.count() = 2 and history[0].name = "2" and history[1].name = "3", "route history is capped without losing the newest routes")
    request = backendApiSyncChannelsRequest("playlist", 1000, "movie")
    check(request.path = "/api/v1/playlists/playlist/bootstrap?page=1&page_size=50&content_type=movie", "movie bootstrap and bounded page size")
    check(request.groupsPath = "/api/v1/playlists/playlist/groups?content_type=movie", "Movies retrieves categories from the movie-only groups endpoint")
    check(backendApiMovieContentType("backend_movies", "m3u") = "", "single-purpose Movies M3U includes unknown imported rows")
    check(backendApiMovieContentType("backend_xtream", "xtream") = "movie" and backendApiMovieContentType("backend_live", "m3u") = "movie", "Xtream and mixed playlists retain strict movie filtering")
    request = backendApiSyncChannelsRequest("playlist", 50, "series", 2)
    check(request.path = "/api/v1/playlists/playlist/series?page=2&page_size=50", "series uses series records and page numbers")
    seriesGroupsRequest = backendApiSyncChannelsRequest("playlist", 50, "series")
    liveGroupsRequest = backendApiSyncChannelsRequest("playlist", 50, "live")
    check(seriesGroupsRequest.groupsPath = "/api/v1/playlists/playlist/groups?content_type=series" and liveGroupsRequest.groupsPath = "/api/v1/playlists/playlist/groups?content_type=live", "Series and Live TV retrieve categories from their typed groups endpoints")
    request = backendApiSyncChannelsRequest("playlist", 50, "live", 1, "Outdoor;Sports", "Sky News")
    check(Instr(1, request.path, "&group=Outdoor%3BSports&search=Sky%20News") > 0, "search and category query values are URL encoded without a transfer object")
    request = backendApiSeriesChannelFallbackRequest("playlist", 2, "Drama;Series", "Pilot")
    check(request.path = "/api/v1/playlists/playlist/channels?page=2&page_size=50&group=Drama%3BSeries&search=Pilot", "M3U series fallback uses channel rows and raw group")
    request = backendApiEpisodesRequest("show", 0, 2, true)
    check(Instr(1, request.path, "season_number=0&page=2&page_size=50&include_stream_url=true") > 0, "specials and playable episode page")

    fixture = {success: true, data: {channels: {items: [{id: "movie", content_type: "movie", poster_url: "https://provider.invalid/poster.jpg", overview: "Plot", duration_seconds: 3600}], pagination: {page: 1, page_size: 50, total: 51, has_next: true}}, groups: [{name: "Drama"}], content_types: [{content_type: "movie", count: 51}]}, meta: {request_id: "fixture"}}
    body = backendApiTaskCompactResponseBody(fixture, "/playlists/p/bootstrap")
    response = {ok: true, body: body}
    check(backendApiResponseItems(response).count() = 1, "bootstrap nested items survive task compaction")
    check(backendApiResponseNextCursor(response) = 2, "bootstrap nested pagination")
    check(backendApiResponseTotalCount(response) = 51, "bootstrap exact totals")
    movie = backendApiMapMovieItem(body.data.items[0], "p", 1)
    check(movie.posterUrl = "https://provider.invalid/poster.jpg" and movie.heroUrl = "" and movie.artworkRole = "poster" and movie.cardDisplayMode = "fit" and movie.description = "Plot" and movie.duration = "1 hour", "backend movie poster remains right-side artwork when no backdrop is supplied")
    check(backendApiDuration({duration_seconds: 6600}) = "1 hour 50 minutes", "backend movie duration uses hours and minutes")
    check(backendApiDuration({duration_seconds: 4500}) = "1 hour 15 minutes", "backend episode duration uses hours and minutes")
    compactMovie = backendApiTaskCompactChannel({duration_seconds: 6600, info: {name: "provider"}})
    check(compactMovie.duration_seconds = 6600, "movie detail keeps top-level runtime when provider info has no duration")
    compactMovie = backendApiTaskCompactChannel({metadata: {info: {duration_secs: 4500}}})
    check(compactMovie.duration_seconds = 4500, "movie detail accepts nested provider runtime")
    check(backendApiDurationLabel("110 min") = "1 hour 50 minutes" and backendApiDurationLabel("110 minutes") = "1 hour 50 minutes" and backendApiDurationLabel("2h 28m") = "2 hours 28 minutes", "stored duration labels use full English units")
    coverMovie = backendApiMapMovieItem({id: "cover-movie", name: "Cover Movie", content_type: "movie", cover_url: "https://provider.invalid/cover.jpg"}, "p", 2)
    check(coverMovie.posterUrl = "https://provider.invalid/cover.jpg" and coverMovie.artworkRole = "poster", "movie cover artwork is retained when poster_url is absent")
    backdropOnlyMovie = backendApiMapMovieItem({id: "backdrop-movie", name: "Backdrop Movie", content_type: "movie", backdrop_url: "https://provider.invalid/backdrop.jpg"}, "p", 3)
    check(backdropOnlyMovie.posterUrl = "https://provider.invalid/backdrop.jpg" and backdropOnlyMovie.artworkRole = "backdrop" and backdropOnlyMovie.heroUrl = backdropOnlyMovie.posterUrl, "backdrop-only movie rows still receive card artwork")
    titledMovie = backendApiMapMovieItem({id: "titled", name: "()-DE-", title: "1991", content_type: "movie"}, "p", 4)
    check(titledMovie.title = "1991" and not titledMovie.titleNeedsDetail, "movie title falls back from malformed provider name to a usable title field")
    untitledMovie = backendApiMapMovieItem({id: "untitled", name: "()", content_type: "movie"}, "p", 5)
    check(untitledMovie.title = "Movie" and untitledMovie.titleNeedsDetail, "malformed movie names use a readable fallback and request detail enrichment")
    metadataTitleFixture = {success: true, data: {items: [{id: "metadata-title", name: "Movie", content_type: "movie", metadata: {o_name: "The Proper Movie", unsafe: [1, 2, 3]}}]}}
    metadataTitleBody = backendApiTaskCompactResponseBody(metadataTitleFixture, "/playlists/p/channels")
    metadataTitleMovie = backendApiMapMovieItem(metadataTitleBody.data.items[0], "p", 6)
    check(metadataTitleMovie.title = "The Proper Movie" and not metadataTitleMovie.titleNeedsDetail and not metadataTitleBody.data.items[0].doesExist("metadata"), "bounded provider metadata recovers a movie title without crossing nested metadata into SceneGraph")
    liveArtworkSource = {id: "live-art", name: "LiveArt", content_type: "live", logo_url: "https://provider.invalid/logo.png", poster_url: "https://provider.invalid/poster.jpg", backdrop_url: "https://provider.invalid/backdrop.jpg"}
    check(backendApiArtworkUrl(liveArtworkSource, "logo_url") <> "" and backendApiArtworkUrl(liveArtworkSource, "poster_url") <> "" and backendApiArtworkUrl(liveArtworkSource, "backdrop_url") <> "", "Live TV accepts logo, poster, and backdrop artwork fields independently")
    logoMovie = backendApiMapMovieItem({id: "logo-movie", name: "Logo Movie", content_type: "movie", logo_url: "https://provider.invalid/logo.png"}, "p", 2)
    check(logoMovie.posterUrl = "https://provider.invalid/logo.png" and logoMovie.heroUrl = "" and logoMovie.artworkRole = "logo" and logoMovie.cardDisplayMode = "fit", "logo-only movie keeps its logo on the card without promoting it to hero artwork")
    artworkFixture = {success: true, data: {items: [{id: "art", poster_url: "https://provider.invalid/poster.jpg", backdrop_url: "https://provider.invalid/backdrop.jpg", hero_url: "https://provider.invalid/hero.jpg", background_url: "https://provider.invalid/background.jpg", fanart_url: "https://provider.invalid/fanart.jpg"}]}}
    artworkBody = backendApiTaskCompactResponseBody(artworkFixture, "/playlists/p/channels")
    artworkMovie = backendApiMapMovieItem(artworkBody.data.items[0], "p", 1)
    check(artworkMovie.heroUrl = "https://provider.invalid/hero.jpg" and artworkMovie.backdropUrl = "https://provider.invalid/hero.jpg", "explicit backend hero aliases survive the task and take priority")

    m3uMovies = backendApiMapMovieChannelItems([{id: "provider-movie", name: "Provider Movie", content_type: "unknown", group_title: "Family", stream_url: "https://provider.invalid/video/42.mp4"}], "p")
    check(m3uMovies.count() = 1 and m3uMovies[0].title = "Provider Movie", "unknown M3U row with a movie URL is inferred as movie")
    assumedMovies = backendApiMapMovieChannelItems([{id: "opaque-a", name: "Feature A", content_type: "unknown", stream_url: "https://provider.invalid/watch/opaque-a"}, {id: "opaque-b", name: "Feature B", stream_url: "https://provider.invalid/watch/opaque-b"}, {id: "live", name: "Live Sports", content_type: "live"}, {id: "series", name: "Show S01E01", content_type: "series"}], "p", 0, true)
    check(assumedMovies.count() = 3 and assumedMovies[0].title = "Feature A" and assumedMovies[1].title = "Feature B" and assumedMovies[2].title = "Live Sports", "single-purpose Movies M3U treats generic channel rows as movies but rejects explicit Series rows")
    m3uMovies = backendApiMapMovieChannelItems([{id: "live", name: "Live Sports", content_type: "live", stream_url: "https://provider.invalid/live/42.m3u8"}, {id: "unknown", name: "Unclassified Item", content_type: "unknown"}], "p")
    check(m3uMovies.count() = 0, "live and unidentifiable rows never leak into Movies")
    check(backendApiMapSyncItems([{id: "unknown", content_type: "unknown"}], "p", "live").count() = 0, "unidentifiable rows never leak into Live TV")
    decorativeLiveRows = [{id: "header-long", name: "######## UK ########", content_type: "live"}, {id: "header-short", name: "#US#", content_type: "live"}]
    check(backendApiMapSyncItems(decorativeLiveRows, "p", "live").count() = 0, "decorative Xtream bouquet headers never appear as Live TV channels")
    check(backendApiLiveItemBrowsable({name: "Channel #1", content_type: "live"}) and backendApiLiveItemBrowsable({name: "#UK#", content_type: "live", logo_url: "https://provider.invalid/uk.png"}) and backendApiLiveItemBrowsable({name: "---- NEWS ----", content_type: "live", tvg_id: "news.example"}), "legitimate Live TV names, artwork, and guide IDs remain browseable")
    hostileFixture = {success: true, data: {items: [invalid, "provider-note", 42, [], {id: "short-url", name: "Short Movie", content_type: "movie", stream_url: "x"}, {id: "good", name: "Good Movie", content_type: "movie", stream_url: "https://provider.invalid/good.mp4"}]}}
    hostileBody = backendApiTaskCompactResponseBody(hostileFixture, "/playlists/p/bootstrap")
    hostileMovies = backendApiMapMovieChannelItems(hostileBody.data.items, "p")
    check(hostileBody.data.items.count() = 2 and hostileMovies.count() = 2, "malformed provider rows are discarded at the task boundary")
    check(hostileMovies[0].streamFormat = "hls" and hostileMovies[1].streamFormat = "mp4", "short and normal stream URLs map without substring failure")
    oversizedRows = []
    for i = 1 to 75
        oversizedRows.push({id: i.toStr(), name: "Series " + i.toStr(), content_type: "series", nested_provider_data: {unsafe: [1, 2, 3]}})
    end for
    boundedBody = backendApiTaskCompactResponseBody({success: true, data: {items: oversizedRows}}, "/playlists/p/series")
    check(boundedBody.data.items.count() = 50, "task boundary enforces the requested catalogue page limit")
    check(not boundedBody.data.items[0].doesExist("nested_provider_data"), "catalogue rows cross SceneGraph as bounded scalar fields only")
    manyGroups = []
    for i = 1 to 250
        manyGroups.push({name: "Group " + i.toStr(), nested: {unsafe: true}})
    end for
    boundedGroupsBody = backendApiTaskCompactResponseBody({success: true, data: {items: [], groups: manyGroups}}, "/playlists/p/bootstrap")
    check(boundedGroupsBody.data.groups.count() = 200 and not boundedGroupsBody.data.groups[0].doesExist("nested"), "group metadata is bounded and compact before SceneGraph transfer")
    check(backendApiMapMovieChannelItems([invalid, "provider-note", 42, []], "p").count() = 0, "catalog mapper rejects hostile row shapes independently")
    check(backendApiResponseItems("bad").count() = 0 and backendApiResponseItems({body: "bad"}).count() = 0, "malformed response envelopes fail closed")
    check(backendApiResponseNextCursor({body: {data: {items: [], pagination: "bad"}}}) = -1, "malformed pagination cannot terminate catalog loading")
    check(playlistStoreText("bad", "title", "fallback") = "fallback" and playlistStoreNumber([], "count") = 0, "playlist store rejects scalar and array records")
    check(progressStoreValue("bad", "mediaId") = invalid and favoriteStoreValue(42, "title") = invalid, "saved progress and favorites reject scalar records")
    cleanMedia = mediaSetPlaylistId(["bad", 42, {id: "valid"}], "p")
    check(cleanMedia.count() = 1 and cleanMedia[0].playlistId = "p", "stored media catalog discards invalid record shapes")
    check(detailText("bad", "title") = "", "series detail reader rejects invalid navigation payloads")

    fixture = {success: true, data: {items: [{id: "show", name: "Movie Stories", cover_url: "https://provider.invalid/cover.jpg", category_title: "Drama", plot: "Series plot"}]}, meta: {request_id: "fixture", pagination: {page: 2, page_size: 50, total: 51, has_next: false}}}
    body = backendApiTaskCompactResponseBody(fixture, "/playlists/p/series?page=2")
    response = {ok: true, body: body}
    check(backendApiResponseNextCursor(response) = -1, "full or partial terminal page never invents a next request")
    mapped = backendApiMapSyncItems(body.data.items, "p", "series")
    check(mapped.count() = 1, "series type overrides misleading title inference")
    check(mapped[0].posterUrl = "https://provider.invalid/cover.jpg" and mapped[0].heroUrl = "" and mapped[0].backdropUrl = "" and mapped[0].streamUrl = "", "cover-only Series artwork stays on the card and right-side fallback")
    metadataFixture = {success: true, data: {items: [{id: "show-metadata", name: "Metadata Series", metadata: {cover_big: "https://provider.invalid/metadata-cover.jpg", backdrop_path: ["https://provider.invalid/metadata-backdrop.jpg"]}}]}}
    metadataBody = backendApiTaskCompactResponseBody(metadataFixture, "/playlists/p/series")
    check(metadataBody.data.items[0].provider_cover_url = "https://provider.invalid/metadata-cover.jpg" and metadataBody.data.items[0].provider_backdrop_url = "https://provider.invalid/metadata-backdrop.jpg", "provider Series artwork aliases survive the bounded task boundary")
    metadataMapped = backendApiMapSyncItems(metadataBody.data.items, "p", "series")
    check(metadataMapped[0].posterUrl = "https://provider.invalid/metadata-cover.jpg" and metadataMapped[0].heroUrl = "https://provider.invalid/metadata-backdrop.jpg", "Series mapper recovers provider cover and backdrop aliases")

    fixture = {success: true, data: {items: [{id: "episode-a", series_id: "show", title: "Pilot", season_number: 3, episode_num: 7, info: {duration_secs: 1800}, stream_url: "https://example.invalid/episode.mp4"}]}, meta: {pagination: {page: 1, page_size: 50, total: 1, has_next: false}}}
    body = backendApiTaskCompactResponseBody(fixture, "/series/show/episodes")
    episode = body.data.items[0]
    check(episode.episode_num = 7 and episode.season_number = 3 and episode.duration_seconds = 1800, "episode numbers and info duration preserved")
    check(backendApiStreamFormat(episode.stream_url) = "mp4", "MP4 format")
    check(backendApiStreamFormat("https://example.invalid/live.ts?token=fixture") = "ts", "TS format with query")
    check(backendApiStreamFormat("https://example.invalid/episode.mkv?token=fixture") = "mkv", "MKV remains MKV for Roku")
    check(backendApiStreamFormatForItem({container_extension: "mkv"}, "https://example.invalid/watch/opaque") = "mkv", "opaque URL uses backend container extension")
    check(backendApiStreamFormatForItem({container_extension: "mkv"}, "https://example.invalid/master.m3u8") = "hls", "explicit HLS URL wins over stale container extension")

    rawGroups = [{name: "Outdoor;Sports"}, {name: " Public ; sports "}, {name: "News"}]
    groupNames = backendApiGroupNames(rawGroups)
    check(groupNames.count() = 4, "compound group names use their specific category")
    check(groupNames[1] = "Outdoor" and groupNames[2] = "Public" and groupNames[3] = "News", "compound group labels keep source order")
    countedGroups = backendApiTaskCompactGroups([{name: "News", channel_count: 12}, {name: "Empty", channel_count: 0}])
    check(countedGroups[0].channel_count = 12 and backendApiGroupNames(countedGroups).count() = 2 and backendApiGroupNames(countedGroups)[1] = "News", "typed category counts survive the task boundary and zero-item groups stay hidden")
    check(backendApiGroupQuery(rawGroups, "Outdoor") = "Outdoor;Sports" and backendApiGroupQuery(rawGroups, "Public") = " Public ; sports ", "display categories route through exact backend group values")
    check(backendApiBrowseGroupQuery(rawGroups, groupNames, 1, true, "") = "Outdoor;Sports", "active category results request the selected backend group")
    check(backendApiBrowseGroupQuery(rawGroups, groupNames, 1, false, "") = "All", "Back requests the complete catalogue while retaining the selected pill index")
    groupNames = backendApiGroupNames([{name: ";Sports;; "}, {name: " "}, {name: "News;"}])
    check(groupNames.count() = 3 and groupNames[1] = "Sports" and groupNames[2] = "News", "empty compound group segments are ignored safely")
    fallbackSeries = backendApiMapSeriesChannelItems([{id: "episode", name: "Pilot S01E01", group_title: "Drama;Series", content_type: "unknown"}], "p")
    check(fallbackSeries.count() = 1 and fallbackSeries[0].detailMediaType = "series_channel" and fallbackSeries[0].genre = "Drama", "M3U episode channels remain browseable on Series")
    fallbackSeries = backendApiMapSeriesChannelItems([{id: "episode", name: "Pilot S01E01", group_title: "Drama;Series", content_type: "unknown", logo_url: "https://provider.invalid/logo.png"}], "p")
    check(fallbackSeries[0].posterUrl <> "" and fallbackSeries[0].heroUrl = "" and fallbackSeries[0].backdropUrl = "" and fallbackSeries[0].artworkRole = "logo", "logo-only M3U Series row keeps the default background")
    posterSeries = backendApiMapSeriesChannelItems([{id: "episode-poster", name: "Pilot S01E02", group_title: "Drama;Series", content_type: "series", poster_url: "https://provider.invalid/series-poster.jpg"}], "p")
    check(posterSeries[0].heroUrl = "" and posterSeries[0].backdropUrl = "" and posterSeries[0].artworkRole = "poster" and posterSeries[0].cardDisplayMode = "fit", "M3U Series poster remains card-only without an explicit backdrop")
    backdropSeries = backendApiMapSeriesChannelItems([{id: "episode-backdrop", name: "Pilot S01E03", content_type: "series", poster_url: "https://provider.invalid/series-poster.jpg", backdrop_url: "https://provider.invalid/series-backdrop.jpg"}], "p")
    check(backdropSeries[0].heroUrl = "https://provider.invalid/series-backdrop.jpg" and backdropSeries[0].backdropUrl = backdropSeries[0].heroUrl, "explicit M3U Series backdrop remains available as hero artwork")
    check(mediaFullscreenArtworkUrl("https://provider.invalid/hero.png") <> "" and mediaFullscreenArtworkUrl("pkg:/images/demo/hero_real/series/dark.jpg") <> "" and mediaFullscreenArtworkUrl("javascript:bad") = "", "full-screen Series artwork accepts bounded web and packaged assets only")
    check(mediaArtworkCanFillHero(1280, 720) and mediaArtworkCanFillHero(640, 360), "large landscape artwork qualifies for a Series hero")
    check(not mediaArtworkCanFillHero(639, 360) and not mediaArtworkCanFillHero(720, 1280) and not mediaArtworkCanFillHero(1600, 300), "small portrait and extreme logo artwork stay off the Series backdrop")
    check(backendApiArtworkUrl({logo_url: "javascript:bad"}, "logo_url") = "", "unsupported provider artwork schemes are rejected")
    fallbackSeries = backendApiMapSeriesChannelItems([{id: "movie", name: "Feature", content_type: "movie", stream_url: "https://provider.invalid/feature.mp4"}, {id: "unknown", name: "Unclassified Item", content_type: "unknown"}], "p")
    check(fallbackSeries.count() = 0, "movie and unidentifiable rows never leak into Series")
    fallbackGroups = backendApiGroupsFromChannelItems([{group_title: "Drama;Series"}, {group_title: "Drama;Series"}, {group_title: "Comedy;Series"}])
    check(fallbackGroups.count() = 2 and backendApiGroupQuery(fallbackGroups, "Comedy") = "Comedy;Series", "M3U series fallback preserves raw category routing")

    failure = {ok: false, statusCode: 409, body: {success: false, error: {code: "import_already_running", details: {job_id: "job"}}, meta: {request_id: "fixture"}}}
    check(backendApiResponseImportJob(failure).id = "job", "409 reuses running import")
    failure.body = backendApiTaskCompactResponseBody(failure.body, "/playlists/p/import")
    check(failure.body.error.code = "import_already_running", "errors retained through task boundary")

    pages = []
    for page = 1 to 4
        rows = []
        for i = 1 to 50
            rows.push({id: page.toStr() + "-" + i.toStr()})
        end for
        window = backendApiCatalogWindow(pages, page, rows, page + 1, "3-25")
        pages = window.pages
    end for
    check(window.items.count() = 150 and window.firstPage = 2 and window.nextPage = 5, "large catalogs retain only three pages")
    check(window.items[window.selectedIndex].id = "3-25", "forward eviction preserves focused item")
    window = backendApiCatalogWindow(pages, 1, [{id: "1-1"}], 2, "2-1")
    check(window.firstPage = 1 and window.nextPage = 4 and window.items[window.selectedIndex].id = "2-1", "backward page retrieval preserves focus and forward cursor")
    pages = []
    for page = 1 to 15
        rows = []
        for i = 1 to 50
            rows.push({id: page.toStr() + "-" + i.toStr()})
        end for
        window = backendApiCatalogWindow(pages, page, rows, page + 1, page.toStr() + "-50")
        pages = window.pages
    end for
    check(window.items.count() = 150 and window.firstPage = 13 and window.nextPage = 16, "750-item catalogue advances while retaining three pages")
    check(window.items[window.selectedIndex].id = "15-50", "large-catalogue paging preserves the latest selection")

    m.backendSeries = true
    m.backendSeasons = [{season_number: 0, name: "Specials"}, {season_number: 3, name: "Season Three"}]
    m.backendEpisodes = [episode]
    m.seasonIndex = 1
    m.episodeIndex = 50
    m.episodePageStart = 50
    m.episodeTotal = 51
    m.seasonWindowStart = 0
    check(selectedBackendSeasonNumber() = 3, "real sparse season numbers")
    check(selectedEpisodeProgressId() = "episode-a", "progress uses stable episode identity")
    check(selectedSeasonEpisodeNumber(50) = 7, "real episode number after pagination")
    check(backendEpisodeAt(49) = invalid, "unloaded episode never reuses another page's URL")
    check(selectedSeasonEpisodeCount() = 51, "no arithmetic distribution of episodes across seasons")
    m.backendSeasons = []
    m.episodeTotal = 0
    check(visibleSeasonCount() = 0 and visibleEpisodeCount() = 0, "empty backend detail has no invented seasons or episodes")
    for i = 0 to 9
        m.backendSeasons.push({season_number: i})
    end for
    m.focusItems = [{action: "season", seasonIndex: 7, col: 3}]
    m.focusIndex = 0
    m.detailLoading = false
    check(routeSeriesDetailFocus(1, 0) and m.seasonWindowStart = 8 and m.focusIndex = 3, "seasons beyond eight remain reachable")
    m.focusItems = [{action: "season", seasonIndex: 8, col: 0}]
    m.focusIndex = 0
    check(routeSeriesDetailFocus(-1, 0) and m.seasonWindowStart = 0 and m.focusIndex = 10, "backward season window restores correct focus")
    print "Contract failures: "; m.failures
end sub

sub check(condition as Boolean, label as String)
    if condition then
        print "PASS "; label
    else
        m.failures += 1
        print "FAIL "; label
    end if
end sub
