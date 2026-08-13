function backendApiBaseUrl() as String
    return "https://backend-dev-2e86.up.railway.app"
end function

function backendApiAuthRegistrySection() as String
    return "iptv_backend_auth"
end function

function backendApiAnonymousAuthRequest() as Object
    return {
        method: "POST",
        path: "/api/v1/auth/anonymous",
        authRequired: false,
        body: {
            device: {
                platform: "roku",
                device_name: "IPTV Max Roku",
                app_version: "0.1.0"
            }
        }
    }
end function

function backendApiRecoverAuthRequest(recoveryCode as String) as Object
    return {
        method: "POST",
        path: "/api/v1/auth/recover",
        authRequired: false,
        body: {
            recovery_code: recoveryCode,
            device: {
                platform: "roku",
                device_name: "IPTV Max Roku",
                app_version: "0.1.0"
            }
        }
    }
end function

function backendApiListPlaylistsRequest() as Object
    return {
        method: "GET",
        path: "/api/v1/playlists"
    }
end function

function backendApiCreatePlaylistRequest(name as String, sourceUrl as String) as Object
    return {
        method: "POST",
        path: "/api/v1/playlists",
        body: {
            name: name,
            source_url: sourceUrl,
            source_type: "m3u",
            auto_refresh: true
        }
    }
end function

function backendApiCreateXtremePlaylistRequest(name as String, serverUrl as String, username as String, password as String) as Object
    return {
        method: "POST",
        path: "/api/v1/playlists",
        body: {
            name: name,
            source_type: "xtream",
            xtream: {
                server_url: serverUrl,
                username: username,
                password: password,
                output: "ts"
            },
            auto_refresh: true
        }
    }
end function

function backendApiRefreshPlaylistRequest(backendPlaylistId as String) as Object
    return {
        method: "POST",
        path: "/api/v1/playlists/" + backendPlaylistId + "/import"
    }
end function

function backendApiDeletePlaylistRequest(backendPlaylistId as String) as Object
    return {
        method: "DELETE",
        path: "/api/v1/playlists/" + backendPlaylistId
    }
end function

function backendApiSyncChannelsRequest(backendPlaylistId as String, limit = 1000 as Integer, contentType = "" as String, cursor = 0 as Integer) as Object
    path = "/api/v1/playlists/" + backendPlaylistId + "/channels/sync?cursor=" + cursor.toStr() + "&limit=" + limit.toStr()
    if contentType <> "" then path += "&content_type=" + contentType
    return {
        method: "GET",
        path: path
    }
end function

function backendApiGetChannelRequest(channelId as String) as Object
    return {
        method: "GET",
        path: "/api/v1/channels/" + channelId
    }
end function

function backendApiCreateSupportReportRequest(category as String, message as String, context = invalid as Dynamic) as Object
    if context = invalid then context = {}
    appInfo = CreateObject("roAppInfo")
    appVersion = ""
    if appInfo <> invalid then appVersion = appInfo.GetVersion()
    return {
        method: "POST",
        path: "/api/v1/support/reports",
        body: {
            category: category,
            severity: "normal",
            subject: "Roku app feedback",
            message: message,
            contact_email: "",
            platform: "roku",
            device_name: "IPTV Max Roku",
            app_version: appVersion,
            context: context
        }
    }
end function

function backendApiBuildUrl(path as String) as String
    if path = invalid or path = "" then return backendApiBaseUrl()
    if Left(path, 4) = "http" then return path
    return backendApiBaseUrl() + path
end function

sub backendApiStoreAuthData(data as Dynamic)
    if data = invalid then return
    section = CreateObject("roRegistrySection", backendApiAuthRegistrySection())
    token = backendApiText(data, "access_token")
    if token <> "" then section.Write("accessToken", token)
    recoveryCode = backendApiText(data, "recovery_code")
    if recoveryCode <> "" then section.Write("recoveryCode", recoveryCode)
    user = invalid
    if data.doesExist("user") then user = data.user
    userId = backendApiText(user, "id")
    if userId <> "" then section.Write("userId", userId)
    section.Flush()
end sub

sub backendApiClearAuthSession()
    section = CreateObject("roRegistrySection", backendApiAuthRegistrySection())
    if section = invalid then return
    if section.Exists("accessToken") then section.Delete("accessToken")
    if section.Exists("recoveryCode") then section.Delete("recoveryCode")
    if section.Exists("userId") then section.Delete("userId")
    section.Flush()
