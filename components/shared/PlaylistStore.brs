function playlistStoreDefaultItems() as Object
    return [
        { id: playlistStoreEmptyM3uId(), title: "Empty M3U Playlist", meta: "No content yet - M3U", itemCount: 0, type: "M3U", status: "Active", time: "Startup playlist", icon: "m3u", accent: "purple", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "empty", isDemo: true, isProtected: true, contentProfile: "empty_m3u" },
        { id: playlistStoreDemoId(), title: "Demo Playlist", meta: "8 live - 10 movies - 8 series", itemCount: 26, type: "Demo", status: "Trial", time: "7-day trial content", icon: "tv", accent: "purple", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "built in", isDemo: true, isProtected: true },
        { id: playlistStoreDemoMoviesId(), title: "Demo Movies", meta: "10 movies only", itemCount: 10, type: "Demo", status: "Trial", time: "Movies-only trial content", icon: "movies", accent: "purple", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "built in", isDemo: true, isProtected: true }
    ]
end function

function playlistStoreEmptyM3uId() as String
    return "empty_m3u_playlist"
end function

function playlistStoreDemoId() as String
    return "demo_playlist"
end function

function playlistStoreDemoMoviesId() as String
    return "demo_movies_playlist"
end function

function playlistStoreDemoLiveM3uId() as String
    return "demo_live_m3u_playlist"
end function

function playlistStoreFakeSeriesUrl() as String
    return "https://iptvmax.test/demo-series.m3u"
end function

function playlistStoreFakeMoviesUrl() as String
    return "https://iptvmax.test/demo-movies.m3u"
end function

function playlistStoreFakeLiveUrl() as String
    return "https://iptvmax.test/demo-live.m3u"
end function

function playlistStoreList() as Object
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    raw = section.Read("items")
    if raw <> invalid and raw <> "" then
        parsed = ParseJson(raw)
        if parsed <> invalid and Type(parsed) = "roArray" then return playlistStoreMergeDemoDefaults(playlistStoreNormalize(parsed))
    end if
    return playlistStoreDefaultItems()
end function

function playlistStoreSave(items as Object) as Boolean
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    raw = FormatJson(items)
    if raw = "" then return false
    section.Write("items", raw)
    section.Flush()
    return true
end function

function playlistStoreAdd(input as Object, mode as String) as Object
    items = playlistStoreList()
    id = playlistStoreUniqueUserId(items)
    accent = "purple"
    if items.count() mod 2 = 1 then accent = "green"

    if mode = "xtreme" then
        title = playlistStoreText(input, "accountName", "Xtreme Account")
        item = {
            id: id,
            title: title,
            meta: "Ready to sync - Xtreme",
            itemCount: 0,
            type: "Xtreme",
            status: "Active",
            time: "Added just now",
            icon: "link",
            accent: accent,
            sourceUrl: "",
            serverUrl: playlistStoreText(input, "serverUrl"),
            username: playlistStoreText(input, "username"),
            password: playlistStoreText(input, "password"),
            lastSync: "not synced yet"
        }
    else
        title = playlistStoreText(input, "playlistTitle", "M3U Playlist")
        sourceUrl = playlistStoreM3uInputUrl(input)
        if sourceUrl = "" then return invalid
        contentProfile = ""
        meta = "Ready to sync - M3U"
        itemCount = 0
        icon = "m3u"
        if playlistStoreIsFakeLiveText(sourceUrl) or playlistStoreIsFakeLiveText(title) then
            contentProfile = "demo_live_m3u"
            meta = "4 live channels - Demo M3U"
            itemCount = 4
            icon = "tv"
        else if playlistStoreIsFakeMoviesText(sourceUrl) or playlistStoreIsFakeMoviesText(title) then
            contentProfile = "demo_movies_m3u"
            meta = "3 movies - Demo M3U"
            itemCount = 3
            icon = "movies"
        else if playlistStoreIsFakeSeriesText(sourceUrl) or playlistStoreIsFakeSeriesText(title) then
            contentProfile = "demo_series"
            meta = "3 series - Demo M3U"
            itemCount = 3
            icon = "series"
        end if
        item = {
            id: id,
            title: title,
            meta: meta,
            itemCount: itemCount,
            type: "M3U",
            status: "Active",
            time: "Added just now",
            icon: icon,
            accent: accent,
            sourceUrl: sourceUrl,
            serverUrl: "",
            username: "",
            password: "",
            lastSync: "not synced yet",
            contentProfile: contentProfile
        }
        if contentProfile = "demo_live_m3u" then item.liveItems = playlistStoreDemoLiveItems(id)
    end if

    items.push(item)
    playlistStoreSave(items)
    playlistStoreSetActive(id)
    return item
