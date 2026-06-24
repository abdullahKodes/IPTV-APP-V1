function demoPlaybackUrl() as String
    return "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
end function

function demoLivePlaybackUrl(index as Integer) as String
    urls = [
        "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
        "https://playertest.longtailvideo.com/streams/live-vtt-countdown/live.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
    ]
    if index < 0 then index = 0
    return urls[index mod urls.count()]
end function

function mediaPlaybackUrl(item as Dynamic) as String
    streamUrl = mediaValue(item, "streamUrl")
    if streamUrl <> invalid and streamUrl <> "" then return streamUrl
    videoUrl = mediaValue(item, "videoUrl")
    if videoUrl <> invalid and videoUrl <> "" then return videoUrl
    playbackUrl = mediaValue(item, "playbackUrl")
    if playbackUrl <> invalid and playbackUrl <> "" then return playbackUrl
    return demoPlaybackUrl()
end function

function mediaPlaybackFormat(item as Dynamic) as String
    streamFormat = mediaValue(item, "streamFormat")
    if streamFormat <> invalid and streamFormat <> "" then return streamFormat
    return "hls"
end function

function mediaLiveCatalogForPlaylist(playlistId as String) as Object
    if playlistId = "demo_playlist" then return mediaSetPlaylistId(mockLiveTvCatalog(), playlistId)
    if mediaPlaylistIsFakeLive(playlistId) then return mediaSetPlaylistId(playlistStoreDemoLiveItems(playlistId), playlistId)
    stored = mediaStoredPlaylistItems(playlistId, "liveItems")
    if stored.count() > 0 then return mediaSetPlaylistId(stored, playlistId)
    parsed = mediaM3uCatalogForPlaylist(playlistId, "live")
    if parsed.count() > 0 then return parsed
    if mediaPlaylistProfile(playlistId) = "demo_live_m3u" then return mediaSetPlaylistId(playlistStoreDemoLiveItems(playlistId), playlistId)
    return parsed
end function

function mediaMovieCatalogForPlaylist(playlistId as String) as Object
    if playlistId = "demo_playlist" then return mediaSetPlaylistId(mockMovieCatalog(), playlistId)
    if playlistId = "demo_movies_playlist" then return mediaSetPlaylistId(mockMovieCatalog(), playlistId)
    parsed = mediaM3uCatalogForPlaylist(playlistId, "movies")
    if parsed.count() > 0 then return parsed
    if mediaPlaylistProfile(playlistId) = "demo_movies_m3u" then return mediaSetPlaylistId(mockMovieCatalog(), playlistId)
    return parsed
end function

function mediaSeriesCatalogForPlaylist(playlistId as String) as Object
    if playlistId = "demo_playlist" then return mediaSetPlaylistId(mockSeriesCatalog(), playlistId)
    parsed = mediaM3uCatalogForPlaylist(playlistId, "series")
    if parsed.count() > 0 then return parsed
    if mediaPlaylistProfile(playlistId) = "demo_series" then return mediaSetPlaylistId(mockSeriesCatalog(), playlistId)
    return parsed
end function

function mediaPlaylistProfile(playlistId as String) as String
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") = playlistId then return playlistStoreText(item, "contentProfile")
    end for
    return ""
end function

function mediaSetPlaylistId(items as Object, playlistId as String) as Object
    if items = invalid then return []
    for i = 0 to items.count() - 1
        if items[i] <> invalid then items[i].playlistId = playlistId
    end for
    return items
end function

function mediaPlaylistItem(playlistId as String) as Object
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") = playlistId then return item
    end for
    return invalid
end function

function mediaPlaylistIsFakeLive(playlistId as String) as Boolean
    item = mediaPlaylistItem(playlistId)
    if item = invalid then return false
    return playlistStoreIsFakeLiveText(playlistStoreText(item, "sourceUrl")) or playlistStoreIsFakeLiveText(playlistStoreText(item, "title"))
end function

function mediaStoredPlaylistItems(playlistId as String, key as String) as Object
    item = mediaPlaylistItem(playlistId)
    if item = invalid then return []
    value = mediaValue(item, key)
    if value = invalid then return []
    if Type(value) <> "roArray" then return []
    return value
end function

