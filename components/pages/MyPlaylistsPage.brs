sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("myPlaylistsCanvas")
    m.focusItems = []
    m.focusIndex = 8
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    m.playlists = playlistStoreList()
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
    if m.searchEditing then return handleSearchKeyboardKey(key)
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
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "search" then openSearchKeyboard() : return
    if item.action = "playlist" then m.top.navigateTo = "LiveTvPage" : return
    if item.action = "refresh" then
        playlistStoreRefresh(item.playlistId)
        m.playlists = playlistStoreList()
        render()
        return
    end if
    if item.action = "delete" then
        playlistStoreDelete(item.playlistId)
        m.playlists = playlistStoreList()
        normalizePlaylistFocus(filteredPlaylists().count())
        render()
        return
    end if
end sub

sub render()
    visible = filteredPlaylists()
    normalizePlaylistFocus(visible.count())

    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    drawBadgeBackdrop()

    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = uiSideNav(m.canvas, m.colors, "playlists", m.focusItems, 0)

    drawPageHeader(row)

    if visible.count() = 0 then
        drawEmptyState()
    else
        drawPlaylistGrid(visible, row)
    end if

    drawFooterSummary()
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

sub normalizePlaylistFocus(visibleCount as Integer)
    maxIndex = 7
    if visibleCount > 0 then maxIndex = 7 + visibleCount * 3
    if m.focusIndex > maxIndex then m.focusIndex = maxIndex
    if m.focusIndex < 0 then m.focusIndex = 0
end sub

sub drawBadgeBackdrop()
    badges = [
        "pkg:/images/logos/live/badges/espn_badge.png",
        "pkg:/images/logos/live/badges/bbc_news_badge.png",
        "pkg:/images/logos/live/badges/cnn_badge.png",
        "pkg:/images/logos/live/badges/bein_sports_badge.png",
        "pkg:/images/logos/live/badges/mtv_hits_badge.png",
        "pkg:/images/logos/live/badges/cartoon_network_badge.png",
        "pkg:/images/logos/live/badges/discovery_badge.png",
        "pkg:/images/logos/live/badges/movie_channel_badge.png"
    ]
    positions = [
        { x: 264, y: 116, w: 150, h: 82 },
        { x: 454, y: 514, w: 150, h: 82 },
        { x: 760, y: 120, w: 148, h: 82 },
        { x: 1050, y: 514, w: 150, h: 82 },
        { x: 330, y: 348, w: 128, h: 70 },
        { x: 636, y: 344, w: 128, h: 70 },
        { x: 940, y: 344, w: 128, h: 70 },
        { x: 1096, y: 170, w: 118, h: 64 }
    ]
    for i = 0 to badges.count() - 1
        uiPoster(m.canvas, badges[i], positions[i].x, positions[i].y, positions[i].w, positions[i].h, 0.12)
    end for
    uiRect(m.canvas, 226, 86, 1054, 634, m.colors.bg, 0.86)
end sub

sub drawPageHeader(row as Integer)
    summary = playlistSummary(m.playlists)
    uiLabel(m.canvas, "MY PLAYLISTS", 258, 112, 260, 26, 14, m.colors.textDim)
    uiLabel(m.canvas, summary.countText + " - " + summary.totalText, 258, 138, 430, 28, 15, m.colors.purpleLine)

    addHeaderAction(940, 108, 210, 44, "plus", "Add Playlist", row, 3, "AddPlaylistPage", "")
    addSearchAction(940, 162, 210, 44, row + 1, 3)
end sub

sub addHeaderAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer, page as String, action as String)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    bg = m.colors.purple
    border = m.colors.purple
    textColor = m.colors.text
    if focused then
        bg = m.colors.greenFocus
        border = m.colors.text
    end if
    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiDrawIcon(m.canvas, icon, x + 22, y + 12, 20, 20, focused, textColor, 12)
    uiLabel(m.canvas, label, x + 52, y + 6, w - 64, 30, 15, textColor)
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 12, titleSize: 15, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, page: page, action: action, mode: "manual" })
end sub

sub addSearchAction(x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    label = "Search"
    if m.searchQuery <> "" then label = m.searchQuery
    bg = "0xFFFFFF10"
    border = m.colors.whiteLine
    textColor = m.colors.textDim
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.purpleLine
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiDrawIcon(m.canvas, "search", x + 22, y + 13, 18, 18, focused, textColor, 11)
    uiLabel(m.canvas, label, x + 52, y + 7, w - 66, 30, 14, textColor)
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: "search", label: label, subtitle: "", iconSize: 11, titleSize: 14, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "search", mode: "manual" })
end sub

sub drawPlaylistGrid(visible as Object, rowStart as Integer)
    x0 = 258
    y0 = 218
    cardW = 300
    cardH = 138
    gapX = 32
    gapY = 54
    for i = 0 to visible.count() - 1
        row = Int(i / 3)
        col = i mod 3
        if row < 2 then
            data = visible[i]
            drawPlaylistCard(data.playlist, x0 + col * (cardW + gapX), y0 + row * (cardH + gapY), cardW, cardH, rowStart + 2 + row * 3, 1 + col * 3)
        end if
    end for
