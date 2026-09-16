sub init()
    m.top.functionName = "runBackendApiRequest"
end sub

sub runBackendApiRequest()
    try
        runBackendApiRequestInternal()
    catch error
        message = "Unexpected catalogue processing error."
        if error <> invalid and error.doesExist("message") then print "Backend task exception: "; error.message
        m.top.response = backendApiErrorResponse(0, message)
    end try
end sub

sub runBackendApiRequestInternal()
    request = m.top.request
    if request = invalid then
        m.top.response = backendApiErrorResponse(0, "Missing backend request.")
        return
    end if

    method = backendApiTaskText(request, "method", "GET")
    path = backendApiTaskText(request, "path", "")
    if path = "/api/v1/auth/anonymous" and backendApiTaskHasSavedIdentity() then
        m.top.response = backendApiErrorResponse(401, "Existing account retained. Use account recovery.")
        return
    end if
    authRequired = backendApiTaskBool(request, "authRequired", true)

    accessToken = ""
    if authRequired then
        accessToken = backendApiTaskAccessToken()
        if accessToken = "" then
            m.top.response = backendApiErrorResponse(401, "Backend authentication could not be created.")
            return
        end if
    end if

    result = backendApiTaskTransfer(request, accessToken)
    responseText = result.text
    statusCode = result.statusCode

    ' Keep stored identity on 401; recovery is an explicit user action.

    parsed = invalid
    if responseText <> invalid then
        if responseText <> "" then parsed = ParseJson(responseText)
    end if

    ok = backendApiTaskResponseOk(statusCode, parsed)

    if ok and request.doesExist("groupsPath") then
        groupsResponse = backendApiTaskTransfer({ method: "GET", path: request.groupsPath }, accessToken)
        groupsBody = ParseJson(groupsResponse.text)
        if groupsResponse.statusCode = 200 and backendApiTaskIsAssoc(groupsBody) then
            if backendApiTaskBool(groupsBody, "success", false) then
                groupsData = backendApiTaskValue(groupsBody, "data")
                if backendApiTaskIsAssoc(groupsData) then parsed.data.groups = backendApiTaskValue(groupsData, "items")
            end if
        end if
    end if
    responseBody = backendApiTaskCompactResponseBody(parsed, path)
    if responseBody = invalid then responseBody = {}
    responseRaw = ""
    ' Never copy arbitrary backend bodies (which may contain provider credentials) to UI/logs.
    requestId = backendApiText(backendApiTaskValue(parsed, "meta"), "request_id")
    if not ok then print "Backend HTTP "; statusCode; " request_id="; requestId

    m.top.response = {
        ok: ok,
        statusCode: statusCode,
        body: responseBody,
        raw: responseRaw,
        requestId: requestId,
        path: path,
        method: method
    }
end sub

function backendApiErrorResponse(statusCode as Integer, message as String) as Object
    return {
        ok: false,
        statusCode: statusCode,
        body: {},
        raw: message,
        path: "",
        method: ""
    }
end function

function backendApiTaskSanitizeJson(value as Dynamic, depth = 0 as Integer) as Dynamic
    if value = invalid then return invalid
    if depth > 6 then return ""
    valueType = Type(value)
    if valueType = "roAssociativeArray" or valueType = "AssociativeArray" then
        clean = {}
        copied = 0
        for each key in value
            if copied >= 100 then exit for
            child = value[key]
            if child = invalid then
                clean[key] = ""
            else
                clean[key] = backendApiTaskSanitizeJson(child, depth + 1)
            end if
            copied += 1
        end for
        return clean
    end if
    if valueType = "roArray" or valueType = "Array" then
        clean = []
        for each child in value
            if clean.count() >= 200 then exit for
            if child = invalid then
                clean.push("")
            else
                clean.push(backendApiTaskSanitizeJson(child, depth + 1))
            end if
        end for
        return clean
    end if
    if valueType = "String" or valueType = "roString" then
        if value.len() > 4096 then return Left(value, 4096)
    end if
    return value
end function