end function

function playlistStoreDelete(id as String) as Boolean
    if playlistStoreIsDemoId(id) then return false
    items = playlistStoreList()
    remaining = []
    for each item in items
        if playlistStoreText(item, "id") <> id then remaining.push(item)
    end for
    saved = playlistStoreSave(remaining)
    if saved and playlistStoreActiveId() = id then playlistStoreSetActive(playlistStoreEmptyM3uId())
    return saved
end function

function playlistStoreRefresh(id as String) as Boolean
    result = playlistStoreRefreshResult(id)
    return result.success
end function

function playlistStoreRefreshResult(id as String) as Object
    items = playlistStoreList()
    for i = 0 to items.count() - 1
        item = items[i]
        if playlistStoreText(item, "id") = id then
            if playlistStoreBool(item, "isProtected", false) then
                item.time = "Built-in content ready"
                item.lastSync = "just now"
                items[i] = item
                saved = playlistStoreSave(items)
                return { success: saved, message: "Built-in playlist is ready." }
            end if

            playlistType = playlistStoreText(item, "type", "M3U")
            if playlistType = "Xtreme" then
                if playlistStoreText(item, "serverUrl") = "" or playlistStoreText(item, "username") = "" or playlistStoreText(item, "password") = "" then
                    item.status = "Offline"
                    item.time = "Account details are incomplete"
                    item.lastSync = "sync failed"
                    items[i] = item
                    playlistStoreSave(items)
                    return { success: false, message: "Complete the Xtreme account details before refreshing." }
                end if
            else if playlistStoreText(item, "sourceUrl") = "" then
                item.status = "Offline"
                item.time = "Playlist URL is missing"
                item.lastSync = "sync failed"
                items[i] = item
                playlistStoreSave(items)
                return { success: false, message: "Add a valid M3U URL before refreshing." }
            end if

            item.status = "Active"
            item.time = "Validated just now"
            item.lastSync = "just now"
            if playlistStoreNumber(item, "itemCount") = 0 then item.meta = "Provider sync pending - " + playlistType
            items[i] = item
            saved = playlistStoreSave(items)
            if saved then return { success: true, message: "Playlist details validated. Provider sync is ready for backend integration." }
            return { success: false, message: "Playlist status could not be saved." }
        end if
    end for
    return { success: false, message: "Playlist could not be found." }
end function

function playlistStoreGet(id as String) as Dynamic
    if id = invalid or id = "" then return invalid
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") = id then return item
    end for
    return invalid
end function

function playlistStoreUpdate(id as String, input as Object, mode as String) as Object
    if id = invalid or id = "" or playlistStoreIsBuiltInId(id) then return invalid
    items = playlistStoreList()
    for i = 0 to items.count() - 1
        item = items[i]
        if playlistStoreText(item, "id") = id then
            if mode = "xtreme" then
                item.title = playlistStoreNormalizeInputText(playlistStoreText(input, "accountName"))
                item.type = "Xtreme"
                item.serverUrl = playlistStoreNormalizeInputText(playlistStoreText(input, "serverUrl"))
                item.username = playlistStoreNormalizeInputText(playlistStoreText(input, "username"))
                item.password = playlistStoreNormalizeInputText(playlistStoreText(input, "password"))
                item.sourceUrl = ""
                item.contentProfile = ""
                item.icon = "link"
                item.meta = "Provider sync pending - Xtreme"
            else
                item.title = playlistStoreNormalizeInputText(playlistStoreText(input, "playlistTitle"))
                item.type = "M3U"
                item.sourceUrl = playlistStoreM3uInputUrl(input)
                item.serverUrl = ""
                item.username = ""
                item.password = ""
                item.contentProfile = playlistStoreInferInputProfile(item.title, item.sourceUrl)
                item.icon = "m3u"
                item.itemCount = 0
                item.meta = "Provider sync pending - M3U"
                if item.contentProfile = "demo_live_m3u" then
                    item.icon = "tv"
                    item.itemCount = 4
                    item.meta = "4 live channels - Demo M3U"
                    item.liveItems = playlistStoreDemoLiveItems(id)
                else if item.contentProfile = "demo_movies_m3u" then
                    item.icon = "movies"
                    item.itemCount = 3
                    item.meta = "3 movies - Demo M3U"
                else if item.contentProfile = "demo_series" then
                    item.icon = "series"
                    item.itemCount = 3
                    item.meta = "3 series - Demo M3U"
                end if
            end if
            item.status = "Active"
            item.time = "Updated just now"
            item.lastSync = "not synced yet"
            items[i] = item
            if playlistStoreSave(items) then return item
            return invalid
        end if
    end for
    return invalid
