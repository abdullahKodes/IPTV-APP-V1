sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("settingsCanvas")
    m.focusItems = []
    m.focusIndex = 1
    m.settings = settingsStoreLoad()
    m.qualityOptions = ["Auto", "1080p", "720p", "480p"]
    m.captionOptions = ["System", "On", "Off", "Replay", "Mute"]
    m.languageOptions = ["English", "Spanish", "French", "Arabic"]
    m.versionText = settingsAppVersionText()
    m.signOutDialog = invalid
    m.dropdownOpen = false
    m.dropdownKey = ""
    m.dropdownOptions = []
    m.dropdownIndex = 0
    m.dropdownX = 0
    m.dropdownY = 0
    render()
end sub

sub refreshClock()
    if m.clock <> invalid then
        now = uiNowStrings()
        m.clock.text = now.time
        m.date.text = now.date
    end if
end sub

function handleKey(key as String) as Boolean
    if m.signOutDialog <> invalid then
        if key = "back" then closeSignOutDialog() : return true
        return false
    end if
    if m.dropdownOpen then return handleDropdownKey(key)
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

function handleDropdownKey(key as String) as Boolean
    if key = "back" then closeDropdown() : return true
    if key = "up" then
        if m.dropdownIndex > 0 then m.dropdownIndex -= 1
        render()
        return true
    end if
    if key = "down" then
        if m.dropdownIndex < m.dropdownOptions.count() - 1 then m.dropdownIndex += 1
        render()
        return true
    end if
    if key = "OK" then
        if m.dropdownIndex >= 0 and m.dropdownIndex < m.dropdownOptions.count() then
            m.settings[m.dropdownKey] = m.dropdownOptions[m.dropdownIndex]
            settingsStoreSave(m.settings)
        end if
        closeDropdown()
        return true
    end if
    return true
end function

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    action = ""
    if item.doesExist("action") then action = item.action

    if action = "quality" then openDropdown("defaultQuality", m.qualityOptions, item.x, item.y + item.h + 4) : return
    if action = "captions" then openDropdown("captionMode", m.captionOptions, item.x, item.y + item.h + 4) : return
    if action = "autoplay" then m.settings.autoplay = not m.settings.autoplay
    if action = "notifications" then m.settings.notifications = not m.settings.notifications
    if action = "language" then openDropdown("appLanguage", m.languageOptions, item.x, item.y + item.h + 4) : return
    if action = "parental" then m.settings.parentalLock = not m.settings.parentalLock
    if action = "sync" then syncAllPlaylists()
    if action = "clearcache" then m.settings.lastSync = "Cache cleared"
    if action = "signout" then openSignOutDialog()

    settingsStoreSave(m.settings)
    render()
end sub

sub openDropdown(key as String, options as Object, x as Integer, y as Integer)
    m.dropdownOpen = true
    m.dropdownKey = key
    m.dropdownOptions = options
    m.dropdownX = x
    m.dropdownY = y
    current = settingsStoreText(m.settings, key, options[0])
    m.dropdownIndex = 0
    for i = 0 to options.count() - 1
        if options[i] = current then m.dropdownIndex = i
    end for
    render()
end sub

sub closeDropdown()
    m.dropdownOpen = false
    m.dropdownKey = ""
    m.dropdownOptions = []
    m.dropdownIndex = 0
    render()
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.canvas, 0, 86, 1280, 634, m.colors.bg, 0.96)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    drawPageHeader()
    drawPlaybackPanel()
    drawAppPanel()
    drawAccountPanel()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.dropdownOpen then drawDropdown()
end sub

function drawSettingsSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addSettingsNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addSettingsNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addSettingsNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addSettingsNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addSettingsNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, true)
    addSettingsProfileItem()
    return 6
end function

sub addSettingsNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: m.colors.textGreen, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: 0, page: page, mode: "row", noFocusShift: true
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
    end if
    m.focusItems.push(item)
end sub

sub addSettingsProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: "0xFFFFFF10", border: m.colors.panel, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 5, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawPageHeader()
    uiLabel(m.canvas, "Settings", 258, 108, 420, 46, 34, m.colors.text)
    drawHeaderBackButton()
end sub

sub drawHeaderBackButton()
    drawHeaderAction(1068, 120, 112, 36, "back", "Back", "HomePage", "", 0, 4)
end sub

sub drawPlaybackPanel()
    x = 258
    y = 176
    w = 590
    drawPanel(x, y, w, 206, "PLAYBACK", m.colors.textGreen)
    drawSettingRow(x, y + 44, w, "Default quality", "", settingsStoreText(m.settings, "defaultQuality", "Auto"), "quality", "select", true, 1, 1)
    drawSettingRow(x, y + 98, w, "Autoplay next", "", "", "autoplay", "toggle", settingsStoreBool(m.settings, "autoplay", true), 2, 1)
    drawSettingRow(x, y + 152, w, "Caption mode", "", captionDisplayText(settingsStoreText(m.settings, "captionMode", "System")), "captions", "select", true, 3, 1)
