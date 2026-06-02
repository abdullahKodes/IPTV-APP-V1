sub init()
    m.colors = appColors()
    m.focusItems = []
    m.focusIndex = 1
    m.autoplay = true
    m.subtitles = false
    m.notifications = true
    m.parental = false
    m.versionStatus = "v2.4.1"
    render()
end sub

sub refreshClock()
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
    if item.action = "autoplay" then m.autoplay = not m.autoplay
    if item.action = "subtitles" then m.subtitles = not m.subtitles
    if item.action = "notifications" then m.notifications = not m.notifications
    if item.action = "parental" then m.parental = not m.parental
    if item.action = "version" then
        if m.versionStatus = "v2.4.1" then m.versionStatus = "Up to date" else m.versionStatus = "v2.4.1"
    end if
    render()
end sub

sub render()
    m.top.removeChildren(m.top.getChildCount(), 0)
    m.focusItems = []
    uiRect(m.top, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.top, 0, 0, 1280, 72, m.colors.bg)
    uiRect(m.top, 0, 71, 1280, 1, "0xFFFFFF14")
    uiRect(m.top, 28, 18, 38, 38, m.colors.purple)
    uiLabel(m.top, "PLAY", 30, 18, 34, 38, 11, m.colors.text, "center")
    uiLabel(m.top, "IPTV", 78, 15, 78, 38, 24, m.colors.textPurple)
    uiLabel(m.top, "Max", 142, 15, 70, 38, 24, m.colors.textGreen)
    addBackButton()

    uiRect(m.top, 390, 112, 500, 74, m.colors.purpleSoft)
    uiRect(m.top, 418, 128, 46, 46, m.colors.purple)
    uiLabel(m.top, "JD", 418, 128, 46, 46, 17, m.colors.text, "center")
    uiLabel(m.top, "John Doe", 486, 120, 180, 30, 17, m.colors.textPurple)
    uiLabel(m.top, "john.doe@email.com", 486, 148, 220, 26, 13, m.colors.purpleLine)
    uiLabel(m.top, "Premium", 772, 136, 86, 24, 12, m.colors.textGreen, "center")

    drawSection(390, 208, "Playback", [
        { title: "Default quality", sub: "Stream resolution", value: "Auto", action: "" },
        { title: "Autoplay next", sub: "Episodes and series", value: boolText(m.autoplay), action: "autoplay" },
        { title: "Subtitles", sub: "Show when available", value: boolText(m.subtitles), action: "subtitles" }
    ], 1)

    drawSection(390, 390, "App", [
        { title: "Notifications", sub: "Channel alerts and updates", value: boolText(m.notifications), action: "notifications" },
        { title: "App language", sub: "", value: "English", action: "" },
        { title: "Parental lock", sub: "PIN protect adult content", value: boolText(m.parental), action: "parental" }
    ], 5)

    drawAccount()
    uiApplyFocus(m.top, m.focusItems, m.focusIndex)
end sub

sub addBackButton()
    item = { x: 1020, y: 20, w: 150, h: 40, icon: "BACK", label: "Back", subtitle: "", iconSize: 12, titleSize: 15, subSize: 10, bg: "0xFFFFFF10", border: "0xFFFFFF18", textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.purple, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: 0, col: 2, page: "LiveTvPage", action: "" }
    m.focusItems.push(item)
end sub

sub drawSection(x as Integer, y as Integer, title as String, rows as Object, startRow as Integer)
    uiRect(m.top, x, y, 500, 158, "0xFFFFFF10")
    uiLabel(m.top, title, x + 20, y + 10, 200, 24, 13, m.colors.textDim)
    for i = 0 to rows.count() - 1
        r = rows[i]
        yy = y + 42 + i * 42
        uiLabel(m.top, r.title, x + 20, yy, 230, 24, 15, m.colors.textPurple)
        if r.sub <> "" then uiLabel(m.top, r.sub, x + 20, yy + 20, 250, 20, 11, m.colors.textDim)
        addSettingAction(x + 350, yy, r.value, startRow + i, r.action)
    end for
end sub

sub addSettingAction(x as Integer, y as Integer, label as String, row as Integer, action as String)
    item = { x: x, y: y, w: 100, h: 34, icon: "", label: label, subtitle: "", iconSize: 1, titleSize: 13, subSize: 10, bg: m.colors.purpleSoft, border: m.colors.purpleLine, textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.green, focusTextColor: m.colors.textGreen, row: row, col: 2, page: "", action: action }
    m.focusItems.push(item)
end sub

sub drawAccount()
    uiRect(m.top, 920, 208, 250, 238, "0xFFFFFF10")
    uiLabel(m.top, "Account", 940, 220, 180, 24, 13, m.colors.textDim)
    drawAccountRow(940, 260, "SYNC", "Sync all playlists", "", 8, "")
    drawAccountRow(940, 322, "INFO", "App version", m.versionStatus, 9, "version")
    drawAccountRow(940, 384, "OUT", "Sign out", "", 10, "")
end sub

sub drawAccountRow(x as Integer, y as Integer, icon as String, label as String, value as String, row as Integer, action as String)
    item = { x: x, y: y, w: 210, h: 44, icon: icon, label: label, subtitle: value, iconSize: 12, titleSize: 13, subSize: 11, bg: m.colors.bg, border: "0xFFFFFF10", textColor: m.colors.textPurple, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text, row: row, col: 3, page: "", action: action }
    m.focusItems.push(item)
end sub

function boolText(v as Boolean) as String
    if v then return "On"
    return "Off"
end function