end sub

function backendApiResponseOk(response as Dynamic) as Boolean
    if response = invalid then return false
    if not response.doesExist("ok") then return false
    return response.ok = true
end function

function backendApiResponseProblem(response as Dynamic, fallback as String) as String
    message = fallback
    statusCode = 0
    if response <> invalid then
        if response.doesExist("statusCode") then statusCode = response.statusCode
        body = invalid
        if response.doesExist("body") then body = response.body
        if body <> invalid then
            errorData = invalid
            if body.doesExist("error") then errorData = body.error
            if errorData <> invalid then
                errorMessage = backendApiText(errorData, "message")
                if errorMessage <> "" then message = errorMessage
                errorCode = backendApiText(errorData, "code")
                if errorMessage = "" and errorCode <> "" then message = errorCode
            end if
        end if
        if message = fallback then
            raw = backendApiText(response, "raw")
            if raw <> "" and raw.len() < 80 then message = raw
        end if
    end if
    if statusCode > 0 then return message + " (" + statusCode.toStr() + ")"
    return message
end function

function backendApiUserMessage(response as Dynamic, fallback as String) as String
    if response <> invalid and Type(response) = "roAssociativeArray" and response.doesExist("statusCode") then
        statusCode = response.statusCode
        if statusCode > 0 then return fallback + " (" + statusCode.toStr() + ")"
    end if
    return fallback
end function

function backendApiResponseStatusCode(response as Dynamic) as Integer
    if response = invalid then return 0
    if not response.doesExist("statusCode") then return 0
    return response.statusCode
end function

function backendApiResponseData(response as Dynamic) as Dynamic
    if response = invalid then return invalid
    if not response.doesExist("body") then return invalid
    body = response.body
    if body = invalid then return invalid
    if not body.doesExist("data") then return invalid
    return body.data
end function

function backendApiResponseItems(response as Dynamic) as Object
    data = backendApiResponseData(response)
    if data = invalid then return []
    if not data.doesExist("items") then return []
    items = data.items
    if items = invalid then return []
    if Type(items) <> "roArray" then return []
    return items
end function

function backendApiResponsePagination(response as Dynamic) as Dynamic
    if response = invalid then return invalid
    if not response.doesExist("body") then return invalid
    body = response.body
    if body = invalid then return invalid
    if body.doesExist("meta") and body.meta <> invalid then return body.meta
    data = backendApiResponseData(response)
    if data <> invalid then
        if data.doesExist("meta") and data.meta <> invalid then return data.meta
        return data
    end if
    return invalid
end function

function backendApiResponseNextCursor(response as Dynamic) as Integer
    meta = backendApiResponsePagination(response)
    if meta = invalid then return -1
    nextCursor = backendApiInt(meta, "next_cursor", -1)
    if nextCursor >= 0 then return nextCursor
    nextCursor = backendApiInt(meta, "nextCursor", -1)
    if nextCursor >= 0 then return nextCursor
    nextCursor = backendApiInt(meta, "cursor_next", -1)
    if nextCursor >= 0 then return nextCursor
    return backendApiInt(meta, "next", -1)
end function

function backendApiResponseTotalCount(response as Dynamic) as Integer
    meta = backendApiResponsePagination(response)
    if meta = invalid then return -1
    total = backendApiInt(meta, "total_count", -1)
    if total >= 0 then return total
    total = backendApiInt(meta, "total", -1)
    if total >= 0 then return total
    total = backendApiInt(meta, "total_items", -1)
    if total >= 0 then return total
    total = backendApiInt(meta, "totalItems", -1)
    if total >= 0 then return total
    total = backendApiInt(meta, "active_channel_count", -1)
    if total >= 0 then return total
    return backendApiInt(meta, "channel_count", -1)
end function

function backendApiFirstItemId(items as Object) as String
    if items = invalid then return ""
    if items.count() = 0 then return ""
    return backendApiText(items[0], "id")
end function

function backendApiResponsePlaylist(response as Dynamic) as Dynamic
    data = backendApiResponseData(response)
    if data = invalid then return invalid
    if not data.doesExist("playlist") then return invalid
    return data.playlist
end function

