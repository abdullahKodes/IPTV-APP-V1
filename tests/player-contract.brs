sub main()
    m.failures = 0
    check(not playerPlaybackWasMeaningful(0, 0, 0), "zero-second finish is a failure")
    check(not playerPlaybackWasMeaningful(0, 0, 1), "one-second metadata cannot hide zero playback")
    check(not playerPlaybackWasMeaningful(2, 2, 3600), "early VOD finish is a failure")
    check(playerPlaybackWasMeaningful(12, 0, 3600), "real played position permits completion")
    check(playerPlaybackWasMeaningful(4, 4, 5), "genuine short clip may complete")
    check(formatTime(75) = "1:15" and formatTime(4500) = "1:15:00" and formatTime(7325) = "2:02:05", "playback clock shows hours after 60 minutes")

    episode = {id: "episode-b", series_id: "show", season_number: 3, episode_num: 2, stream_url: "https://example.invalid/e2.mkv"}
    response = {ok: true, body: {data: {items: [{id: "episode-a", stream_url: "https://example.invalid/e1.mp4"}, episode]}}}
    chosen = playerNextEpisodeFromResponse(response, 1, "show", 3)
    check(chosen <> invalid and chosen.id = "episode-b", "next episode uses its own record")
    check(playerNextEpisodeFromResponse(response, 2, "show", 3) = invalid, "missing next episode is rejected")
    check(playerNextEpisodeFromResponse(response, 1, "another-show", 3) = invalid, "wrong series is rejected")
    check(playerNextEpisodeFromResponse(response, 1, "show", 4) = invalid, "wrong season is rejected")
    noUrl = {ok: true, body: {data: {items: [{id: "episode-b", series_id: "show", season_number: 3}]}}}
    check(playerNextEpisodeFromResponse(noUrl, 0, "show", 3) = invalid, "missing URL is rejected")
    retryEpisode = playerRetrySourceFromResponse(response, "series", "show", 3, 1, "episode-b")
    check(retryEpisode <> invalid and retryEpisode.id = "episode-b", "retry refreshes the selected episode")
    check(playerRetrySourceFromResponse(response, "series", "show", 3, 1, "episode-a") = invalid, "retry rejects another episode on the same page")
    check(playerRetrySourceFromResponse(response, "series", "show", 4, 1, "episode-b") = invalid, "retry rejects another season")
    check(playerRetrySourceFromResponse(response, "series", "other-show", 3, 1, "episode-b") = invalid, "retry rejects another series")
    check(playerRetrySourceFromResponse(noUrl, "series", "show", 3, 0, "episode-b") = invalid, "retry rejects an episode without a URL")
    movieResponse = {ok: true, body: {data: {channel: {id: "movie-a", stream_url: "https://example.invalid/movie.mp4"}}}}
    check(playerRetrySourceFromResponse(movieResponse, "movie", "movie-a", 0, 0, "") <> invalid, "movie retry refreshes its own source")
    check(playerRetrySourceFromResponse(movieResponse, "movie", "movie-b", 0, 0, "") = invalid, "movie retry rejects another title")
    print "Player contract failures: "; m.failures
end sub

sub check(condition as Boolean, label as String)
    if condition then
        print "PASS "; label
    else
        m.failures += 1
        print "FAIL "; label
    end if
end sub
