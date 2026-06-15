sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("myPlaylistsCanvas")
    m.focusItems = []
    m.focusIndex = 8
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.deleteDialog = invalid
    m.pendingDeleteId = ""
    m.pendingDeleteTitle = ""
    m.playlistWindowStart = 0
    m.playlistWindowSize = 6
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
    if m.deleteDialog <> invalid then
        if key = "back" then closeDeleteDialog() : return true
        return false
    end if
    if m.searchEditing then return handleSearchKeyboardKey(key)
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    if routePlaylistFocus(dx, dy) then render() : return
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "search" then openSearchKeyboard() : return
    if item.action = "playlist" then m.top.navigateTo = "LiveTvPage" : return
    if item.action = "delete" then
        openDeleteConfirm(item.playlistId, item.playlistTitle)
        return
    end if
end sub

sub render()
    visible = filteredPlaylists()
    normalizePlaylistWindow(visible.count())
    normalizePlaylistFocus(visible.count())

    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    drawPageBackdrop()

    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = drawPlaylistSideNav()

    drawPageHeader(row)

    if visible.count() = 0 then
        drawEmptyState()
    else
        drawPlaylistGrid(visible, row)
    end if

    drawFooterSummary()
    drawPlaylistScrollbar(visible.count())
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

function routePlaylistFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then m.focusIndex = 0
    current = m.focusItems[m.focusIndex]
    currentCol = -1
    if current.doesExist("col") then currentCol = current.col
    action = ""
    if current.doesExist("action") then action = current.action
    page = ""
    if current.doesExist("page") then page = current.page
    visible = filteredPlaylists()

    if dy < 0 and page = "AddPlaylistPage" then
        searchTarget = findPlaylistActionFocus("search")
        if searchTarget >= 0 then m.focusIndex = searchTarget
        return true
    end if

    if dy > 0 and action = "search" then
        addTarget = findPlaylistPageFocus("AddPlaylistPage")
        if addTarget >= 0 then m.focusIndex = addTarget
        return true
    end if

    if dx < 0 and action = "delete" then
        target = findPlaylistCardFocus(current.playlistId)
        if target >= 0 then m.focusIndex = target
        return true
    end if

    if dx < 0 and action = "playlist" then
        currentVisible = 0
        if current.doesExist("visibleIndex") then currentVisible = current.visibleIndex
        slot = currentVisible - m.playlistWindowStart
        if slot <= 0 or (slot mod 3) = 0 then
            m.focusIndex = 0
            return true
        end if
        previousVisible = currentVisible - 1
        target = findPlaylistCardVisibleFocus(previousVisible)
        if target >= 0 then
            m.focusIndex = target
        else
            m.focusIndex = playlistFocusIndexForVisible(previousVisible, false)
        end if
        return true
    end if

    if dx > 0 and action = "delete" then
        currentVisible = 0
        if current.doesExist("visibleIndex") then currentVisible = current.visibleIndex
        slot = currentVisible - m.playlistWindowStart
        if (slot mod 3) = 2 then return true
        nextVisible = currentVisible + 1
        if nextVisible < visible.count() then
            normalizePlaylistWindowForIndex(nextVisible, visible.count())
            target = findPlaylistCardVisibleFocus(nextVisible)
            if target >= 0 then
                m.focusIndex = target
            else
                m.focusIndex = playlistFocusIndexForVisible(nextVisible, false)
            end if
            return true
        end if
        return true
    end if

    if dx > 0 and action = "playlist" then
        target = findPlaylistDeleteFocus(current.playlistId)
        if target >= 0 then m.focusIndex = target : return true
    end if

    if dx < 0 and currentCol > 0 then
        m.focusIndex = 0
        return true
    end if

    if (dy < 0 or dy > 0) and (action = "playlist" or action = "delete") then
        currentVisible = 0
        if current.doesExist("visibleIndex") then currentVisible = current.visibleIndex
        nextVisible = currentVisible
        if dy < 0 then nextVisible = currentVisible - 3
        if dy > 0 then nextVisible = currentVisible + 3
        if nextVisible >= 0 and nextVisible < visible.count() then
            normalizePlaylistWindowForIndex(nextVisible, visible.count())
            if action = "delete" then
                target = findPlaylistDeleteVisibleFocus(nextVisible)
            else
                target = findPlaylistCardVisibleFocus(nextVisible)
            end if
            if target >= 0 then
                m.focusIndex = target
            else
                m.focusIndex = playlistFocusIndexForVisible(nextVisible, action = "delete")
            end if
            return true
        end if
        if dy < 0 then
            addTarget = findPlaylistPageFocus("AddPlaylistPage")
            if addTarget >= 0 then
                m.focusIndex = addTarget
            else
                searchTarget = findPlaylistActionFocus("search")
                if searchTarget >= 0 then m.focusIndex = searchTarget
            end if
            return true
        end if
        return true
    end if

    if dx > 0 and currentCol = 0 then
        target = findFirstPlaylistCardFocus()
        if target >= 0 then m.focusIndex = target : return true
        searchTarget = findPlaylistActionFocus("search")
        if searchTarget >= 0 then m.focusIndex = searchTarget : return true
    end if

    if dy < 0 and action = "playlist" then
        searchTarget = findPlaylistActionFocus("search")
        if searchTarget >= 0 then m.focusIndex = searchTarget : return true
    end if

    return false