function mediaValue(item as Dynamic, key as String) as Dynamic
    if item = invalid then return invalid
    if item.doesExist(key) then return item[key]
    lowerKey = LCase(key)
    if lowerKey <> key and item.doesExist(lowerKey) then return item[lowerKey]
    return invalid
end function

function mediaM3uCatalogForPlaylist(playlistId as String, kind as String) as Object
    item = mediaPlaylistItem(playlistId)
    if item = invalid then return []

    sourceUrl = playlistStoreText(item, "sourceUrl")
    title = playlistStoreText(item, "title")
    if sourceUrl = "" then return []

    raw = ""
    if playlistStoreIsFakeLiveText(sourceUrl) or playlistStoreIsFakeLiveText(title) then
        raw = mediaFakeLiveM3u()
    else if playlistStoreIsFakeMoviesText(sourceUrl) or playlistStoreIsFakeMoviesText(title) then
        raw = mediaFakeMoviesM3u()
    else if playlistStoreIsFakeSeriesText(sourceUrl) or playlistStoreIsFakeSeriesText(title) then
        raw = mediaFakeSeriesM3u()
    else
        raw = ""
    end if

    if raw = "" then return []
    return mediaParseM3uCatalog(raw, playlistId, kind)
end function

function mediaFetchM3uText(sourceUrl as String) as String
    ' Network fetches must run in a Task, not inside page render.
    if sourceUrl = invalid or sourceUrl = "" then return ""
    return ""
end function

function mediaParseM3uCatalog(raw as String, playlistId as String, kind as String) as Object
    out = []
    if raw = invalid or raw = "" then return out

    lines = raw.Tokenize(Chr(10))
    extinf = ""
    itemIndex = 0

    for each rawLine in lines
        line = mediaTrimText(rawLine)
        if line <> "" then
            if Left(line, 7) = "#EXTINF" then
                extinf = line
            else if extinf <> "" and Left(line, 1) <> "#" then
                itemIndex += 1
                item = mediaM3uBuildItem(extinf, line, playlistId, kind, itemIndex)
                if item <> invalid then out.push(item)
                extinf = ""
                if out.count() >= 250 then return out
            end if
        end if
    end for

    return out
end function

function mediaM3uBuildItem(extinf as String, streamUrl as String, playlistId as String, kind as String, itemIndex as Integer) as Object
    title = mediaM3uTitle(extinf)
    if title = "" then title = "M3U Item " + itemIndex.toStr()
    groupTitle = mediaM3uAttribute(extinf, "group-title")
    logoUrl = mediaM3uAttribute(extinf, "tvg-logo")
    resolvedKind = mediaM3uKind(title, groupTitle, streamUrl)
    if resolvedKind <> kind then return invalid

    itemId = kind + "_" + itemIndex.toStr()
    accent = "purple"
    if itemIndex mod 2 = 1 then accent = "green"

    if kind = "live" then
        category = groupTitle
        if category = "" then category = "Live TV"
        return {
            id: itemId,
            playlistId: playlistId,
            name: title,
            title: title,
            now: "Live stream",
            category: category,
            groupTitle: category,
            icon: "tv",
            logoUrl: logoUrl,
            badgeUrl: "",
            logoText: Left(UCase(title), 4),
            brandColor: "0x2B8C6BFF",
            brandColor2: "0x151C26FF",
            cardUrl: "",
            backdropUrl: "",
            streamUrl: streamUrl,
            streamFormat: mediaStreamFormat(streamUrl),
            live: true,
            favorite: false,
            channelNumber: itemIndex.toStr(),
            epg: [
                { time: "Now", title: "Live stream" },
                { time: "Next", title: "Schedule unavailable" }
            ]
        }
    end if

    if kind = "movies" then
        genre = groupTitle
        if genre = "" then genre = "Movie"
        return {
            id: itemId,
            playlistId: playlistId,
            title: title,
            year: "",
            duration: "",
            genre: genre,
            rating: "",
            posterUrl: logoUrl,
            cardUrl: logoUrl,
            backdropUrl: logoUrl,
            streamUrl: streamUrl,
            streamFormat: mediaStreamFormat(streamUrl),
            resumePercent: 0,
            featured: itemIndex = 1,
            accent: accent
        }
    end if

    genre = groupTitle
    if genre = "" then genre = "Series"
    return {
        id: itemId,
        playlistId: playlistId,
        title: title,
        year: "",
        seasons: "Series",
        episodeCount: "Episodes",
        genre: genre,
        rating: "",
        posterUrl: logoUrl,
        cardUrl: logoUrl,
        backdropUrl: logoUrl,
        streamUrl: streamUrl,
        streamFormat: mediaStreamFormat(streamUrl),
        activeEpisodeTitle: mediaEpisodeLabel(title),
        progressText: "",
        resumePercent: 0,
        featured: itemIndex = 1,
        accent: accent
    }
