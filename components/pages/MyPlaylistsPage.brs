sub init()
    m.colors = appColors()
    m.focusItems = []
    m.focusIndex = 5
    m.playlists = [
        { title: "Sports HD Pack", meta: "4,280 channels - M3U", status: "Active", time: "Updated 2h ago", icon: "TV", accent: "purple" },
        { title: "Movies & Cinema", meta: "2,100 titles - Xtreme", status: "Active", time: "Updated 1d ago", icon: "M", accent: "green" },
        { title: "Series Vault", meta: "890 series - M3U", status: "Expires soon", time: "Expires in 3 days", icon: "S", accent: "purple" },
        { title: "International Live", meta: "3,600 channels - M3U", status: "Active", time: "Updated 4h ago", icon: "WORLD", accent: "green" },
        { title: "Music TV Channels", meta: "420 channels - Xtreme", status: "Offline", time: "Last seen 3d ago", icon: "NOTE", accent: "purple" },
        { title: "Kids & Family", meta: "1,160 channels - M3U", status: "Active", time: "Updated 6h ago", icon: "KIDS", accent: "green" }
    ]
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
    row = uiSideNav(m.top, m.colors, "playlists", m.focusItems, 0)

    uiLabel(m.top, "My Playlists", 230, 104, 300, 30, 16, m.colors.textDim)
    uiLabel(m.top, "6 playlists - 12,450 channels total", 230, 132, 360, 26, 15, m.colors.purpleLine)
    addTopAction(980, 104, "PLUS", "Add Playlist", row, 3, "AddPlaylistPage")
    addTopAction(980, 158, "SEARCH", "Search", row + 1, 3, "")

    x0 = 230
    y0 = 190
    cardW = 300
    cardH = 138
    for i = 0 to m.playlists.count() - 1
        p = m.playlists[i]
        col = i mod 3
        r = Int(i / 3)
        drawPlaylistCard(p, x0 + col * 330, y0 + r * 162, cardW, cardH, row + 2 + r, col + 1)
    end for

    uiRect(m.top, 230, 650, 7, 7, m.colors.green)
    uiLabel(m.top, "5 active - 1 offline - last sync 2 hours ago", 248, 636, 420, 38, 13, "0x444441FF")
    uiApplyFocus(m.top, m.focusItems, m.focusIndex)
end sub

sub addTopAction(x as Integer, y as Integer, icon as String, label as String, row as Integer, col as Integer, page as String)
    item = { x: x, y: y, w: 190, h: 44, icon: icon, label: label, subtitle: "", iconSize: 13, titleSize: 15, subSize: 10, bg: m.colors.purple, border: m.colors.purple, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.greenFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, page: page, action: "" }
    m.focusItems.push(item)
end sub

sub drawPlaylistCard(p as Object, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    iconBg = m.colors.purpleSoft
    iconColor = m.colors.textPurple
    if p.accent = "green" then iconBg = m.colors.greenSoft : iconColor = m.colors.textGreen

    item = { x: x, y: y, w: w, h: h, icon: p.icon, label: p.title, subtitle: p.meta, iconSize: 13, titleSize: 16, subSize: 12, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.purpleLine, focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, page: "LiveTvPage", action: "" }
    m.focusItems.push(item)
    uiRect(m.top, x + 18, y + 78, w - 36, 1, "0x7F77DD44")
    uiLabel(m.top, p.status, x + 190, y + 17, 86, 24, 12, statusColor(p.status), "center")
    uiLabel(m.top, p.time, x + 18, y + 94, 150, 28, 12, m.colors.textDim)
    uiLabel(m.top, "REF", x + 210, y + 94, 45, 28, 12, m.colors.purpleLine)
    uiLabel(m.top, "DEL", x + 254, y + 94, 45, 28, 12, "0x993C1DFF")
end sub

function statusColor(status as String) as String
    if status = "Offline" then return "0xF09595FF"
    if status = "Expires soon" then return m.colors.amber
    return m.colors.textGreen
end function
