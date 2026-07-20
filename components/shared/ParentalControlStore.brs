function parentalControlRestrictedCategory() as String
    return "Drama"
end function

function parentalControlRestrictedLiveCategory() as String
    return "Sports"
end function

function parentalControlPinIsSet() as Boolean
    section = CreateObject("roRegistrySection", "iptvmax_parental")
    return section <> invalid and section.Exists("pinHash")
end function

function parentalControlSavePin(pin as String) as Boolean
    if not parentalControlPinValid(pin) then return false
    section = CreateObject("roRegistrySection", "iptvmax_parental")
    section.Write("pinHash", parentalControlPinHash(pin))
    section.Write("pinVersion", "1")
    section.Flush()
    return true
end function

function parentalControlVerifyPin(pin as String) as Boolean
    if not parentalControlPinValid(pin) then return false
    section = CreateObject("roRegistrySection", "iptvmax_parental")
    if section = invalid or not section.Exists("pinHash") then return false
    return section.Read("pinHash") = parentalControlPinHash(pin)
end function

function parentalControlPinValid(pin as String) as Boolean
    if pin = invalid or pin.len() <> 4 then return false
    for i = 1 to 4
        ch = Mid(pin, i, 1)
        if Instr(1, "0123456789", ch) = 0 then return false
    end for
    return true
end function

function parentalControlPinHash(pin as String) as String
    value = 347
    for i = 1 to 4
        digit = Val(Mid(pin, i, 1))
        value = (value * 37 + digit * 19 + i * 11) MOD 1000003
    end for
    return value.toStr()
end function

function parentalControlLockEnabled() as Boolean
    section = CreateObject("roRegistrySection", "iptvmax_settings")
    if section = invalid or not section.Exists("parentalLock") then return false
    value = LCase(section.Read("parentalLock"))
    return value = "1" or value = "true" or value = "yes"
end function

sub parentalControlSetLock(enabled as Boolean)
    section = CreateObject("roRegistrySection", "iptvmax_settings")
    if enabled then
        section.Write("parentalLock", "1")
    else
        section.Write("parentalLock", "0")
    end if
    section.Flush()
end sub

function parentalControlIsRestrictedDetailPayload(payload as Object) as Boolean
    if payload = invalid then return false
    text = parentalControlPayloadText(payload, "meta") + " " + parentalControlPayloadText(payload, "subtitle") + " " + parentalControlPayloadText(payload, "title")
    return parentalControlTextIsRestricted(text)
end function

function parentalControlIsRestrictedPlaybackPayload(payload as Object) as Boolean
    if payload = invalid then return false
    text = parentalControlPayloadText(payload, "subtitle") + " " + parentalControlPayloadText(payload, "title") + " " + parentalControlPayloadText(payload, "mediaType")
    if LCase(parentalControlPayloadText(payload, "mediaType")) = "live" then
        return parentalControlLiveTextIsRestricted(text)
    end if
    return parentalControlTextIsRestricted(text)
end function

function parentalControlTextIsRestricted(text as String) as Boolean
    if text = invalid or text = "" then return false
    needle = LCase(parentalControlRestrictedCategory())
    return Instr(1, LCase(text), needle) > 0
end function

function parentalControlLiveTextIsRestricted(text as String) as Boolean
    if text = invalid or text = "" then return false
    needle = LCase(parentalControlRestrictedLiveCategory())
    return Instr(1, LCase(text), needle) > 0
end function

function parentalControlPayloadText(payload as Object, key as String) as String
    if payload = invalid or key = invalid then return ""
    if payload.doesExist(key) and payload[key] <> invalid then return payload[key]
    return ""
end function