end function

function mediaM3uKind(title as String, groupTitle as String, streamUrl as String) as String
    text = LCase(groupTitle + " " + title + " " + streamUrl)
    if Instr(1, text, "series") > 0 then return "series"
    if Instr(1, text, "season") > 0 then return "series"
    if Instr(1, text, "episode") > 0 then return "series"
    if Instr(1, text, "s01") > 0 or Instr(1, text, "s02") > 0 or Instr(1, text, "s03") > 0 then return "series"
    if Instr(1, text, "movie") > 0 then return "movies"
    if Instr(1, text, "movies") > 0 then return "movies"
    if Instr(1, text, "vod") > 0 then return "movies"
    if Instr(1, text, "film") > 0 then return "movies"
    if Instr(1, text, ".mp4") > 0 or Instr(1, text, ".mkv") > 0 or Instr(1, text, ".avi") > 0 then return "movies"
    return "live"
end function

function mediaM3uTitle(extinf as String) as String
    comma = Instr(1, extinf, ",")
    if comma = 0 then return ""
    return mediaTrimText(Right(extinf, extinf.len() - comma))
end function

function mediaM3uAttribute(line as String, key as String) as String
    marker = key + Chr(61) + Chr(34)
    start = Instr(1, line, marker)
    quote = Chr(34)
    if start = 0 then
        marker = key + Chr(61) + "'"
        start = Instr(1, line, marker)
        quote = "'"
    end if
    if start = 0 then return ""
    valueStart = start + marker.len()
    rest = Mid(line, valueStart)
    valueEnd = Instr(1, rest, quote)
    if valueEnd = 0 then return ""
    return Left(rest, valueEnd - 1)
end function

function mediaEpisodeLabel(title as String) as String
    text = LCase(title)
    sPos = Instr(1, text, "s0")
    if sPos > 0 then return Mid(title, sPos)
    return ""
end function

function mediaStreamFormat(streamUrl as String) as String
    text = LCase(streamUrl)
    if Instr(1, text, ".mp4") > 0 then return "mp4"
    return "hls"
end function

function mediaTrimText(value as Dynamic) as String
    if value = invalid then return ""
    text = value
    while text.len() > 0 and (Left(text, 1) = " " or Left(text, 1) = Chr(9) or Left(text, 1) = Chr(13))
        text = Right(text, text.len() - 1)
    end while
    while text.len() > 0 and (Right(text, 1) = " " or Right(text, 1) = Chr(9) or Right(text, 1) = Chr(13))
        text = Left(text, text.len() - 1)
    end while
    return text
end function

function mediaFakeSeriesM3u() as String
    stream = demoPlaybackUrl()
    return "#EXTM3U" + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/demo/posters/get_out.jpg" + Chr(34) + " group-title=" + Chr(34) + "Series" + Chr(34) + ",Ozark S01E01" + Chr(10) + stream + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/demo/posters/inception.jpg" + Chr(34) + " group-title=" + Chr(34) + "Series" + Chr(34) + ",Westworld S01E01" + Chr(10) + stream + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/demo/posters/arrival.jpg" + Chr(34) + " group-title=" + Chr(34) + "Series" + Chr(34) + ",The Crown S01E01" + Chr(10) + stream
end function

function mediaFakeMoviesM3u() as String
    stream = demoPlaybackUrl()
    return "#EXTM3U" + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/demo/posters/dune_part_two.jpg" + Chr(34) + " group-title=" + Chr(34) + "Movies" + Chr(34) + ",Dune Part Two" + Chr(10) + stream + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/demo/posters/inception.jpg" + Chr(34) + " group-title=" + Chr(34) + "Movies" + Chr(34) + ",Inception" + Chr(10) + stream + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/demo/posters/dark_knight.jpg" + Chr(34) + " group-title=" + Chr(34) + "Movies" + Chr(34) + ",The Dark Knight" + Chr(10) + stream
