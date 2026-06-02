sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("liveTvCanvas")
    m.focusItems = []
    m.focusIndex = 5
    m.channels = [
        { name: "ESPN HD", now: "Premier League Live", icon: "SP", live: true },
        { name: "BBC World", now: "Evening News", icon: "NW", live: false },
        { name: "CNN Intl", now: "Breaking News", icon: "CNN", live: false },
        { name: "beIN Sports", now: "La Liga Live", icon: "BN", live: true },
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
    row = uiSideNav(m.canvas, m.colors, "live", m.focusItems, 0)

    uiLabel(m.canvas, "Search channels", 910, 22, 190, 28, 14, m.colors.textMuted)
    drawCategoryPills(row)
    for i = 0 to m.channels.count() - 1
        drawChannel(m.channels[i], 230, 148 + i * 70, row + 1 + i, 1)
    end for
    drawPlayer()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)

    for i = 0 to m.channels.count() - 1
        drawChannelBadge(m.channels[i], 230, 148 + i * 70)
    end for
end sub

sub drawCategoryPills(row as Integer)
    cats = ["All", "Sports", "News", "Kids", "Music"]
    for i = 0 to cats.count() - 1
        item = { x: 246 + i * 90, y: 94, w: 80, h: 36, icon: "", label: cats[i], subtitle: "", iconSize: 1, titleSize: 13, subSize: 10, bg: m.colors.bg, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.purple, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: i + 1, page: "", action: "cat" }
        if i = 0 then item.bg = m.colors.purple
        m.focusItems.push(item)
    end for
end sub

sub drawChannel(ch as Object, x as Integer, y as Integer, row as Integer, col as Integer)
    item = { x: x, y: y, w: 300, h: 58, icon: ch.icon, label: ch.name, subtitle: ch.now, iconSize: 11, titleSize: 14, subSize: 11, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textMuted, focusBg: m.colors.greenSoft, focusBorder: m.colors.green, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "channel", mode: "row" }
    m.focusItems.push(item)
end sub

sub drawChannelBadge(ch as Object, x as Integer, y as Integer)
    if ch.live then uiLabel(m.canvas, "LIVE", x + 242, y + 18, 44, 20, 10, "0xF09595FF", "center")
end sub

sub drawPlayer()
    uiRect(m.canvas, 565, 112, 640, 410, m.colors.purpleSoft)
    uiLabel(m.canvas, "LIVE", 590, 130, 48, 22, 11, "0xF09595FF")
    uiLabel(m.canvas, "ESPN HD", 642, 126, 150, 26, 14, m.colors.textPurple)
    uiLabel(m.canvas, "Premier League - Man City vs Arsenal", 590, 160, 430, 34, 18, m.colors.text)
    uiLabel(m.canvas, "Sports - HD - 1080p", 590, 193, 250, 24, 13, m.colors.textMuted)
    uiRect(m.canvas, 590, 232, 590, 212, m.colors.black)
    uiRect(m.canvas, 860, 306, 84, 84, m.colors.purple, 0.65)
    uiLabel(m.canvas, "PLAY", 860, 306, 84, 84, 18, m.colors.text, "center")
    uiLabel(m.canvas, "22:15 / 90:00", 1020, 410, 150, 24, 12, m.colors.textDim, "right")
    uiLabel(m.canvas, "Up next on ESPN HD", 590, 548, 250, 24, 13, m.colors.textDim)
    drawEpg("21:00", "NFL Highlights", 590)
    drawEpg("23:00", "SportsCenter", 790)
    drawEpg("01:00", "NBA Pre-game", 990)
end sub

sub drawEpg(time as String, title as String, x as Integer)
    uiRect(m.canvas, x, 585, 180, 64, "0xFFFFFF10")
    uiLabel(m.canvas, time, x + 12, 590, 80, 22, 12, m.colors.purpleLine)
    uiLabel(m.canvas, title, x + 12, 616, 150, 22, 13, m.colors.textPurple)
end sub
