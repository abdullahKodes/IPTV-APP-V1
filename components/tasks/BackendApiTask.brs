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

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetUrl(url)
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("X-User-Id", backendApiUserId())
    transfer.AddHeader("X-User-Email", "roku-test@example.com")

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

    parsed = invalid
    if responseText <> invalid and responseText <> "" then parsed = ParseJson(responseText)

    ok = statusCode >= 200 and statusCode < 300
    if parsed <> invalid and parsed.doesExist("success") then ok = ok and parsed.success = true

    m.top.response = {
        ok: ok,
        statusCode: statusCode,
        body: parsed,
        raw: responseText,
        path: path,
        method: method
    }
end sub

function backendApiErrorResponse(statusCode as Integer, message as String) as Object
    return {
        ok: false,
        statusCode: statusCode,
        body: invalid,
        raw: message,
        path: "",
        method: ""
    }
end function

function backendApiTaskText(item as Object, key as String, fallback as String) as String
    if item = invalid then return fallback
    if item.doesExist(key) and item[key] <> invalid and item[key] <> "" then return item[key]
    return fallback
end function