function backendApiTaskCompactResponseBody(parsed as Dynamic, path as String) as Dynamic
    if parsed = invalid then return invalid
    if not backendApiTaskIsAssoc(parsed) then return invalid

    clean = {}
    clean.success = backendApiTaskValue(parsed, "success")
    if clean.success = invalid then clean.success = true

    data = backendApiTaskValue(parsed, "data")
    if data = invalid or not backendApiTaskIsAssoc(data) then
        return backendApiTaskSanitizeJson(parsed)
    end if

    meta = backendApiTaskValue(parsed, "meta")
    if meta <> invalid then clean.meta = backendApiTaskSanitizeJson(meta)

    cleanData = {}
    backendApiTaskCopyIfExists(clean, parsed, "error")
    series = backendApiTaskValue(data, "series")
    if backendApiTaskIsAssoc(series) then cleanData.series = backendApiTaskCompactChannel(series)
    seasons = backendApiTaskValue(data, "seasons")
    if backendApiTaskIsArray(seasons) then
        cleanSeasons = []
        for each season in seasons
            if cleanSeasons.count() >= 100 then exit for
            if backendApiTaskIsAssoc(season) then cleanSeasons.push(backendApiTaskCompactChannel(season))
        end for
        cleanSeasons.SortBy("season_number")
        cleanData.seasons = cleanSeasons
    end if
    groups = backendApiTaskValue(data, "groups")
    if backendApiTaskIsArray(groups) then cleanData.groups = backendApiTaskCompactGroups(groups)
    backendApiTaskCopyIfExists(cleanData, data, "content_types")
    channels = backendApiTaskValue(data, "channels")
    if backendApiTaskIsAssoc(channels) then
        copiedData = {}
        for each key in data
            copiedData[key] = data[key]
        end for
        data = copiedData
        data.items = backendApiTaskValue(channels, "items")
        data.pagination = backendApiTaskValue(channels, "pagination")
    end if
    backendApiTaskCopyIfExists(cleanData, data, "pagination")
    items = backendApiTaskValue(data, "items")
    if items <> invalid and backendApiTaskIsArray(items) then
        cleanItems = []
        for each item in items
            if cleanItems.count() >= 50 then exit for
            ' Provider feeds can contain scalar metadata rows. Never pass them into SceneGraph catalog mappers.
            if backendApiTaskIsAssoc(item) then cleanItems.push(backendApiTaskCompactItem(item, path))
        end for
        cleanData.items = cleanItems
    end if

    playlist = backendApiTaskValue(data, "playlist")
    if playlist <> invalid then cleanData.playlist = backendApiTaskCompactPlaylist(playlist)

    importJob = backendApiTaskValue(data, "import_job")
    if importJob <> invalid then cleanData.import_job = backendApiTaskCompactImportJob(importJob)

    channel = backendApiTaskValue(data, "channel")
    if channel <> invalid then cleanData.channel = backendApiTaskCompactChannel(channel)

    backendApiTaskCopyIfExists(cleanData, data, "meta")
    backendApiTaskCopyIfExists(cleanData, data, "cursor")
    backendApiTaskCopyIfExists(cleanData, data, "next_cursor")
    backendApiTaskCopyIfExists(cleanData, data, "nextCursor")
    backendApiTaskCopyIfExists(cleanData, data, "cursor_next")
    backendApiTaskCopyIfExists(cleanData, data, "next")
    backendApiTaskCopyIfExists(cleanData, data, "limit")
    backendApiTaskCopyIfExists(cleanData, data, "has_more")
    backendApiTaskCopyIfExists(cleanData, data, "hasMore")
    backendApiTaskCopyIfExists(cleanData, data, "total")
    backendApiTaskCopyIfExists(cleanData, data, "total_count")
    backendApiTaskCopyIfExists(cleanData, data, "count")

    if cleanData.Count() = 0 then cleanData = backendApiTaskSanitizeJson(data)
    clean.data = cleanData
    return clean
end function

function backendApiTaskCompactGroups(groups as Dynamic) as Object
    clean = []
    if not backendApiTaskIsArray(groups) then return clean
    for each group in groups
        if clean.count() >= 200 then exit for
        if backendApiTaskIsAssoc(group) then
            name = backendApiTaskValue(group, "name")
            nameType = Type(name)
            if nameType = "String" or nameType = "roString" then
                if name <> "" then
                    cleanGroup = {name: Left(name, 256)}
                    backendApiTaskCopy(cleanGroup, group, "channel_count")
                    clean.push(cleanGroup)
                end if
            end if
        end if
    end for
    return clean
end function

function backendApiTaskCompactItem(item as Dynamic, path as String) as Dynamic
    if item = invalid then return {}
    if not backendApiTaskIsAssoc(item) then return backendApiTaskSanitizeJson(item)
    if Instr(1, path, "/series") > 0 and Instr(1, path, "/episodes") = 0 then
        clean = backendApiTaskCompactChannel(item)
        clean.content_type = "series"
        return clean
    end if
    if Instr(1, path, "/channels") > 0 or Instr(1, path, "/bootstrap") > 0 or Instr(1, path, "/series") > 0 then return backendApiTaskCompactChannel(item)
    return backendApiTaskCompactPlaylist(item)
