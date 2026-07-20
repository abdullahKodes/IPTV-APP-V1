sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("settingsCanvas")
    m.focusItems = []
    m.focusIndex = 0
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
    m.parentalPromptOpen = false
    m.parentalPinMode = ""
    m.parentalPinInput = ""
    m.parentalPinFirst = ""
    m.parentalPinError = ""
    m.parentalPinKeyboardIndex = 0
    m.parentalPinKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "DONE"]
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
    if m.parentalPromptOpen then return handleParentalPinKey(key)
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
    if action = "parental" then openParentalPinFlow() : return
    if action = "sync" then syncAllPlaylists()
    if action = "clearcache" then m.settings.lastSync = "Cache cleared"
    if action = "changepin" then openParentalChangePinFlow() : return
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
    if m.parentalPromptOpen then drawParentalPinOverlay()
end sub

function drawSettingsSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addSettingsNavItem(12, 112, "home", "Home", "HomePage", 0, false)
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
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: row, col: 0, page: page, mode: "row", noFocusShift: true
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
        item.opacity = 0.58
    end if
    m.focusItems.push(item)
end sub

sub addSettingsProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: 5, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawPageHeader()
    title = uiLabel(m.canvas, "Settings", 258, 108, 420, 46, 32, m.colors.text)
    title.font.size = 32
end sub

sub drawHeaderBackButton()
    drawHeaderAction(1068, 120, 112, 36, "back", "Back", "HomePage", "", 0, 4)
end sub

sub drawPlaybackPanel()
    x = 258
    y = 176
    w = 590
    drawPanel(x, y, w, 206, "PLAYBACK", m.colors.textGreen)
    drawSettingRow(x, y + 52, w, "Default quality", "", settingsStoreText(m.settings, "defaultQuality", "Auto"), "quality", "select", true, 1, 1)
    drawSettingRow(x, y + 104, w, "Autoplay next", "", "", "autoplay", "toggle", settingsStoreBool(m.settings, "autoplay", true), 2, 1)
    drawSettingRow(x, y + 156, w, "Caption mode", "", captionDisplayText(settingsStoreText(m.settings, "captionMode", "System")), "captions", "select", true, 3, 1)
end sub

sub drawAppPanel()
    x = 258
    y = 404
    w = 590
    drawPanel(x, y, w, 206, "APP", m.colors.textGreen)
    drawSettingRow(x, y + 52, w, "Notifications", "", "", "notifications", "toggle", settingsStoreBool(m.settings, "notifications", true), 4, 1)
    drawSettingRow(x, y + 104, w, "App language", "", settingsStoreText(m.settings, "appLanguage", "English"), "language", "select", true, 5, 1)
    drawSettingRow(x, y + 156, w, "Parental lock", "", "", "parental", "toggle", settingsStoreBool(m.settings, "parentalLock", false), 6, 1)
end sub

sub drawAccountPanel()
    x = 872
    y = 176
    w = 330
    drawPanel(x, y, w, 258, "ACCOUNT", m.colors.amber)
    drawAccountRow(x, y + 52, w, "sync_account", "Sync playlists", "sync", 1)
    drawAccountRow(x, y + 104, w, "cache_account", "Clear cache", "clearcache", 2)
    drawAccountRow(x, y + 156, w, "settings", "Change PIN", "changepin", 3)
    drawAccountRow(x, y + 208, w, "logout_account", "Sign out", "signout", 4)
end sub

sub drawDropdown()
    if m.dropdownOptions = invalid or m.dropdownOptions.count() = 0 then return
    rowH = 40
    w = 126
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
        uiRoundRect(m.canvas, x, optionY, w, 40, bg, border)
        optionLabel = uiLabel(m.canvas, dropdownDisplayText(m.dropdownKey, m.dropdownOptions[i]), x + 4, optionY, w - 8, 40, 14, textColor, "center")
        optionLabel.font.size = 14
    end for
end sub

sub drawPanel(x as Integer, y as Integer, w as Integer, h as Integer, title as String, titleColor as String)
    uiRoundRect(m.canvas, x, y, w, h, m.colors.panel, m.colors.whiteLine, 0.96)
    panelTitle = uiLabel(m.canvas, title, x + 22, y + 3, w - 44, 38, 22, titleColor)
    panelTitle.font.size = 22
