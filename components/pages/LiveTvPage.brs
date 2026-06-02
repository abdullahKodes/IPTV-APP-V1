sub init()
    m.colors = appColors()
    m.focusItems = []
    m.focusIndex = 5
    m.channels = [
        { name: "ESPN HD", now: "Premier League Live", icon: "BALL", live: true },
        { name: "BBC World", now: "Evening News", icon: "NEWS", live: false },
        { name: "CNN Intl", now: "Breaking News", icon: "CNN", live: false },
        { name: "beIN Sports", now: "La Liga Live", icon: "FOOT", live: true },
        { name: "MTV Hits", now: "Top 40 Charts", icon: "NOTE", live: false },
        { name: "Cartoon Net.", now: "Kids Shows", icon: "KIDS", live: false }
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
    uiClear(m.top)
    m.focusItems = []
    uiRect(m.top, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.top, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = uiSideNav(m.top, m.colors, "live", m.focusItems, 0)

    uiLabel(m.top, "Search channels...", 932, 22, 190, 28, 15, m.colors.textMuted)
    drawCategoryPills(row)
    for i = 0 to m.channels.count() - 1
        drawChannel(m.channels[i], 230, 148 + i * 70, row + 1 + i, 1)
    end for
    drawPlayer()
    uiApplyFocus(m.top, m.focusItems, m.focusIndex)
end sub

sub drawCategoryPills(row as Integer)
    cats = ["All", "Sports", "News", "Kids", "Music"]
    for i = 0 to cats.count() - 1
        item = { x: 230 + i * 88, y: 94, w: 78, h: 38, icon: "", label: cats[i], subtitle: "", iconSize: 1, titleSize: 14, subSize: 10, bg: m.colors.bg, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.purple, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: i + 1, page: "", action: "cat" }
        if i = 0 then item.bg = m.colors.purple
        m.focusItems.push(item)
    end for
end sub

sub drawChannel(ch as Object, x as Integer, y as Integer, row as Integer, col as Integer)
    item = { x: x, y: y, w: 300, h: 58, icon: ch.icon, label: ch.name, subtitle: ch.now, iconSize: 12, titleSize: 15, subSize: 12, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textMuted, focusBg: m.colors.greenSoft, focusBorder: m.colors.green, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "channel" }
    m.focusItems.push(item)
    if ch.live then uiLabel(m.top, "LIVE", x + 242, y + 18, 44, 20, 10, "0xF09595FF", "center")
end sub

sub drawPlayer()
    uiRect(m.top, 565, 112, 640, 410, m.colors.purpleSoft)
    uiLabel(m.top, "LIVE", 590, 130, 48, 22, 11, "0xF09595FF")
    uiLabel(m.top, "ESPN HD", 642, 126, 150, 26, 14, m.colors.textPurple)
    uiLabel(m.top, "Premier League - Man City vs Arsenal", 590, 160, 430, 34, 18, m.colors.text)
    uiLabel(m.top, "Sports - HD - 1080p", 590, 193, 250, 24, 13, m.colors.textMuted)
    uiRect(m.top, 590, 232, 590, 212, m.colors.black)
    uiRect(m.top, 860, 306, 84, 84, m.colors.purple, 0.65)
    uiLabel(m.top, "PLAY", 860, 306, 84, 84, 18, m.colors.text, "center")
    uiLabel(m.top, "22:15 / 90:00", 1020, 410, 150, 24, 12, m.colors.textDim, "right")
    uiLabel(m.top, "Up next on ESPN HD", 590, 548, 250, 24, 13, m.colors.textDim)
    drawEpg("21:00", "NFL Highlights", 590)
    drawEpg("23:00", "SportsCenter", 790)
    drawEpg("01:00", "NBA Pre-game", 990)
end sub

sub drawEpg(time as String, title as String, x as Integer)
    uiRect(m.top, x, 585, 180, 64, "0xFFFFFF10")
    uiLabel(m.top, time, x + 12, 590, 80, 22, 12, m.colors.purpleLine)
    uiLabel(m.top, title, x + 12, 616, 150, 22, 13, m.colors.textPurple)
end sub
