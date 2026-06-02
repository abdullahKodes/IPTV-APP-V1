sub init()
    m.colors = appColors()
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
    m.top.removeChildren(m.top.getChildCount(), 0)
    m.focusItems = []
    uiRect(m.top, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.top, 0, 72, 1280, 648, m.colors.bg2)
    clockParts = uiTopBar(m.top, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    nextRow = uiSideNav(m.top, m.colors, "playlists", m.focusItems, 0)

    uiLabel(m.top, "Quick Access", 520, 125, 260, 32, 18, m.colors.textDim, "center")
    addTile(408, 182, 260, 142, "ADD", "Add Playlist", "Import M3U / URL", m.colors.purpleSoft, m.colors.purpleLine, m.colors.textPurple, nextRow, 1, "AddPlaylistPage")
    addTile(700, 182, 260, 142, "TV", "Live TV", "Watch channels live", m.colors.greenSoft, m.colors.green, m.colors.textGreen, nextRow, 2, "LiveTvPage")
    addTile(408, 350, 260, 142, "S", "Series", "TV shows and episodes", m.colors.purpleSoft, m.colors.purpleLine, m.colors.textPurple, nextRow + 1, 1, "SeriesPage")
    addTile(700, 350, 260, 142, "M", "Movies", "Browse and stream films", m.colors.greenSoft, m.colors.green, m.colors.textGreen, nextRow + 1, 2, "MoviesPage")

    uiRect(m.top, 500, 548, 8, 8, m.colors.green)
    uiLabel(m.top, "Connected - 3 playlists loaded - 4,280 channels", 518, 532, 460, 40, 14, "0x444441FF")
    drawFocus()
end sub

sub addTile(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, subText as String, bg as String, border as String, textColor as String, row as Integer, col as Integer, page as String)
    item = {
        x: x, y: y, w: w, h: h,
        icon: icon, label: label, subtitle: subText,
        iconSize: 19, titleSize: 18, subSize: 13,
        bg: bg, border: border, textColor: textColor, subColor: m.colors.textMuted,
        focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text,
        row: row, col: col, page: page
    }
    m.focusItems.push(item)
end sub

sub drawFocus()
    uiApplyFocus(m.top, m.focusItems, m.focusIndex)
end sub
