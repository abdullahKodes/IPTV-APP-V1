sub init()
    m.top.functionName = "runBackendApiRequest"
end sub

sub runBackendApiRequest()
    request = m.top.request
    if request = invalid then
        m.top.response = backendApiErrorResponse(0, "Missing backend request.")
        return
    end if

    method = backendApiTaskText(request, "method", "GET")
    path = backendApiTaskText(request, "path", "")
    url = backendApiBuildUrl(path)
    authRequired = backendApiTaskBool(request, "authRequired", true)

    accessToken = ""
    if authRequired then
        accessToken = backendApiTaskAccessToken()
        if accessToken = "" then
            m.top.response = backendApiErrorResponse(401, "Backend authentication could not be created.")
            return
        end if
    end if

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetUrl(url)
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.AddHeader("Accept", "application/json")
    if accessToken <> "" then transfer.AddHeader("Authorization", "Bearer " + accessToken)

    bodyText = ""
    started = false
    if method = "POST" then
        transfer.AddHeader("Content-Type", "application/json")
        body = invalid
        if request.doesExist("body") then body = request.body
        if body <> invalid then bodyText = FormatJson(body)
        started = transfer.AsyncPostFromString(bodyText)
    else
        if method <> "GET" then transfer.SetRequest(method)
        started = transfer.AsyncGetToString()
    end if

    if not started then
        m.top.response = backendApiErrorResponse(0, "Backend request could not be started.")
        return
    end if

    msg = wait(8000, port)
    if msg = invalid then
        transfer.AsyncCancel()
        m.top.response = backendApiErrorResponse(0, "Backend request timed out.")
        return
    end if

    responseText = ""
    statusCode = 0
    if Type(msg) = "roUrlEvent" then
        responseText = msg.GetString()
        statusCode = msg.GetResponseCode()
    else
        m.top.response = backendApiErrorResponse(0, "Unexpected backend response.")
        return
    end if

    if authRequired and statusCode = 401 then backendApiTaskClearAccessToken()

    parsed = invalid
    if responseText <> invalid then
        if responseText <> "" then parsed = ParseJson(responseText)
    end if

    ok = statusCode >= 200 and statusCode < 300
    if parsed <> invalid then
        if parsed.doesExist("success") then
            if parsed.success <> true then ok = false
        end if
    end if

    responseBody = backendApiTaskCompactResponseBody(parsed, path)
    if responseBody = invalid then responseBody = {}
    responseRaw = ""
    if not ok and responseText <> invalid then responseRaw = Left(responseText, 500)

    m.top.response = {
        ok: ok,
        statusCode: statusCode,
        body: responseBody,
        raw: responseRaw,
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

function backendApiTaskSanitizeJson(value as Dynamic) as Dynamic
    if value = invalid then return invalid
    valueType = Type(value)
    if valueType = "roAssociativeArray" or valueType = "AssociativeArray" then
        clean = {}
        for each key in value
            child = value[key]
            if child = invalid then
                clean[key] = ""
            else
                clean[key] = backendApiTaskSanitizeJson(child)
            end if
        end for
        return clean
    end if
    if valueType = "roArray" or valueType = "Array" then
        clean = []
        for each child in value
            if child = invalid then
                clean.push("")
            else
                clean.push(backendApiTaskSanitizeJson(child))
            end if
        end for
        return clean
    end if
    return value
end function

function backendApiTaskCompactResponseBody(parsed as Dynamic, path as String) as Dynamic
    if parsed = invalid then return invalid
    if not backendApiTaskIsAssoc(parsed) then return backendApiTaskSanitizeJson(parsed)

    clean = {}
    clean.success = backendApiTaskValue(parsed, "success")
    if clean.success = invalid then clean.success = true

    data = backendApiTaskValue(parsed, "data")
    if data = invalid or not backendApiTaskIsAssoc(data) then
        return backendApiTaskSanitizeJson(parsed)
    end if

    cleanData = {}
    items = backendApiTaskValue(data, "items")
    if items <> invalid and backendApiTaskIsArray(items) then
        cleanItems = []
        for each item in items
            cleanItems.push(backendApiTaskCompactItem(item, path))
        end for
        cleanData.items = cleanItems
    end if

    playlist = backendApiTaskValue(data, "playlist")
    if playlist <> invalid then cleanData.playlist = backendApiTaskCompactPlaylist(playlist)

    importJob = backendApiTaskValue(data, "import_job")
    if importJob <> invalid then cleanData.import_job = backendApiTaskCompactImportJob(importJob)

    channel = backendApiTaskValue(data, "channel")
    if channel <> invalid then cleanData.channel = backendApiTaskCompactChannel(channel)

    if cleanData.Count() = 0 then cleanData = backendApiTaskSanitizeJson(data)
    clean.data = cleanData
    return clean
end function

function backendApiTaskCompactItem(item as Dynamic, path as String) as Dynamic
    if item = invalid then return {}
    if not backendApiTaskIsAssoc(item) then return backendApiTaskSanitizeJson(item)
    if Instr(1, path, "/channels/sync") > 0 then return backendApiTaskCompactChannel(item)
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
    backendApiTaskCopy(clean, item, "tvg_id")
    backendApiTaskCopy(clean, item, "tvg_name")
    backendApiTaskCopy(clean, item, "logo_url")
    backendApiTaskCopy(clean, item, "group_title")
    backendApiTaskCopy(clean, item, "content_type")
    backendApiTaskCopy(clean, item, "stream_host")
    backendApiTaskCopy(clean, item, "stream_url")
    backendApiTaskCopy(clean, item, "is_active")
    backendApiTaskCopy(clean, item, "updated_at")
    backendApiTaskCopy(clean, item, "deleted")
    return clean
end function

sub backendApiTaskCopy(target as Object, source as Dynamic, key as String)
    if target = invalid or source = invalid then return
    if not backendApiTaskIsAssoc(source) then return
    if not source.doesExist(key) then return
    value = source[key]
    if value = invalid then
        target[key] = ""
    else
        target[key] = backendApiTaskSanitizeJson(value)
    end if
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
    if item = invalid then return fallback
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
    if response = invalid then return invalid
    if not response.doesExist("data") then return invalid
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
    if item = invalid then return fallback
    if not item.doesExist(key) then return fallback
    if item[key] = invalid then return fallback
    if item[key] = true then return true
    return fallback
end function

function backendApiTaskAccessToken() as String
    section = CreateObject("roRegistrySection", backendApiAuthRegistrySection())
    token = section.Read("accessToken")
    if token <> invalid and token <> "" then return token

    response = backendApiTaskRunAuthRequest()
    if response = invalid then return ""
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

sub backendApiTaskClearAccessToken()
    section = CreateObject("roRegistrySection", backendApiAuthRegistrySection())
    if section = invalid then return
    if section.Exists("accessToken") then section.Delete("accessToken")
    section.Flush()
end sub

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