end function

function playlistStoreInferInputProfile(title as String, sourceUrl as String) as String
    if playlistStoreIsFakeLiveText(sourceUrl) or playlistStoreIsFakeLiveText(title) then return "demo_live_m3u"
    if playlistStoreIsFakeMoviesText(sourceUrl) or playlistStoreIsFakeMoviesText(title) then return "demo_movies_m3u"
    if playlistStoreIsFakeSeriesText(sourceUrl) or playlistStoreIsFakeSeriesText(title) then return "demo_series"
    return ""
end function

sub playlistStoreSetPendingEdit(id as String)
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    section.Write("pendingEditId", id)
    section.Flush()
end sub

function playlistStoreTakePendingEditId() as String
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    id = section.Read("pendingEditId")
    if id = invalid then id = ""
    if section.Exists("pendingEditId") then section.Delete("pendingEditId")
    section.Flush()
    return id
end function

function playlistStoreNormalize(items as Object) as Object
    normalized = []
    usedIds = {}
    for i = 0 to items.count() - 1
        item = items[i]
        if item <> invalid then
            if not item.doesExist("id") then item.id = "playlist_" + i.toStr()
            itemId = playlistStoreText(item, "id", "playlist_" + i.toStr())
            if usedIds.doesExist(itemId) then
                item.id = playlistStoreDuplicateSafeId(itemId, i, usedIds)
                itemId = item.id
            end if
            usedIds[itemId] = true
            if not item.doesExist("title") then item.title = "Playlist"
            if not item.doesExist("meta") then item.meta = "Ready to sync"
            if not item.doesExist("itemCount") then item.itemCount = 0
            if not item.doesExist("type") then item.type = "M3U"
            if not item.doesExist("status") then item.status = "Active"
            if not item.doesExist("time") then item.time = "Ready"
            if not item.doesExist("icon") then item.icon = "list"
            if not item.doesExist("accent") then item.accent = "purple"
            if not item.doesExist("lastSync") then item.lastSync = "not synced yet"
            if not item.doesExist("isDemo") then item.isDemo = playlistStoreIsDemoId(playlistStoreText(item, "id"))
            if not item.doesExist("isProtected") then item.isProtected = item.isDemo
            if not item.doesExist("contentProfile") then item.contentProfile = ""
            playlistStoreRepairMissingM3uSource(item)
            if item.contentProfile = "" then item.contentProfile = playlistStoreInferContentProfile(item)
            if item.contentProfile = "demo_live_m3u" then
                item.liveItems = playlistStoreDemoLiveItems(itemId)
                item.meta = "4 live channels - Demo M3U"
                item.itemCount = 4
                item.icon = "tv"
            else if item.contentProfile = "demo_movies_m3u" and playlistStoreNumber(item, "itemCount") = 0 then
                item.meta = "3 movies - Demo M3U"
                item.itemCount = 3
                item.icon = "movies"
            else if item.contentProfile = "demo_series" and playlistStoreNumber(item, "itemCount") = 0 then
                item.meta = "3 series - Demo M3U"
                item.itemCount = 3
                item.icon = "series"
            end if
            normalized.push(item)
        end if
    end for
    return normalized
end function

