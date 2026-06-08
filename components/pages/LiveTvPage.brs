sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("liveTvCanvas")
    m.focusItems = []
    m.focusIndex = 1
    m.categoryIndex = 0
    m.channelIndex = 0
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
    if item.action = "cat" then m.categoryIndex = item.catIndex : render() : return
    if item.action = "channel" then m.channelIndex = item.channelIndex : render() : return
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
    drawChannelDivider()
    for i = 0 to m.channels.count() - 1
        drawChannel(m.channels[i], i, 244, 210 + i * 68, channelRow + i, 1)
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
    cats = [
        { label: "All", x: 244, y: 106, w: 62, row: row, col: 1 },
        { label: "Sports", x: 316, y: 106, w: 82, row: row, col: 2 },
        { label: "News", x: 408, y: 106, w: 76, row: row, col: 3 },
        { label: "Kids", x: 244, y: 150, w: 70, row: row + 1, col: 1 },
        { label: "Music", x: 324, y: 150, w: 82, row: row + 1, col: 2 }
    ]
    for i = 0 to cats.count() - 1
        cat = cats[i]
        itemIndex = m.focusItems.count()
        focused = itemIndex = m.focusIndex
        selected = i = m.categoryIndex
        bg = m.colors.bg
        border = m.colors.whiteLine
        textColor = m.colors.textPurple
        if selected then
            bg = m.colors.purpleSoft
            border = m.colors.greenFocus
            textColor = m.colors.text
        end if
        if focused then
            bg = m.colors.purpleSoft
            border = m.colors.greenFocus
            textColor = m.colors.text
        end if
        uiRoundRect(m.canvas, cat.x, cat.y, cat.w, 34, bg, border)
        uiLabel(m.canvas, cat.label, cat.x, cat.y + 1, cat.w, 30, 12, textColor, "center")
        item = {
            x: cat.x, y: cat.y, w: cat.w, h: 34,
            icon: "", label: cat.label, subtitle: "",
            iconSize: 1, titleSize: 12, subSize: 10,
            bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
            focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text,
            row: cat.row, col: cat.col, page: "", action: "cat", catIndex: i, mode: "manual"
        }
        m.focusItems.push(item)
    end for
    return row + 2
end function

sub drawChannelDivider()
    uiRect(m.canvas, 244, 194, 276, 1, "0xFFFFFF18")
    uiRect(m.canvas, 244, 194, 72, 1, m.colors.greenFocus, 0.72)
end sub

sub drawChannel(ch as Object, channelIndex as Integer, x as Integer, y as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    selected = channelIndex = m.channelIndex
    w = 276
    h = 60
    bg = m.colors.panel
    border = m.colors.whiteLine
    iconBg = m.colors.purpleSoft
    titleColor = m.colors.text
    subColor = m.colors.textMuted
    if ch.live then iconBg = m.colors.greenSoft
    if selected then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
        iconBg = m.colors.greenSoft
        subColor = m.colors.text
    end if
    if focused then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
        iconBg = m.colors.greenSoft
        subColor = m.colors.text
    end if

    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiRoundRect(m.canvas, x + 12, y + 8, 44, 44, iconBg, iconBg)
    uiDrawIcon(m.canvas, ch.icon, x + 23, y + 19, 22, 22, focused, titleColor, 11)
    uiLabel(m.canvas, ch.name, x + 70, y + 8, 132, 23, 15, titleColor)
    uiLabel(m.canvas, ch.now, x + 70, y + 32, 132, 18, 10, subColor)
    if ch.live then
        drawLiveBadge(x + 206, y + 19)
    end if

    item = {
        x: x, y: y, w: w, h: h,
        icon: ch.icon, label: ch.name, subtitle: ch.now,
        iconSize: 11, iconW: 44, iconH: 44, iconX: 12,
        labelX: 70, labelW: 132, labelAlign: "left",
        titleSize: 15, subSize: 11,
        bg: bg, border: border, textColor: titleColor, subColor: subColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "channel", channelIndex: channelIndex, mode: "manual"
    }
    m.focusItems.push(item)
end sub

sub drawLiveBadge(x as Integer, y as Integer)
    uiRoundRect(m.canvas, x, y, 58, 22, "0x993C1DFF", "0x993C1DFF")
    uiRect(m.canvas, x + 8, y + 8, 6, 6, m.colors.red)
    uiLabel(m.canvas, "LIVE", x + 16, y + 1, 34, 18, 10, m.colors.text, "center")
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