end sub

sub drawSettingRow(x as Integer, y as Integer, w as Integer, title as String, subtitle as String, value as String, action as String, kind as String, enabled as Boolean, row as Integer, col as Integer)
    if y > 0 then uiRect(m.canvas, x + 22, y - 8, w - 44, 1, "0xFFFFFF0C")
    drawRowText(x + 24, y, 300, title, subtitle)
    if kind = "toggle" then
        drawCompactToggle(x + w - 104, y + 8, enabled, action, row, col)
    else
        drawCompactSelect(x + w - 178, y + 1, 126, value, action, row, col)
    end if
end sub

sub drawRowText(x as Integer, y as Integer, w as Integer, title as String, subtitle as String)
    rowLabel = uiLabel(m.canvas, title, x, y + 3, w, 30, 18, m.colors.text)
    rowLabel.font.size = 18
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
    uiRoundRect(m.canvas, x, y, w, 40, bg, border, 1.0)
    valueLabel = uiLabel(m.canvas, value, x + 4, y, w - 8, 40, 14, textColor, "center")
    valueLabel.font.size = 14
    chevronUri = "pkg:/images/ui/select_chevron_down.png"
    if focused then chevronUri = "pkg:/images/ui/select_chevron_down_focus.png"
    uiPoster(m.canvas, chevronUri, x + w - 29, y + 11, 18, 18)
    m.focusItems.push({ x: x, y: y, w: w, h: 40, icon: "", label: value, subtitle: "", iconSize: 1, titleSize: 14, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: bg, focusBorder: border, focusTextColor: textColor, row: row, col: col, page: "", action: action, mode: "manual", noFocusShift: true })
end sub

sub drawCompactToggle(x as Integer, y as Integer, enabled as Boolean, action as String, row as Integer, col as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    state = "off"
    if enabled then state = "on"
    focusSuffix = ""
    if focused then focusSuffix = "_focus"
    uri = "pkg:/images/ui/settings_toggle_" + state + focusSuffix + ".png"
    uiPoster(m.canvas, uri, x, y, 52, 26)
    m.focusItems.push({ x: x, y: y, w: 52, h: 26, icon: "", label: boolText(enabled), subtitle: "", iconSize: 1, titleSize: 10, subSize: 10, bg: m.colors.bg2, border: m.colors.whiteLine, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: "", action: action, mode: "manual", noFocusShift: true })
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
    accountLabel = uiLabel(m.canvas, label, x + 66, y + 4, 205, 30, 18, textColor)
    accountLabel.font.size = 18
    m.focusItems.push({ x: x + 16, y: y - 2, w: w - 32, h: 46, icon: icon, label: label, subtitle: "", iconSize: 11, titleSize: 18, subSize: 8, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: 4, page: "", action: action, mode: "manual", noFocusShift: true })
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
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 12, titleSize: 15, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: page, action: action, mode: "manual", noFocusShift: true })
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

sub openParentalPinFlow()
    m.parentalPromptOpen = true
    m.parentalPinInput = ""
    m.parentalPinFirst = ""
    m.parentalPinError = ""
    m.parentalPinKeyboardIndex = 0
    if not parentalControlPinIsSet() then
        m.parentalPinMode = "setup_new"
    else if settingsStoreBool(m.settings, "parentalLock", false) then
        m.parentalPinMode = "disable"
    else
        m.parentalPinMode = "enable"
    end if
    render()
end sub

sub openParentalChangePinFlow()
    m.parentalPromptOpen = true
    m.parentalPinInput = ""
    m.parentalPinFirst = ""
    m.parentalPinError = ""
    m.parentalPinKeyboardIndex = 0
    if parentalControlPinIsSet() then
        m.parentalPinMode = "change_verify_old"
    else
        m.parentalPinMode = "setup_new"
    end if
    render()
end sub

sub closeParentalPinFlow()
    m.parentalPromptOpen = false
    m.parentalPinMode = ""
    m.parentalPinInput = ""
    m.parentalPinFirst = ""
    m.parentalPinError = ""
    render()
