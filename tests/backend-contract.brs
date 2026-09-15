sub main()
    m.failures = 0
    check(not backendApiTaskResponseOk(200, invalid), "empty JSON is not success")
    check(not backendApiTaskResponseOk(200, {data: {}}), "success flag required")
    check(not backendApiTaskResponseOk(200, {success: true, data: []}), "invalid data shape rejected")
    check(not backendApiTaskResponseOk(401, {success: true, data: {}}), "HTTP failure overrides success flag")
    request = backendApiSyncChannelsRequest("playlist", 1000, "movie")
    check(request.path = "/api/v1/playlists/playlist/bootstrap?page=1&page_size=50&content_type=movie", "movie bootstrap and bounded page size")
    check(backendApiMovieContentType("backend_movies", "m3u") = "", "single-purpose Movies M3U includes unknown imported rows")
    check(backendApiMovieContentType("backend_xtream", "xtream") = "movie" and backendApiMovieContentType("backend_live", "m3u") = "movie", "Xtream and mixed playlists retain strict movie filtering")
    request = backendApiSyncChannelsRequest("playlist", 50, "series", 2)
    check(request.path = "/api/v1/playlists/playlist/series?page=2&page_size=50", "series uses series records and page numbers")
    request = backendApiSyncChannelsRequest("playlist", 50, "live", 1, "Outdoor;Sports", "Sky News")
    check(Instr(1, request.path, "&group=Outdoor%3BSports&search=Sky%20News") > 0, "search and category query values are URL encoded without a transfer object")
    request = backendApiSeriesChannelFallbackRequest("playlist", 2, "Drama;Series", "Pilot")
    check(request.path = "/api/v1/playlists/playlist/channels?page=2&page_size=50&group=Drama%3BSeries&search=Pilot", "M3U series fallback uses channel rows and raw group")
    request = backendApiEpisodesRequest("show", 0, 2, true)
    check(Instr(1, request.path, "season_number=0&page=2&page_size=50&include_stream_url=true") > 0, "specials and playable episode page")

    fixture = {success: true, data: {channels: {items: [{id: "movie", content_type: "movie", poster_url: "poster", overview: "Plot", duration_seconds: 3600}], pagination: {page: 1, page_size: 50, total: 51, has_next: true}}, groups: [{name: "Drama"}], content_types: [{content_type: "movie", count: 51}]}, meta: {request_id: "fixture"}}
    body = backendApiTaskCompactResponseBody(fixture, "/playlists/p/bootstrap")
    response = {ok: true, body: body}
    check(backendApiResponseItems(response).count() = 1, "bootstrap nested items survive task compaction")
    check(backendApiResponseNextCursor(response) = 2, "bootstrap nested pagination")
    check(backendApiResponseTotalCount(response) = 51, "bootstrap exact totals")
    movie = backendApiMapMovieItem(body.data.items[0], "p", 1)
    check(movie.posterUrl = "poster" and movie.description = "Plot" and movie.duration = "60 min", "movie metadata survives worker mapping")
    m3uMovies = backendApiMapMovieChannelItems([{id: "provider-movie", name: "Provider Movie", content_type: "unknown", group_title: "Family", stream_url: "https://provider.invalid/video/42.mp4"}], "p")
    check(m3uMovies.count() = 1 and m3uMovies[0].title = "Provider Movie", "unknown M3U row with a movie URL is inferred as movie")
    m3uMovies = backendApiMapMovieChannelItems([{id: "live", name: "Live Sports", content_type: "live", stream_url: "https://provider.invalid/live/42.m3u8"}, {id: "unknown", name: "Unclassified Item", content_type: "unknown"}], "p")
    check(m3uMovies.count() = 0, "live and unidentifiable rows never leak into Movies")
    check(backendApiMapSyncItems([{id: "unknown", content_type: "unknown"}], "p", "live").count() = 0, "unidentifiable rows never leak into Live TV")
    hostileFixture = {success: true, data: {items: [invalid, "provider-note", 42, [], {id: "short-url", name: "Short Movie", content_type: "movie", stream_url: "x"}, {id: "good", name: "Good Movie", content_type: "movie", stream_url: "https://provider.invalid/good.mp4"}]}}
    hostileBody = backendApiTaskCompactResponseBody(hostileFixture, "/playlists/p/bootstrap")
    hostileMovies = backendApiMapMovieChannelItems(hostileBody.data.items, "p")
    check(hostileBody.data.items.count() = 2 and hostileMovies.count() = 2, "malformed provider rows are discarded at the task boundary")
    check(hostileMovies[0].streamFormat = "hls" and hostileMovies[1].streamFormat = "mp4", "short and normal stream URLs map without substring failure")
    check(backendApiMapMovieChannelItems([invalid, "provider-note", 42, []], "p").count() = 0, "catalog mapper rejects hostile row shapes independently")
    check(backendApiResponseItems("bad").count() = 0 and backendApiResponseItems({body: "bad"}).count() = 0, "malformed response envelopes fail closed")
    check(backendApiResponseNextCursor({body: {data: {items: [], pagination: "bad"}}}) = -1, "malformed pagination cannot terminate catalog loading")
    check(playlistStoreText("bad", "title", "fallback") = "fallback" and playlistStoreNumber([], "count") = 0, "playlist store rejects scalar and array records")
    check(progressStoreValue("bad", "mediaId") = invalid and favoriteStoreValue(42, "title") = invalid, "saved progress and favorites reject scalar records")
    cleanMedia = mediaSetPlaylistId(["bad", 42, {id: "valid"}], "p")
    check(cleanMedia.count() = 1 and cleanMedia[0].playlistId = "p", "stored media catalog discards invalid record shapes")
    check(detailText("bad", "title") = "", "series detail reader rejects invalid navigation payloads")

    fixture = {success: true, data: {items: [{id: "show", name: "Movie Stories", cover_url: "cover", category_title: "Drama", plot: "Series plot"}]}, meta: {request_id: "fixture", pagination: {page: 2, page_size: 50, total: 51, has_next: false}}}
    body = backendApiTaskCompactResponseBody(fixture, "/playlists/p/series?page=2")
    response = {ok: true, body: body}
    check(backendApiResponseNextCursor(response) = -1, "full or partial terminal page never invents a next request")
    mapped = backendApiMapSyncItems(body.data.items, "p", "series")
    check(mapped.count() = 1, "series type overrides misleading title inference")
    check(mapped[0].posterUrl = "cover" and mapped[0].streamUrl = "", "series artwork and no fake channel playback")

    fixture = {success: true, data: {items: [{id: "episode-a", series_id: "show", title: "Pilot", season_number: 3, episode_num: 7, info: {duration_secs: 1800}, stream_url: "https://example.invalid/episode.mp4"}]}, meta: {pagination: {page: 1, page_size: 50, total: 1, has_next: false}}}
    body = backendApiTaskCompactResponseBody(fixture, "/series/show/episodes")
    episode = body.data.items[0]
    check(episode.episode_num = 7 and episode.season_number = 3 and episode.duration_seconds = 1800, "episode numbers and info duration preserved")
    check(backendApiStreamFormat(episode.stream_url) = "mp4", "MP4 format")
    check(backendApiStreamFormat("https://example.invalid/live.ts?token=fixture") = "ts", "TS format with query")

    rawGroups = [{name: "Outdoor;Sports"}, {name: " Public ; sports "}, {name: "News"}]
    groupNames = backendApiGroupNames(rawGroups)
    check(groupNames.count() = 4, "compound group names use their specific category")
    check(groupNames[1] = "Outdoor" and groupNames[2] = "Public" and groupNames[3] = "News", "compound group labels keep source order")
    check(backendApiGroupQuery(rawGroups, "Outdoor") = "Outdoor;Sports" and backendApiGroupQuery(rawGroups, "Public") = " Public ; sports ", "display categories route through exact backend group values")
    check(backendApiBrowseGroupQuery(rawGroups, groupNames, 1, true, "") = "Outdoor;Sports", "active category results request the selected backend group")
    check(backendApiBrowseGroupQuery(rawGroups, groupNames, 1, false, "") = "All", "Back requests the complete catalogue while retaining the selected pill index")
    groupNames = backendApiGroupNames([{name: ";Sports;; "}, {name: " "}, {name: "News;"}])
    check(groupNames.count() = 3 and groupNames[1] = "Sports" and groupNames[2] = "News", "empty compound group segments are ignored safely")
    fallbackSeries = backendApiMapSeriesChannelItems([{id: "episode", name: "Pilot S01E01", group_title: "Drama;Series", content_type: "unknown"}], "p")
    check(fallbackSeries.count() = 1 and fallbackSeries[0].detailMediaType = "series_channel" and fallbackSeries[0].genre = "Drama", "M3U episode channels remain browseable on Series")
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