end function

function backendApiTaskCompactPlaylist(item as Dynamic) as Object
    clean = {}
    backendApiTaskCopy(clean, item, "id")
    backendApiTaskCopy(clean, item, "name")
    backendApiTaskCopy(clean, item, "source_url")
    backendApiTaskCopy(clean, item, "source_host")
    backendApiTaskCopy(clean, item, "source_type")
    backendApiTaskCopy(clean, item, "status")
    backendApiTaskCopy(clean, item, "auto_refresh")
    backendApiTaskCopy(clean, item, "channel_count")
    backendApiTaskCopy(clean, item, "active_channel_count")
    backendApiTaskCopy(clean, item, "last_import_status")
    backendApiTaskCopy(clean, item, "last_imported_at")
    backendApiTaskCopy(clean, item, "playlist_version")
    backendApiTaskCopy(clean, item, "created_at")
    backendApiTaskCopy(clean, item, "updated_at")
    return clean
end function

function backendApiTaskCompactImportJob(item as Dynamic) as Object
    clean = {}
    backendApiTaskCopy(clean, item, "id")
    backendApiTaskCopy(clean, item, "playlist_id")
    backendApiTaskCopy(clean, item, "status")
    backendApiTaskCopy(clean, item, "parser_mode")
    backendApiTaskCopy(clean, item, "records_seen")
    backendApiTaskCopy(clean, item, "records_inserted")
    backendApiTaskCopy(clean, item, "records_updated")
    backendApiTaskCopy(clean, item, "records_failed")
    backendApiTaskCopy(clean, item, "progress_percent")
    backendApiTaskCopy(clean, item, "error_code")
    backendApiTaskCopy(clean, item, "error_message")
    return clean
end function

function backendApiTaskCompactChannel(item as Dynamic) as Object
    clean = {}
    backendApiTaskCopy(clean, item, "id")
    backendApiTaskCopy(clean, item, "playlist_id")
    backendApiTaskCopy(clean, item, "name")
    backendApiTaskCopyProviderTitleAliases(clean, item)
    metadata = backendApiTaskValue(item, "metadata")
    if backendApiTaskIsAssoc(metadata) then
        backendApiTaskCopyProviderTitleAliases(clean, metadata)
        backendApiTaskCopyProviderArtworkAliases(clean, metadata)
        metadataInfo = backendApiTaskValue(metadata, "info")
        if backendApiTaskIsAssoc(metadataInfo) then
            backendApiTaskCopyProviderTitleAliases(clean, metadataInfo)
            backendApiTaskCopyProviderArtworkAliases(clean, metadataInfo)
        end if
    end if
    for each key in ["title", "category_title", "cover_url", "plot", "genre", "release_date", "release_year", "poster_url", "hero_url", "backdrop_url", "background_url", "fanart_url", "overview", "duration_seconds", "rating", "container_extension", "season_number", "episode_num", "series_id"]
        backendApiTaskCopy(clean, item, key)
    end for
    backendApiTaskCopyProviderArtworkAliases(clean, item)
    info = backendApiTaskValue(item, "info")
    if backendApiTaskIsAssoc(info) then clean.duration_seconds = backendApiInt(info, "duration_secs", 0)
    backendApiTaskCopy(clean, item, "tvg_id")
    backendApiTaskCopy(clean, item, "tvg_name")
    backendApiTaskCopy(clean, item, "logo_url")
    backendApiTaskCopy(clean, item, "group_title")
    backendApiTaskCopy(clean, item, "content_type")
    backendApiTaskCopy(clean, item, "media_type")
    backendApiTaskCopy(clean, item, "stream_host")
    backendApiTaskCopy(clean, item, "stream_url")
    backendApiTaskCopy(clean, item, "is_active")
    backendApiTaskCopy(clean, item, "updated_at")
    backendApiTaskCopy(clean, item, "deleted")
    return clean
end function

sub backendApiTaskCopyProviderTitleAliases(target as Object, source as Dynamic)
    backendApiTaskCopyTextAliasIfMissing(target, source, "provider_title", "title")
    backendApiTaskCopyTextAliasIfMissing(target, source, "provider_original_name", "o_name")
    backendApiTaskCopyTextAliasIfMissing(target, source, "provider_original_name", "original_name")
    backendApiTaskCopyTextAliasIfMissing(target, source, "provider_name", "movie_name")
    backendApiTaskCopyTextAliasIfMissing(target, source, "provider_name", "name")
