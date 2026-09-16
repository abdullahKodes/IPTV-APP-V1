function backendApiBaseUrl() as String
    return "https://16-192-92-41.sslip.io"
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

function backendApiSyncChannelsRequest(backendPlaylistId as String, limit = 50 as Integer, contentType = "" as String, cursor = 0 as Integer, group = "" as String, search = "" as String) as Object
    ' Existing page state uses zero for the initial request; subsequent values are page numbers.
    page = cursor
    if page < 1 then page = 1
    requestedContentType = LCase(contentType)
    route = "/channels"
    if page = 1 then route = "/bootstrap"
    if requestedContentType = "series" then route = "/series"
    path = "/api/v1/playlists/" + backendPlaylistId + route + "?page=" + page.toStr() + "&page_size=50"
    if requestedContentType <> "" and requestedContentType <> "series" then path += "&content_type=" + requestedContentType
    if group <> "" and group <> "All" then path += "&group=" + group.Escape()
    if search <> "" then path += "&search=" + search.Escape()
    request = { method: "GET", path: path }
    if requestedContentType <> "" and page = 1 and search = "" and (group = "" or group = "All") then
        request.groupsPath = "/api/v1/playlists/" + backendPlaylistId + "/groups?content_type=" + requestedContentType
    end if
    return request
end function

function backendApiMovieContentType(contentProfile as String, sourceType as String) as String
    if LCase(contentProfile) = "backend_movies" and LCase(sourceType) <> "xtream" then return ""
    return "movie"
end function

function backendApiGetSeriesRequest(seriesId as String) as Object
    return { method: "GET", path: "/api/v1/series/" + seriesId }
end function

function backendApiEpisodesRequest(seriesId as String, seasonNumber as Integer, page = 1 as Integer, playable = false as Boolean) as Object
    path = "/api/v1/series/" + seriesId + "/episodes?season_number=" + seasonNumber.toStr() + "&page=" + page.toStr() + "&page_size=50"
    if playable then path += "&include_stream_url=true"
    return { method: "GET", path: path }
end function

function backendApiSeriesChannelFallbackRequest(backendPlaylistId as String, page = 1 as Integer, group = "" as String, search = "" as String) as Object
    if page < 1 then page = 1
    path = "/api/v1/playlists/" + backendPlaylistId + "/channels?page=" + page.toStr() + "&page_size=50"
    if group <> "" and group <> "All" then path += "&group=" + group.Escape()
    if search <> "" then path += "&search=" + search.Escape()
    return {method: "GET", path: path}
end function

function backendApiImportJobRequest(jobId as String) as Object
    return { method: "GET", path: "/api/v1/import-jobs/" + jobId }
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
    if not backendApiIsAssoc(data) then return
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
    if not backendApiIsAssoc(response) then return false
    if not response.doesExist("ok") then return false
    return response.ok = true
end function

function backendApiResponseProblem(response as Dynamic, fallback as String) as String
    message = fallback
    statusCode = 0
    if backendApiIsAssoc(response) then
        if response.doesExist("statusCode") then statusCode = response.statusCode
        body = invalid
        if response.doesExist("body") then body = response.body
        if backendApiIsAssoc(body) then
            errorData = invalid
            if body.doesExist("error") then errorData = body.error
            if backendApiIsAssoc(errorData) then
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
        if statusCode = 401 then return "Account access could not be verified. Please retry or contact support."
        if statusCode = 404 then return "This saved content is unavailable for your account."
        if statusCode > 0 then return fallback + " (" + statusCode.toStr() + ")"
    end if
    return fallback
end function

function backendApiResponseStatusCode(response as Dynamic) as Integer
    return backendApiInt(response, "statusCode", 0)
end function

function backendApiResponseData(response as Dynamic) as Dynamic
    if not backendApiIsAssoc(response) then return invalid
    if not response.doesExist("body") then return invalid
    body = response.body
    if not backendApiIsAssoc(body) then return invalid
    if not body.doesExist("data") then return invalid
    if not backendApiIsAssoc(body.data) then return invalid
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
    if not backendApiIsAssoc(response) then return invalid
    if not response.doesExist("body") then return invalid
    body = response.body
    if not backendApiIsAssoc(body) then return invalid
    if body.doesExist("meta") and backendApiIsAssoc(body.meta) then
        if body.meta.doesExist("pagination") and backendApiIsAssoc(body.meta.pagination) then return body.meta.pagination
    end if
    data = backendApiResponseData(response)
    if data <> invalid then
        if data.doesExist("pagination") and backendApiIsAssoc(data.pagination) then return data.pagination
        if data.doesExist("meta") and backendApiIsAssoc(data.meta) then return data.meta
        return data
    end if
    return invalid
