sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("addPlaylistCanvas")
    m.mode = "m3u"
    m.added = false
    m.focusItems = []
    m.focusIndex = 6
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
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "m3u" or item.action = "xtreme" then m.mode = item.action : render() : return
    if item.action = "submit" then m.added = true : render() : return
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = drawAddPlaylistSideNav()

    uiLabel(m.canvas, "Add New Playlist", 380, 114, 760, 48, 30, m.colors.text, "center")
    addSmallButton(505, 198, 230, 48, "", "M3U Playlist", row, 1, "m3u")
    addSmallButton(765, 198, 230, 48, "", "Xtreme Account", row, 2, "xtreme")

    if m.mode = "m3u" then
        drawField(380, 292, 760, "Playlist Title", "", m.colors.textGreen)
        drawField(380, 398, 760, "M3U URL", "", m.colors.textGreen)
        submitText = "Add Playlist"
        if m.added then submitText = "Playlist Added"
        addWideAction(530, 520, 460, 56, "", submitText, row + 3, 1)
    else
        drawField(380, 258, 760, "Account Name", "", m.colors.textGreen)
        drawField(380, 344, 760, "Server URL", "", m.colors.textGreen)
        drawField(380, 430, 760, "Username", "", m.colors.textGreen)
        drawField(380, 516, 760, "Password", "", m.colors.textGreen)
        addWideAction(530, 616, 460, 56, "", "Connect Account", row + 4, 1)
    end if

    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
end sub

function drawAddPlaylistSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addAddNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addAddNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addAddNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addAddNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addAddNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)

    addAddProfileItem()
    return 6
end function

sub addAddNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: m.colors.textGreen, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: 0, page: page, mode: "row"
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.purpleLine
        item.textColor = m.colors.text
    end if
    m.focusItems.push(item)
end sub

sub addAddProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: "0xFFFFFF10", border: m.colors.panel, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 5, col: 0, page: "SettingsPage", mode: "row"
    }
    m.focusItems.push(item)
end sub

sub drawField(x as Integer, y as Integer, w as Integer, label as String, value as String, accent as String)
    uiLabel(m.canvas, label, x, y, w, 24, 13, accent)
    uiRoundRect(m.canvas, x, y + 32, w, 56, m.colors.panel, m.colors.panel)
    uiLabel(m.canvas, value, x + 24, y + 43, w - 48, 32, 16, m.colors.textMuted)
end sub

sub addSmallButton(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer, action as String)
    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 14, titleSize: 15, subSize: 10, bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, action: action, page: "", mode: "row", noFocusShift: true }
    m.focusItems.push(item)
end sub

sub addWideAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer)
    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 15, titleSize: 17, subSize: 10, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, action: "submit", page: "", mode: "row" }
    m.focusItems.push(item)
end sub