end function

function mediaFakeLiveM3u() as String
    return "#EXTM3U" + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/logos/live/bbc_news.png" + Chr(34) + " group-title=" + Chr(34) + "News" + Chr(34) + ",IPTV Max News" + Chr(10) + demoLivePlaybackUrl(0) + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/logos/live/bein_sports.png" + Chr(34) + " group-title=" + Chr(34) + "Sports" + Chr(34) + ",IPTV Max Sports" + Chr(10) + demoLivePlaybackUrl(1) + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/logos/live/discovery.png" + Chr(34) + " group-title=" + Chr(34) + "Documentary" + Chr(34) + ",IPTV Max Docs" + Chr(10) + demoLivePlaybackUrl(2) + Chr(10) + "#EXTINF:-1 tvg-logo=" + Chr(34) + "pkg:/images/logos/live/movie_channel.png" + Chr(34) + " group-title=" + Chr(34) + "Entertainment" + Chr(34) + ",IPTV Max Mix" + Chr(10) + demoLivePlaybackUrl(0)
end function

function mockLiveTvCatalog() as Object
    return [
        {
            id: "live_espn_hd",
            playlistId: "demo_live",
            name: "ESPN HD",
            title: "ESPN HD",
            now: "Premier League Live",
            category: "Sports",
            groupTitle: "Sports",
            icon: "sport",
            logoUrl: "pkg:/images/logos/live/espn.png",
            badgeUrl: "pkg:/images/logos/live/badges/espn_badge.png",
            logoText: "ESPN",
            brandColor: "0xC2182BFF",
            brandColor2: "0x111111FF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/espn_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(0),
            streamFormat: "hls",
            live: true,
            favorite: true,
            channelNumber: "101",
            epg: [
                { time: "21:00", title: "NFL Highlights" },
                { time: "23:00", title: "SportsCenter" },
                { time: "01:00", title: "NBA Pre-game" }
            ]
        },
        {
            id: "live_bbc_world",
            playlistId: "demo_live",
            name: "BBC World",
            title: "BBC World",
            now: "Evening News",
            category: "News",
            groupTitle: "News",
            icon: "NW",
            logoUrl: "pkg:/images/logos/live/bbc_news.png",
            badgeUrl: "pkg:/images/logos/live/badges/bbc_news_badge.png",
            logoText: "BBC",
            brandColor: "0x111111FF",
            brandColor2: "0x2A3446FF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/bbc_news_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(1),
            streamFormat: "hls",
            live: false,
            favorite: false,
            channelNumber: "201",
            epg: [
                { time: "20:30", title: "Global Business" },
                { time: "21:00", title: "Evening News" },
                { time: "22:00", title: "World Report" }
            ]
        },
        {
            id: "live_cnn_intl",
            playlistId: "demo_live",
            name: "CNN Intl",
            title: "CNN Intl",
            now: "Breaking News",
            category: "News",
            groupTitle: "News",
            icon: "CNN",
            logoUrl: "pkg:/images/logos/live/cnn.png",
            badgeUrl: "pkg:/images/logos/live/badges/cnn_badge.png",
            logoText: "CNN",
            brandColor: "0xB5101BFF",
            brandColor2: "0x251118FF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/cnn_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(2),
            streamFormat: "hls",
            live: false,
            favorite: false,
            channelNumber: "202",
            epg: [
                { time: "20:00", title: "The Lead" },
                { time: "21:00", title: "Breaking News" },
                { time: "22:00", title: "World Brief" }
            ]
        },
        {
            id: "live_bein_sports",
            playlistId: "demo_live",
            name: "beIN Sports",
            title: "beIN Sports",
            now: "La Liga Live",
            category: "Sports",
            groupTitle: "Sports",
            icon: "sport",
            logoUrl: "pkg:/images/logos/live/bein_sports.png",
            badgeUrl: "pkg:/images/logos/live/badges/bein_sports_badge.png",
            logoText: "beIN",
            brandColor: "0x6D3BEFFF",
            brandColor2: "0x23133DFF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/bein_sports_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(1),
            streamFormat: "hls",
            live: true,
            favorite: false,
            channelNumber: "102",
            epg: [
                { time: "20:45", title: "La Liga Live" },
                { time: "22:45", title: "Match Review" },
                { time: "23:30", title: "Football Tonight" }
            ]
        },
        {
            id: "live_mtv_hits",
            playlistId: "demo_live",
            name: "MTV Hits",
            title: "MTV Hits",
            now: "Top 40 Charts",
            category: "Music",
            groupTitle: "Music",
            icon: "MTV",
            logoUrl: "pkg:/images/logos/live/mtv_hits.png",
            badgeUrl: "pkg:/images/logos/live/badges/mtv_hits_badge.png",
            logoText: "MTV",
            brandColor: "0x2D63E6FF",
            brandColor2: "0x151A39FF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/mtv_hits_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(0),
            streamFormat: "hls",
            live: false,
            favorite: false,
            channelNumber: "301",
            epg: [
                { time: "19:00", title: "Top 40 Charts" },
                { time: "21:00", title: "Fresh Videos" },
                { time: "22:00", title: "Late Mix" }
            ]
        },
        {
            id: "live_cartoon_net",
            playlistId: "demo_live",
            name: "Cartoon Net.",
            title: "Cartoon Net.",
            now: "Kids Shows",
            category: "Kids",
            groupTitle: "Kids",
            icon: "KD",
            logoUrl: "pkg:/images/logos/live/cartoon_network.png",
            badgeUrl: "pkg:/images/logos/live/badges/cartoon_network_badge.png",
            logoText: "CN",
            brandColor: "0x24A8D8FF",
            brandColor2: "0x101F2CFF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/cartoon_network_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(2),
            streamFormat: "hls",
            live: false,
            favorite: false,
            channelNumber: "401",
            epg: [
                { time: "18:30", title: "Adventure Hour" },
                { time: "19:30", title: "Kids Shows" },
                { time: "21:00", title: "Family Cartoons" }
            ]
        },
        {
            id: "live_discovery",
            playlistId: "demo_live",
            name: "Discovery",
            title: "Discovery",
            now: "Expedition Unknown",
            category: "Documentary",
            groupTitle: "Documentary",
            icon: "WORLD",
            logoUrl: "pkg:/images/logos/live/discovery.png",
            badgeUrl: "pkg:/images/logos/live/badges/discovery_badge.png",
            logoText: "DISC",
            brandColor: "0x16775DFF",
            brandColor2: "0x102921FF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/discovery_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(1),
            streamFormat: "hls",
            live: false,
            favorite: false,
            channelNumber: "501",
            epg: [
                { time: "20:00", title: "Expedition Unknown" },
                { time: "21:00", title: "Planet Stories" },
                { time: "22:00", title: "Deep Ocean" }
            ]
        },
        {
            id: "live_movie_mix",
            playlistId: "demo_live",
            name: "Movie Mix",
            title: "Movie Mix",
            now: "Action Classics",
            category: "Entertainment",
            groupTitle: "Entertainment",
            icon: "movies",
            logoUrl: "pkg:/images/logos/live/movie_channel.png",
            badgeUrl: "pkg:/images/logos/live/badges/movie_channel_badge.png",
            logoText: "MIX",
            brandColor: "0x6B48D7FF",
            brandColor2: "0x19112EFF",
            cardUrl: "",
            backdropUrl: "pkg:/images/logos/live/backdrops/movie_channel_backdrop.jpg",
            streamUrl: demoLivePlaybackUrl(0),
            streamFormat: "hls",
            live: false,
            favorite: false,
            channelNumber: "601",
            epg: [
                { time: "19:00", title: "Action Classics" },
                { time: "21:15", title: "Late Feature" },
                { time: "23:30", title: "Director's Cut" }
            ]
        }
    ]