end function

function backendApiResponseNextCursor(response as Dynamic) as Integer
    meta = backendApiResponsePagination(response)
    if not backendApiIsAssoc(meta) then return -1
    if meta.doesExist("has_next") then
        if not backendApiBool(meta, "has_next", false) then return -1
        return backendApiInt(meta, "page", 1) + 1
    end if
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
    if not backendApiIsArray(items) then return ""
    if items.count() = 0 then return ""
    return backendApiText(items[0], "id")
end function

function backendApiResponsePlaylist(response as Dynamic) as Dynamic
    data = backendApiResponseData(response)
    if not backendApiIsAssoc(data) then return invalid
    if not data.doesExist("playlist") then return invalid
    if not backendApiIsAssoc(data.playlist) then return invalid
    return data.playlist
end function

function backendApiResponseImportJob(response as Dynamic) as Dynamic
    data = backendApiResponseData(response)
    if data = invalid then
        if backendApiIsAssoc(response) then
            if response.doesExist("body") and backendApiIsAssoc(response.body) then
                body = response.body
                if body.doesExist("error") and backendApiIsAssoc(body.error) then
                    if body.error.doesExist("details") and backendApiIsAssoc(body.error.details) then
                        details = body.error.details
                        if details.doesExist("import_job") and backendApiIsAssoc(details.import_job) then return details.import_job
                        jobId = backendApiText(details, "import_job_id", backendApiText(details, "job_id"))
                        if jobId <> "" then return {id: jobId, status: "running"}
                    end if
                end if
            end if
        end if
        return invalid
    end if
    if not backendApiIsAssoc(data) then return invalid
    if not data.doesExist("import_job") then return invalid
    if not backendApiIsAssoc(data.import_job) then return invalid
    return data.import_job
end function

function backendApiChannelData(response as Dynamic) as Dynamic
    data = backendApiResponseData(response)
    if not backendApiIsAssoc(data) then return invalid
    if data.doesExist("channel") then
        if backendApiIsAssoc(data.channel) then return data.channel
    end if
    if data.doesExist("item") then
        if backendApiIsAssoc(data.item) then return data.item
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

function backendApiMapSyncItems(items as Dynamic, playlistId as String, kind as String, startIndex = 0 as Integer) as Object
    out = []
    if items = invalid then return out
    if Type(items) <> "roArray" then return out
    index = startIndex
    for each item in items
        if backendApiIsAssoc(item) and not backendApiBool(item, "deleted", false) then
            itemKind = backendApiItemKind(item)
            if kind = "movies" then
                if itemKind = "movie" then
                    index += 1
                    out.push(backendApiMapMovieItem(item, playlistId, index))
                end if
            else if kind = "series" then
                if itemKind = "series" then
                    index += 1
                    out.push(backendApiMapSeriesItem(item, playlistId, index))
                end if
            else
                if itemKind = "live" and backendApiLiveItemBrowsable(item) then
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
    if Instr(1, text, ".mp4") > 0 then return true
    if Instr(1, text, ".mkv") > 0 then return true
    if Instr(1, text, ".avi") > 0 then return true
    if Instr(1, text, ".m4v") > 0 then return true
    if Instr(1, text, ".mov") > 0 then return true
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

