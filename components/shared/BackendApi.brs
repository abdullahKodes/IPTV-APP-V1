function backendApiBaseUrl() as String
    return "https://backend-dev-2e86.up.railway.app"
end function

function backendApiUserId() as String
    return "00000000-0000-0000-0000-000000000001"
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
