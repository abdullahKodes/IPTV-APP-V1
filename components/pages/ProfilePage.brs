sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("profileCanvas")
    m.focusItems = []
    m.focusIndex = 0
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
    m.settings = settingsStoreLoad()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.canvas, 0, 86, 1280, 634, m.colors.bg, 0.96)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    drawProfileHeader()
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

sub addProfileProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: m.colors.purpleSoft, border: m.colors.greenFocus, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.58, focusOpacity: 0.66,
        row: 5, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawProfileHeader()
    title = uiLabel(m.canvas, "My Profile", 300, 96, 520, 64, 32, m.colors.text)
    title.font.size = 32
end sub

sub drawProfileSummary()
    x = 300
    y = 184
    w = 680
    uiRoundRect(m.canvas, x, y, w, 168, m.colors.panel, m.colors.whiteLine, 0.94)
    uiPoster(m.canvas, "pkg:/images/ui/profile_avatar_circle.png", x + 34, y + 40, 88, 88)
    initials = profileInitials(settingsStoreText(m.settings, "userName", "John Doe"))
    initialsLabel = uiLabel(m.canvas, initials, x + 34, y + 40, 88, 88, 32, m.colors.text, "center")
    initialsLabel.font.size = 32
    uiLabel(m.canvas, settingsStoreText(m.settings, "userName", "John Doe"), x + 150, y + 44, 340, 34, 23, m.colors.text)
    uiLabel(m.canvas, settingsStoreText(m.settings, "userEmail", "john.doe@email.com"), x + 150, y + 82, 360, 28, 15, m.colors.purpleLine)
    badge = profileStatusLabel()
    badgeW = profileBadgeWidth(badge)
    badgeX = x + w - badgeW - 76
    uiRoundRect(m.canvas, badgeX, y + 64, badgeW, 38, m.colors.greenSoft, m.colors.greenFocus)
    badgeLabel = uiLabel(m.canvas, badge, badgeX + 4, y + 64, badgeW - 8, 38, 17, m.colors.textGreen, "center")
    badgeLabel.font.size = 17
    status = "Signed in"
    if not settingsStoreBool(m.settings, "signedIn", true) then status = "Signed out locally"
    uiLabel(m.canvas, status, x + 150, y + 116, 340, 24, 13, m.colors.textDim)
end sub

sub drawProfileActions()
    x = 300
    y = 392
    w = 680
    uiRoundRect(m.canvas, x, y, w, 236, m.colors.panel, m.colors.whiteLine, 0.94)
    buttonX = x + 90
    actionsTitle = uiLabel(m.canvas, "PROFILE ACTIONS", buttonX + 4, y + 16, 280, 34, 21, m.colors.textGreen)
    actionsTitle.font.size = 21
    drawProfileAction(buttonX, y + 62, 500, "Manage Subscription", "manage", "", 0)
    drawProfileAction(buttonX, y + 116, 500, "App Settings", "settings", "", 1)
    drawProfileAction(buttonX, y + 170, 500, "Sign Out", "signout", "", 2)
end sub

sub drawProfileAction(x as Integer, y as Integer, w as Integer, label as String, action as String, page as String, row as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    bg = m.colors.bg2
    border = m.colors.bg2
    textColor = m.colors.textPurple
    if action = "signout" then textColor = "0xFFB2A8FF"
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, x, y, w, 44, bg, border, 0.92)
    uiLabel(m.canvas, label, x + 22, y + 6, w - 44, 30, 14, textColor)
    m.focusItems.push({ x: x, y: y, w: w, h: 44, icon: "", label: label, subtitle: "", iconSize: 1, titleSize: 14, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: 0, page: page, action: action, mode: "manual", noFocusShift: true })
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

function profileSubscriptionLabel(value as String) as String
    if value = invalid or value = "" then return "Demo"
    lower = LCase(value)
    if Instr(1, lower, "trial") > 0 then return "Trial"
    if Instr(1, lower, "demo") > 0 then return "Demo"
    return value
end function

function profileStatusLabel() as String
    activePlaylist = playlistStoreActive()
    playlistType = playlistStoreText(activePlaylist, "type")
    status = playlistStoreText(activePlaylist, "status")
    if Instr(1, LCase(status), "trial") > 0 then return "Trial"
    subscription = profileSubscriptionLabel(settingsStoreText(m.settings, "subscription", ""))
    if LCase(subscription) = "premium" then return "Premium"
    if status <> "" then return profileSubscriptionLabel(status)
    if subscription <> "" then return subscription
    if playlistType <> "" then return playlistType
    return "Demo"
end function

function profileBadgeWidth(label as String) as Integer
    length = label.len()
    if length <= 5 then return 100
    if length <= 7 then return 120
    if length <= 12 then return 160
    return 200
end function