sub playlistStoreRepairMissingM3uSource(item as Object)
    if item = invalid then return
    if playlistStoreText(item, "sourceUrl") <> "" then return
    if playlistStoreText(item, "contentProfile") <> "" then return
    if playlistStoreText(item, "type") <> "M3U" then return

    title = playlistStoreNormalizeMatchText(playlistStoreText(item, "title"))
    meta = playlistStoreNormalizeMatchText(playlistStoreText(item, "meta"))
    if Instr(1, title, "test") > 0 or Instr(1, meta, "live") > 0 or playlistStoreNumber(item, "itemCount") = 4 then
        item.sourceUrl = playlistStoreFakeLiveUrl()
    end if
end sub

function playlistStoreM3uInputUrl(input as Object) as String
    sourceUrl = playlistStoreText(input, "m3uUrl")
    if sourceUrl = "" then sourceUrl = playlistStoreText(input, "sourceUrl")
    if sourceUrl = "" then sourceUrl = playlistStoreText(input, "url")
    if sourceUrl = "" then sourceUrl = playlistStoreText(input, "serverUrl")
    return playlistStoreNormalizeInputText(sourceUrl)
end function

function playlistStoreNormalizeInputText(value as Dynamic) as String
    if value = invalid then return ""
    if type(value) <> "String" and type(value) <> "roString" then return ""
    text = value
    while text.len() > 0 and Left(text, 1) = " "
        text = Right(text, text.len() - 1)
    end while
    while text.len() > 0 and Right(text, 1) = " "
        text = Left(text, text.len() - 1)
    end while
    return text
end function

function playlistStoreDemoLiveItems(playlistId as String) as Object
    return [
        {
            id: "live_test_news",
            playlistId: playlistId,
            name: "IPTV Max News",
            title: "IPTV Max News",
            now: "Live stream",
            category: "News",
            groupTitle: "News",
            icon: "news",
            logoUrl: "pkg:/images/logos/live/bbc_news.png",
            badgeUrl: "",
            logoText: "NEWS",
            brandColor: "0x2B8C6BFF",
            brandColor2: "0x151C26FF",
            cardUrl: "",
            backdropUrl: "",
            streamUrl: playlistStoreDemoLiveStream(0),
            streamFormat: "hls",
            live: true,
            favorite: false,
            channelNumber: "1",
            epg: [
                { time: "Now", title: "Live stream" },
                { time: "Next", title: "Schedule unavailable" }
            ]
        },
        {
            id: "live_test_sports",
            playlistId: playlistId,
            name: "IPTV Max Sports",
            title: "IPTV Max Sports",
            now: "Live stream",
            category: "Sports",
            groupTitle: "Sports",
            icon: "sport",
            logoUrl: "pkg:/images/logos/live/bein_sports.png",
            badgeUrl: "",
            logoText: "SPRT",
            brandColor: "0x6258D6FF",
            brandColor2: "0x151C26FF",
            cardUrl: "",
            backdropUrl: "",
            streamUrl: playlistStoreDemoLiveStream(1),
            streamFormat: "hls",
            live: true,
            favorite: false,
            channelNumber: "2",
            epg: [
                { time: "Now", title: "Live stream" },
                { time: "Next", title: "Schedule unavailable" }
            ]
        },
        {
            id: "live_test_docs",
            playlistId: playlistId,
            name: "IPTV Max Docs",
            title: "IPTV Max Docs",
            now: "Live stream",
            category: "Documentary",
            groupTitle: "Documentary",
            icon: "world",
            logoUrl: "pkg:/images/logos/live/discovery.png",
            badgeUrl: "",
            logoText: "DOCS",
            brandColor: "0x19C6B3FF",
            brandColor2: "0x151C26FF",
            cardUrl: "",
            backdropUrl: "",
            streamUrl: playlistStoreDemoLiveStream(2),
            streamFormat: "hls",
            live: true,
            favorite: false,
            channelNumber: "3",
            epg: [
                { time: "Now", title: "Live stream" },
                { time: "Next", title: "Schedule unavailable" }
            ]
        },
        {
            id: "live_test_mix",
            playlistId: playlistId,
            name: "IPTV Max Mix",
            title: "IPTV Max Mix",
            now: "Live stream",
            category: "Entertainment",
            groupTitle: "Entertainment",
            icon: "movies",
            logoUrl: "pkg:/images/logos/live/movie_channel.png",
            badgeUrl: "",
            logoText: "MIX",
            brandColor: "0x8E86FFFF",
            brandColor2: "0x151C26FF",
            cardUrl: "",
            backdropUrl: "",
            streamUrl: playlistStoreDemoLiveStream(0),
            streamFormat: "hls",
            live: true,
            favorite: false,
            channelNumber: "4",
            epg: [
                { time: "Now", title: "Live stream" },
                { time: "Next", title: "Schedule unavailable" }
            ]
        }
    ]