end function

function mockMovieCatalog() as Object
    return [
        {
            id: "movie_inception",
            playlistId: "demo_movies",
            title: "Inception",
            year: "2010",
            duration: "2h 28m",
            genre: "Sci-Fi - Thriller",
            rating: "PG-13",
            posterUrl: "pkg:/images/demo/posters/inception.jpg",
            cardUrl: "pkg:/images/demo/posters/inception.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/inception.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 0,
            featured: false,
            accent: "green"
        },
        {
            id: "movie_dark_knight",
            playlistId: "demo_movies",
            title: "The Dark Knight",
            year: "2008",
            duration: "2h 32m",
            genre: "Action - Crime",
            rating: "PG-13",
            posterUrl: "pkg:/images/demo/posters/dark_knight.jpg",
            cardUrl: "pkg:/images/demo/posters/dark_knight.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/dark_knight.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 0,
            featured: false,
            accent: "purple"
        },
        {
            id: "movie_get_out",
            playlistId: "demo_movies",
            title: "Get Out",
            year: "2017",
            duration: "1h 44m",
            genre: "Horror - Mystery",
            rating: "R",
            posterUrl: "pkg:/images/demo/posters/get_out.jpg",
            cardUrl: "pkg:/images/demo/posters/get_out.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/get_out.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 38,
            featured: false,
            accent: "green"
        },
        {
            id: "movie_dune_part_two",
            playlistId: "demo_movies",
            title: "Dune Part Two",
            year: "2024",
            duration: "2h 46m",
            genre: "Sci-Fi - Adventure",
            rating: "PG-13",
            posterUrl: "pkg:/images/demo/posters/dune_part_two.jpg",
            cardUrl: "pkg:/images/demo/posters/dune_part_two.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/dune_part_two.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 0,
            featured: true,
            accent: "purple"
        },
        {
            id: "movie_inside_out_two",
            playlistId: "demo_movies",
            title: "Inside Out 2",
            year: "2024",
            duration: "1h 36m",
            genre: "Animation - Family",
            rating: "PG",
            posterUrl: "pkg:/images/demo/posters/inside_out_two.jpg",
            cardUrl: "pkg:/images/demo/posters/inside_out_two.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/inside_out_two.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 0,
            featured: false,
            accent: "green"
        },
        {
            id: "movie_fall_guy",
            playlistId: "demo_movies",
            title: "The Fall Guy",
            year: "2024",
            duration: "2h 06m",
            genre: "Action - Comedy",
            rating: "PG-13",
            posterUrl: "pkg:/images/demo/posters/fall_guy.jpg",
            cardUrl: "pkg:/images/demo/posters/fall_guy.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/fall_guy.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 14,
            featured: false,
            accent: "purple"
        },
        {
            id: "movie_arrival",
            playlistId: "demo_movies",
            title: "Arrival",
            year: "2016",
            duration: "1h 56m",
            genre: "Sci-Fi - Drama",
            rating: "PG-13",
            posterUrl: "pkg:/images/demo/posters/arrival.jpg",
            cardUrl: "pkg:/images/demo/posters/arrival.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/arrival.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 0,
            featured: false,
            accent: "green"
        },
        {
            id: "movie_mad_max_fury_road",
            playlistId: "demo_movies",
            title: "Mad Max Fury Road",
            year: "2015",
            duration: "2h 00m",
            genre: "Action - Adventure",
            rating: "R",
            posterUrl: "pkg:/images/demo/posters/mad_max_fury_road.jpg",
            cardUrl: "pkg:/images/demo/posters/mad_max_fury_road.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/mad_max_fury_road.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 66,
            featured: false,
            accent: "purple"
        },
        {
            id: "movie_spiderverse",
            playlistId: "demo_movies",
            title: "Spider-Verse",
            year: "2023",
            duration: "2h 20m",
            genre: "Animation - Action",
            rating: "PG",
            posterUrl: "pkg:/images/demo/posters/spiderverse.jpg",
            cardUrl: "pkg:/images/demo/posters/spiderverse.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/spiderverse.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 0,
            featured: false,
            accent: "green"
        },
        {
            id: "movie_knives_out",
            playlistId: "demo_movies",
            title: "Knives Out",
            year: "2019",
            duration: "2h 10m",
            genre: "Comedy - Mystery",
            rating: "PG-13",
            posterUrl: "pkg:/images/demo/posters/knives_out.jpg",
            cardUrl: "pkg:/images/demo/posters/knives_out.jpg",
            backdropUrl: "pkg:/images/demo/movie_backdrops/knives_out.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            resumePercent: 0,
            featured: false,
            accent: "purple"
        }
    ]
