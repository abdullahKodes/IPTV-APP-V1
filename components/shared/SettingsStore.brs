function settingsStoreDefaults() as Object
    return {
        defaultQuality: "Auto",
        captionMode: "System",
        autoplay: true,
        notifications: true,
        appLanguage: "English",
        parentalLock: false,
        lastSync: "Not synced yet",
        syncCount: 0,
        signedIn: true,
        userName: "John Doe",
        userEmail: "john.doe@email.com",
        subscription: "Premium"
    }
end function

function settingsStoreLoad() as Object
    defaults = settingsStoreDefaults()
    section = CreateObject("roRegistrySection", "iptvmax_settings")
    return {
        defaultQuality: settingsStoreReadString(section, "defaultQuality", defaults.defaultQuality),
        captionMode: settingsStoreReadString(section, "captionMode", defaults.captionMode),
        autoplay: settingsStoreReadBool(section, "autoplay", defaults.autoplay),
        notifications: settingsStoreReadBool(section, "notifications", defaults.notifications),
        appLanguage: settingsStoreReadString(section, "appLanguage", defaults.appLanguage),
        parentalLock: settingsStoreReadBool(section, "parentalLock", defaults.parentalLock),
        lastSync: settingsStoreReadString(section, "lastSync", defaults.lastSync),
        syncCount: settingsStoreReadInt(section, "syncCount", defaults.syncCount),
        signedIn: settingsStoreReadBool(section, "signedIn", defaults.signedIn),
        userName: settingsStoreReadString(section, "userName", defaults.userName),
        userEmail: settingsStoreReadString(section, "userEmail", defaults.userEmail),
        subscription: settingsStoreReadString(section, "subscription", defaults.subscription)
    }
end function

sub settingsStoreSave(settings as Object)
    if settings = invalid then return
    section = CreateObject("roRegistrySection", "iptvmax_settings")
    section.Write("defaultQuality", settingsStoreText(settings, "defaultQuality", "Auto"))
    section.Write("captionMode", settingsStoreText(settings, "captionMode", "System"))
    section.Write("autoplay", settingsStoreBoolValue(settings, "autoplay", true))
    section.Write("notifications", settingsStoreBoolValue(settings, "notifications", true))
    section.Write("appLanguage", settingsStoreText(settings, "appLanguage", "English"))
    section.Write("parentalLock", settingsStoreBoolValue(settings, "parentalLock", false))
    section.Write("lastSync", settingsStoreText(settings, "lastSync", "Not synced yet"))
    section.Write("syncCount", settingsStoreIntValue(settings, "syncCount", 0).toStr())
    section.Write("signedIn", settingsStoreBoolValue(settings, "signedIn", true))
    section.Write("userName", settingsStoreText(settings, "userName", "John Doe"))
    section.Write("userEmail", settingsStoreText(settings, "userEmail", "john.doe@email.com"))
    section.Write("subscription", settingsStoreText(settings, "subscription", "Premium"))
    section.Flush()
end sub

function settingsStoreReadString(section as Object, key as String, fallback as String) as String
    if section <> invalid and section.Exists(key) then
        value = section.Read(key)
        if value <> invalid and value <> "" then return value
    end if
    return fallback
end function

function settingsStoreReadBool(section as Object, key as String, fallback as Boolean) as Boolean
    value = settingsStoreReadString(section, key, "")
    value = LCase(value)
    if value = "1" or value = "true" or value = "yes" then return true
    if value = "0" or value = "false" or value = "no" then return false
    return fallback
end function

function settingsStoreReadInt(section as Object, key as String, fallback as Integer) as Integer
    value = settingsStoreReadString(section, key, "")
    if value <> "" then return Val(value)
    return fallback
end function

function settingsStoreText(settings as Object, key as String, fallback = "" as String) as String
    value = settingsStoreValue(settings, key)
    if value <> invalid then return value
    return fallback
end function

function settingsStoreBool(settings as Object, key as String, fallback as Boolean) as Boolean
    value = settingsStoreValue(settings, key)
    if value <> invalid then return value
    return fallback
end function

function settingsStoreNumber(settings as Object, key as String, fallback as Integer) as Integer
    value = settingsStoreValue(settings, key)
    if value <> invalid then return value
    return fallback
end function

function settingsStoreValue(settings as Object, key as String) as Dynamic
    if settings = invalid then return invalid
    if settings.doesExist(key) then return settings[key]
    lowerKey = LCase(key)
    if lowerKey <> key and settings.doesExist(lowerKey) then return settings[lowerKey]
    return invalid
end function

function settingsStoreBoolValue(settings as Object, key as String, fallback as Boolean) as String
    if settingsStoreBool(settings, key, fallback) then return "1"
    return "0"
end function

function settingsStoreIntValue(settings as Object, key as String, fallback as Integer) as Integer
    return settingsStoreNumber(settings, key, fallback)
end function
