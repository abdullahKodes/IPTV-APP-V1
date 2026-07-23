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

function backendApiSyncChannelsRequest(backendPlaylistId as String, limit = 1000 as Integer) as Object
    return {
        method: "GET",
        path: "/api/v1/playlists/" + backendPlaylistId + "/channels/sync?cursor=0&limit=" + limit.toStr()
    }
end function

function backendApiGetChannelRequest(channelId as String) as Object
    return {
        method: "GET",
        path: "/api/v1/channels/" + channelId
    }
end function

function backendApiBuildUrl(path as String) as String
    if path = invalid or path = "" then return backendApiBaseUrl()
    if Left(path, 4) = "http" then return path
    return backendApiBaseUrl() + path
end function

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

function backendApiResponsePlaylist(response as Dynamic) as Dynamic
    data = backendApiResponseData(response)
    if data = invalid then return invalid
    if not data.doesExist("playlist") then return invalid
    return data.playlist
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
            index += 1
            if kind = "movies" then
                out.push(backendApiMapMovieItem(item, playlistId, index))
            else if kind = "series" then
                out.push(backendApiMapSeriesItem(item, playlistId, index))
            else
                out.push(backendApiMapLiveItem(item, playlistId, index))
            end if
        end if
    end for
    return out
end function

function backendApiMapLiveItem(item as Object, playlistId as String, index as Integer) as Object
    name = backendApiText(item, "name", "Live TV")
    group = backendApiText(item, "group_title", "Uncategorized")
    logoUrl = backendApiText(item, "logo_url")
    return {
        id: backendApiText(item, "id", "backend_live_" + index.toStr()),
        backendChannelId: backendApiText(item, "id"),
        playlistId: playlistId,
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
        title: name,
        year: "",
        duration: "Live stream",
        genre: group,
        rating: "NR",
        posterUrl: logoUrl,
        cardUrl: logoUrl,
        backdropUrl: "",
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
        title: name,
        year: "",
        seasons: "Streaming channel",
        episodeCount: "Live episodes",
        genre: group,
        rating: "NR",
        posterUrl: logoUrl,
        cardUrl: logoUrl,
        backdropUrl: "",
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
