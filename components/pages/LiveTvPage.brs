sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("liveTvCanvas")
    m.focusItems = []
    m.focusIndex = 1
    m.channels = [
        { name: "ESPN HD", now: "Premier League Live", icon: "sport", live: true },
        { name: "BBC World", now: "Evening News", icon: "NW", live: false },
        { name: "CNN Intl", now: "Breaking News", icon: "CNN", live: false },
        { name: "beIN Sports", now: "La Liga Live", icon: "sport", live: true },
        { name: "MTV Hits", now: "Top 40 Charts", icon: "MTV", live: false },
        { name: "Cartoon Net.", now: "Kids Shows", icon: "KD", live: false }
    ]
    render()
end sub

sub refreshClock()
    if m.clock <> invalid then now = uiNowStrings() : m.clock.text = now.time : m.date.text = now.date
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
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = drawLiveSideNav()

    drawSearchBox()
    uiRect(m.canvas, 534, 86, 1, 634, "0xFFFFFF12")
    channelRow = drawCategoryPills(row)
    for i = 0 to m.channels.count() - 1
        drawChannel(m.channels[i], 244, 202 + i * 58, channelRow + i, 1)
    end for
    drawPlayer()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
end sub

function drawLiveSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    liveActive = (m.focusIndex = 1) or (m.focusIndex > 5)
    addLiveNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addLiveNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, liveActive)
    addLiveNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addLiveNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addLiveNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)

    addLiveProfileItem()
    return 6
end function

sub addLiveNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
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

sub addLiveProfileItem()
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

sub drawSearchBox()
    uiRoundRect(m.canvas, 908, 20, 230, 48, m.colors.panel, m.colors.purpleLine)
    uiDrawIcon(m.canvas, "search", 926, 33, 20, 20, false, m.colors.textDim, 11)
    uiLabel(m.canvas, "Search channels...", 956, 25, 154, 34, 14, m.colors.textDim)
end sub

function drawCategoryPills(row as Integer) as Integer
    cats = ["All", "Sports", "News", "Kids", "Music"]
    for i = 0 to cats.count() - 1
        pillW = 80
        if cats[i] = "Sports" or cats[i] = "Music" then pillW = 88
        pillX = 244
        if i = 1 then pillX = 334
        if i = 2 then pillX = 432
        pillY = 104
        pillRow = row
        pillCol = i + 1
        if i > 2 then
            pillX = 244
            if i = 4 then pillX = 334
            pillY = 148
            pillRow = row + 1
            pillCol = i - 2
        end if
        item = {
            x: pillX, y: pillY, w: pillW, h: 36,
            icon: "", label: cats[i], subtitle: "",
            iconSize: 1, titleSize: 12, subSize: 10,
            bg: m.colors.bg, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
            focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text,
            row: pillRow, col: pillCol, page: "", action: "cat", noFocusShift: true
        }
        if i = 0 then
            item.bg = m.colors.purple
            item.border = m.colors.purple
            item.textColor = m.colors.text
        end if
        m.focusItems.push(item)
    end for
    return row + 2
end function