end function

function mockSeriesCatalog() as Object
    return [
        {
            id: "series_ozark",
            playlistId: "demo_series",
            title: "Ozark",
            year: "2017",
            seasons: "4 Seasons",
            episodeCount: "44 Episodes",
            genre: "Drama - Thriller",
            rating: "TV-MA",
            posterUrl: "pkg:/images/demo/series_posters/ozark.jpg",
            cardUrl: "pkg:/images/demo/series_posters/ozark.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/ozark.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "S3 - E7",
            progressText: "22 min left",
            resumePercent: 70,
            featured: true,
            accent: "green"
        },
        {
            id: "series_westworld",
            playlistId: "demo_series",
            title: "Westworld",
            year: "2016",
            seasons: "4 Seasons",
            episodeCount: "36 Episodes",
            genre: "Sci-Fi - Drama",
            rating: "TV-MA",
            posterUrl: "pkg:/images/demo/series_posters/westworld.jpg",
            cardUrl: "pkg:/images/demo/series_posters/westworld.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/westworld.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "S4 - E2",
            progressText: "31 min left",
            resumePercent: 52,
            featured: false,
            accent: "purple"
        },
        {
            id: "series_the_crown",
            playlistId: "demo_series",
            title: "The Crown",
            year: "2016",
            seasons: "6 Seasons",
            episodeCount: "60 Episodes",
            genre: "Drama - History",
            rating: "TV-MA",
            posterUrl: "pkg:/images/demo/series_posters/the_crown.jpg",
            cardUrl: "pkg:/images/demo/series_posters/the_crown.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/the_crown.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "",
            progressText: "",
            resumePercent: 0,
            featured: false,
            accent: "green"
        },
        {
            id: "series_house_of_dragon",
            playlistId: "demo_series",
            title: "House of Dragon",
            year: "2022",
            seasons: "2 Seasons",
            episodeCount: "18 Episodes",
            genre: "Action - Fantasy",
            rating: "TV-MA",
            posterUrl: "pkg:/images/demo/series_posters/house_of_dragon.jpg",
            cardUrl: "pkg:/images/demo/series_posters/house_of_dragon.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/house_of_dragon.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "S2 - E3",
            progressText: "44 min left",
            resumePercent: 30,
            featured: false,
            accent: "purple"
        },
        {
            id: "series_peaky_blinders",
            playlistId: "demo_series",
            title: "Peaky Blinders",
            year: "2013",
            seasons: "6 Seasons",
            episodeCount: "36 Episodes",
            genre: "Crime - Drama",
            rating: "TV-MA",
            posterUrl: "pkg:/images/demo/series_posters/peaky_blinders.jpg",
            cardUrl: "pkg:/images/demo/series_posters/peaky_blinders.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/peaky_blinders.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "",
            progressText: "",
            resumePercent: 0,
            featured: false,
            accent: "green"
        },
        {
            id: "series_silicon_valley",
            playlistId: "demo_series",
            title: "Silicon Valley",
            year: "2014",
            seasons: "6 Seasons",
            episodeCount: "53 Episodes",
            genre: "Comedy",
            rating: "TV-MA",
            posterUrl: "pkg:/images/demo/series_posters/silicon_valley.jpg",
            cardUrl: "pkg:/images/demo/series_posters/silicon_valley.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/silicon_valley.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "",
            progressText: "",
            resumePercent: 0,
            featured: false,
            accent: "purple"
        },
        {
            id: "series_dark",
            playlistId: "demo_series",
            title: "Dark",
            year: "2017",
            seasons: "3 Seasons",
            episodeCount: "26 Episodes",
            genre: "Sci-Fi - Thriller",
            rating: "TV-MA",
            posterUrl: "pkg:/images/demo/series_posters/dark.jpg",
            cardUrl: "pkg:/images/demo/series_posters/dark.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/dark.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "",
            progressText: "",
            resumePercent: 0,
            featured: false,
            accent: "green"
        },
        {
            id: "series_only_murders",
            playlistId: "demo_series",
            title: "Only Murders",
            year: "2021",
            seasons: "4 Seasons",
            episodeCount: "40 Episodes",
            genre: "Comedy - Mystery",
            rating: "TV-14",
            posterUrl: "pkg:/images/demo/series_posters/only_murders.jpg",
            cardUrl: "pkg:/images/demo/series_posters/only_murders.jpg",
            backdropUrl: "pkg:/images/demo/series_backdrops/only_murders.jpg",
            streamUrl: demoPlaybackUrl(),
            streamFormat: "hls",
            activeEpisodeTitle: "",
            progressText: "",
            resumePercent: 0,
            featured: false,
            accent: "purple"
        }
    ]
end function