function backendApiLiveItemBrowsable(item as Dynamic) as Boolean
    if not backendApiIsAssoc(item) then return false
    name = backendApiTrim(backendApiText(item, "name", backendApiText(item, "title")))
    if name = "" then return false

    ' Artwork or a provider guide ID is strong evidence that this is a real channel.
    if backendApiArtworkUrl(item, "logo_url") <> "" then return true
    if backendApiArtworkUrl(item, "poster_url") <> "" then return true
    if backendApiArtworkUrl(item, "backdrop_url") <> "" then return true
    if backendApiText(item, "tvg_id") <> "" then return true

    decorationCount = 0
    alphaNumericCount = 0
    otherCount = 0
    decorations = "#*=_~-|"
    alphaNumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    upperName = UCase(name)
    for i = 1 to upperName.len()
        ch = Mid(upperName, i, 1)
        if Instr(1, alphaNumeric, ch) > 0 then
            alphaNumericCount += 1
        else if Instr(1, decorations, ch) > 0 then
            decorationCount += 1
        else if ch <> " " and ch <> Chr(9) then
            otherCount += 1
        end if
    end for

    ' Xtream feeds sometimes encode bouquet/country headers as fake live rows.
    if decorationCount >= 6 and decorationCount >= alphaNumericCount then return false
    if alphaNumericCount <= 4 and otherCount = 0 and decorationCount >= 2 then
        if Instr(1, decorations, Left(upperName, 1)) > 0 and Instr(1, decorations, Right(upperName, 1)) > 0 then return false
    end if
    return true
end function
function backendApiMapLiveItem(item as Object, playlistId as String, index as Integer) as Object
    name = backendApiText(item, "name", "Live TV")
    group = backendApiText(item, "group_title", "Uncategorized")
    logoUrl = backendApiArtworkUrl(item, "logo_url")
    posterUrl = backendApiArtworkUrl(item, "poster_url")
    backdropUrl = backendApiArtworkUrl(item, "backdrop_url")
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
        posterUrl: posterUrl,
        cardUrl: posterUrl,
        cardBackgroundUrl: backdropUrl,
        backdropUrl: backdropUrl,
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

function backendApiMovieDisplayTitle(item as Dynamic, fallback = "Movie" as String) as String
    name = backendApiTrim(backendApiText(item, "name"))
    if backendApiMovieTitleUsable(name) then return name
    title = backendApiTrim(backendApiText(item, "title"))
    if backendApiMovieTitleUsable(title) then return title
    tvgName = backendApiTrim(backendApiText(item, "tvg_name"))
    if backendApiMovieTitleUsable(tvgName) then return tvgName
    providerTitle = backendApiTrim(backendApiText(item, "provider_title"))
    if backendApiMovieTitleUsable(providerTitle) then return providerTitle
    providerOriginalName = backendApiTrim(backendApiText(item, "provider_original_name"))
    if backendApiMovieTitleUsable(providerOriginalName) then return providerOriginalName
    providerName = backendApiTrim(backendApiText(item, "provider_name"))
    if backendApiMovieTitleUsable(providerName) then return providerName
    return fallback
end function

function backendApiMovieHasUsableTitle(item as Dynamic) as Boolean
    if backendApiMovieTitleUsable(backendApiTrim(backendApiText(item, "name"))) then return true
    if backendApiMovieTitleUsable(backendApiTrim(backendApiText(item, "title"))) then return true
    if backendApiMovieTitleUsable(backendApiTrim(backendApiText(item, "tvg_name"))) then return true
    if backendApiMovieTitleUsable(backendApiTrim(backendApiText(item, "provider_title"))) then return true
    if backendApiMovieTitleUsable(backendApiTrim(backendApiText(item, "provider_original_name"))) then return true
    return backendApiMovieTitleUsable(backendApiTrim(backendApiText(item, "provider_name")))
end function

function backendApiMovieTitleUsable(value as String) as Boolean
    if value = invalid or value = "" then return false
    normalizedValue = LCase(backendApiTrim(value))
    if normalizedValue = "movie" or normalizedValue = "vod" or normalizedValue = "untitled" then return false
    upperValue = UCase(value)
    alphaNumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    alphaNumericCount = 0
    punctuationCount = 0
    for i = 1 to upperValue.len()
        ch = Mid(upperValue, i, 1)
        if Instr(1, alphaNumeric, ch) > 0 then
            alphaNumericCount += 1
        else if ch <> " " and ch <> Chr(9) then
            punctuationCount += 1
        end if
    end for
    if alphaNumericCount = 0 then return false
    if alphaNumericCount <= 3 and punctuationCount >= 2 then return false
    return true