end sub

sub drawPlaylistCard(p as Object, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    cardFocused = itemIndex = m.focusIndex
    accent = playlistStoreText(p, "accent", "purple")
    fill = m.colors.panel
    border = m.colors.purpleLine
    titleColor = m.colors.text
    iconFill = m.colors.purpleSoft
    iconBorder = m.colors.purpleLine
    if accent = "green" then
        border = m.colors.panel
        iconFill = m.colors.greenSoft
        iconBorder = m.colors.green
    end if
    if cardFocused then
        fill = m.colors.purpleSoft
        border = m.colors.purpleLine
        if accent = "green" then fill = m.colors.greenSoft : border = m.colors.green
    end if

    uiRoundRect(m.canvas, x, y, w, h, fill, border)
    if accent = "green" and not cardFocused then uiRectBorder(m.canvas, x, y, w, h, m.colors.green, 1, 0.55)
    uiRoundRect(m.canvas, x + 24, y + 20, 54, 54, iconFill, iconBorder)
    uiDrawIcon(m.canvas, playlistStoreText(p, "icon", "list"), x + 39, y + 35, 24, 24, cardFocused, m.colors.text, 13)
    drawStatusPill(p, x + w - 118, y + 28, cardFocused)
    uiLabel(m.canvas, playlistStoreText(p, "title", "Playlist"), x + 24, y + 74, w - 48, 28, 16, titleColor)
    uiLabel(m.canvas, playlistStoreText(p, "meta", "Ready to sync"), x + 24, y + 98, w - 48, 22, 12, m.colors.purpleLine)
    uiRect(m.canvas, x + 24, y + 118, w - 48, 1, "0xFFFFFF14")
    uiLabel(m.canvas, playlistStoreText(p, "time", "Ready"), x + 24, y + 120, 148, 18, 10, m.colors.textDim)

    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: playlistStoreText(p, "icon", "list"), label: playlistStoreText(p, "title", "Playlist"), subtitle: playlistStoreText(p, "meta"), iconSize: 13, titleSize: 16, subSize: 12, bg: fill, border: border, textColor: titleColor, subColor: m.colors.textDim, focusBg: fill, focusBorder: border, focusTextColor: titleColor, row: row, col: col, page: "", action: "playlist", playlistId: playlistStoreText(p, "id"), mode: "manual" })

    drawCardAction("REF", "refresh", playlistStoreText(p, "id"), x + w - 98, y + h - 32, row + 1, col)
    drawCardAction("DEL", "delete", playlistStoreText(p, "id"), x + w - 50, y + h - 32, row + 1, col + 1)
end sub

sub drawStatusPill(p as Object, x as Integer, y as Integer, focused as Boolean)
    status = playlistStoreText(p, "status", "Active")
    textColor = m.colors.textGreen
    bg = m.colors.greenSoft
    border = m.colors.green
    if status = "Offline" then
        textColor = "0xF09595FF"
        bg = "0xFFFFFF10"
        border = m.colors.whiteLine
    else if status = "Expires soon" then
        textColor = m.colors.amber
        bg = "0xFFFFFF10"
        border = m.colors.whiteLine
    end if
    if focused and status = "Active" then textColor = m.colors.text
    uiRoundRect(m.canvas, x, y, 100, 34, bg, border)
    uiLabel(m.canvas, status, x + 4, y + 1, 92, 28, 11, textColor, "center")
end sub