function backendApiResponseImportJob(response as Dynamic) as Dynamic
    data = backendApiResponseData(response)
    if data = invalid then return invalid
    if not data.doesExist("import_job") then return invalid
    return data.import_job
end function

function backendApiChannelData(response as Dynamic) as Dynamic
    data = backendApiResponseData(response)
    if data = invalid then return invalid
    if data.doesExist("channel") then
        if data.channel <> invalid then return data.channel
    end if
    if data.doesExist("item") then
        if data.item <> invalid then return data.item
    end if
    return data
end function

function backendApiChannelStreamUrl(response as Dynamic) as String
    item = backendApiChannelData(response)
    if item = invalid then return ""
    streamUrl = backendApiText(item, "stream_url")
    if streamUrl <> "" then return streamUrl
    return backendApiText(item, "streamUrl")
end function

function backendApiMapSyncItems(items as Dynamic, playlistId as String, kind as String) as Object
    out = []
    if items = invalid then return out
    if Type(items) <> "roArray" then return out
    index = 0
    for each item in items
        if item <> invalid and not backendApiBool(item, "deleted", false) then
            itemKind = backendApiItemKind(item)
            if kind = "movies" then
                if itemKind = "movie" or itemKind = "unknown" then
                    index += 1
                    out.push(backendApiMapMovieItem(item, playlistId, index))
                end if
            else if kind = "series" then
                if itemKind = "series" or itemKind = "unknown" then
                    index += 1
                    out.push(backendApiMapSeriesItem(item, playlistId, index))
                end if
            else
                if itemKind = "live" or itemKind = "unknown" then
                    index += 1
                    out.push(backendApiMapLiveItem(item, playlistId, index))
                end if
            end if
        end if
    end for
    return out
end function

function backendApiItemKind(item as Object) as String
    contentType = LCase(backendApiText(item, "content_type"))
    mediaType = LCase(backendApiText(item, "media_type"))
    typeText = contentType
    if typeText = "" or typeText = "unknown" then typeText = mediaType
    if typeText = "movie" or typeText = "movies" or typeText = "vod" or typeText = "video" then return "movie"
    if typeText = "series" or typeText = "show" or typeText = "tv_series" then return "series"
    if typeText = "live" or typeText = "livetv" or typeText = "live_tv" or typeText = "channel" then return "live"

    text = LCase(backendApiText(item, "name") + " " + backendApiText(item, "group_title") + " " + backendApiText(item, "stream_url") + " " + backendApiText(item, "stream_host"))
    if backendApiLooksSeries(text) then return "series"
    if backendApiLooksMovie(text) then return "movie"
    if backendApiLooksLive(text) then return "live"
    return "unknown"
end function

function backendApiLooksMovie(text as String) as Boolean
    if Instr(1, text, "movie") > 0 then return true
    if Instr(1, text, "movies") > 0 then return true
    if Instr(1, text, "vod") > 0 then return true
    if Instr(1, text, "/film") > 0 then return true
    if Instr(1, text, "/movies/") > 0 then return true
    if Instr(1, text, "/movie/") > 0 then return true
    if Instr(1, text, "/vod/") > 0 then return true
    return false
end function

function backendApiLooksSeries(text as String) as Boolean
    if Instr(1, text, "series") > 0 then return true
    if Instr(1, text, "season") > 0 then return true
    if Instr(1, text, "episode") > 0 then return true
    if Instr(1, text, "/series/") > 0 then return true
    if Instr(1, text, "/show/") > 0 then return true
    if Instr(1, text, " s01") > 0 or Instr(1, text, ".s01") > 0 or Instr(1, text, "-s01") > 0 then return true
    return false
end function

function backendApiLooksLive(text as String) as Boolean
    if Instr(1, text, "live") > 0 then return true
    if Instr(1, text, "news") > 0 then return true
    if Instr(1, text, "sports") > 0 then return true
    if Instr(1, text, "channel") > 0 then return true
    if Instr(1, text, "/live/") > 0 then return true
    return false
end function