end function
function backendApiMapMovieItem(item as Object, playlistId as String, index as Integer) as Object
    name = backendApiMovieDisplayTitle(item)
    providerPoster = backendApiArtworkUrl(item, "poster_url", backendApiArtworkUrl(item, "cover_url"))
    providerLogo = backendApiArtworkUrl(item, "logo_url")
    providerBackdrop = backendApiMovieExplicitHeroArtworkUrl(item)
    cardArtwork = providerPoster
    artworkRole = "poster"
    if cardArtwork = "" then
        cardArtwork = providerLogo
        artworkRole = "logo"
    end if
    if cardArtwork = "" then
        cardArtwork = providerBackdrop
        artworkRole = "backdrop"
    end if
    return {
        id: backendApiText(item, "id"), backendChannelId: backendApiText(item, "id"), playlistId: playlistId,
        contentType: "movie", title: name, titleNeedsDetail: not backendApiMovieHasUsableTitle(item), year: backendApiText(item, "release_year"),
        duration: backendApiDuration(item), genre: backendApiGroupLabel(backendApiText(item, "group_title", "Movies")),
        rating: backendApiText(item, "rating", "NR"), description: backendApiText(item, "overview"),
        posterUrl: cardArtwork, cardUrl: cardArtwork, cardDisplayMode: "fit", artworkRole: artworkRole,
        heroUrl: backendApiMovieHeroArtworkUrl(item), backdropUrl: backendApiMovieExplicitHeroArtworkUrl(item),
        streamUrl: backendApiText(item, "stream_url"), streamHost: backendApiText(item, "stream_host"),
        streamFormat: backendApiStreamFormat(backendApiText(item, "stream_url")),
        featured: index = 1, featuredPriority: 1000 - index, resumePercent: 0, accent: "purple"
    }
end function

function backendApiMovieExplicitHeroArtworkUrl(item as Dynamic) as String
    heroUrl = backendApiArtworkUrl(item, "hero_url")
    if heroUrl <> "" then return heroUrl
    heroUrl = backendApiArtworkUrl(item, "backdrop_url")
    if heroUrl <> "" then return heroUrl
    heroUrl = backendApiArtworkUrl(item, "background_url")
    if heroUrl <> "" then return heroUrl
    heroUrl = backendApiArtworkUrl(item, "fanart_url")
    if heroUrl <> "" then return heroUrl
    return backendApiArtworkUrl(item, "provider_backdrop_url")
end function

function backendApiMovieHeroArtworkUrl(item as Dynamic) as String
    ' The backend contract provides a dedicated backdrop_url. Poster and logo artwork
    ' remain in the right-side slot when no explicit background is available.
    return backendApiMovieExplicitHeroArtworkUrl(item)
end function

function backendApiMapMovieChannelItems(items as Dynamic, playlistId as String, startIndex = 0 as Integer, assumeMoviePlaylist = false as Boolean) as Object
    out = []
    if Type(items) <> "roArray" then return out
    index = startIndex
    for each item in items
        if backendApiIsAssoc(item) and not backendApiBool(item, "deleted", false) then
            itemKind = backendApiItemKind(item)
            includeMovie = itemKind = "movie"
            ' Generic M3U imports are commonly stored as channel/live rows. When the saved
            ' playlist itself is explicitly Movies-only, that source profile is authoritative.
            if assumeMoviePlaylist and itemKind <> "series" then includeMovie = true
            if includeMovie then
                index += 1
                out.push(backendApiMapMovieItem(item, playlistId, index))
            end if
        end if
    end for
    return out
end function

function backendApiItemTypeIsMissing(item as Dynamic) as Boolean
    if not backendApiIsAssoc(item) then return false
    contentType = LCase(backendApiText(item, "content_type"))
    mediaType = LCase(backendApiText(item, "media_type"))
    contentMissing = contentType = "" or contentType = "unknown"
    mediaMissing = mediaType = "" or mediaType = "unknown"
    return contentMissing and mediaMissing
end function

