sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("profileCanvas")
    m.focusItems = []
    m.focusIndex = 7
    m.settings = settingsStoreLoad()
    m.signOutDialog = invalid
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
        if key = "back" then closeProfileDialog() : return true
        return false
    end if
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

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "manage" then m.settings.lastSync = "Subscription portal pending"
    if item.action = "settings" then m.top.navigateTo = "SettingsPage" : return
    if item.action = "signout" then openProfileDialog()
    settingsStoreSave(m.settings)
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
    row = drawProfileSideNav()
    drawProfileHeader(row)
    drawProfileSummary()
    drawProfileActions()
end sub

function drawProfileSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addProfileNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addProfileNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addProfileNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addProfileNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addProfileNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)
    addProfileProfileItem()
    return 6
end function

sub addProfileNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: m.colors.textGreen, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: 0, page: page, mode: "row", noFocusShift: true
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
    end if
    m.focusItems.push(item)
end sub

sub addProfileProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: m.colors.purpleSoft, border: m.colors.greenFocus, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 5, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawProfileHeader(row as Integer)
    uiLabel(m.canvas, "My Profile", 270, 108, 360, 36, 26, m.colors.text)
    uiLabel(m.canvas, "Account identity and subscription status", 270, 140, 520, 24, 13, m.colors.textDim)
    addProfileBackButton(row)
end sub

sub addProfileBackButton(row as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    bg = "0xFFFFFF10"
    border = m.colors.whiteLine
    textColor = m.colors.textPurple
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, 1030, 118, 150, 40, bg, border)
    uiDrawIcon(m.canvas, "back", 1060, 128, 18, 18, focused, textColor, 12)
    uiLabel(m.canvas, "Back", 1090, 121, 64, 30, 15, textColor)
    m.focusItems.push({ x: 1030, y: 118, w: 150, h: 40, icon: "back", label: "Back", subtitle: "", iconSize: 12, titleSize: 15, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: 4, page: "HomePage", action: "", mode: "manual", noFocusShift: true })
end sub

sub drawProfileSummary()
    x = 270
    y = 198
    uiRect(m.canvas, x, y, 840, 168, m.colors.panel, 0.94)
    uiRectBorder(m.canvas, x, y, 840, 168, m.colors.whiteLine, 1, 0.58)
    uiRect(m.canvas, x + 34, y + 42, 82, 82, m.colors.purple)
    uiRectBorder(m.canvas, x + 34, y + 42, 82, 82, m.colors.purpleLine, 2)
    initials = profileInitials(settingsStoreText(m.settings, "userName", "John Doe"))
    uiLabel(m.canvas, initials, x + 34, y + 49, 82, 58, 26, m.colors.text, "center")
    uiLabel(m.canvas, settingsStoreText(m.settings, "userName", "John Doe"), x + 146, y + 44, 360, 34, 23, m.colors.text)
    uiLabel(m.canvas, settingsStoreText(m.settings, "userEmail", "john.doe@email.com"), x + 146, y + 82, 380, 28, 15, m.colors.purpleLine)
    uiRect(m.canvas, x + 670, y + 66, 104, 26, m.colors.greenSoft)
    uiRectBorder(m.canvas, x + 670, y + 66, 104, 26, m.colors.green, 1)
    uiLabel(m.canvas, settingsStoreText(m.settings, "subscription", "Premium"), x + 674, y + 63, 96, 26, 13, m.colors.textGreen, "center")
    status = "Signed in"
    if not settingsStoreBool(m.settings, "signedIn", true) then status = "Signed out locally"
    uiLabel(m.canvas, status, x + 146, y + 116, 360, 24, 13, m.colors.textDim)
end sub

sub drawProfileActions()
    x = 270
    y = 400
    uiRect(m.canvas, x, y, 840, 168, m.colors.panel, 0.94)
    uiRectBorder(m.canvas, x, y, 840, 168, m.colors.whiteLine, 1, 0.58)
    uiLabel(m.canvas, "PROFILE ACTIONS", x + 32, y + 18, 260, 24, 14, m.colors.textDim)
    drawProfileAction(x + 32, y + 54, "info", "Manage subscription", "Open billing provider portal when connected", "manage", "", 3)
    drawProfileAction(x + 32, y + 92, "settings", "App settings", "Playback and account preferences", "settings", "", 4)
    drawProfileAction(x + 32, y + 130, "out", "Sign out", "Clear local account session", "signout", "", 5)
end sub

sub drawProfileAction(x as Integer, y as Integer, icon as String, label as String, value as String, action as String, page as String, row as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    bg = m.colors.panel
    border = m.colors.panel
    textColor = m.colors.textPurple
    valueColor = m.colors.textDim
    if action = "signout" then textColor = "0xFFB2A8FF"
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
        valueColor = m.colors.textPurple
    end if
    uiRect(m.canvas, x, y - 2, 784, 36, bg, 0.88)
    if focused then uiRectBorder(m.canvas, x, y - 2, 784, 36, border, 2)
    uiDrawIcon(m.canvas, icon, x + 18, y + 7, 18, 18, focused, textColor, 12)
    uiLabel(m.canvas, label, x + 54, y - 1, 246, 28, 14, textColor)
    uiLabel(m.canvas, value, x + 350, y - 1, 408, 28, 11, valueColor, "right")
    m.focusItems.push({ x: x, y: y - 2, w: 784, h: 36, icon: icon, label: label, subtitle: value, iconSize: 12, titleSize: 14, subSize: 11, bg: bg, border: border, textColor: textColor, subColor: valueColor, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: 3, page: page, action: action, mode: "manual", noFocusShift: true })
end sub

sub openProfileDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Sign out?"
    dialog.message = "This clears the local account session. Playlists and app settings stay on this Roku."
    dialog.buttons = ["Cancel", "Sign out"]
    dialog.observeField("buttonSelected", "onProfileDialogButton")
    m.signOutDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub closeProfileDialog()
    if m.top <> invalid and m.top.getScene() <> invalid then m.top.getScene().dialog = invalid
    m.signOutDialog = invalid
end sub

sub onProfileDialogButton()
    if m.signOutDialog = invalid then return
    if m.signOutDialog.buttonSelected = 1 then
        m.settings.signedIn = false
        m.settings.lastSync = "Signed out locally"
        settingsStoreSave(m.settings)
    end if
    closeProfileDialog()
    render()
end sub

function profileInitials(name as String) as String
    if name = invalid or name = "" then return "JD"
    parts = name.Tokenize(" ")
    if parts.count() = 1 then return UCase(Left(parts[0], 2))
    return UCase(Left(parts[0], 1) + Left(parts[1], 1))
end function
