sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("seriesCanvas")
    m.focusItems = []
    m.focusIndex = 5
    m.series = [
        { title: "Ozark", meta: "4 Seasons", genre: "Drama - Thriller", icon: "OZ" },
        { title: "Westworld", meta: "4 Seasons", genre: "Sci-Fi - Drama", icon: "AI" },
        { title: "The Crown", meta: "6 Seasons", genre: "Drama - History", icon: "CR" },
        { title: "Peaky Blinders", meta: "6 Seasons", genre: "Crime - Drama", icon: "PB" }
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
    row = uiSideNav(m.canvas, m.colors, "series", m.focusItems, 0)
    uiLabel(m.canvas, "Search series", 930, 22, 190, 28, 14, m.colors.textMuted)
    drawPills(["All", "Drama", "Action", "Comedy", "Sci-Fi", "Thriller"], row)

    uiLabel(m.canvas, "Continue watching", 230, 158, 260, 26, 14, m.colors.textDim)
    drawContinueCard(230, 198, 365, "The Last of Us", "S1 - E6 - 28 min left", 70, row + 1, 1)
    drawContinueCard(625, 198, 365, "House of Dragon", "S2 - E3 - 44 min left", 30, row + 1, 2)
    uiLabel(m.canvas, "Popular series", 230, 350, 250, 26, 14, m.colors.textDim)
    for i = 0 to m.series.count() - 1
        drawMediaCard(m.series[i], 230 + i * 238, 390, 214, 190, row + 2, i + 1)
    end for
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)

    drawContinueProgress(230, 198, 365, 70)
    drawContinueProgress(625, 198, 365, 30)
end sub

sub drawPills(items as Object, row as Integer)
    for i = 0 to items.count() - 1
        item = { x: 246 + i * 100, y: 104, w: 88, h: 36, icon: "", label: items[i], subtitle: "", iconSize: 1, titleSize: 13, subSize: 10, bg: m.colors.bg, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.purple, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: i + 1, page: "", action: "genre" }
        if i = 0 then item.bg = m.colors.purple
        m.focusItems.push(item)
    end for
end sub

sub drawContinueCard(x as Integer, y as Integer, w as Integer, title as String, meta as String, progress as Integer, row as Integer, col as Integer)
    item = { x: x, y: y, w: w, h: 112, icon: "PLAY", label: title, subtitle: meta, iconSize: 13, titleSize: 15, subSize: 11, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textMuted, focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "play", mode: "row" }
    m.focusItems.push(item)
end sub

sub drawContinueProgress(x as Integer, y as Integer, w as Integer, progress as Integer)
    uiRect(m.canvas, x + 74, y + 86, w - 96, 4, "0x7F77DD44")
    uiRect(m.canvas, x + 74, y + 86, Int((w - 96) * progress / 100), 4, m.colors.green)
end sub

sub drawMediaCard(media as Object, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    item = { x: x, y: y, w: w, h: h, icon: media.icon, label: media.title, subtitle: media.meta + " - " + media.genre, iconSize: 17, titleSize: 14, subSize: 10, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textMuted, focusBg: m.colors.greenSoft, focusBorder: m.colors.green, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "series" }
    m.focusItems.push(item)
end sub