sub drawCardAction(label as String, action as String, playlistId as String, x as Integer, y as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    textColor = m.colors.purpleLine
    if action = "delete" then textColor = m.colors.red
    if focused then
        uiRect(m.canvas, x - 4, y - 5, 42, 28, m.colors.purpleSoft)
        uiRectBorder(m.canvas, x - 4, y - 5, 42, 28, m.colors.greenFocus, 2)
        textColor = m.colors.text
    end if
    uiLabel(m.canvas, label, x, y - 2, 34, 22, 10, textColor, "center")
    m.focusItems.push({ x: x - 4, y: y - 5, w: 42, h: 28, icon: "", label: label, subtitle: "", iconSize: 1, titleSize: 10, subSize: 10, bg: m.colors.panel, border: m.colors.whiteLine, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: "", action: action, playlistId: playlistId, mode: "manual" })
end sub

sub drawFooterSummary()
    summary = playlistSummary(m.playlists)
    uiRect(m.canvas, 258, 650, 7, 7, m.colors.green)
    uiLabel(m.canvas, summary.statusText, 278, 636, 560, 38, 13, m.colors.textDim)
end sub

sub drawEmptyState()
    message = "No playlists found"
    if m.searchQuery <> "" then message = "No playlists match your search"
    uiRect(m.canvas, 418, 274, 520, 152, m.colors.panel)
    uiRectBorder(m.canvas, 418, 274, 520, 152, m.colors.purpleLine, 2)
    uiDrawIcon(m.canvas, "list", 638, 306, 44, 44, true, m.colors.text, 18)
    uiLabel(m.canvas, message, 468, 360, 420, 30, 18, m.colors.text, "center")
    uiLabel(m.canvas, "Use Add Playlist to connect M3U or Xtreme accounts.", 478, 392, 400, 24, 12, m.colors.textDim, "center")
end sub

function filteredPlaylists() as Object
    out = []
    query = LCase(m.searchQuery)
    for i = 0 to m.playlists.count() - 1
        p = m.playlists[i]
        searchable = LCase(playlistStoreText(p, "title") + " " + playlistStoreText(p, "meta") + " " + playlistStoreText(p, "status") + " " + playlistStoreText(p, "type"))
        if query = "" or Instr(1, searchable, query) > 0 then out.push({ playlist: p, index: i })
    end for
    return out
end function

function playlistSummary(items as Object) as Object
    activeCount = 0
    offlineCount = 0
    total = 0
    for each item in items
        if playlistStoreText(item, "status") = "Offline" then
            offlineCount += 1
        else
            activeCount += 1
        end if
        total += playlistStoreNumber(item, "itemCount")
    end for
    playlistWord = " playlists"
    if items.count() = 1 then playlistWord = " playlist"
    return {
        countText: items.count().toStr() + playlistWord,
        totalText: formatCount(total) + " channels total",
        statusText: activeCount.toStr() + " active - " + offlineCount.toStr() + " offline - last sync " + latestSyncText(items)
    }
end function

function latestSyncText(items as Object) as String
    if items.count() = 0 then return "not synced yet"
    for each item in items
        if playlistStoreText(item, "lastSync") = "just now" then return "just now"
    end for
    return "2 hours ago"
end function

function formatCount(value as Integer) as String
    text = value.toStr()
    if value >= 1000 and value < 1000000 then
        head = Left(text, text.len() - 3)
        tail = Right(text, 3)
        return head + "," + tail
    end if
    return text
end function

sub openSearchKeyboard()
    m.searchEditing = true
    m.searchKeyboardIndex = 0
    render()
end sub

function handleSearchKeyboardKey(key as String) as Boolean
    cols = 10
    keyCount = m.searchKeys.count()
    if key = "left" and m.searchKeyboardIndex > 0 then m.searchKeyboardIndex -= 1 : render() : return true
    if key = "right" and m.searchKeyboardIndex < keyCount - 1 then m.searchKeyboardIndex += 1 : render() : return true
    if key = "up" and m.searchKeyboardIndex - cols >= 0 then m.searchKeyboardIndex -= cols : render() : return true
    if key = "down" and m.searchKeyboardIndex + cols < keyCount then m.searchKeyboardIndex += cols : render() : return true
    if key = "back" then closeSearchKeyboard() : return true
    if key = "OK" then pressSearchKey() : return true
    return true
end function

sub pressSearchKey()
    selected = m.searchKeys[m.searchKeyboardIndex]
    if selected = "DONE" then closeSearchKeyboard() : return
    if selected = "CLEAR" then
        m.searchQuery = ""
    else if selected = "DEL" then
        if m.searchQuery.len() > 0 then m.searchQuery = m.searchQuery.left(m.searchQuery.len() - 1)
    else if selected = "SPACE" then
        if m.searchQuery.len() < 28 then m.searchQuery += " "
    else
        if m.searchQuery.len() < 28 then m.searchQuery += selected
    end if
    m.focusIndex = 7
    render()
end sub

sub closeSearchKeyboard()
    m.searchEditing = false
    render()
end sub

sub drawSearchKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiRect(m.canvas, 260, 116, 760, 488, m.colors.panel)
    uiRectBorder(m.canvas, 260, 116, 760, 488, m.colors.purpleLine, 2)
    uiLabel(m.canvas, "Search Playlists", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiRect(m.canvas, 330, 188, 620, 48, m.colors.bg2)
    uiLabel(m.canvas, m.searchQuery, 350, 196, 580, 32, 17, m.colors.text, "left")

    keyW = 56
    keyH = 42
    gap = 8
    startX = 324
    startY = 268
    for i = 0 to m.searchKeys.count() - 1
        r = Int(i / 10)
        c = i mod 10
        x = startX + c * (keyW + gap)
        y = startY + r * (keyH + gap)
        keyLabel = m.searchKeys[i]
        if keyLabel = "SPACE" then keyLabel = "Space"
        if keyLabel = "DEL" then keyLabel = "Del"
        if keyLabel = "CLEAR" then keyLabel = "Clear"
        if keyLabel = "DONE" then keyLabel = "Done"

        bg = m.colors.bg
        border = m.colors.whiteLine
        if i = m.searchKeyboardIndex then
            bg = m.colors.purpleSoft
            border = m.colors.greenFocus
        end if
        uiRect(m.canvas, x, y, keyW, keyH, bg)
        uiRectBorder(m.canvas, x, y, keyW, keyH, border, 2)
        uiLabel(m.canvas, keyLabel, x, y + 5, keyW, 28, 14, m.colors.text, "center")
    end for
end sub
