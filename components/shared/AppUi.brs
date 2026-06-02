function appColors() as Object
    return {
        bg: "0x0E1117FF",
        bg2: "0x121722FF",
        panel: "0x171B25FF",
        panelSoft: "0x211D3DFF",
        purple: "0x534AB7FF",
        purpleSoft: "0x2B2755FF",
        purpleFocus: "0x6D62D9FF",
        purpleLine: "0x7F77DDFF",
        green: "0x1D9E75FF",
        greenSoft: "0x12372FFF",
        greenFocus: "0x21B989FF",
        text: "0xE8E6FFFF",
        textMuted: "0x888780FF",
        textDim: "0x5F5E5AFF",
        textPurple: "0xCECBF6FF",
        textGreen: "0x9FE1CBFF",
        red: "0xD85A30FF",
        amber: "0xEF9F27FF",
        black: "0x090B0FFF",
        whiteSoft: "0xFFFFFF12"
    }
end function

function appPageMap() as Object
    return {
        home: "HomePage",
        add: "AddPlaylistPage",
        playlists: "MyPlaylistsPage",
        live: "LiveTvPage",
        series: "SeriesPage",
        movies: "MoviesPage",
        settings: "SettingsPage"
    }
end function

function appNavItems(activeKey as String) as Object
    return [
        { key: "playlists", label: "My Playlists", icon: "LIST", page: "MyPlaylistsPage", active: activeKey = "playlists" },
        { key: "live", label: "Live TV", icon: "TV", page: "LiveTvPage", active: activeKey = "live" },
        { key: "series", label: "Series", icon: "S", page: "SeriesPage", active: activeKey = "series" },
        { key: "movies", label: "Movies", icon: "M", page: "MoviesPage", active: activeKey = "movies" },
        { key: "settings", label: "Settings", icon: "GEAR", page: "SettingsPage", active: activeKey = "settings" }
    ]
end function

function uiRect(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String, opacity = 1.0 as Float) as Object
    node = CreateObject("roSGNode", "Rectangle")
    node.translation = [x, y]
    node.width = w
    node.height = h
    node.color = color
    node.opacity = opacity
    parent.appendChild(node)
    return node
end function

function uiLabel(parent as Object, text as String, x as Integer, y as Integer, w as Integer, h as Integer, size as Integer, color as String, align = "left" as String) as Object
    node = CreateObject("roSGNode", "Label")
    node.translation = [x, y]
    node.width = w
    node.height = h
    node.text = text
    node.color = color
    font = CreateObject("roSGNode", "Font")
    font.uri = "font:MediumSystemFont"
    font.size = size
    node.font = font
    node.horizAlign = align
    node.vertAlign = "center"
    parent.appendChild(node)
    return node
end function

function uiPoster(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String, text as String, textColor as String) as Object
    g = CreateObject("roSGNode", "Group")
    g.translation = [x, y]
    parent.appendChild(g)
    uiRect(g, 0, 0, w, h, color)
    uiLabel(g, text, 0, 0, w, h, 22, textColor, "center")
    return g
end function

function uiButton(parent as Object, item as Object, focused as Boolean) as Object
    g = CreateObject("roSGNode", "Group")
    g.translation = [item.x, item.y]
    parent.appendChild(g)

    bg = item.bg
    border = item.border
    textColor = item.textColor
    if focused then
        bg = item.focusBg
        border = item.focusBorder
        textColor = item.focusTextColor
    end if

    uiRect(g, 0, 0, item.w, item.h, border)
    uiRect(g, 2, 2, item.w - 4, item.h - 4, bg)

    labelX = 74
    labelW = item.w - 88
    labelAlign = "left"
    if item.icon = invalid or item.icon = "" then
        labelX = 0
        labelW = item.w
        labelAlign = "center"
    else
        uiLabel(g, item.icon, 14, 0, 56, item.h, item.iconSize, textColor, "center")
    end if

    uiLabel(g, item.label, labelX, 10, labelW, 26, item.titleSize, textColor, labelAlign)
    if item.subtitle <> invalid and item.subtitle <> "" then
        uiLabel(g, item.subtitle, labelX, 38, labelW, 22, item.subSize, item.subColor, labelAlign)
    end if
    return g
end function

