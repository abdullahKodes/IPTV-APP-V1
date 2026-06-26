function favoriteStoreRegistryKey(playlistId as String) as String
    if playlistId = invalid or playlistId = "" then playlistId = playlistStoreDemoId()
    return "favorites_" + playlistId
end function

function favoriteStoreList(playlistId as String) as Object
    section = CreateObject("roRegistrySection", "iptv_max_favorites")
    key = favoriteStoreRegistryKey(playlistId)
    raw = section.Read(key)
    if raw <> invalid and raw <> "" then
        parsed = ParseJson(raw)
        if parsed <> invalid and Type(parsed) = "roArray" then return favoriteStoreNormalizeList(parsed, playlistId)
    end if
    return favoriteStoreDemoItems(playlistId)
end function

function favoriteStoreNormalizeList(items as Object, playlistId as String) as Object
    out = []
    if items = invalid then return out
    for each item in items
        if item <> invalid then
            if not item.doesExist("playlistId") then item.playlistId = playlistId
            if not item.doesExist("favorite") then item.favorite = true
            if not item.doesExist("favoriteKey") then item.favoriteKey = favoriteStoreItemKey(item, favoriteStoreText(item, "favoriteKind"))
            out.push(item)
        end if
    end for
    return out
end function

function favoriteStoreSave(playlistId as String, items as Object) as Boolean
    section = CreateObject("roRegistrySection", "iptv_max_favorites")
    raw = FormatJson(items)
    if raw = "" then raw = "[]"
    section.Write(favoriteStoreRegistryKey(playlistId), raw)
    section.Flush()
    return true
end function

function favoriteStoreToggle(kind as String, item as Object, playlistId as String) as Boolean
    if item = invalid then return false
    if playlistId = invalid or playlistId = "" then playlistId = favoriteStoreText(item, "playlistId", playlistStoreActiveId())
    items = favoriteStoreList(playlistId)
    key = favoriteStoreItemKey(item, kind)
    kept = []
    removed = false
    for each fav in items
        favKey = favoriteStoreText(fav, "favoriteKey")
        if favKey = "" then favKey = favoriteStoreItemKey(fav, favoriteStoreText(fav, "favoriteKind"))
        if favKey = key then
            removed = true
        else
            kept.push(fav)
        end if
    end for

    if removed then
        favoriteStoreSave(playlistId, kept)
        return false
    end if

    kept.push(favoriteStoreNormalizeItem(kind, item, playlistId))
    favoriteStoreSave(playlistId, kept)
    return true
end function

function favoriteStoreIsFavorite(kind as String, item as Object, playlistId as String) as Boolean
    if item = invalid then return false
    key = favoriteStoreItemKey(item, kind)
    items = favoriteStoreList(playlistId)
    for each fav in items
        favKey = favoriteStoreText(fav, "favoriteKey")
        if favKey = "" then favKey = favoriteStoreItemKey(fav, favoriteStoreText(fav, "favoriteKind"))
        if favKey = key then return true
    end for
    return false
end function

function favoriteStoreItemKey(item as Object, kind as String) as String
    if kind = invalid or kind = "" then kind = favoriteStoreText(item, "favoriteKind", "item")
    itemId = favoriteStoreText(item, "id")
    if itemId = "" then itemId = favoriteStoreText(item, "title")
    if itemId = "" then itemId = favoriteStoreText(item, "name")
    return kind + ":" + itemId
end function

function favoriteStoreNormalizeItem(kind as String, item as Object, playlistId as String) as Object
    out = {}
    out.favoriteKind = kind
    out.playlistId = playlistId
    out.favorite = true
    out.favoriteKey = favoriteStoreItemKey(item, kind)
    favoriteStoreCopyField(out, item, "id")
    favoriteStoreCopyField(out, item, "title")
    favoriteStoreCopyField(out, item, "name")
    favoriteStoreCopyField(out, item, "year")
    favoriteStoreCopyField(out, item, "duration")
    favoriteStoreCopyField(out, item, "genre")
    favoriteStoreCopyField(out, item, "rating")
    favoriteStoreCopyField(out, item, "posterUrl")
    favoriteStoreCopyField(out, item, "cardUrl")
    favoriteStoreCopyField(out, item, "heroUrl")
    favoriteStoreCopyField(out, item, "backdropUrl")
    favoriteStoreCopyField(out, item, "streamUrl")
    favoriteStoreCopyField(out, item, "streamFormat")
    favoriteStoreCopyField(out, item, "resumePercent")
    favoriteStoreCopyField(out, item, "featured")
    favoriteStoreCopyField(out, item, "accent")
    favoriteStoreCopyField(out, item, "seasons")
    favoriteStoreCopyField(out, item, "episodeCount")
    favoriteStoreCopyField(out, item, "episodeNames")
    favoriteStoreCopyField(out, item, "activeEpisodeTitle")
    favoriteStoreCopyField(out, item, "progressText")
    favoriteStoreCopyField(out, item, "category")
    favoriteStoreCopyField(out, item, "groupTitle")
    favoriteStoreCopyField(out, item, "now")
    favoriteStoreCopyField(out, item, "programTitle")
    favoriteStoreCopyField(out, item, "logoUrl")
    favoriteStoreCopyField(out, item, "badgeUrl")
    favoriteStoreCopyField(out, item, "logoText")
    favoriteStoreCopyField(out, item, "brandColor")
    favoriteStoreCopyField(out, item, "brandColor2")
    favoriteStoreCopyField(out, item, "channelNumber")
    favoriteStoreCopyField(out, item, "live")
    favoriteStoreCopyField(out, item, "description")
    return out
end function

sub favoriteStoreCopyField(out as Object, item as Object, key as String)
    value = favoriteStoreValue(item, key)
    if value <> invalid then out[key] = value
end sub

function favoriteStoreDemoItems(playlistId as String) as Object
    out = []
    if playlistId = playlistStoreDemoId() then
        movies = mediaMovieCatalogForPlaylist(playlistId)
        series = mediaSeriesCatalogForPlaylist(playlistId)
        live = mediaLiveCatalogForPlaylist(playlistId)
        if movies.count() > 3 then out.push(favoriteStoreNormalizeItem("movie", movies[3], playlistId))
        if movies.count() > 0 then out.push(favoriteStoreNormalizeItem("movie", movies[0], playlistId))
        if series.count() > 0 then out.push(favoriteStoreNormalizeItem("series", series[0], playlistId))
        if series.count() > 3 then out.push(favoriteStoreNormalizeItem("series", series[3], playlistId))
        if live.count() > 0 then out.push(favoriteStoreNormalizeItem("live", live[0], playlistId))
        if live.count() > 3 then out.push(favoriteStoreNormalizeItem("live", live[3], playlistId))
    else if playlistId = playlistStoreDemoMoviesId() then
        movies = mediaMovieCatalogForPlaylist(playlistId)
        if movies.count() > 0 then out.push(favoriteStoreNormalizeItem("movie", movies[0], playlistId))
        if movies.count() > 1 then out.push(favoriteStoreNormalizeItem("movie", movies[1], playlistId))
    end if
    return out
end function

function favoriteStoreText(item as Dynamic, key as String, fallback = "" as String) as String
    value = favoriteStoreValue(item, key)
    if value = invalid then return fallback
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function favoriteStoreValue(item as Dynamic, key as String) as Dynamic
    if item = invalid then return invalid
    if item.doesExist(key) then return item[key]
    lowerKey = LCase(key)
    if lowerKey <> key and item.doesExist(lowerKey) then return item[lowerKey]
    return invalid
end function