function backendApiMapLiveItem(item as Object, playlistId as String, index as Integer) as Object
    name = backendApiText(item, "name", "Live TV")
    group = backendApiText(item, "group_title", "Uncategorized")
    logoUrl = backendApiText(item, "logo_url")
    return {
        id: backendApiText(item, "id", "backend_live_" + index.toStr()),
        backendChannelId: backendApiText(item, "id"),
        playlistId: playlistId,
        contentType: backendApiText(item, "content_type"),
        name: name,
        title: name,
        now: "Live stream",
        category: group,
        groupTitle: group,
        logoUrl: logoUrl,
        badgeUrl: logoUrl,
        logoText: backendApiInitials(name),
        brandColor: "0x2B8C6BFF",
        brandColor2: "0x151C26FF",
        streamUrl: backendApiText(item, "stream_url"),
        streamHost: backendApiText(item, "stream_host"),
        streamFormat: "hls",
        live: true,
        favorite: false,
        channelNumber: index.toStr()
    }
end function

function backendApiMapMovieItem(item as Object, playlistId as String, index as Integer) as Object
    name = backendApiText(item, "name", "Movie")
    group = backendApiGroupLabel(backendApiText(item, "group_title", "Movies"))
    logoUrl = backendApiText(item, "logo_url")
    return {
        id: backendApiText(item, "id", "backend_movie_" + index.toStr()),
        backendChannelId: backendApiText(item, "id"),
        playlistId: playlistId,
        contentType: backendApiText(item, "content_type"),
        title: name,
        year: "",
        duration: "Live stream",
        genre: group,
        rating: "NR",
        posterUrl: logoUrl,
        cardUrl: logoUrl,
        backdropUrl: "",
        streamUrl: backendApiText(item, "stream_url"),
        streamHost: backendApiText(item, "stream_host"),
        streamFormat: "hls",
        featured: index = 1,
        featuredPriority: 1000 - index,
        resumePercent: 0,
        accent: "purple"
    }
end function

function backendApiMapSeriesItem(item as Object, playlistId as String, index as Integer) as Object
    name = backendApiText(item, "name", "Series")
    group = backendApiGroupLabel(backendApiText(item, "group_title", "Series"))
    logoUrl = backendApiText(item, "logo_url")
    return {
        id: backendApiText(item, "id", "backend_series_" + index.toStr()),
        backendChannelId: backendApiText(item, "id"),
        playlistId: playlistId,
        contentType: backendApiText(item, "content_type"),
        title: name,
        year: "",
        seasons: "Streaming channel",
        episodeCount: "Live episodes",
        genre: group,
        rating: "NR",
        posterUrl: logoUrl,
        cardUrl: logoUrl,
        backdropUrl: "",
        streamUrl: backendApiText(item, "stream_url"),
        streamHost: backendApiText(item, "stream_host"),
        streamFormat: "hls",
        episodeNames: name,
        seasonNames: "Playlist",
        episodeDurations: "Live",
        activeEpisodeTitle: name,
        resumePercent: 0,
        accent: "purple"
    }
end function

function backendApiGroupLabel(groupTitle as String) as String
    if groupTitle = invalid or groupTitle = "" then return "Uncategorized"
    out = ""
    for i = 1 to groupTitle.len()
        ch = Mid(groupTitle, i, 1)
        if ch = ";" then
            out += " - "
        else
            out += ch
        end if
    end for
    return out
end function

function backendApiText(item as Dynamic, key as String, fallback = "" as String) as String
    if item = invalid then return fallback
    value = invalid
    if item.doesExist(key) then value = item[key]
    if value = invalid then return fallback
    valueType = Type(value)
    if valueType = "String" or valueType = "roString" then
        if value = "" then return fallback
        return value
    end if
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function backendApiBool(item as Dynamic, key as String, fallback as Boolean) as Boolean
    if item = invalid then return fallback
    if not item.doesExist(key) then return fallback
    return item[key] = true
end function

function backendApiInt(item as Dynamic, key as String, fallback as Integer) as Integer
    if item = invalid then return fallback
    if not item.doesExist(key) then return fallback
    value = item[key]
    if value = invalid then return fallback
    valueType = Type(value)
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" then return Int(value)
    if valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return Int(value)
    if valueType = "String" or valueType = "roString" then
        if value = "" then return fallback
        return Int(Val(value))
    end if
    return fallback
end function

function backendApiInitials(text as String) as String
    if text = invalid or text = "" then return "TV"
    letters = ""
    words = text.Tokenize(" ")
    for each word in words
        if word <> "" and letters.len() < 4 then letters += Left(UCase(word), 1)
    end for
    if letters = "" then letters = Left(UCase(text), 4)
    return letters
end function