end sub

sub backendApiTaskCopyProviderArtworkAliases(target as Object, source as Dynamic)
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_cover_url", "cover")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_cover_url", "cover_big")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_cover_url", "series_image")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_cover_url", "movie_image")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_cover_url", "stream_icon")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_cover_url", "image")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_cover_url", "poster")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_backdrop_url", "backdrop")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_backdrop_url", "backdrop_path")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_backdrop_url", "background")
    backendApiTaskCopyArtworkAliasIfMissing(target, source, "provider_backdrop_url", "fanart")
end sub

sub backendApiTaskCopyArtworkAliasIfMissing(target as Object, source as Dynamic, targetKey as String, sourceKey as String)
    if target = invalid or source = invalid then return
    if target.doesExist(targetKey) and backendApiTaskString(target, targetKey) <> "" then return
    if not backendApiTaskIsAssoc(source) or not source.doesExist(sourceKey) then return
    value = source[sourceKey]
    if backendApiTaskIsArray(value) then
        if value.count() = 0 then return
        value = value[0]
    end if
    valueType = Type(value)
    if valueType <> "String" and valueType <> "roString" then return
    if value = "" then return
    target[targetKey] = Left(value, 2048)
end sub

sub backendApiTaskCopyTextAliasIfMissing(target as Object, source as Dynamic, targetKey as String, sourceKey as String)
    if target = invalid or source = invalid then return
    if target.doesExist(targetKey) then return
    if not backendApiTaskIsAssoc(source) or not source.doesExist(sourceKey) then return
    value = source[sourceKey]
    valueType = Type(value)
    if valueType <> "String" and valueType <> "roString" then return
    if value = "" then return
    target[targetKey] = Left(value, 512)
end sub
sub backendApiTaskCopy(target as Object, source as Dynamic, key as String)
    if target = invalid or source = invalid then return
    if not backendApiTaskIsAssoc(source) then return
    if not source.doesExist(key) then return
    value = source[key]
    if value = invalid then target[key] = "" : return
    valueType = Type(value)
    if valueType = "String" or valueType = "roString" then
        target[key] = Left(value, 4096)
    else if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" or valueType = "Boolean" or valueType = "roBoolean" then
        target[key] = value
    end if
end sub

sub backendApiTaskCopyIfExists(target as Object, source as Dynamic, key as String)
    if target = invalid or source = invalid then return
    if not backendApiTaskIsAssoc(source) then return
    if not source.doesExist(key) then return
    target[key] = backendApiTaskSanitizeJson(source[key])
end sub

function backendApiTaskIsAssoc(value as Dynamic) as Boolean
    valueType = Type(value)
    return valueType = "roAssociativeArray" or valueType = "AssociativeArray"
end function

function backendApiTaskIsArray(value as Dynamic) as Boolean
    valueType = Type(value)
    return valueType = "roArray" or valueType = "Array"
end function

function backendApiTaskText(item as Object, key as String, fallback as String) as String
    if not backendApiTaskIsAssoc(item) then return fallback
    if not item.doesExist(key) then return fallback
    if item[key] = invalid then return fallback
    if item[key] = "" then return fallback
    return item[key]
end function

function backendApiTaskValue(item as Object, key as String) as Dynamic
    if item = invalid then return invalid
    itemType = Type(item)
    if itemType <> "roAssociativeArray" and itemType <> "AssociativeArray" then return invalid
    if not item.doesExist(key) then return invalid
    return item[key]
end function

function backendApiTaskData(response as Dynamic) as Dynamic
    if not backendApiTaskIsAssoc(response) then return invalid
    if not response.doesExist("data") then return invalid
    if not backendApiTaskIsAssoc(response.data) then return invalid
    return response.data
end function

function backendApiTaskString(item as Dynamic, key as String) as String
    value = backendApiTaskValue(item, key)
    if value = invalid then return ""
    valueType = Type(value)
    if valueType = "String" or valueType = "roString" then return value
    return ""
end function

function backendApiTaskBool(item as Object, key as String, fallback as Boolean) as Boolean
    if not backendApiTaskIsAssoc(item) then return fallback
    if not item.doesExist(key) then return fallback
    if item[key] = invalid then return fallback
    if item[key] = true then return true
    return fallback
end function