end sub

function handleParentalPinKey(key as String) as Boolean
    keyCount = m.parentalPinKeys.count()
    if key = "back" then closeParentalPinFlow() : return true
    if key = "left" and m.parentalPinKeyboardIndex > 0 then m.parentalPinKeyboardIndex -= 1 : render() : return true
    if key = "right" and m.parentalPinKeyboardIndex < keyCount - 1 then m.parentalPinKeyboardIndex += 1 : render() : return true
    if key = "up" and m.parentalPinKeyboardIndex - 3 >= 0 then m.parentalPinKeyboardIndex -= 3 : render() : return true
    if key = "down" and m.parentalPinKeyboardIndex + 3 < keyCount then m.parentalPinKeyboardIndex += 3 : render() : return true
    if key = "OK" then pressParentalPinKey() : return true
    return true
end function

sub pressParentalPinKey()
    selected = m.parentalPinKeys[m.parentalPinKeyboardIndex]
    m.parentalPinError = ""
    if selected = "DEL" then
        if m.parentalPinInput.len() > 0 then m.parentalPinInput = Left(m.parentalPinInput, m.parentalPinInput.len() - 1)
        render()
        return
    end if
    if selected = "DONE" then
        submitParentalPin()
        return
    end if
    if m.parentalPinInput.len() < 4 then m.parentalPinInput += selected
    render()
end sub

sub submitParentalPin()
    if not parentalControlPinValid(m.parentalPinInput) then
        m.parentalPinError = "Enter a 4-digit PIN."
        render()
        return
    end if

    if m.parentalPinMode = "setup_new" then
        m.parentalPinFirst = m.parentalPinInput
        m.parentalPinInput = ""
        m.parentalPinMode = "setup_confirm"
        render()
        return
    end if

    if m.parentalPinMode = "setup_confirm" then
        if m.parentalPinInput <> m.parentalPinFirst then
            m.parentalPinInput = ""
            m.parentalPinFirst = ""
            m.parentalPinMode = "setup_new"
            m.parentalPinError = "PINs did not match. Try again."
            render()
            return
        end if
        if parentalControlSavePin(m.parentalPinInput) then
            parentalControlSetLock(true)
            m.settings.parentalLock = true
            settingsStoreSave(m.settings)
            closeParentalPinFlow()
        end if
        return
    end if

    if m.parentalPinMode = "change_verify_old" then
        if not parentalControlVerifyPin(m.parentalPinInput) then
            m.parentalPinInput = ""
            m.parentalPinError = "Incorrect current PIN."
            render()
            return
        end if
        m.parentalPinInput = ""
        m.parentalPinMode = "change_new"
        render()
        return
    end if

    if m.parentalPinMode = "change_new" then
        m.parentalPinFirst = m.parentalPinInput
        m.parentalPinInput = ""
        m.parentalPinMode = "change_confirm"
        render()
        return
    end if

    if m.parentalPinMode = "change_confirm" then
        if m.parentalPinInput <> m.parentalPinFirst then
            m.parentalPinInput = ""
            m.parentalPinFirst = ""
            m.parentalPinMode = "change_new"
            m.parentalPinError = "PINs did not match. Try again."
            render()
            return
        end if
        if parentalControlSavePin(m.parentalPinInput) then closeParentalPinFlow()
        return
    end if

    if not parentalControlVerifyPin(m.parentalPinInput) then
        m.parentalPinInput = ""
        m.parentalPinError = "Incorrect PIN."
        render()
        return
    end if

    if m.parentalPinMode = "enable" then
        parentalControlSetLock(true)
        m.settings.parentalLock = true
    else if m.parentalPinMode = "disable" then
        parentalControlSetLock(false)
        m.settings.parentalLock = false
    end if
    settingsStoreSave(m.settings)
    closeParentalPinFlow()
end sub