sub drawChannel(ch as Object, x as Integer, y as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    w = 276
    h = 52
    bg = m.colors.panel
    border = "0xFFFFFF14"
    iconBg = m.colors.purpleActive
    titleColor = m.colors.text
    if ch.live then iconBg = m.colors.greenActive
    if focused then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
        iconBg = m.colors.greenActive
    end if

    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiRect(m.canvas, x + 14, y + 12, 28, 28, iconBg, 0.94)
    uiDrawIcon(m.canvas, ch.icon, x + 18, y + 16, 20, 20, focused, titleColor, 11)
    uiLabel(m.canvas, ch.name, x + 56, y + 5, 150, 24, 14, titleColor)
    uiLabel(m.canvas, ch.now, x + 56, y + 27, 150, 20, 10, m.colors.textMuted)
    if ch.live then
        uiRect(m.canvas, x + 218, y + 16, 42, 20, "0x993C1DFF", 0.76)
        uiLabel(m.canvas, "LIVE", x + 218, y + 14, 42, 20, 10, m.colors.text, "center")
    end if

    item = {
        x: x, y: y, w: w, h: h,
        icon: ch.icon, label: ch.name, subtitle: ch.now,
        iconSize: 11, iconW: 28, iconH: 28, iconX: 18,
        labelX: 62, labelW: 170, labelAlign: "left",
        titleSize: 15, subSize: 11,
        bg: m.colors.panel, border: m.colors.purpleLine, textColor: m.colors.text, subColor: m.colors.textMuted,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.green, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "channel", mode: "manual", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawPlayer()
    panelX = 560
    panelY = 112
    panelW = 654
    panelH = 350
    drawBorderRect(panelX, panelY, panelW, panelH, m.colors.purpleActive, m.colors.purpleLine, 0.98)

    uiRect(m.canvas, panelX + 24, panelY + 24, 54, 22, "0x993C1DFF", 0.76)
    uiLabel(m.canvas, "LIVE", panelX + 24, panelY + 22, 54, 22, 11, m.colors.text, "center")
    uiLabel(m.canvas, "ESPN HD", panelX + 94, panelY + 20, 160, 28, 16, m.colors.text)
    uiLabel(m.canvas, "Premier League - Man City vs Arsenal", panelX + 24, panelY + 58, 430, 30, 17, m.colors.text)
    uiLabel(m.canvas, "Sports - HD - 1080p", panelX + 24, panelY + 86, 240, 22, 12, m.colors.textMuted)

    uiRect(m.canvas, panelX + 24, panelY + 126, panelW - 48, 156, m.colors.black)
    uiRect(m.canvas, panelX + 301, panelY + 176, 54, 54, m.colors.purple, 0.64)
    uiDrawIcon(m.canvas, "play", panelX + 317, panelY + 192, 22, 22, true, m.colors.text, 14)
    uiRect(m.canvas, panelX + 38, panelY + 260, 48, 20, "0x993C1DFF", 0.74)
    uiLabel(m.canvas, "LIVE", panelX + 38, panelY + 258, 48, 20, 10, m.colors.text, "center")
    uiLabel(m.canvas, "22:15 / 90:00", panelX + panelW - 190, panelY + 254, 150, 24, 12, m.colors.textDim, "right")

    uiRect(m.canvas, panelX + 24, panelY + 302, panelW - 48, 3, "0xFFFFFF18")
    uiRect(m.canvas, panelX + 24, panelY + 302, 420, 3, m.colors.purpleLine)

    uiLabel(m.canvas, "UP NEXT ON ESPN HD", panelX, 484, 300, 24, 12, m.colors.textDim)
    drawEpg("21:00", "NFL Highlights", 572)
    drawEpg("23:00", "SportsCenter", 808)
    drawEpg("01:00", "NBA Pre-game", 1044)
end sub

sub drawEpg(time as String, title as String, x as Integer)
    uiRoundRect(m.canvas, x, 516, 180, 64, m.colors.panel, m.colors.purpleLine)
    uiLabel(m.canvas, time, x + 12, 522, 80, 20, 12, m.colors.purpleLine)
    uiLabel(m.canvas, title, x + 12, 548, 150, 22, 13, m.colors.text)
end sub

sub drawBorderRect(x as Integer, y as Integer, w as Integer, h as Integer, fill as String, border as String, opacity = 1.0 as Float)
    uiRect(m.canvas, x, y, w, h, fill, opacity)
    uiRect(m.canvas, x, y, w, 1, border, 0.72)
    uiRect(m.canvas, x, y + h - 1, w, 1, border, 0.72)
    uiRect(m.canvas, x, y, 1, h, border, 0.72)
    uiRect(m.canvas, x + w - 1, y, 1, h, border, 0.72)
end sub