function backendApiMapSeriesItem(item as Object, playlistId as String, index as Integer) as Object
    cover = backendApiArtworkUrl(item, "cover_url", backendApiArtworkUrl(item, "poster_url", backendApiArtworkUrl(item, "logo_url", backendApiArtworkUrl(item, "provider_cover_url"))))
    return {
        id: backendApiText(item, "id"), backendSeriesId: backendApiText(item, "id"), playlistId: playlistId,
        contentType: "series", title: backendApiText(item, "name", "Series"), year: backendApiText(item, "release_date"),
        seasons: "", episodeCount: "", genre: backendApiGroupLabel(backendApiText(item, "category_title", "Series")),
        rating: backendApiText(item, "rating", "NR"), description: backendApiText(item, "plot"),
        posterUrl: cover, cardUrl: cover, cardDisplayMode: "fit", artworkRole: "cover", heroUrl: backendApiMovieExplicitHeroArtworkUrl(item), backdropUrl: backendApiMovieExplicitHeroArtworkUrl(item),
        streamUrl: "", streamFormat: "", episodeNames: "", seasonNames: "", episodeDurations: "",
        activeEpisodeTitle: "", resumePercent: 0, accent: "purple"
    }
end function

function backendApiMapSeriesChannelItems(items as Dynamic, playlistId as String, startIndex = 0 as Integer) as Object
    out = []
    if Type(items) <> "roArray" then return out
    index = startIndex
    for each item in items
        if backendApiIsAssoc(item) and not backendApiBool(item, "deleted", false) then
            itemKind = backendApiItemKind(item)
            if itemKind = "series" then
                index += 1
                name = backendApiText(item, "name", "Series episode")
                providerPoster = backendApiArtworkUrl(item, "poster_url")
                providerLogo = backendApiArtworkUrl(item, "logo_url")
                poster = providerPoster
                artworkRole = "poster"
                if poster = "" then
                    poster = providerLogo
                    artworkRole = "logo"
                end if
                heroUrl = backendApiMovieExplicitHeroArtworkUrl(item)
                out.push({
                    id: backendApiText(item, "id", "backend_series_channel_" + index.toStr()),
                    backendChannelId: backendApiText(item, "id"), playlistId: playlistId,
                    contentType: "series", detailMediaType: "series_channel", title: name, year: "",
                    seasons: "Series", episodeCount: "1 Episode",
                    genre: backendApiPrimaryGroupLabel(backendApiText(item, "group_title", "Series")),
                    rating: "", description: backendApiText(item, "overview"),
                    posterUrl: poster, cardUrl: poster, cardDisplayMode: "fit", artworkRole: artworkRole, heroUrl: heroUrl, backdropUrl: backendApiMovieExplicitHeroArtworkUrl(item),
                    streamUrl: backendApiText(item, "stream_url"), streamFormat: backendApiStreamFormat(backendApiText(item, "stream_url")),
                    episodeNames: name, seasonNames: "Season 1", episodeDurations: "",
                    activeEpisodeTitle: name, resumePercent: 0, featured: index = 1, accent: "purple"
                })
            end if
        end if
    end for
    return out
end function

function backendApiArtworkUrl(item as Dynamic, key as String, fallback = "" as String) as String
    url = backendApiText(item, key, fallback)
    if url = "" or url.len() > 2048 then return ""
    lowerUrl = LCase(url)
    if Left(lowerUrl, 8) = "https://" then return url
    if Left(lowerUrl, 7) = "http://" then return url
    if Left(lowerUrl, 5) = "pkg:/" then return url
    return ""
end function

function backendApiDuration(item as Dynamic) as String
    seconds = backendApiInt(item, "duration_seconds", 0)
    if seconds <= 0 then return ""
    return Int(seconds / 60).toStr() + " min"
end function

function backendApiStreamFormat(url as String) as String
    if url = "" then return "hls"
    path = LCase(url)
    queryStart = Instr(1, path, "?")
    if queryStart > 0 then path = Left(path, queryStart - 1)
    if path.len() >= 3 then
        if Right(path, 3) = ".ts" then return "ts"
    end if
    if path.len() >= 4 then
        suffix = Right(path, 4)
        if suffix = ".mp4" or suffix = ".mkv" or suffix = ".m4v" then return "mp4"
    end if
    return "hls"
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
    if not backendApiIsAssoc(item) then return fallback
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
    if not backendApiIsAssoc(item) then return fallback
    if not item.doesExist(key) then return fallback
    return item[key] = true
end function

function backendApiInt(item as Dynamic, key as String, fallback as Integer) as Integer
    if not backendApiIsAssoc(item) then return fallback
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

