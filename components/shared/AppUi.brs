function appColors() as Object
    return {
        bg: "0x090D16FF",
        bg2: "0x0D1422FF",
        panel: "0x151C2BFF",
        panelSoft: "0x1C2340FF",
        purple: "0x6258D6FF",
        purpleSoft: "0x242B57FF",
        purpleFocus: "0x7468F0FF",
        purpleDeep: "0x1A1F46FF",
        purpleActive: "0x111735FF",
        purpleBorderDark: "0x0B102BFF",
        purpleLine: "0x8E86FFFF",
        green: "0x19C6B3FF",
        greenSoft: "0x0D454BFF",
        greenDeep: "0x07353AFF",
        greenActive: "0x04282DFF",
        greenBorderDark: "0x021D22FF",
        greenFocus: "0x1EE0CAFF",
        text: "0xE8E6FFFF",
        textMuted: "0xA7B1C8FF",
        textDim: "0x758099FF",
        textPurple: "0xCECBF6FF",
        textGreen: "0xA9FFF2FF",
        red: "0xFF6B4AFF",
        amber: "0xFFBD4AFF",
        black: "0x090B0FFF",
        whiteSoft: "0xFFFFFF12",
        whiteLine: "0xFFFFFF18",
        blue: "0x2C7BE5FF"
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

sub uiRectBorder(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String, thickness = 1 as Integer, opacity = 1.0 as Float)
    uiRect(parent, x, y, w, thickness, color, opacity)
    uiRect(parent, x, y + h - thickness, w, thickness, color, opacity)
    uiRect(parent, x, y, thickness, h, color, opacity)
    uiRect(parent, x + w - thickness, y, thickness, h, color, opacity)
end sub

function uiPoster(parent as Object, uri as String, x as Integer, y as Integer, w as Integer, h as Integer, opacity = 1.0 as Float) as Object
    node = CreateObject("roSGNode", "Poster")
    node.uri = uri
    node.translation = [x, y]
    node.width = w
    node.height = h
    node.opacity = opacity
    parent.appendChild(node)
    return node
end function

function uiPosterZoom(parent as Object, uri as String, x as Integer, y as Integer, w as Integer, h as Integer, opacity = 1.0 as Float) as Object
    node = CreateObject("roSGNode", "Poster")
    node.translation = [x, y]
    node.width = w
    node.height = h
    node.opacity = opacity
    node.loadDisplayMode = "scaleToZoom"
    node.uri = uri
    parent.appendChild(node)
    return node
end function

function uiColorKey(color as String) as String
    if color = "0x090D16FF" then return "bg"
    if color = "0x0D1422FF" then return "bg2"
    if color = "0x151C2BFF" then return "panel"
    if color = "0x1C2340FF" then return "panelSoft"
    if color = "0x6258D6FF" then return "purple"
    if color = "0x242B57FF" then return "purpleSoft"
    if color = "0x7468F0FF" then return "purpleFocus"
    if color = "0x1A1F46FF" then return "purpleDeep"
    if color = "0x111735FF" then return "purpleActive"
    if color = "0x0B102BFF" then return "purpleBorderDark"
    if color = "0x8E86FFFF" then return "purpleLine"
    if color = "0x19C6B3FF" then return "green"
    if color = "0x0D454BFF" then return "greenSoft"
    if color = "0x07353AFF" then return "greenDeep"
    if color = "0x04282DFF" then return "greenActive"
    if color = "0x021D22FF" then return "greenBorderDark"
    if color = "0x1EE0CAFF" then return "greenFocus"
    if color = "0xE8E6FFFF" then return "text"
    if color = "0xA7B1C8FF" then return "textMuted"
    if color = "0x758099FF" then return "textDim"
    if color = "0xCECBF6FF" then return "textPurple"
    if color = "0xA9FFF2FF" then return "textGreen"
    if color = "0xFF6B4AFF" then return "red"
    if color = "0xFFBD4AFF" then return "amber"
    if color = "0x090B0FFF" then return "black"
    if color = "0xFFFFFF12" then return "whiteSoft"
    if color = "0xFFFFFF18" then return "whiteLine"
    if color = "0x2C7BE5FF" then return "blue"
    if color = "0xFFFFFF10" then return "white10"
    if color = "0xFFFFFF14" then return "white14"
    if color = "0x7F77DD44" then return "purple44"
    if color = "0xF09595FF" then return "rose"
    if color = "0x444441FF" then return "dimOlive"
    if color = "0x993C1DFF" then return "burnt"
    return "panel"
end function

function uiRoundUri(w as Integer, h as Integer, fill as String, border as String) as String
    widthStr = w.toStr()
    if w = 140 and h = 34 then widthStr = "100" ' Fallback for missing asset
    return "pkg:/images/ui/rr_" + widthStr + "x" + h.toStr() + "_" + uiColorKey(fill) + "_" + uiColorKey(border) + ".png"
end function

function uiThinRoundUri(w as Integer, h as Integer, fill as String, border as String) as String
    return "pkg:/images/ui/thin_" + w.toStr() + "x" + h.toStr() + "_" + uiColorKey(fill) + "_" + uiColorKey(border) + ".png"
end function

function uiRoundRect(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, fill as String, border = "" as String, opacity = 1.0 as Float) as Object
    if border = "" then border = fill
    return uiPoster(parent, uiRoundUri(w, h, fill, border), x, y, w, h, opacity)
end function

function uiThinRoundRect(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, fill as String, border = "" as String, opacity = 1.0 as Float) as Object
    if border = "" then border = fill
    return uiPoster(parent, uiThinRoundUri(w, h, fill, border), x, y, w, h, opacity)
end function

function uiLabel(parent as Object, text as String, x as Integer, y as Integer, w as Integer, h as Integer, size as Integer, color as String, align = "left" as String) as Object
    node = CreateObject("roSGNode", "Label")
    node.translation = [x, y]
    node.width = w
    desiredHeight = size + 16
    if h < desiredHeight then
        node.height = desiredHeight
    else
        node.height = h
    end if
    node.text = text
    node.color = color
    node.horizAlign = align
    node.vertAlign = "center"
    parent.appendChild(node)
    return node
end function

function uiIconUri(icon as String, focused as Boolean) as String
    key = LCase(icon)
    if focused then
        return "pkg:/images/icons/" + key + "_focus.png"
    end if
    return "pkg:/images/icons/" + key + ".png"
end function

function uiKnownIcon(icon as String) as Boolean
    known = {
        list: true, tv: true, series: true, movies: true, settings: true,
        add: true, play: true, search: true, back: true, sync: true, info: true,
        out: true, plus: true, link: true, m3u: true, x: true, profile: true,
        world: true, note: true, kids: true, sport: true, news: true,
        heart: true, bell: true,
        player_volume: true, player_play: true, player_replay: true, player_full: true, player_heart: true,
        card_add: true, card_tv: true, card_series: true, card_movies: true,
        iptv: true, cards_badge: true
    }
    return known.doesExist(LCase(icon))
end function

function uiDrawIcon(parent as Object, icon as String, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean, fallbackColor as String, fallbackSize as Integer) as Boolean
    if icon = invalid or icon = "" then return false
    normalized = icon
    if icon = "S" then normalized = "series"
    if icon = "M" then normalized = "movies"
    if icon = "GEAR" then normalized = "settings"
    if icon = "BALL" or icon = "SP" or icon = "BN" or icon = "FOOT" then normalized = "sport"
    if icon = "NEWS" or icon = "NW" or icon = "CNN" then normalized = "news"
    if uiKnownIcon(normalized) then
        poster = uiPoster(parent, uiIconUri(normalized, focused), x, y, w, h)
        if fallbackColor <> invalid and fallbackColor <> "" then
            poster.blendColor = fallbackColor
        end if
        return true
    end if
    uiLabel(parent, icon, x, y, w, h, fallbackSize, fallbackColor, "center")
    return true
end function

sub uiBadge(parent as Object, x as Integer, y as Integer, w as Integer, label as String, bg as String, fg as String)
    uiRoundRect(parent, x, y, w, 26, bg, bg)
    uiLabel(parent, label, x, y - 1, w, 26, 13, fg, "center")
end sub

function uiPosterCard(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String, text as String, textColor as String) as Object
    g = CreateObject("roSGNode", "Group")
    g.translation = [x, y]
    parent.appendChild(g)
    uiRoundRect(g, 0, 0, w, h, color, color)
    uiLabel(g, text, 0, 0, w, h, 22, textColor, "center")
    return g
end function

sub uiClear(parent as Object)
    while parent.getChildCount() > 0
        parent.removeChild(parent.getChild(0))
    end while
end sub

function uiButton(parent as Object, item as Object, focused as Boolean) as Object
    g = CreateObject("roSGNode", "Group")
    g.translation = [item.x, item.y]
    noFocusShift = false
    if item.doesExist("noFocusShift") then noFocusShift = item.noFocusShift
    if focused and not noFocusShift then
        g.translation = [item.x - 3, item.y - 3]
    end if
    parent.appendChild(g)

    bg = item.bg
    border = item.border
    textColor = item.textColor
    if focused then
        bg = item.focusBg
        border = item.focusBorder
        textColor = item.focusTextColor
    end if

    mode = ""
    if item.doesExist("mode") then mode = item.mode
    if mode = "" then
        if item.h >= 100 then
            mode = "tile"
        else
            mode = "row"
        end if
    end if
    if mode = "manual" then return g

    thin = false
    if item.doesExist("thin") then thin = item.thin
    if thin then
        uiThinRoundRect(g, 0, 0, item.w, item.h, bg, border)
    else
        uiRoundRect(g, 0, 0, item.w, item.h, bg, border)
    end if
    if mode = "blank" then return g

    if mode = "tile" then
        uiDrawIcon(g, item.icon, Int((item.w - 58) / 2), 18, 58, 58, focused, textColor, item.iconSize)
        tileTitleY = 92
        tileTitleH = 42
        if item.subtitle <> invalid and item.subtitle <> "" then
            tileTitleY = 82
            tileTitleH = 30
        end if
        uiLabel(g, item.label, 20, tileTitleY, item.w - 40, tileTitleH, item.titleSize, textColor, "center")
        if item.subtitle <> invalid and item.subtitle <> "" then
            uiLabel(g, item.subtitle, 20, 112, item.w - 40, 24, item.subSize, item.subColor, "center")
        end if
    else
        labelX = 62
        labelW = item.w - labelX - 14
        labelAlign = "left"
        if item.icon = invalid or item.icon = "" then
            labelX = 0
            labelW = item.w
            labelAlign = "center"
        else
            iconW = 24
            iconH = 24
            iconX = 22
            if item.doesExist("iconW") then iconW = item.iconW
            if item.doesExist("iconH") then iconH = item.iconH
            if item.doesExist("iconX") then iconX = item.iconX
            if item.doesExist("labelX") then labelX = item.labelX
            if item.doesExist("labelW") then labelW = item.labelW
            if item.doesExist("labelAlign") then labelAlign = item.labelAlign
            uiDrawIcon(g, item.icon, iconX, Int((item.h - iconH) / 2), iconW, iconH, focused, textColor, item.iconSize)
        end if
        if item.doesExist("labelX") then labelX = item.labelX
        if item.doesExist("labelW") then labelW = item.labelW
        if item.doesExist("labelAlign") then labelAlign = item.labelAlign

        titleY = 9
        titleH = item.h - 18
        if item.subtitle <> invalid and item.subtitle <> "" then
            titleY = 3
            titleH = 28
        end if
        uiLabel(g, item.label, labelX, titleY, labelW, titleH, item.titleSize, textColor, labelAlign)
        if item.subtitle <> invalid and item.subtitle <> "" then
            uiLabel(g, item.subtitle, labelX, 28, labelW, 24, item.subSize, item.subColor, labelAlign)
        end if
    end if
    return g
end function

function uiTopBar(parent as Object, colors as Object) as Object
    uiRect(parent, 0, 0, 1280, 86, colors.bg)
    uiRect(parent, 0, 85, 1280, 1, "0xFFFFFF14")
    uiPoster(parent, "pkg:/images/logo_full_dark_modified.png", 28, 10, 205, 64)
    clock = uiLabel(parent, "--:--", 1115, 12, 130, 32, 25, colors.text, "right")
    date = uiLabel(parent, "---", 1052, 48, 193, 24, 14, colors.textMuted, "right")
    return { clock: clock, date: date }
end function

function uiSideNav(parent as Object, colors as Object, activeKey as String, focusItems as Object, startRow as Integer) as Integer
    uiRect(parent, 0, 86, 226, 634, colors.purpleSoft, 0.45)
    uiRect(parent, 225, 86, 1, 634, "0xFFFFFF12")

    items = appNavItems(activeKey)
    row = startRow
    y = 100
    for each nav in items
        item = {
            x: 14, y: y, w: 206, h: 50,
            icon: nav.icon, label: nav.label, subtitle: "",
            iconSize: 13, titleSize: 15, subSize: 10,
            bg: colors.bg, border: colors.bg, textColor: colors.textGreen, subColor: colors.textDim,
            focusBg: colors.purpleSoft, focusBorder: colors.purpleLine, focusTextColor: colors.textPurple,
            row: row, col: 0, page: nav.page, mode: "row"
        }
        if nav.active then
            item.bg = colors.purpleSoft
            item.border = colors.purpleLine
            item.textColor = colors.textPurple
        end if
        item.node = uiButton(parent, item, false)
        focusItems.push(item)
        y += 58
        row += 1
    end for

    uiRoundRect(parent, 16, 630, 204, 60, "0xFFFFFF10", "0xFFFFFF10")
    uiRoundRect(parent, 26, 643, 34, 34, colors.purple, colors.purple)
    uiDrawIcon(parent, "profile", 33, 650, 20, 20, true, colors.text, 13)
    uiLabel(parent, "My Profile", 70, 636, 126, 24, 14, colors.textPurple)
    uiLabel(parent, "Premium", 70, 660, 106, 20, 12, colors.textDim)
    return row
end function

sub uiApplyFocus(parent as Object, focusItems as Object, focusIndex as Integer)
    for i = 0 to focusItems.count() - 1
        item = focusItems[i]
        mode = ""
        if item.doesExist("mode") then mode = item.mode
        if mode <> "manual" then
            if item.doesExist("node") and item.node <> invalid then parent.removeChild(item.node)
            item.node = uiButton(parent, item, i = focusIndex)
        end if
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