end function

function playlistStoreDemoLiveStream(index as Integer) as String
    urls = [
        "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
        "https://playertest.longtailvideo.com/streams/live-vtt-countdown/live.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
    ]
    if index < 0 then index = 0
    return urls[index mod urls.count()]
end function

function playlistStoreUniqueUserId(items as Object) as String
    dt = CreateObject("roDateTime")
    dt.toLocalTime()
    base = "user_" + dt.asSeconds().toStr() + "_" + items.count().toStr()
    id = base
    suffix = 1
    while playlistStoreContainsId(items, id)
        id = base + "_" + suffix.toStr()
        suffix += 1
    end while
    return id
end function

function playlistStoreContainsId(items as Object, id as String) as Boolean
    if items = invalid then return false
    for each item in items
        if playlistStoreText(item, "id") = id then return true
    end for
    return false
end function

function playlistStoreDuplicateSafeId(baseId as String, index as Integer, usedIds as Object) as String
    if baseId = invalid or baseId = "" then baseId = "playlist"
    id = baseId + "_copy_" + index.toStr()
    suffix = 1
    while usedIds.doesExist(id)
        id = baseId + "_copy_" + index.toStr() + "_" + suffix.toStr()
        suffix += 1
    end while
    return id
end function

function playlistStoreMergeDemoDefaults(items as Object) as Object
    out = []
    defaults = playlistStoreDefaultItems()
    for each item in defaults
        out.push(item)
    end for
    for each item in items
        if not playlistStoreIsBuiltInId(playlistStoreText(item, "id")) then out.push(item)
    end for
    return out
end function

function playlistStoreActiveId() as String
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    activeId = section.Read("activePlaylistId")
    if activeId = invalid or activeId = "" then return playlistStoreEmptyM3uId()
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") = activeId then return activeId
    end for
    return playlistStoreEmptyM3uId()
end function

function playlistStoreActive() as Object
    activeId = playlistStoreActiveId()
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") = activeId then return item
    end for
    return playlistStoreDefaultItems()[0]
end function

sub playlistStoreSetActive(id as String)
    if id = invalid or id = "" then id = playlistStoreEmptyM3uId()
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    section.Write("activePlaylistId", id)
    section.Flush()
end sub

function playlistStoreIsDemoId(id as String) as Boolean
    if id = invalid then return false
    return playlistStoreIsBuiltInId(id)
end function

function playlistStoreIsBuiltInId(id as String) as Boolean
    if id = invalid then return false
    return id = playlistStoreEmptyM3uId() or id = playlistStoreDemoId() or Left(id, 5) = "demo_"
end function

function playlistStoreInferContentProfile(item as Object) as String
    if playlistStoreIsFakeLiveText(playlistStoreText(item, "sourceUrl")) then return "demo_live_m3u"
    if playlistStoreIsFakeLiveText(playlistStoreText(item, "title")) then return "demo_live_m3u"
    if playlistStoreIsFakeMoviesText(playlistStoreText(item, "sourceUrl")) then return "demo_movies_m3u"
    if playlistStoreIsFakeMoviesText(playlistStoreText(item, "title")) then return "demo_movies_m3u"
    if playlistStoreIsFakeSeriesText(playlistStoreText(item, "sourceUrl")) then return "demo_series"
    if playlistStoreIsFakeSeriesText(playlistStoreText(item, "title")) then return "demo_series"
    return ""
end function

function playlistStoreIsFakeSeriesText(value as Dynamic) as Boolean
    if value = invalid then return false
    if type(value) <> "String" and type(value) <> "roString" then return false
    text = playlistStoreNormalizeMatchText(value)
    if text = playlistStoreFakeSeriesUrl() then return true
    if Instr(1, text, "demo-series") > 0 then return true
    if Instr(1, text, "series.m3u") > 0 then return true
    if Instr(1, text, "iptvmax.test") > 0 and Instr(1, text, "series") > 0 then return true
    if Instr(1, text, "demo") > 0 and Instr(1, text, "series") > 0 then return true
    if Instr(1, text, "series") > 0 then return true
    return false