function backendApiGroupNames(groups as Object) as Object
    names = ["All"]
    if not backendApiIsArray(groups) then return names
    for each group in groups
        includeGroup = true
        if backendApiIsAssoc(group) and group.doesExist("channel_count") then includeGroup = backendApiInt(group, "channel_count", 0) > 0
        if includeGroup then backendApiAppendGroupName(names, backendApiPrimaryGroupLabel(backendApiText(group, "name")))
    end for
    return names
end function

function backendApiGroupQuery(groups as Object, displayName as String) as String
    if displayName = "" or displayName = "All" then return "All"
    if not backendApiIsArray(groups) then return displayName
    needle = LCase(displayName)
    for each group in groups
        rawName = backendApiText(group, "name")
        if LCase(backendApiPrimaryGroupLabel(rawName)) = needle then return rawName
    end for
    return displayName
end function

function backendApiBrowseGroupQuery(groups as Object, categories as Dynamic, categoryIndex as Integer, categoryResultsActive as Boolean, searchQuery as String) as String
    if searchQuery <> "" or not categoryResultsActive then return "All"
    if Type(categories) <> "roArray" then return "All"
    if categoryIndex < 0 or categoryIndex >= categories.count() then return "All"
    return backendApiGroupQuery(groups, categories[categoryIndex])
end function

function backendApiGroupsFromChannelItems(items as Dynamic) as Object
    groups = []
    if Type(items) <> "roArray" then return groups
    for each item in items
        rawName = backendApiText(item, "group_title")
        if rawName <> "" then
            exists = false
            for each group in groups
                if LCase(backendApiText(group, "name")) = LCase(rawName) then exists = true
            end for
            if not exists then groups.push({name: rawName})
        end if
    end for
    return groups
end function

function backendApiPrimaryGroupLabel(rawName as String) as String
    remaining = rawName
    while remaining <> ""
        separator = Instr(1, remaining, ";")
        if separator = 0 then return backendApiTrim(remaining)
        part = ""
        if separator > 1 then part = backendApiTrim(Left(remaining, separator - 1))
        if part <> "" then return part
        if separator >= remaining.len() then return ""
        remaining = Mid(remaining, separator + 1)
    end while
    return ""
end function

sub backendApiAppendGroupName(names as Object, value as String)
    name = backendApiTrim(value)
    if name = "" then return
    needle = LCase(name)
    for each existing in names
        if LCase(existing) = needle then return
    end for
    names.push(name)
end sub

function backendApiTrim(value as String) as String
    text = value
    while text.len() > 0 and (Left(text, 1) = " " or Left(text, 1) = Chr(9))
        if text.len() = 1 then return ""
        text = Mid(text, 2)
    end while
    while text.len() > 0 and (Right(text, 1) = " " or Right(text, 1) = Chr(9))
        if text.len() = 1 then return ""
        text = Left(text, text.len() - 1)
    end while
    return text
end function

' Retain at most three catalog pages. Evicted pages are fetched again when going back.
function backendApiCatalogWindow(pages as Object, page as Integer, items as Object, nextPage as Integer, selectedId as String) as Object
    if page < 1 then page = 1
    if not backendApiIsArray(pages) then pages = []
    if not backendApiIsArray(items) then items = []
    updated = []
    for each cached in pages
        if backendApiIsAssoc(cached) then
            if backendApiInt(cached, "page", -1) <> page and cached.doesExist("items") then
                if backendApiIsArray(cached.items) then updated.push(cached)
            end if
        end if
    end for
    updated.push({page: page, items: items, nextPage: nextPage})
    updated.SortBy("page")
    if updated.count() > 3 then
        if updated[0].page = page then
            updated.Pop()
        else
            updated.Shift()
        end if
    end if
    combined = []
    selectedIndex = 0
    for each cached in updated
        for each item in cached.items
            if backendApiIsAssoc(item) then
                if backendApiText(item, "id") = selectedId then selectedIndex = combined.count()
                combined.push(item)
            end if
        end for
    end for
    return {pages: updated, items: combined, selectedIndex: selectedIndex, firstPage: updated[0].page, nextPage: updated[updated.count() - 1].nextPage}
end function

function backendApiIsAssoc(value as Dynamic) as Boolean
    valueType = Type(value)
    return valueType = "roAssociativeArray" or valueType = "AssociativeArray"
end function

function backendApiIsArray(value as Dynamic) as Boolean
    valueType = Type(value)
    return valueType = "roArray" or valueType = "Array"
end function