end sub

sub drawAppPanel()
    x = 258
    y = 404
    w = 590
    drawPanel(x, y, w, 206, "APP", m.colors.textGreen)
    drawSettingRow(x, y + 44, w, "Notifications", "", "", "notifications", "toggle", settingsStoreBool(m.settings, "notifications", true), 4, 1)
    drawSettingRow(x, y + 98, w, "App language", "", settingsStoreText(m.settings, "appLanguage", "English"), "language", "select", true, 5, 1)
    drawSettingRow(x, y + 152, w, "Parental lock", "", "", "parental", "toggle", settingsStoreBool(m.settings, "parentalLock", false), 6, 1)
end sub

sub drawAccountPanel()
    x = 872
    y = 176
    w = 330
    drawPanel(x, y, w, 206, "ACCOUNT", m.colors.amber)
    drawAccountRow(x, y + 46, w, "sync_account", "Sync playlists", "sync", 1)
    drawAccountRow(x, y + 98, w, "cache_account", "Clear cache", "clearcache", 2)
    drawAccountRow(x, y + 150, w, "logout_account", "Sign out", "signout", 3)
end sub

sub drawDropdown()
    if m.dropdownOptions = invalid or m.dropdownOptions.count() = 0 then return
    rowH = 34
    w = 178
    x = m.dropdownX
    y = m.dropdownY
    totalH = rowH * m.dropdownOptions.count()
    if y + totalH > 704 then y = 704 - totalH
    uiRect(m.canvas, x - 4, y - 4, w + 8, totalH + 8, m.colors.bg, 0.84)
    for i = 0 to m.dropdownOptions.count() - 1
        optionY = y + i * rowH
        bg = m.colors.bg2
        border = m.colors.whiteLine
        textColor = m.colors.textPurple
        if i = m.dropdownIndex then
            bg = m.colors.purpleSoft
            border = m.colors.greenFocus
            textColor = m.colors.text
        end if
        uiRoundRect(m.canvas, x, optionY, w, 34, bg, border)
        uiLabel(m.canvas, dropdownDisplayText(m.dropdownKey, m.dropdownOptions[i]), x + 10, optionY + 1, w - 20, 26, 12, textColor, "center")
    end for
end sub

sub drawPanel(x as Integer, y as Integer, w as Integer, h as Integer, title as String, titleColor as String)
    uiRoundRect(m.canvas, x, y, w, h, m.colors.panel, m.colors.whiteLine, 0.96)
    uiLabel(m.canvas, title, x + 22, y + 13, w - 44, 22, 15, titleColor)
end sub

sub drawSettingRow(x as Integer, y as Integer, w as Integer, title as String, subtitle as String, value as String, action as String, kind as String, enabled as Boolean, row as Integer, col as Integer)
    if y > 0 then uiRect(m.canvas, x + 22, y - 8, w - 44, 1, "0xFFFFFF0C")
    drawRowText(x + 24, y, 300, title, subtitle)
    if kind = "toggle" then
        drawCompactToggle(x + w - 84, y + 8, enabled, action, row, col)
    else
        drawCompactSelect(x + w - 210, y + 4, 178, value, action, row, col)
    end if
end sub

sub drawRowText(x as Integer, y as Integer, w as Integer, title as String, subtitle as String)
    uiLabel(m.canvas, title, x, y + 3, w, 30, 14, m.colors.text)
end sub

sub drawCompactSelect(x as Integer, y as Integer, w as Integer, value as String, action as String, row as Integer, col as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    bg = m.colors.bg2
    border = m.colors.whiteLine
    textColor = m.colors.textPurple
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, x, y, w, 34, bg, border, 1.0)
    uiLabel(m.canvas, value, x + 12, y + 2, w - 44, 28, 12, textColor, "center")
    chevronUri = "pkg:/images/ui/select_chevron_down.png"
    if focused then chevronUri = "pkg:/images/ui/select_chevron_down_focus.png"
    uiPoster(m.canvas, chevronUri, x + w - 31, y + 8, 18, 18)
    m.focusItems.push({ x: x, y: y, w: w, h: 34, icon: "", label: value, subtitle: "", iconSize: 1, titleSize: 12, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: bg, focusBorder: border, focusTextColor: textColor, row: row, col: col, page: "", action: action, mode: "manual", noFocusShift: true })
end sub

