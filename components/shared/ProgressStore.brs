function progressStoreRegistryKey(playlistId as String) as String
    if playlistId = invalid or playlistId = "" then playlistId = "default"
    return "progress_" + playlistId
end function

function progressStoreList(playlistId as String) as Object
    section = CreateObject("roRegistrySection", "iptv_max_progress")
    raw = section.Read(progressStoreRegistryKey(playlistId))
    if raw = invalid or raw = "" then return []
    parsed = ParseJson(raw)
    if parsed = invalid or Type(parsed) <> "roArray" then return []
    return parsed
end function

function progressStoreFind(playlistId as String, mediaType as String, mediaId as String) as Dynamic
    if mediaId = invalid or mediaId = "" then return invalid
    key = progressStoreItemKey(mediaType, mediaId)
    items = progressStoreList(playlistId)
    for each item in items
        if progressStoreText(item, "key") = key then return item
    end for
    return invalid
end function

function progressStorePosition(playlistId as String, mediaType as String, mediaId as String, episodeId = "" as String) as Integer
    item = progressStoreFind(playlistId, mediaType, mediaId)
    if item = invalid then return 0
    if episodeId <> "" and progressStoreText(item, "episodeId") <> episodeId then return 0
    return progressStoreInt(item, "position")
end function

function progressStoreSave(playlistId as String, entry as Object) as Boolean
    if entry = invalid then return false
    mediaType = progressStoreText(entry, "mediaType")
    mediaId = progressStoreText(entry, "mediaId")
    if playlistId = invalid or playlistId = "" or mediaType = "" or mediaId = "" then return false

    entry.key = progressStoreItemKey(mediaType, mediaId)
    entry.playlistId = playlistId
    now = CreateObject("roDateTime")
    entry.updatedAt = now.AsSeconds()

    existing = progressStoreList(playlistId)
    output = [entry]
    seriesCount = 0
    if mediaType = "series" then seriesCount = 1
    for each item in existing
        if progressStoreText(item, "key") <> entry.key and output.count() < 40 then
            itemType = progressStoreText(item, "mediaType")
            if itemType = "series" then
                if seriesCount < 5 then
                    output.push(item)
                    seriesCount += 1
                end if
            else
                output.push(item)
            end if
        end if
    end for
    return progressStoreWrite(playlistId, output)
end function

function progressStoreRemove(playlistId as String, mediaType as String, mediaId as String) as Boolean
    if mediaId = invalid or mediaId = "" then return false
    key = progressStoreItemKey(mediaType, mediaId)
    existing = progressStoreList(playlistId)
    output = []
    changed = false
    for each item in existing
        if progressStoreText(item, "key") = key then
            changed = true
        else
            output.push(item)
        end if
    end for
    if not changed then return true
    return progressStoreWrite(playlistId, output)
end function

function progressStoreTrimMediaType(playlistId as String, mediaType as String, maxItems as Integer) as Boolean
    if maxItems < 0 then maxItems = 0
    existing = progressStoreList(playlistId)
    output = []
    typeCount = 0
    changed = false
    for each item in existing
        if progressStoreText(item, "mediaType") = mediaType then
            if typeCount < maxItems then
                output.push(item)
                typeCount += 1
            else
                changed = true
            end if
        else
            output.push(item)
        end if
    end for
    if not changed then return true
    return progressStoreWrite(playlistId, output)
end function

function progressStoreWrite(playlistId as String, items as Object) as Boolean
    section = CreateObject("roRegistrySection", "iptv_max_progress")
    raw = FormatJson(items)
    if raw = invalid or raw = "" then raw = "[]"
    if not section.Write(progressStoreRegistryKey(playlistId), raw) then return false
    return section.Flush()
end function

function progressStoreItemKey(mediaType as String, mediaId as String) as String
    return LCase(mediaType) + ":" + mediaId
end function

function progressStoreText(item as Dynamic, key as String, fallback = "" as String) as String
    value = progressStoreValue(item, key)
    if value = invalid then return fallback
    valueType = Type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function progressStoreInt(item as Dynamic, key as String, fallback = 0 as Integer) as Integer
    value = progressStoreValue(item, key)
    if value = invalid then return fallback
    valueType = Type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return Int(value)
    if valueType = "String" or valueType = "roString" then return value.ToInt()
    return fallback
end function

function progressStoreValue(item as Dynamic, key as String) as Dynamic
    if item = invalid then return invalid
    if item.doesExist(key) then return item[key]
    lowerKey = LCase(key)
    if lowerKey <> key and item.doesExist(lowerKey) then return item[lowerKey]
    return invalid
end function