end function

function playlistStoreIsFakeMoviesText(value as Dynamic) as Boolean
    if value = invalid then return false
    if type(value) <> "String" and type(value) <> "roString" then return false
    text = playlistStoreNormalizeMatchText(value)
    if text = playlistStoreFakeMoviesUrl() then return true
    if Instr(1, text, "demo-movies") > 0 then return true
    if Instr(1, text, "movies.m3u") > 0 then return true
    if Instr(1, text, "movie.m3u") > 0 then return true
    if Instr(1, text, "iptvmax.test") > 0 and Instr(1, text, "movie") > 0 then return true
    if Instr(1, text, "demo") > 0 and Instr(1, text, "movie") > 0 then return true
    return false
end function

function playlistStoreIsFakeLiveText(value as Dynamic) as Boolean
    if value = invalid then return false
    if type(value) <> "String" and type(value) <> "roString" then return false
    text = playlistStoreNormalizeMatchText(value)
    if text = playlistStoreFakeLiveUrl() then return true
    if Instr(1, text, "demo-live") > 0 then return true
    if Instr(1, text, "live.m3u") > 0 then return true
    if Instr(1, text, "iptvmax.test") > 0 and Instr(1, text, "live") > 0 then return true
    if Instr(1, text, "demo") > 0 and Instr(1, text, "live") > 0 then return true
    return false
end function

function playlistStoreNormalizeMatchText(value as String) as String
    text = LCase(value)
    while text.len() > 0 and Left(text, 1) = " "
        text = Right(text, text.len() - 1)
    end while
    while text.len() > 0 and Right(text, 1) = " "
        text = Left(text, text.len() - 1)
    end while
    return text
end function

function playlistStorePreferredPageForId(id as String) as String
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") = id then
            if id = playlistStoreDemoLiveM3uId() then return "LiveTvPage"
            if playlistStoreText(item, "contentProfile") = "demo_live_m3u" then return "LiveTvPage"
            if id = playlistStoreDemoMoviesId() then return "MoviesPage"
            if playlistStoreText(item, "contentProfile") = "demo_movies_m3u" then return "MoviesPage"
            if playlistStoreText(item, "contentProfile") = "demo_series" then return "SeriesPage"
            return "LiveTvPage"
        end if
    end for
    return "LiveTvPage"
end function

function playlistStoreDeletedDemos() as Object
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    raw = section.Read("deletedDemoIds")
    deleted = {}
    if raw <> invalid and raw <> "" then
        parsed = ParseJson(raw)
        if parsed <> invalid and Type(parsed) = "roArray" then
            for each id in parsed
                deleted[id] = true
            end for
        end if
    end if
    return deleted
end function

sub playlistStoreRememberDeletedDemo(id as String)
    deleted = playlistStoreDeletedDemos()
    deleted[id] = true
    ids = []
    for each key in deleted
        ids.push(key)
    end for
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    section.Write("deletedDemoIds", FormatJson(ids))
    section.Flush()
end sub

function playlistStoreText(item as Object, key as String, fallback = "" as String) as String
    value = playlistStoreValue(item, key)
    if value = invalid or value = "" then return fallback
    return value
end function

function playlistStoreNumber(item as Object, key as String) as Integer
    value = playlistStoreValue(item, key)
    if value = invalid then return 0
    return value
end function

function playlistStoreBool(item as Object, key as String, fallback as Boolean) as Boolean
    value = playlistStoreValue(item, key)
    if value = invalid then return fallback
    return value = true
end function

function playlistStoreValue(item as Object, key as String) as Dynamic
    if item = invalid then return invalid
    if item.doesExist(key) then return item[key]
    lowerKey = LCase(key)
    if lowerKey <> key and item.doesExist(lowerKey) then return item[lowerKey]
    return invalid
end function

function playlistStoreTitleExists(title as String) as Boolean
    return playlistStoreTitleExistsExcept(title, "")
end function

function playlistStoreTitleExistsExcept(title as String, excludedId as String) as Boolean
    compareTitle = LCase(title)
    if compareTitle = "" then return false
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") <> excludedId and LCase(playlistStoreText(item, "title")) = compareTitle then return true
    end for
    return false
end function