end function

function playlistFocusIndexForVisible(visibleIndex as Integer, deleteAction as Boolean) as Integer
    slot = visibleIndex - m.playlistWindowStart
    if slot < 0 then slot = 0
    if slot > m.playlistWindowSize - 1 then slot = m.playlistWindowSize - 1
    index = 8 + slot * 2
    if deleteAction then index += 1
    return index
end function

function findPlaylistActionFocus(action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = action then return i
    end for
    return -1
end function

function findPlaylistPageFocus(page as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("page") and item.page = page then return i
    end for
    return -1
end function

function findFirstPlaylistCardFocus() as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "playlist" then return i
    end for
    return -1
end function

function findPlaylistCardFocus(playlistId as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "playlist" and item.playlistId = playlistId then return i
    end for
    return -1
end function

function findPlaylistDeleteFocus(playlistId as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "delete" and item.playlistId = playlistId then return i
    end for
    return -1
end function

function findPlaylistCardVisibleFocus(visibleIndex as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "playlist" and item.doesExist("visibleIndex") and item.visibleIndex = visibleIndex then return i
    end for
    return -1
end function

function findPlaylistDeleteVisibleFocus(visibleIndex as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "delete" and item.doesExist("visibleIndex") and item.visibleIndex = visibleIndex then return i
    end for
    return -1
end function

sub normalizePlaylistFocus(visibleCount as Integer)
    maxIndex = 7
    drawnCount = visibleCount
    if drawnCount > m.playlistWindowSize then drawnCount = m.playlistWindowSize
    if drawnCount > 0 then maxIndex = 7 + drawnCount * 2
    if m.focusIndex > maxIndex then m.focusIndex = maxIndex
    if m.focusIndex < 0 then m.focusIndex = 0
end sub

sub normalizePlaylistWindow(visibleCount as Integer)
    if visibleCount <= m.playlistWindowSize then
        m.playlistWindowStart = 0
        return
    end if
    if m.playlistWindowStart < 0 then m.playlistWindowStart = 0
    maxStart = visibleCount - m.playlistWindowSize
    if m.playlistWindowStart > maxStart then m.playlistWindowStart = maxStart
end sub

sub normalizePlaylistWindowForIndex(visibleIndex as Integer, visibleCount as Integer)
    if visibleIndex < m.playlistWindowStart then m.playlistWindowStart = visibleIndex
    if visibleIndex >= m.playlistWindowStart + m.playlistWindowSize then m.playlistWindowStart = visibleIndex - m.playlistWindowSize + 1
    normalizePlaylistWindow(visibleCount)
end sub

sub drawPageBackdrop()
    uiRect(m.canvas, 226, 86, 1054, 634, m.colors.bg, 0.98)
end sub

function drawPlaylistSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    playlistsActive = (m.focusIndex = 0) or (m.focusIndex > 5)
    addPlaylistNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, playlistsActive)
    addPlaylistNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addPlaylistNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addPlaylistNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addPlaylistNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)

    addPlaylistProfileItem()
    return 6
end function

sub addPlaylistNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: m.colors.textGreen, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: 0, page: page, mode: "row"
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
    end if
    m.focusItems.push(item)
end sub

sub addPlaylistProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: "0xFFFFFF10", border: m.colors.panel, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 5, col: 0, page: "SettingsPage", mode: "row"
    }
    m.focusItems.push(item)
end sub

sub drawPageHeader(row as Integer)
    summary = playlistSummary(m.playlists)
    uiLabel(m.canvas, "MY PLAYLISTS", 258, 112, 260, 26, 14, m.colors.textDim)
    uiLabel(m.canvas, summary.countText + " - " + summary.totalText, 258, 138, 430, 28, 15, m.colors.purpleLine)

    addSearchAction(686, 24, 260, 40, 0, 3)
    addHeaderAction(920, 108, 230, 48, "plus", "Add Playlist", row, 3, "AddPlaylistPage", "")
end sub

sub addHeaderAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer, page as String, action as String)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    bg = m.colors.purpleSoft
    border = m.colors.purpleLine
    textColor = m.colors.text
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
    end if
    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiDrawIcon(m.canvas, icon, x + 28, y + 13, 20, 20, focused, textColor, 12)
    uiLabel(m.canvas, label, x + 58, y + 8, w - 72, 30, 15, textColor)
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 12, titleSize: 15, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, page: page, action: action, mode: "manual" })
end sub