sub drawParentalPinOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.58)
    x = 390
    y = 126
    w = 500
    h = 468
    uiPoster(m.canvas, "pkg:/images/ui/rr_500x468_panel_greenFocus.png", x, y, w, h, 0.98)
    titleLabel = uiLabel(m.canvas, parentalPinTitle(), x + 32, y + 20, w - 64, 42, 26, m.colors.textGreen, "center")
    titleLabel.font.size = 26
    subtitleLabel = uiLabel(m.canvas, parentalPinMessage(), x + 42, y + 72, w - 84, 34, 18, m.colors.textMuted, "center")
    subtitleLabel.font.size = 18
    drawParentalPinDots(x + 142, y + 124)
    if m.parentalPinError <> "" then
        errorLabel = uiLabel(m.canvas, m.parentalPinError, x + 36, y + 182, w - 72, 34, 18, m.colors.red, "center")
        errorLabel.font.size = 18
    else
        demoLockLabel = uiLabel(m.canvas, "Demo locks: VOD " + parentalControlRestrictedCategory() + ", Live TV " + parentalControlRestrictedLiveCategory(), x + 36, y + 182, w - 72, 34, 18, m.colors.textDim, "center")
        demoLockLabel.font.size = 18
    end if
    drawParentalPinKeyboard(x + 118, y + 222)
    uiLabel(m.canvas, "Back cancels", x + 32, y + h - 42, w - 64, 22, 11, m.colors.textDim, "center")
end sub

sub drawParentalPinDots(x as Integer, y as Integer)
    for i = 0 to 3
        filled = i < m.parentalPinInput.len()
        dotX = x + i * 56
        drawParentalPinSlot(m.canvas, dotX, y, filled)
    end for
end sub

sub drawParentalPinSlot(parent as Object, x as Integer, y as Integer, filled as Boolean)
    slotUri = "pkg:/images/ui/rr_42x42_panel_purpleLine.png"
    if filled then slotUri = "pkg:/images/ui/rr_42x42_greenSoft_green.png"
    uiPoster(parent, slotUri, x, y, 42, 42, 0.94)
    if filled then
        uiPoster(parent, "pkg:/images/ui/rr_16x16_text_text.png", x + 13, y + 13, 16, 16, 0.94)
    else
        uiRect(parent, x + 12, y + 20, 18, 2, m.colors.textDim, 0.28)
    end if
end sub

sub drawParentalPinKeyboard(startX as Integer, startY as Integer)
    keyW = 70
    keyH = 36
    gap = 12
    for i = 0 to m.parentalPinKeys.count() - 1
        keyRect = parentalPinKeyRect(i, startX, startY, keyW, keyH, gap)
        keyLabel = m.parentalPinKeys[i]
        uiDrawKeyboardKey(m.canvas, keyLabel, uiKeyboardDisplayText(keyLabel, true), keyRect.x, keyRect.y, keyRect.w, keyRect.h, i = m.parentalPinKeyboardIndex, m.colors)
    end for
end sub

function parentalPinKeyRect(index as Integer, startX as Integer, startY as Integer, keyW as Integer, keyH as Integer, gap as Integer) as Object
    row = Int(index / 3)
    col = index MOD 3
    return { x: startX + col * (keyW + gap), y: startY + row * (keyH + gap), w: keyW, h: keyH }
end function

function parentalPinTitle() as String
    if m.parentalPinMode = "setup_confirm" then return "Confirm PIN"
    if m.parentalPinMode = "change_verify_old" then return "Current PIN"
    if m.parentalPinMode = "change_new" then return "New PIN"
    if m.parentalPinMode = "change_confirm" then return "Confirm New PIN"
    if m.parentalPinMode = "disable" then return "Turn Off Parental Lock"
    if m.parentalPinMode = "enable" then return "Turn On Parental Lock"
    return "Create Parental PIN"
end function

function parentalPinMessage() as String
    if m.parentalPinMode = "setup_confirm" then return "Enter the same 4 digits."
    if m.parentalPinMode = "change_verify_old" then return "Enter your Current Pin"
    if m.parentalPinMode = "change_new" then return "Choose a new PIN."
    if m.parentalPinMode = "change_confirm" then return "Confirm your new PIN."
    if m.parentalPinMode = "disable" then return "Enter PIN to turn off lock."
    if m.parentalPinMode = "enable" then return "Enter PIN to turn on lock."
    return "Create a 4-digit PIN."
end function

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