function backendApiTaskAccessToken() as String
    section = CreateObject("roRegistrySection", backendApiAuthRegistrySection())
    token = section.Read("accessToken")
    if token <> invalid and token <> "" then return token

    ' Only a fresh installation may bootstrap anonymously. Never replace a saved user.
    if backendApiTaskHasSavedIdentity() then return ""
    response = backendApiTaskRunAuthRequest()
    if not backendApiTaskIsAssoc(response) then return ""
    if not response.doesExist("success") then return ""
    if response.success <> true then return ""
    data = backendApiTaskData(response)
    if data = invalid then return ""
    if not data.doesExist("access_token") then return ""

    token = data.access_token
    if token = invalid or token = "" then return ""
    section.Write("accessToken", token)
    recoveryCode = backendApiTaskString(data, "recovery_code")
    if recoveryCode <> "" then section.Write("recoveryCode", recoveryCode)
    user = backendApiTaskValue(data, "user")
    userId = backendApiTaskString(user, "id")
    if userId <> "" then section.Write("userId", userId)
    section.Flush()
    return token
end function

function backendApiTaskHasSavedIdentity() as Boolean
    section = CreateObject("roRegistrySection", backendApiAuthRegistrySection())
    if section.Exists("recoveryCode") or section.Exists("userId") or section.Exists("accessToken") then return true
    playlistSection = CreateObject("roRegistrySection", "iptv_max_playlists")
    savedItems = ParseJson(playlistSection.Read("items"))
    if backendApiTaskIsArray(savedItems) then
        for each savedItem in savedItems
            if backendApiTaskIsAssoc(savedItem) then
                if backendApiTaskBool(savedItem, "backendManaged", false) then return true
            end if
        end for
    end if
    return false
end function

function backendApiTaskResponseOk(statusCode as Integer, parsed as Dynamic) as Boolean
    if statusCode < 200 or statusCode >= 300 then return false
    if not backendApiTaskIsAssoc(parsed) then return false
    if not backendApiTaskBool(parsed, "success", false) then return false
    return backendApiTaskIsAssoc(backendApiTaskValue(parsed, "data"))
end function

function backendApiTaskRunAuthRequest() as Dynamic
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetUrl(backendApiBuildUrl("/api/v1/auth/anonymous"))
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("Content-Type", "application/json")
    body = FormatJson(backendApiAnonymousAuthRequest().body)
    started = transfer.AsyncPostFromString(body)
    if not started then return invalid
    msg = wait(8000, port)
    if msg = invalid then
        transfer.AsyncCancel()
        return invalid
    end if
    if Type(msg) <> "roUrlEvent" then return invalid
    if msg.GetResponseCode() < 200 or msg.GetResponseCode() >= 300 then return invalid
    responseText = msg.GetString()
    if responseText = invalid then return invalid
    if responseText = "" then return invalid
    return ParseJson(responseText)
end function

' All waits, JSON parsing and bounded retries execute on this Task's worker thread.
function backendApiTaskTransfer(request as Object, token as String) as Object
    method = backendApiTaskText(request, "method", "GET")
    url = backendApiBuildUrl(backendApiTaskText(request, "path", ""))
    if Left(LCase(url), 8) <> "https://" then return {statusCode: 0, text: ""}
    attempts = 1
    if method = "GET" then attempts = 3
    result = {statusCode: 0, text: ""}
    for attempt = 1 to attempts
        transfer = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        transfer.SetUrl(url)
        transfer.SetMessagePort(port)
        transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
        transfer.InitClientCertificates()
        transfer.AddHeader("Accept", "application/json")
        if token <> "" then transfer.AddHeader("Authorization", "Bearer " + token)
        if method = "POST" then
            transfer.AddHeader("Content-Type", "application/json")
            bodyText = ""
            if request.doesExist("body") then bodyText = FormatJson(request.body)
            started = transfer.AsyncPostFromString(bodyText)
        else
            if method <> "GET" then transfer.SetRequest(method)
            started = transfer.AsyncGetToString()
        end if
        msg = invalid
        if started then msg = wait(45000, port)
        result = {statusCode: 0, text: ""}
        if Type(msg) = "roUrlEvent" then
            result = {statusCode: msg.GetResponseCode(), text: msg.GetString()}
        else
            transfer.AsyncCancel()
        end if
        code = result.statusCode
        retryable = code <= 0 or code = 429 or code >= 500
        if not retryable or attempt = attempts then return result
        delay = 1000 * (2 ^ (attempt - 1))
        if code = 429 then delay = 5000 * attempt
        sleep(Int(delay))
    end for
    return result
end function
