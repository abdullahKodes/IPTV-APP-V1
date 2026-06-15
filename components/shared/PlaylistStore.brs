function playlistStoreDefaultItems() as Object
    return [
        { id: "demo_sports", title: "Sports HD Pack", meta: "4,280 channels - M3U", itemCount: 4280, type: "M3U", status: "Active", time: "Updated 2h ago", icon: "tv", accent: "purple", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "2 hours ago" },
        { id: "demo_movies", title: "Movies & Cinema", meta: "2,100 titles - Xtreme", itemCount: 2100, type: "Xtreme", status: "Active", time: "Updated 1d ago", icon: "movies", accent: "green", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "1 day ago" },
        { id: "demo_series", title: "Series Vault", meta: "890 series - M3U", itemCount: 890, type: "M3U", status: "Expires soon", time: "Expires in 3 days", icon: "series", accent: "purple", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "3 days ago" },
        { id: "demo_international", title: "International Live", meta: "3,600 channels - M3U", itemCount: 3600, type: "M3U", status: "Active", time: "Updated 4h ago", icon: "world", accent: "green", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "4 hours ago" },
        { id: "demo_music", title: "Music TV Channels", meta: "420 channels - Xtreme", itemCount: 420, type: "Xtreme", status: "Offline", time: "Last seen 3d ago", icon: "note", accent: "purple", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "3 days ago" },
        { id: "demo_kids", title: "Kids & Family", meta: "1,160 channels - M3U", itemCount: 1160, type: "M3U", status: "Active", time: "Updated 6h ago", icon: "kids", accent: "green", sourceUrl: "", serverUrl: "", username: "", password: "", lastSync: "6 hours ago" }
    ]
end function

function playlistStoreList() as Object
    section = CreateObject("roRegistrySection", "iptv_max_playlists")
    raw = section.Read("items")
    if raw <> invalid and raw <> "" then
        parsed = ParseJson(raw)
        if parsed <> invalid and Type(parsed) = "roArray" then return playlistStoreNormalize(parsed)
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
        item = {
            id: id,
            title: title,
            meta: "Ready to sync - M3U",
            itemCount: 0,
            type: "M3U",
            status: "Active",
            time: "Added just now",
            icon: "m3u",
            accent: accent,
            sourceUrl: playlistStoreText(input, "m3uUrl"),
            serverUrl: "",
            username: "",
            password: "",
            lastSync: "not synced yet"
        }
    end if

    items.push(item)
    playlistStoreSave(items)
    return item
end function

function playlistStoreDelete(id as String) as Boolean
    items = playlistStoreList()
    remaining = []
    for each item in items
        if playlistStoreText(item, "id") <> id then remaining.push(item)
    end for
    return playlistStoreSave(remaining)
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
            normalized.push(item)
        end if
    end for
    return normalized
end function

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