sub drawCompactToggle(x as Integer, y as Integer, enabled as Boolean, action as String, row as Integer, col as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    track = m.colors.bg2
    border = m.colors.whiteLine
    knob = m.colors.text
    knobX = x + 1
    if enabled then
        track = m.colors.greenSoft
        border = m.colors.green
        knobX = x + 25
    end if
    if focused then border = m.colors.greenFocus
    uiRoundRect(m.canvas, x, y, 50, 26, track, border, 1.0)
    uiRoundRect(m.canvas, knobX, y + 1, 24, 24, knob, knob, 1.0)
    m.focusItems.push({ x: x, y: y, w: 50, h: 26, icon: "", label: boolText(enabled), subtitle: "", iconSize: 1, titleSize: 10, subSize: 10, bg: track, border: border, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: track, focusBorder: border, focusTextColor: m.colors.text, row: row, col: col, page: "", action: action, mode: "manual", noFocusShift: true })
end sub

sub drawAccountRow(x as Integer, y as Integer, w as Integer, icon as String, label as String, action as String, row as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    bg = m.colors.bg2
    border = m.colors.bg2
    textColor = m.colors.textPurple
    if action = "signout" then textColor = "0xFFB2A8FF"
    if focused then
        bg = m.colors.panelSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, x + 16, y - 2, w - 32, 46, bg, border, 1.0)
    uiDrawIcon(m.canvas, icon, x + 34, y + 12, 18, 18, focused, textColor, 11)
    uiLabel(m.canvas, label, x + 66, y + 4, 205, 30, 13, textColor)
    m.focusItems.push({ x: x + 16, y: y - 2, w: w - 32, h: 46, icon: icon, label: label, subtitle: "", iconSize: 11, titleSize: 13, subSize: 8, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: 4, page: "", action: action, mode: "manual", noFocusShift: true })
end sub

sub drawHeaderAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, page as String, action as String, row as Integer, col as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    bg = m.colors.bg2
    border = m.colors.whiteLine
    textColor = m.colors.textPurple
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiDrawIcon(m.canvas, icon, x + 18, y + 9, 18, 18, focused, textColor, 12)
    uiLabel(m.canvas, label, x + 42, y + 2, w - 54, 30, 14, textColor)
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 12, titleSize: 15, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: page, action: action, mode: "manual", noFocusShift: true })
end sub

sub cycleSetting(key as String, options as Object, delta as Integer)
    current = settingsStoreText(m.settings, key, options[0])
    index = 0
    for i = 0 to options.count() - 1
        if options[i] = current then index = i
    end for
    index += delta
    if index < 0 then index = options.count() - 1
    if index >= options.count() then index = 0
    m.settings[key] = options[index]
end sub

sub syncAllPlaylists()
    count = 0
    items = playlistStoreList()
    if items <> invalid then count = items.count()
    m.settings.syncCount = settingsStoreNumber(m.settings, "syncCount", 0) + 1
    m.settings.lastSync = "Synced now - " + count.toStr() + " playlists"
end sub

sub openSignOutDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Sign out?"
    dialog.message = "This clears the local account session. Playlists and app settings stay on this Roku."
    dialog.buttons = ["Cancel", "Sign out"]
    dialog.observeField("buttonSelected", "onSignOutDialogButton")
    m.signOutDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub closeSignOutDialog()
    if m.top <> invalid and m.top.getScene() <> invalid then m.top.getScene().dialog = invalid
    m.signOutDialog = invalid
end sub

sub onSignOutDialogButton()
    if m.signOutDialog = invalid then return
    if m.signOutDialog.buttonSelected = 1 then
        m.settings.signedIn = false
        m.settings.lastSync = "Signed out locally"
        settingsStoreSave(m.settings)
    end if
    closeSignOutDialog()
    render()
end sub

function settingsAppVersionText() as String
    appInfo = CreateObject("roAppInfo")
    if appInfo <> invalid then
        version = appInfo.GetVersion()
        if version <> invalid and version <> "" then return "v" + version
    end if
    return "v0.1"
end function

function captionDisplayText(value as String) as String
    if value = "System" then return "System"
    if value = "Replay" then return "Replay"
    if value = "Mute" then return "On mute"
    return value
end function

function dropdownDisplayText(key as String, value as String) as String
    if key = "captionMode" then return captionDisplayText(value)
    return value
end function

function compactSyncText(value as String) as String
    if value = invalid or value = "" then return "Not synced"
    if Instr(1, value, "Synced now") > 0 then return "Synced now"
    if Instr(1, value, "Signed out") > 0 then return "Signed out"
    return value
end function

function boolText(v as Boolean) as String
    if v then return "On"
    return "Off"
end function
