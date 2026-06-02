sub init()
    m.colors = appColors()
    m.focusItems = []
    m.focusIndex = 5
    m.movies = [
        { title: "Inception", meta: "8.8 - Sci-Fi - 2h 28m", icon: "IN" },
        { title: "The Dark Knight", meta: "9.0 - Action - 2h 32m", icon: "DK" },
        { title: "Get Out", meta: "7.7 - Horror - 1h 44m", icon: "GO" },
        { title: "Dune Part 2", meta: "8.5 - Sci-Fi - 2h 46m", icon: "D2" }
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
    m.top.removeChildren(m.top.getChildCount(), 0)
    m.focusItems = []
    uiRect(m.top, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.top, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = uiSideNav(m.top, m.colors, "movies", m.focusItems, 0)
    uiLabel(m.top, "Search movies...", 950, 22, 190, 28, 15, m.colors.textMuted)
    drawPills(["All", "Action", "Horror", "Comedy", "Animation", "Sci-Fi"], row)
    drawFeatured(row + 1)
    uiLabel(m.top, "All movies", 230, 390, 250, 26, 14, m.colors.textDim)
    for i = 0 to m.movies.count() - 1
        drawMovieCard(m.movies[i], 230 + i * 238, 430, 214, 172, row + 2, i + 1)
    end for
    uiApplyFocus(m.top, m.focusItems, m.focusIndex)
end sub

sub drawPills(items as Object, row as Integer)
    for i = 0 to items.count() - 1
        item = { x: 230 + i * 105, y: 104, w: 92, h: 38, icon: "", label: items[i], subtitle: "", iconSize: 1, titleSize: 14, subSize: 10, bg: m.colors.bg, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.purple, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: i + 1, page: "", action: "genre" }
        if i = 0 then item.bg = m.colors.purple
        m.focusItems.push(item)
    end for
end sub

sub drawFeatured(row as Integer)
    item = { x: 230, y: 178, w: 770, h: 168, icon: "PLAY", label: "Interstellar", subtitle: "2014 - 2h 49m - Sci-Fi - Adventure - IMDb 8.7", iconSize: 18, titleSize: 20, subSize: 13, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.text, subColor: m.colors.textMuted, focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: 1, page: "", action: "watch" }
    m.focusItems.push(item)
    uiPoster(m.top, 255, 198, 96, 126, m.colors.purple, "STAR", m.colors.text)
    uiLabel(m.top, "Featured", 376, 198, 88, 22, 12, m.colors.textPurple)
    uiLabel(m.top, "Watch now", 376, 292, 112, 28, 13, m.colors.text)
end sub

sub drawMovieCard(movie as Object, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    item = { x: x, y: y, w: w, h: h, icon: movie.icon, label: movie.title, subtitle: movie.meta, iconSize: 18, titleSize: 15, subSize: 11, bg: m.colors.greenSoft, border: m.colors.green, textColor: m.colors.textGreen, subColor: m.colors.textMuted, focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "movie" }
    if col mod 2 = 0 then item.bg = m.colors.purpleSoft : item.border = m.colors.purpleLine : item.textColor = m.colors.textPurple
    m.focusItems.push(item)
end sub