sub addSearchAction(x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    label = "Search"
    label = "Search Playlist"
    if m.searchQuery <> "" then label = m.searchQuery
    bg = m.colors.panel
    border = m.colors.whiteLine
    textColor = m.colors.textDim
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiDrawIcon(m.canvas, "search", x + 22, y + 13, 18, 18, focused, textColor, 11)
    uiLabel(m.canvas, label, x + 52, y + 7, w - 66, 30, 14, textColor)
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: "search", label: label, subtitle: "", iconSize: 11, titleSize: 14, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "search", mode: "manual" })
end sub

sub drawPlaylistGrid(visible as Object, rowStart as Integer)
    x0 = 238
    y0 = 186
    cardW = 300
    cardH = 174
    gapX = 12
    gapY = 26
    endIndex = m.playlistWindowStart + m.playlistWindowSize - 1
    if endIndex > visible.count() - 1 then endIndex = visible.count() - 1
    slot = 0
    for i = m.playlistWindowStart to endIndex
        row = Int(slot / 3)
        col = slot mod 3
        if row < 2 then
            data = visible[i]
            drawPlaylistCard(data.playlist, x0 + col * (cardW + gapX), y0 + row * (cardH + gapY), cardW, cardH, rowStart + 2 + row * 3, 1 + col * 3, i)
        end if
        slot += 1
    end for
end sub

