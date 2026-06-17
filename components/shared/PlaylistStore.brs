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
    dt = CreateObject("roDateTime")
    dt.toLocalTime()
    id = "user_" + dt.asSeconds().toStr()
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
        sourceUrl = playlistStoreText(input, "m3uUrl")
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
    end if

    items.push(item)
    playlistStoreSave(items)
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
    items = playlistStoreList()
    for i = 0 to items.count() - 1
        item = items[i]
        if playlistStoreText(item, "id") = id then
            item.status = "Active"
            item.time = "Synced just now"
            item.lastSync = "just now"
            if playlistStoreNumber(item, "itemCount") = 0 then
                item.meta = "Sync pending - " + playlistStoreText(item, "type", "Playlist")
            end if
            items[i] = item
        end if
    end for
    return playlistStoreSave(items)
end function

function playlistStoreNormalize(items as Object) as Object
    normalized = []
    for i = 0 to items.count() - 1
        item = items[i]
        if item <> invalid then
            if not item.doesExist("id") then item.id = "playlist_" + i.toStr()
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
            if item.contentProfile = "" then item.contentProfile = playlistStoreInferContentProfile(item)
            if item.contentProfile = "demo_live_m3u" and playlistStoreNumber(item, "itemCount") = 0 then
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
    text = LCase(value)
    if text = playlistStoreFakeSeriesUrl() then return true
    if Instr(1, text, "demo-series") > 0 then return true
    if Instr(1, text, "series.m3u") > 0 then return true
    if Instr(1, text, "series") > 0 then return true
    return false
end function

function playlistStoreIsFakeMoviesText(value as Dynamic) as Boolean
    if value = invalid then return false
    if type(value) <> "String" and type(value) <> "roString" then return false
    text = LCase(value)
    if text = playlistStoreFakeMoviesUrl() then return true
    if Instr(1, text, "demo-movies") > 0 then return true
    if Instr(1, text, "movies.m3u") > 0 then return true
    if Instr(1, text, "movie.m3u") > 0 then return true
    return false
end function

function playlistStoreIsFakeLiveText(value as Dynamic) as Boolean
    if value = invalid then return false
    if type(value) <> "String" and type(value) <> "roString" then return false
    text = LCase(value)
    if text = playlistStoreFakeLiveUrl() then return true
    if Instr(1, text, "demo-live") > 0 then return true
    if Instr(1, text, "live.m3u") > 0 then return true
    return false
end function

function playlistStorePreferredPageForId(id as String) as String
    items = playlistStoreList()
    for each item in items
        if playlistStoreText(item, "id") = id then
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
    if item = invalid then return fallback
    if not item.doesExist(key) then return fallback
    value = item[key]
    if value = invalid or value = "" then return fallback
    return value
end function

function playlistStoreNumber(item as Object, key as String) as Integer
    if item = invalid then return 0
    if not item.doesExist(key) then return 0
    value = item[key]
    if value = invalid then return 0
    return value
end function

function playlistStoreTitleExists(title as String) as Boolean
    compareTitle = LCase(title)
    if compareTitle = "" then return false
    items = playlistStoreList()
    for each item in items
        if LCase(playlistStoreText(item, "title")) = compareTitle then return true
    end for
    return false
end function