function uiTopBar(parent as Object, colors as Object) as Object
    uiRect(parent, 0, 0, 1280, 72, colors.bg)
    uiRect(parent, 0, 71, 1280, 1, "0xFFFFFF14")
    uiRect(parent, 28, 18, 38, 38, colors.purple)
    uiLabel(parent, "PLAY", 30, 18, 34, 38, 11, colors.text, "center")
    uiLabel(parent, "IPTV", 78, 15, 78, 38, 24, colors.textPurple)
    uiLabel(parent, "Max", 142, 15, 70, 38, 24, colors.textGreen)
    uiRect(parent, 1128, 23, 9, 9, colors.red)
    clock = uiLabel(parent, "--:--", 1115, 10, 130, 30, 22, colors.text, "right")
    date = uiLabel(parent, "---", 1052, 38, 193, 22, 14, colors.textMuted, "right")
    return { clock: clock, date: date }
end function

function uiSideNav(parent as Object, colors as Object, activeKey as String, focusItems as Object, startRow as Integer) as Integer
    uiRect(parent, 0, 72, 188, 648, colors.purpleSoft, 0.55)
    uiRect(parent, 187, 72, 1, 648, "0xFFFFFF12")

    items = appNavItems(activeKey)
    row = startRow
    y = 100
    for each nav in items
        item = {
            x: 16, y: y, w: 156, h: 48,
            icon: nav.icon, label: nav.label, subtitle: "",
            iconSize: 14, titleSize: 15, subSize: 10,
            bg: colors.bg, border: colors.bg, textColor: colors.textGreen, subColor: colors.textDim,
            focusBg: colors.purpleSoft, focusBorder: colors.purpleLine, focusTextColor: colors.textPurple,
            row: row, col: 0, page: nav.page
        }
        if nav.active then
            item.bg = colors.purpleSoft
            item.border = colors.purpleLine
            item.textColor = colors.textPurple
        end if
        item.node = uiButton(parent, item, false)
        focusItems.push(item)
        y += 56
        row += 1
    end for

    uiRect(parent, 16, 630, 156, 60, "0xFFFFFF10")
    uiRect(parent, 26, 643, 34, 34, colors.purple)
    uiLabel(parent, "JD", 26, 643, 34, 34, 13, colors.text, "center")
    uiLabel(parent, "My Profile", 70, 636, 100, 24, 14, colors.textPurple)
    uiLabel(parent, "Premium", 70, 660, 80, 20, 12, colors.textDim)
    return row
end function

sub uiApplyFocus(parent as Object, focusItems as Object, focusIndex as Integer)
    for i = 0 to focusItems.count() - 1
        item = focusItems[i]
        if item.doesExist("node") and item.node <> invalid then parent.removeChild(item.node)
        item.node = uiButton(parent, item, i = focusIndex)
    end for
end sub

function uiMoveFocus(focusItems as Object, focusIndex as Integer, dx as Integer, dy as Integer) as Integer
    if focusItems.count() = 0 then return 0
    current = focusItems[focusIndex]
    best = focusIndex
    bestScore = 999999

    for i = 0 to focusItems.count() - 1
        candidate = focusItems[i]
        if i <> focusIndex then
            rowDelta = candidate.row - current.row
            colDelta = candidate.col - current.col
            valid = false
            if dx < 0 and colDelta < 0 then valid = true
            if dx > 0 and colDelta > 0 then valid = true
            if dy < 0 and rowDelta < 0 then valid = true
            if dy > 0 and rowDelta > 0 then valid = true
            if valid then
                score = Abs(rowDelta) * 100 + Abs(colDelta)
                if dx <> 0 then score = Abs(colDelta) * 100 + Abs(rowDelta)
                if score < bestScore then
                    bestScore = score
                    best = i
                end if
            end if
        end if
    end for

    return best
end function

function uiNowStrings() as Object
    dt = CreateObject("roDateTime")
    dt.toLocalTime()
    hours = dt.getHours().toStr()
    minutes = dt.getMinutes().toStr()
    if hours.len() = 1 then hours = "0" + hours
    if minutes.len() = 1 then minutes = "0" + minutes
    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return {
        time: hours + ":" + minutes,
        date: days[dt.getDayOfWeek()] + ", " + months[dt.getMonth() - 1] + " " + dt.getDayOfMonth().toStr()
    }
end function
