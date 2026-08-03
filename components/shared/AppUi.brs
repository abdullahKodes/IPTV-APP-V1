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
        favorites: "FavoritesPage",
        settings: "SettingsPage",
        profile: "ProfilePage"
    }
end function

function appNavItems(activeKey as String) as Object
    return [
        { key: "playlists", label: "My Playlists", icon: "LIST", page: "MyPlaylistsPage", active: activeKey = "playlists" },
        { key: "live", label: "Live TV", icon: "TV", page: "LiveTvPage", active: activeKey = "live" },
        { key: "series", label: "Series", icon: "S", page: "SeriesPage", active: activeKey = "series" },
        { key: "movies", label: "Movies", icon: "M", page: "MoviesPage", active: activeKey = "movies" },
        { key: "favorites", label: "Favorites", icon: "heart", page: "FavoritesPage", active: activeKey = "favorites" },
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

sub uiVerticalPill(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String, capUri as String, opacity = 1.0 as Float)
    if h <= w then
        uiPoster(parent, capUri, x, y, w, h, opacity)
        return
    end if
    radius = Int(w / 2)
    uiPoster(parent, capUri, x, y, w, w, opacity)
    uiRect(parent, x, y + radius, w, h - w, color, opacity)
    uiPoster(parent, capUri, x, y + h - w, w, w, opacity)
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

function uiCategoryPillUri(w as Integer, selected as Boolean, focused as Boolean) as String
    state = "base"
    if selected then state = "selected"
    if focused then state = "focus"
    return "pkg:/images/ui/category_pill_" + uiCategoryPillAssetWidth(w) + "x34_" + state + ".png"
end function

function uiCategoryPillAssetWidth(w as Integer) as String
    if w <= 70 then return "70"
    if w <= 82 then return "82"
    if w <= 96 then return "96"
    if w <= 116 then return "116"
    return "172"
end function

function uiSidebarPillUri(fill as String, border as String) as String
    return "pkg:/images/ui/sidebar_pill_204x52_" + uiColorKey(fill) + "_" + uiColorKey(border) + ".png"
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

function uiSearchPill(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean, opacity = 0.52 as Float) as Object
    uri = "pkg:/images/ui/search_pill_260x40_panel_whiteLine.png"
    if focused then uri = "pkg:/images/ui/search_pill_260x40_purpleSoft_greenFocus.png"
    return uiPoster(parent, uri, x, y, w, h, opacity)
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

function uiScaledLabel(parent as Object, text as String, x as Integer, y as Integer, w as Integer, h as Integer, size as Integer, color as String, align = "left" as String, scale = 0.8 as Float) as Object
    node = uiLabel(parent, text, x, y, Int(w / scale), Int(h / scale), size, color, align)
    node.scale = [scale, scale]
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
        home: true, list: true, tv: true, series: true, movies: true, settings: true,
        add: true, play: true, search: true, back: true, sync: true, info: true, cache: true,
        sync_account: true, cache_account: true, logout_account: true,
        out: true, plus: true, link: true, m3u: true, x: true, profile: true,
        world: true, note: true, captions: true, kids: true, clock: true, sport: true, news: true,
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

function uiKeyboardKeyWidth(keyId as String) as Integer
    if keyId = "SPACE" then return 150
    if keyId = "CLEAR" then return 112
    if keyId = "DONE" then return 112
    if keyId = "DEL" then return 92
    if keyId = "CASE" then return 92
    return 70
end function

function uiKeyboardIsLetter(keyId as String) as Boolean
    if keyId = invalid or keyId.len() <> 1 then return false
    return Instr(1, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", keyId) > 0
end function

function uiKeyboardDisplayText(keyId as String, upper as Boolean) as String
    if keyId = "SPACE" then return ""
    if keyId = "DEL" then return "Del"
    if keyId = "CLEAR" then return "Clear"
    if keyId = "DONE" then return "Done"
    if keyId = "CASE" then
        if upper then return "abc"
        return "ABC"
    end if
    if not upper and uiKeyboardIsLetter(keyId) then return LCase(keyId)
    return keyId
end function

function uiKeyboardInputText(keyId as String, upper as Boolean) as String
    if not upper and uiKeyboardIsLetter(keyId) then return LCase(keyId)
    return keyId
end function

function uiKeyboardKeyRect(keys as Object, index as Integer, startX as Integer, startY as Integer, baseW as Integer, keyH as Integer, gap as Integer) as Object
    row = Int(index / 10)
    y = startY + row * (keyH + gap)
    if row < 4 then
        col = index mod 10
        return { x: startX + col * (baseW + gap), y: y, w: baseW, h: keyH }
    end if

    rowStart = row * 10
    rowEnd = rowStart + 9
    if rowEnd > keys.count() - 1 then rowEnd = keys.count() - 1

    totalW = 0
    for i = rowStart to rowEnd
        totalW += uiKeyboardKeyWidth(keys[i])
        if i < rowEnd then totalW += gap
    end for

    fullRowW = 10 * baseW + 9 * gap
    x = startX + Int((fullRowW - totalW) / 2)
    for i = rowStart to index - 1
        x += uiKeyboardKeyWidth(keys[i]) + gap
    end for
    return { x: x, y: y, w: uiKeyboardKeyWidth(keys[index]), h: keyH }
end function

function uiKeyboardMoveIndex(keys as Object, currentIndex as Integer, key as String, cols as Integer) as Integer
    if keys = invalid or keys.count() = 0 then return 0
    keyCount = keys.count()
    if currentIndex < 0 then currentIndex = 0
    if currentIndex >= keyCount then currentIndex = keyCount - 1

    if key = "left" and currentIndex > 0 then return currentIndex - 1
    if key = "right" and currentIndex < keyCount - 1 then return currentIndex + 1
    if key = "up" then
        returnIndex = uiKeyboardStoredReturnIndex(currentIndex)
        if returnIndex >= 0 and returnIndex < keyCount then return returnIndex
        return uiKeyboardVerticalMoveIndex(keys, keyCount, currentIndex, cols, -1)
    end if
    if key = "down" then
        nextIndex = uiKeyboardVerticalMoveIndex(keys, keyCount, currentIndex, cols, 1)
        if nextIndex <> currentIndex and uiKeyboardIsShortBottomRowIndex(keyCount, nextIndex, cols) then uiKeyboardStoreReturnIndex(nextIndex, currentIndex)
        return nextIndex
    end if
    return currentIndex
end function

function uiKeyboardVerticalMoveIndex(keys as Object, keyCount as Integer, currentIndex as Integer, cols as Integer, rowDelta as Integer) as Integer
    if cols <= 0 then return currentIndex
    currentRow = Int(currentIndex / cols)
    currentCol = currentIndex MOD cols
    targetRow = currentRow + rowDelta
    if targetRow < 0 then return currentIndex

    first = targetRow * cols
    if first >= keyCount then return currentIndex

    last = first + cols - 1
    if last >= keyCount then last = keyCount - 1

    if rowDelta > 0 and last = keyCount - 1 and last - first + 1 < cols then
        actionTarget = uiKeyboardBottomActionTargetIndex(keys, currentIndex, first, last)
        if actionTarget >= 0 then return actionTarget
    end if

    target = first + currentCol
    if target > last then target = last
    return target
end function

function uiKeyboardBottomActionTargetIndex(keys as Object, currentIndex as Integer, first as Integer, last as Integer) as Integer
    if keys = invalid then return -1
    if currentIndex < 0 or currentIndex >= keys.count() then return -1

    label = UCase(keys[currentIndex])
    if label = "V" or label = "B" then return uiKeyboardFindKeyInRange(keys, "SPACE", first, last)
    if label = "N" or label = "M" then return uiKeyboardFindKeyInRange(keys, "DEL", first, last)
    if label = "/" or label = "," then return uiKeyboardFindKeyInRange(keys, "CLEAR", first, last)
    if label = ":" or label = "-" or label = "?" or label = "!" then return uiKeyboardFindKeyInRange(keys, "DONE", first, last)
    return -1
end function

function uiKeyboardFindKeyInRange(keys as Object, targetLabel as String, first as Integer, last as Integer) as Integer
    if keys = invalid then return -1
    for i = first to last
        if UCase(keys[i]) = targetLabel then return i
    end for
    return -1
end function

function uiKeyboardIsShortBottomRowIndex(keyCount as Integer, index as Integer, cols as Integer) as Boolean
    if cols <= 0 or keyCount <= 0 then return false
    bottomFirst = Int((keyCount - 1) / cols) * cols
    if keyCount - bottomFirst >= cols then return false
    return index >= bottomFirst and index < keyCount
end function

sub uiKeyboardStoreReturnIndex(targetIndex as Integer, sourceIndex as Integer)
    if m = invalid then return
    m.uiKeyboardReturnTargetIndex = targetIndex
    m.uiKeyboardReturnSourceIndex = sourceIndex
end sub

function uiKeyboardStoredReturnIndex(currentIndex as Integer) as Integer
    if m = invalid then return -1
    if not m.doesExist("uiKeyboardReturnTargetIndex") then return -1
    if not m.doesExist("uiKeyboardReturnSourceIndex") then return -1
    if m.uiKeyboardReturnTargetIndex <> currentIndex then return -1
    return m.uiKeyboardReturnSourceIndex
end function

sub uiDrawKeyboardKey(parent as Object, keyId as String, displayText as String, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean, colors as Object)
    bgUri = "pkg:/images/ui/rr_70x36_panel_whiteLine.png"
    if focused then bgUri = "pkg:/images/ui/rr_70x36_purpleSoft_greenFocus.png"
    if w = 92 then
        bgUri = "pkg:/images/ui/rr_92x36_panel_whiteLine.png"
        if focused then bgUri = "pkg:/images/ui/rr_92x36_purpleSoft_greenFocus.png"
    else if w = 112 then
        bgUri = "pkg:/images/ui/rr_112x36_panel_whiteLine.png"
        if focused then bgUri = "pkg:/images/ui/rr_112x36_purpleSoft_greenFocus.png"
    else if w = 150 then
        bgUri = "pkg:/images/ui/rr_150x40_panel_whiteLine.png"
        if focused then bgUri = "pkg:/images/ui/rr_150x40_purpleSoft_greenFocus.png"
    end if
    uiPoster(parent, bgUri, x, y, w, h, 0.92)

    if keyId = "SPACE" then
        iconW = 58
        iconX = x + Int((w - iconW) / 2)
        iconY = y + Int(h / 2) + 1
        uiRect(parent, iconX, iconY, iconW, 3, colors.text, 0.92)
        uiRect(parent, iconX, iconY - 6, 3, 9, colors.text, 0.92)
        uiRect(parent, iconX + iconW - 3, iconY - 6, 3, 9, colors.text, 0.92)
        return
    end if

    label = displayText
    if label = "DEL" then label = "Del"
    if label = "CLEAR" then label = "Clear"
    if label = "DONE" then label = "Done"
    textSize = 12
    if keyId = "CLEAR" or keyId = "DONE" or keyId = "DEL" or keyId = "CASE" then textSize = 11
    uiLabel(parent, label, x, y + 5, w, h - 8, textSize, colors.text, "center")
end sub

sub uiDrawPinKeyboardKey(parent as Object, keyId as String, displayText as String, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean, colors as Object)
    if keyId <> "DEL" and keyId <> "DONE" then
        uiDrawKeyboardKey(parent, keyId, displayText, x, y, w, h, focused, colors)
        return
    end if

    bgUri = "pkg:/images/ui/rr_70x36_panel_whiteLine.png"
    if focused then bgUri = "pkg:/images/ui/rr_70x36_purpleSoft_greenFocus.png"

    textColor = colors.amber
    if keyId = "DONE" then textColor = colors.textGreen

    uiPoster(parent, bgUri, x, y, w, h, 0.92)
    uiLabel(parent, displayText, x, y + 5, w, h - 8, 11, textColor, "center")
end sub

sub uiCardFocusTint(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean)
    if not focused then return
    uiRect(parent, x + 1, y + 1, w - 2, h - 2, "0x1EE0CAFF", 0.08)
end sub

sub uiAnimateCardFocus(parent as Object, cardCanvas as Object, x as Integer, y as Integer)
    animation = CreateObject("roSGNode", "Animation")
    animation.duration = 0.14
    animation.easeFunction = "outQuad"

    scaleAnimation = animation.createChild("Vector2DFieldInterpolator")
    scaleAnimation.key = [0.0, 1.0]
    scaleAnimation.keyValue = [[1.0, 1.0], [1.025, 1.025]]
    scaleAnimation.fieldToInterp = cardCanvas.id + ".scale"

    positionAnimation = animation.createChild("Vector2DFieldInterpolator")
    positionAnimation.key = [0.0, 1.0]
    positionAnimation.keyValue = [[x, y], [x - 2, y - 3]]
    positionAnimation.fieldToInterp = cardCanvas.id + ".translation"

    parent.appendChild(animation)
    animation.control = "start"
end sub

sub uiAnimatePanelFocus(parent as Object, panelCanvas as Object)
    animation = CreateObject("roSGNode", "Animation")
    animation.duration = 0.12
    animation.easeFunction = "outQuad"

    scaleAnimation = animation.createChild("Vector2DFieldInterpolator")
    scaleAnimation.key = [0.0, 1.0]
    scaleAnimation.keyValue = [[1.0, 1.0], [1.015, 1.015]]
    scaleAnimation.fieldToInterp = panelCanvas.id + ".scale"

    parent.appendChild(animation)
    animation.control = "start"
end sub

sub uiAnimateActionFocus(parent as Object, actionCanvas as Object)
    animation = CreateObject("roSGNode", "Animation")
    animation.duration = 0.14
    animation.easeFunction = "outQuad"

    scaleAnimation = animation.createChild("Vector2DFieldInterpolator")
    scaleAnimation.key = [0.0, 1.0]
    scaleAnimation.keyValue = [[1.0, 1.0], [1.02, 1.02]]
    scaleAnimation.fieldToInterp = actionCanvas.id + ".scale"

    parent.appendChild(animation)
    animation.control = "start"
end sub

sub uiContentLoader(parent as Object, colors as Object, title as String)
    loader = CreateObject("roSGNode", "Group")
    loader.id = "contentLoader"
    loader.translation = [244, 316]
    parent.appendChild(loader)

    uiRoundRect(loader, 0, 0, 860, 92, colors.panel, colors.whiteLine, 0.24)
    uiLabel(loader, title, 0, 10, 860, 34, 18, colors.text, "center")
    uiRect(loader, 56, 56, 748, 2, colors.greenFocus, 0.20)

    sweep = uiRect(loader, 56, 56, 118, 2, colors.greenFocus, 0.86)
    sweep.id = "contentLoaderSweep"

    sweepAnimation = CreateObject("roSGNode", "Animation")
    sweepAnimation.duration = 1.6
    sweepAnimation.easeFunction = "inOutQuad"
    sweepAnimation.repeat = true
    sweepMove = sweepAnimation.createChild("Vector2DFieldInterpolator")
    sweepMove.key = [0.0, 0.5, 1.0]
    sweepMove.keyValue = [[56, 56], [686, 56], [56, 56]]
    sweepMove.fieldToInterp = "contentLoaderSweep.translation"
    parent.appendChild(sweepAnimation)
    sweepAnimation.control = "start"
end sub

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
    opacity = 1.0
    if item.doesExist("opacity") then opacity = item.opacity
    if focused then
        bg = item.focusBg
        border = item.focusBorder
        textColor = item.focusTextColor
        if item.doesExist("focusOpacity") then opacity = item.focusOpacity
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
    artUri = ""
    if item.doesExist("artUri") then artUri = item.artUri
    if focused and item.doesExist("artFocusUri") then artUri = item.artFocusUri
    if artUri <> "" then
        uiPoster(g, artUri, 0, 0, item.w, item.h, opacity)
        if focused and item.doesExist("artFocusOverlayUri") then
            uiPoster(g, item.artFocusOverlayUri, 0, 0, item.w, item.h, opacity)
        end if
    else if item.doesExist("pillStyle") and item.pillStyle = "sidebar" then
        uiPoster(g, uiSidebarPillUri(bg, border), 0, 0, item.w, item.h, opacity)
    else if thin then
        uiThinRoundRect(g, 0, 0, item.w, item.h, bg, border, opacity)
    else
        uiRoundRect(g, 0, 0, item.w, item.h, bg, border, opacity)
    end if
    if mode = "blank" then return g

    if mode = "tile" then
        uiDrawIcon(g, item.icon, Int((item.w - 58) / 2), 18, 58, 58, focused, textColor, item.iconSize)
        tileTitleY = 92
        tileTitleH = 42
        if artUri <> "" and (item.icon = invalid or item.icon = "") then
            tileTitleY = 106
            tileTitleH = 36
        end if
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
    uiRect(parent, 0, 0, 1280, 86, colors.bg, 0.52)
    uiRect(parent, 0, 85, 1280, 1, "0xFFFFFF14", 0.48)
    uiPoster(parent, "pkg:/images/logo_full_dark_modified.png", 26, 13, 206, 64)
    clock = uiLabel(parent, "--:--", 1115, 12, 130, 32, 25, colors.text, "right")
    date = uiLabel(parent, "---", 994, 48, 251, 24, 13, colors.textMuted, "right")
    if not uiShowClockSetting() then
        clock.opacity = 0
        date.opacity = 0
    end if
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
            bg: colors.bg, border: colors.whiteLine, textColor: colors.textPurple, subColor: colors.textDim,
            focusBg: colors.greenSoft, focusBorder: colors.greenFocus, focusTextColor: colors.text,
            opacity: 0.42, focusOpacity: 0.66,
            row: row, col: 0, page: nav.page, mode: "row", pillStyle: "sidebar", noFocusShift: true
        }
        if nav.active then
            item.bg = colors.purpleSoft
            item.border = colors.greenFocus
            item.textColor = colors.text
            item.opacity = 0.58
        end if
        item.node = uiButton(parent, item, false)
        focusItems.push(item)
        y += 59
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
    if focusIndex < 0 then focusIndex = 0
    if focusIndex >= focusItems.count() then focusIndex = focusItems.count() - 1
    current = focusItems[focusIndex]
    if current = invalid then return 0
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
    rawHours = dt.getHours()
    hours = rawHours.toStr()
    minutes = dt.getMinutes().toStr()
    suffix = ""
    if uiClockFormatSetting() = "12-hour" then
        if rawHours >= 12 then
            suffix = " PM"
        else
            suffix = " AM"
        end if
        displayHours = rawHours MOD 12
        if displayHours = 0 then displayHours = 12
        hours = displayHours.toStr()
    else if hours.len() = 1 then
        hours = "0" + hours
    end if
    if minutes.len() = 1 then minutes = "0" + minutes
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    return {
        time: hours + ":" + minutes + suffix,
        date: days[dt.getDayOfWeek()] + ", " + months[dt.getMonth() - 1] + " " + dt.getDayOfMonth().toStr()
    }
end function

function uiClockFormatSetting() as String
    section = CreateObject("roRegistrySection", "iptvmax_settings")
    if section <> invalid and section.Exists("clockFormat") then
        value = section.Read("clockFormat")
        if value <> invalid and value <> "" then return value
    end if
    return "24-hour"
end function

function uiShowClockSetting() as Boolean
    section = CreateObject("roRegistrySection", "iptvmax_settings")
    if section <> invalid and section.Exists("showClock") then
        value = LCase(section.Read("showClock"))
        if value = "0" or value = "false" or value = "no" then return false
    end if
    return true
end function