sub drawPlaylistCard(p as Object, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer, visibleIndex as Integer)
    itemIndex = m.focusItems.count()
    cardFocused = itemIndex = m.focusIndex
    accent = playlistStoreText(p, "accent", "purple")
    fill = m.colors.purpleSoft
    border = m.colors.purpleLine
    titleColor = m.colors.textGreen
    if accent = "green" then
        fill = m.colors.greenSoft
        border = m.colors.green
    end if
    if cardFocused then
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
    end if

    drawCardArtwork(p, x, y, w, h)
    overlayOpacity = 0.18
    shellOpacity = 0.46
    if cardFocused then
        overlayOpacity = 0.36
        shellOpacity = 0.52
    end if
    uiRect(m.canvas, x, y, w, h, fill, overlayOpacity)
    uiRect(m.canvas, x + 1, y + h - 58, w - 2, 54, m.colors.bg, 0.66)
    drawPlaylistCardShell(x, y, w, h, fill, border, shellOpacity)
    drawStatusPill(p, x + 18, y + 18, cardFocused)
    uiLabel(m.canvas, playlistStoreText(p, "title", "Playlist"), x + 18, y + 68, w - 36, 28, 14, titleColor)
    uiLabel(m.canvas, playlistTypeLabel(p), x + 18, y + 94, w - 36, 22, 11, m.colors.textPurple)
    uiRect(m.canvas, x + 18, y + 124, w - 152, 1, "0xFFFFFF14")
    uiLabel(m.canvas, playlistStoreText(p, "time", "Ready"), x + 18, y + 127, 150, 22, 8, m.colors.textDim)

    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: playlistStoreText(p, "icon", "list"), label: playlistStoreText(p, "title", "Playlist"), subtitle: playlistStoreText(p, "meta"), iconSize: 13, titleSize: 16, subSize: 12, bg: fill, border: border, textColor: titleColor, subColor: m.colors.textDim, focusBg: fill, focusBorder: border, focusTextColor: titleColor, row: row, col: col, page: "", action: "playlist", playlistId: playlistStoreText(p, "id"), visibleIndex: visibleIndex, mode: "manual" })

    drawCardAction("Delete", "delete", playlistStoreText(p, "id"), playlistStoreText(p, "title", "Playlist"), x + w - 104, y + h - 43, row + 1, col + 1, visibleIndex)
end sub

sub drawPlaylistCardShell(x as Integer, y as Integer, w as Integer, h as Integer, fill as String, border as String, opacity = 1.0 as Float)
    fillKey = "purpleSoft"
    borderKey = "purpleLine"
    if fill = m.colors.greenSoft then fillKey = "greenSoft"
    if border = m.colors.green or border = m.colors.greenFocus then borderKey = "greenFocus"
    if border = m.colors.purpleLine then borderKey = "purpleLine"
    uri = "pkg:/images/ui/thin_280x152_" + fillKey + "_" + borderKey + ".png"
    uiPoster(m.canvas, uri, x, y, w, h, opacity)
end sub

sub drawCardArtwork(p as Object, x as Integer, y as Integer, w as Integer, h as Integer)
    art = playlistArtworkUri(p)
    if art <> "" then
        poster = uiPosterZoom(m.canvas, art, x, y, w, h, 1.0)
        uiRect(m.canvas, x, y, w, h, m.colors.bg, 0.08)
    end if
end sub

function playlistArtworkUri(p as Object) as String
    id = playlistStoreText(p, "id")
    if id = "demo_live_tv" then return "pkg:/images/logos/live/backdrops/espn_backdrop.jpg"
    if id = "demo_movies" then return "pkg:/images/logos/live/backdrops/movie_channel_backdrop.jpg"
    if id = "demo_series" then return "pkg:/images/logos/live/backdrops/bbc_news_backdrop.jpg"
    if id = "demo_sports" then return "pkg:/images/logos/live/backdrops/bein_sports_backdrop.jpg"
    if id = "demo_news" then return "pkg:/images/logos/live/backdrops/cnn_backdrop.jpg"
    if id = "demo_music" then return "pkg:/images/logos/live/backdrops/mtv_hits_backdrop.jpg"
    if id = "demo_kids" then return "pkg:/images/logos/live/backdrops/cartoon_network_backdrop.jpg"
    if id = "demo_documentary" then return "pkg:/images/logos/live/backdrops/discovery_backdrop.jpg"
    if id = "demo_favourites" then return "pkg:/images/logos/live/backdrops/bbc_news_backdrop.jpg"
    if id = "demo_family" then return "pkg:/images/logos/live/backdrops/movie_channel_backdrop.jpg"
    if playlistStoreText(p, "type") = "Xtreme" then return "pkg:/images/logos/live/backdrops/bein_sports_backdrop.jpg"
    return "pkg:/images/logos/live/backdrops/cnn_backdrop.jpg"
end function

