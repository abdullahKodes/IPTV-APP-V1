sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("homeCanvas")
    m.focusItems = []
    m.focusIndex = 5
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
    drawFocus()
end sub

sub activate()
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then
        m.top.navigateTo = item.page
    end if
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

    nextRow = drawHomeSideNav()

    uiLabel(m.canvas, "QUICK ACCESS", 514, 150, 430, 34, 18, m.colors.textDim, "center")
    addTile(480, 230, 260, 152, "card_add", "Add Playlist", "", m.colors.purpleSoft, m.colors.purpleLine, m.colors.textPurple, nextRow, 1, "AddPlaylistPage")
    addTile(780, 230, 260, 152, "card_tv", "Live TV", "", m.colors.greenSoft, m.colors.green, m.colors.textGreen, nextRow, 2, "LiveTvPage")
    addTile(480, 412, 260, 152, "card_series", "Series", "", m.colors.purpleSoft, m.colors.purpleLine, m.colors.textPurple, nextRow + 1, 1, "SeriesPage")
    addTile(780, 412, 260, 152, "card_movies", "Movies", "", m.colors.greenSoft, m.colors.green, m.colors.textGreen, nextRow + 1, 2, "MoviesPage")

    drawFocus()
end sub

function drawHomeSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addHomeNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addHomeNavItem(12, 168, "heart", "Favourites", "MoviesPage", 1, false)
    addHomeNavItem(12, 224, "settings", "Settings", "SettingsPage", 2, false)
    addHomeNavItem(12, 280, "bell", "Notifications", "", 3, false)

    addHomeProfileItem()
    return 5
end function

sub addHomeNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
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

sub addHomeProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: "0xFFFFFF10", border: m.colors.panel, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 4, col: 0, page: "SettingsPage", mode: "row"
    }
    m.focusItems.push(item)
end sub

sub addTile(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, subText as String, bg as String, border as String, textColor as String, row as Integer, col as Integer, page as String)
    focusBorder = m.colors.greenFocus
    focusBg = m.colors.purpleDeep
    if bg = m.colors.greenSoft then
        focusBorder = m.colors.purpleLine
        focusBg = m.colors.greenDeep
    end if
    item = {
        x: x, y: y, w: w, h: h,
        icon: icon, label: label, subtitle: subText,
        iconSize: 18, titleSize: 25, subSize: 12,
        bg: bg, border: border, textColor: textColor, subColor: m.colors.textMuted,
        focusBg: focusBg, focusBorder: focusBorder, focusTextColor: m.colors.text,
        row: row, col: col, page: page, mode: "tile", thin: true
    }
    m.focusItems.push(item)
end sub

sub drawFocus()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
end sub
