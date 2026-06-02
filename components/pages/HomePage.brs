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
    uiRect(m.canvas, 0, 72, 1280, 648, m.colors.bg2)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    nextRow = uiSideNav(m.canvas, m.colors, "playlists", m.focusItems, 0)

    uiLabel(m.canvas, "Quick Access", 445, 112, 380, 36, 22, m.colors.text, "center")
    uiLabel(m.canvas, "Jump into live channels, playlists, series, and movies", 390, 144, 490, 28, 14, m.colors.textMuted, "center")
    addTile(390, 194, 280, 152, "ADD", "Add Playlist", "Import M3U or Xtreme", m.colors.purpleSoft, m.colors.purpleLine, m.colors.textPurple, nextRow, 1, "AddPlaylistPage")
    addTile(710, 194, 280, 152, "TV", "Live TV", "Watch channels live", m.colors.greenSoft, m.colors.green, m.colors.textGreen, nextRow, 2, "LiveTvPage")
    addTile(390, 374, 280, 152, "S", "Series", "Continue episodes", m.colors.purpleSoft, m.colors.purpleLine, m.colors.textPurple, nextRow + 1, 1, "SeriesPage")
    addTile(710, 374, 280, 152, "M", "Movies", "Browse featured films", m.colors.greenSoft, m.colors.green, m.colors.textGreen, nextRow + 1, 2, "MoviesPage")

    uiRect(m.canvas, 408, 574, 460, 42, "0xFFFFFF10")
    uiRect(m.canvas, 426, 588, 8, 8, m.colors.green)
    uiLabel(m.canvas, "Connected", 446, 576, 100, 30, 14, m.colors.textGreen)
    uiLabel(m.canvas, "3 playlists loaded", 560, 576, 150, 30, 14, m.colors.textMuted)
    uiLabel(m.canvas, "4,280 channels", 720, 576, 150, 30, 14, m.colors.textMuted)
    drawFocus()
end sub

sub addTile(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, subText as String, bg as String, border as String, textColor as String, row as Integer, col as Integer, page as String)
    item = {
        x: x, y: y, w: w, h: h,
        icon: icon, label: label, subtitle: subText,
        iconSize: 19, titleSize: 18, subSize: 13,
        bg: bg, border: border, textColor: textColor, subColor: m.colors.textMuted,
        focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text,
        row: row, col: col, page: page, mode: "tile"
    }
    m.focusItems.push(item)
end sub

sub drawFocus()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
end sub