function playlistTypeLabel(p as Object) as String
    typeText = playlistStoreText(p, "type", "M3U")
    if typeText = "Xtreme" then return "Xtreme Account"
    return "M3U Playlist"
end function

sub drawStatusPill(p as Object, x as Integer, y as Integer, focused as Boolean)
    status = playlistStoreText(p, "status", "Active")
    textColor = "0xFFFFFFFF"
    uri = "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png"
    label = status
    if status = "Offline" then
        textColor = "0xFFFFFFFF"
    else if status = "Expires soon" then
        label = "Expires"
        textColor = m.colors.amber
    end if
    uiPoster(m.canvas, uri, x, y, 88, 30)
    uiLabel(m.canvas, label, x + 4, y - 1, 80, 30, 9, textColor, "center")
end sub

sub drawCardAction(label as String, action as String, playlistId as String, playlistTitle as String, x as Integer, y as Integer, row as Integer, col as Integer, visibleIndex as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    buttonUri = "pkg:/images/ui/movie_watch_140x40_panel_greenFocus.png"
    textColor = "0xFFFFFFFF"
    if focused then
        buttonUri = "pkg:/images/ui/movie_watch_140x40_greenSoft_greenFocus.png"
    end if
    uiPoster(m.canvas, buttonUri, x, y, 90, 28)
    uiLabel(m.canvas, label, x + 4, y - 1, 82, 28, 7, textColor, "center")
    m.focusItems.push({ x: x, y: y, w: 90, h: 28, icon: "", label: label, subtitle: "", iconSize: 1, titleSize: 7, subSize: 7, bg: m.colors.panel, border: m.colors.greenFocus, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: textColor, row: row, col: col, page: "", action: action, playlistId: playlistId, playlistTitle: playlistTitle, visibleIndex: visibleIndex, mode: "manual", noFocusShift: true })
end sub

sub drawFooterSummary()
    summary = playlistSummary(m.playlists)
    uiRect(m.canvas, 258, 650, 7, 7, m.colors.green)
    uiLabel(m.canvas, summary.statusText, 278, 636, 560, 38, 13, m.colors.textDim)
end sub

sub drawPlaylistScrollbar(totalCount as Integer)
    if totalCount <= m.playlistWindowSize then return
    trackX = 1172
    trackY = 186
    trackH = 374
    uiVerticalPill(m.canvas, trackX, trackY, 3, trackH, "0xFFFFFF18", "pkg:/images/ui/scroll_cap_4_whiteLine.png", 0.42)
    maxStart = totalCount - m.playlistWindowSize
    thumbH = Int(trackH * m.playlistWindowSize / totalCount)
    if thumbH < 64 then thumbH = 64
    thumbTravel = trackH - thumbH
    thumbY = trackY
    if maxStart > 0 then thumbY = trackY + Int(thumbTravel * m.playlistWindowStart / maxStart)
    uiVerticalPill(m.canvas, trackX - 1, thumbY, 5, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.86)
end sub

sub openDeleteConfirm(playlistId as String, playlistTitle as String)
    m.pendingDeleteId = playlistId
    m.pendingDeleteTitle = playlistTitle
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Delete playlist?"
    dialog.message = "Remove " + playlistTitle + " from My Playlists?"
    dialog.buttons = ["Cancel", "Delete"]
    dialog.observeField("buttonSelected", "onDeleteDialogButton")
    m.deleteDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub closeDeleteDialog()
    if m.top <> invalid and m.top.getScene() <> invalid then m.top.getScene().dialog = invalid
    m.deleteDialog = invalid
    m.pendingDeleteId = ""
    m.pendingDeleteTitle = ""
end sub

sub onDeleteDialogButton()
    if m.deleteDialog = invalid then return
    selected = m.deleteDialog.buttonSelected
    if selected = 1 then
        playlistStoreDelete(m.pendingDeleteId)
        m.playlists = playlistStoreList()
    end if
    closeDeleteDialog()
    normalizePlaylistFocus(filteredPlaylists().count())
    render()
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
