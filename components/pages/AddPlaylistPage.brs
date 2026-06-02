sub init()
    m.colors = appColors()
    m.mode = "m3u"
    m.added = false
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
    render()
end sub

sub activate()
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "m3u" or item.action = "xtreme" then m.mode = item.action : render() : return
    if item.action = "submit" then m.added = true : render() : return
end sub

sub render()
    uiClear(m.top)
    m.focusItems = []
    uiRect(m.top, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.top, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = uiSideNav(m.top, m.colors, "playlists", m.focusItems, 0)

    uiLabel(m.top, "Add New Playlist", 250, 104, 300, 30, 16, m.colors.textDim)
    addSmallButton(418, 150, 205, 48, "M3U", "M3U Playlist", row, 1, "m3u")
    addSmallButton(650, 150, 230, 48, "X", "Xtreme Account", row, 2, "xtreme")

    if m.mode = "m3u" then
        drawField(295, 235, "Playlist Title", "e.g. Sports Pack HD", m.colors.purpleLine)
        drawField(295, 325, "M3U URL", "http://provider.com/list.m3u", m.colors.purpleLine)
        submitText = "Add Playlist"
        if m.added then submitText = "Playlist Added"
        addWideAction(295, 438, 520, 56, "PLUS", submitText, row + 3, 1)
    else
        drawField(295, 220, "Account Name", "My Xtreme Account", m.colors.green)
        drawField(295, 292, "Server URL", "http://server.com:8080", m.colors.green)
        drawField(295, 364, "Username", "username", m.colors.green)
        drawField(295, 436, "Password", "********", m.colors.green)
        addWideAction(295, 528, 520, 56, "LINK", "Connect Account", row + 4, 1)
    end if

    drawQrPanel()
    uiApplyFocus(m.top, m.focusItems, m.focusIndex)
end sub

sub drawField(x as Integer, y as Integer, label as String, value as String, accent as String)
    uiLabel(m.top, label, x, y, 360, 24, 14, accent)
    uiRect(m.top, x, y + 32, 520, 52, "0xFFFFFF10")
    uiRect(m.top, x + 2, y + 34, 516, 48, m.colors.panel)
    uiLabel(m.top, value, x + 18, y + 42, 480, 34, 16, m.colors.textMuted)
end sub

sub drawQrPanel()
    uiRect(m.top, 910, 190, 210, 320, "0xFFFFFF10")
    uiLabel(m.top, "Scan to add", 930, 212, 170, 26, 14, m.colors.purpleLine, "center")
    uiRect(m.top, 962, 258, 104, 104, m.colors.text)
    uiRect(m.top, 976, 272, 24, 24, m.colors.bg)
    uiRect(m.top, 1028, 272, 24, 24, m.colors.bg)
    uiRect(m.top, 976, 324, 24, 24, m.colors.bg)
    for i = 0 to 9
        uiRect(m.top, 982 + ((i * 19) mod 74), 304 + ((i * 13) mod 52), 8, 8, m.colors.purple)
    end for
    uiLabel(m.top, "Point your phone camera to scan and import playlist", 928, 384, 174, 58, 13, m.colors.textMuted, "center")
    uiRect(m.top, 910, 530, 210, 86, m.colors.greenSoft)
    uiLabel(m.top, "Tip", 928, 540, 170, 22, 14, m.colors.textGreen)
    uiLabel(m.top, "Use the IPTV Max mobile app to push playlists directly to your TV.", 928, 564, 174, 44, 12, m.colors.textMuted)
end sub

sub addSmallButton(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer, action as String)
    active = m.mode = action
    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 14, titleSize: 16, subSize: 10, bg: m.colors.bg, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.purpleFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, action: action, page: "" }
    if active then item.bg = m.colors.purple
    m.focusItems.push(item)
end sub

sub addWideAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer)
    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 14, titleSize: 17, subSize: 10, bg: m.colors.purple, border: m.colors.purple, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.greenFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, action: "submit", page: "" }
    m.focusItems.push(item)
end sub
