sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("myPlaylistsCanvas")
    m.focusItems = []
    m.focusIndex = firstPlaylistFocusIndex()
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.deleteDialog = invalid
    m.manageDialog = invalid
    m.refreshDialog = invalid
    m.pendingDeleteId = ""
    m.pendingDeleteTitle = ""
    m.pendingManageId = ""
    m.pendingManageTitle = ""
    m.manageProtected = false
    m.feedbackMessage = ""
    m.feedbackSuccess = true
    m.backendLoading = false
    m.backendLoaded = false
    m.backendTask = invalid
    m.backendActionTask = invalid
    m.backendAction = ""
    m.backendActionPlaylistId = ""
    m.refreshingId = ""
    m.pendingActivationNavigateTo = ""
    m.playlistWindowStart = 0
    m.playlistWindowSize = 6
    m.initialFocusPlaylistId = playlistStoreActiveId()
    m.initialFocusApplied = false
    m.searchKeyboardUpper = true
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "CASE", "SPACE", "DEL", "CLEAR", "DONE"]
    m.playlists = playlistStoreList()

    m.refreshTimer = CreateObject("roSGNode", "Timer")
    m.refreshTimer.repeat = false
    m.refreshTimer.duration = 0.7
    m.refreshTimer.observeField("fire", "finishPlaylistRefresh")

    m.activationTimer = CreateObject("roSGNode", "Timer")
    m.activationTimer.repeat = false
    m.activationTimer.duration = 0.45
    m.activationTimer.observeField("fire", "finishPlaylistActivation")
    render()
    startBackendPlaylistLoad()
end sub

sub startBackendPlaylistLoad()
    if m.backendLoading then return
    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.feedbackSuccess = false
        m.feedbackMessage = "Backend connection is unavailable."
        return
    end if

    m.backendLoading = true
    m.feedbackSuccess = true
    m.feedbackMessage = "Loading backend playlists..."
    render()
    task.observeField("response", "onBackendPlaylistsLoaded")
    task.request = backendApiListPlaylistsRequest()
    m.backendTask = task
    task.control = "RUN"
end sub

sub onBackendPlaylistsLoaded()
    if m.backendTask = invalid then return
    response = m.backendTask.response
    m.backendLoading = false
    m.backendLoaded = true

    if backendApiResponseOk(response) then
        items = backendApiResponseItems(response)
        if items.count() > 0 then
            m.playlists = playlistStoreMergeBackendPlaylists(items)
            m.feedbackSuccess = true
            m.feedbackMessage = items.count().toStr() + " backend playlists synced."
        else
            m.playlists = playlistStoreMergeBackendPlaylists([])
            m.feedbackSuccess = true
            m.feedbackMessage = "No backend playlists yet."
        end if
    else
        m.feedbackSuccess = false
        m.feedbackMessage = "Backend playlists could not be loaded."
    end if

    m.backendTask = invalid
    normalizePlaylistFocus(filteredPlaylists().count())
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
    if m.pendingActivationNavigateTo <> "" then return true
    if m.backendActionTask <> invalid then return true
    if m.refreshingId <> "" then return true
    if m.manageDialog <> invalid then
        if key = "back" then closeManageDialog() : return true
        return false
    end if
    if m.refreshDialog <> invalid then
        if key = "back" then closeRefreshDialog() : return true
        return false
    end if
    if m.deleteDialog <> invalid then
        if key = "back" then closeDeleteDialog() : return true
        return false
    end if
    if m.searchEditing then return handleSearchKeyboardKey(key)
    if key = "back" and m.searchQuery <> "" then clearPlaylistSearchAndStay() : return true
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
    if item.action = "playlist" then
        playlistStoreSetActive(item.playlistId)
        m.playlists = playlistStoreList()
        m.initialFocusPlaylistId = item.playlistId
        m.initialFocusApplied = false
        m.feedbackMessage = item.playlistTitle + " is now active."
        m.feedbackSuccess = true
        m.pendingActivationNavigateTo = playlistStorePreferredPageForId(item.playlistId)
        render()
        m.activationTimer.control = "stop"
        m.activationTimer.control = "start"
        return
    end if
    if item.action = "manage" then
        openManageDialog(item.playlistId, item.playlistTitle, item.playlistProtected)
        return
    end if
end sub

sub render()
    visible = filteredPlaylists()
    keepActivePlaylistFirstFocus(visible)
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

function firstPlaylistFocusIndex() as Integer
    return 9
end function

sub keepActivePlaylistFirstFocus(visible as Object)
    if m.initialFocusApplied then return
    m.initialFocusApplied = true
    if m.initialFocusPlaylistId = invalid or m.initialFocusPlaylistId = "" then return
    if visible.count() <= 0 then return
    if playlistStoreText(visible[0].playlist, "id") = m.initialFocusPlaylistId then
        m.playlistWindowStart = 0
        m.focusIndex = firstPlaylistFocusIndex()
    end if
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

    if dy < 0 and (page = "AddPlaylistPage" or page = "ManagePlaylistsPage") then
        searchTarget = findPlaylistActionFocus("search")
        if searchTarget >= 0 then m.focusIndex = searchTarget
        return true
    end if

    if dy > 0 and action = "search" then
        addTarget = findPlaylistPageFocus("AddPlaylistPage")
        if addTarget >= 0 then m.focusIndex = addTarget
        return true
    end if

    if dx > 0 and page = "AddPlaylistPage" then
        manageTarget = findPlaylistPageFocus("ManagePlaylistsPage")
        if manageTarget >= 0 then m.focusIndex = manageTarget
        return true
    end if

    if dx < 0 and page = "ManagePlaylistsPage" then
        addTarget = findPlaylistPageFocus("AddPlaylistPage")
        if addTarget >= 0 then m.focusIndex = addTarget
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

    if dx > 0 and action = "playlist" then
        currentVisible = 0
        if current.doesExist("visibleIndex") then currentVisible = current.visibleIndex
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

    if dx < 0 and currentCol > 0 then
        m.focusIndex = 0
        return true
    end if

    if (dy < 0 or dy > 0) and action = "playlist" then
        currentVisible = 0
        if current.doesExist("visibleIndex") then currentVisible = current.visibleIndex
        nextVisible = currentVisible
        if dy < 0 then nextVisible = currentVisible - 3
        if dy > 0 then nextVisible = currentVisible + 3
        if nextVisible >= 0 and nextVisible < visible.count() then
            normalizePlaylistWindowForIndex(nextVisible, visible.count())
            target = findPlaylistCardVisibleFocus(nextVisible)
            if target >= 0 then
                m.focusIndex = target
            else
                m.focusIndex = playlistFocusIndexForVisible(nextVisible, false)
            end if
            return true
        end if
        if dy < 0 then
            slot = currentVisible - m.playlistWindowStart
            if (slot mod 3) < 2 then
                headerTarget = findPlaylistPageFocus("AddPlaylistPage")
            else
                headerTarget = findPlaylistPageFocus("ManagePlaylistsPage")
            end if
            if headerTarget >= 0 then m.focusIndex = headerTarget
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

function playlistFocusIndexForVisible(visibleIndex as Integer, manageAction as Boolean) as Integer
    visible = filteredPlaylists()
    index = 9
    for i = m.playlistWindowStart to visibleIndex - 1
        if i >= 0 and i < visible.count() then index += 1
    end for
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

function findPlaylistManageFocus(playlistId as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "manage" and item.playlistId = playlistId then return i
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

function findPlaylistManageVisibleFocus(visibleIndex as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "manage" and item.doesExist("visibleIndex") and item.visibleIndex = visibleIndex then return i
    end for
    return -1
end function

sub normalizePlaylistFocus(visibleCount as Integer)
    maxIndex = 8
    drawnCount = visibleCount
    if drawnCount > m.playlistWindowSize then drawnCount = m.playlistWindowSize
    if drawnCount > 0 then
        maxIndex = 8
        visible = filteredPlaylists()
        endIndex = m.playlistWindowStart + drawnCount - 1
        if endIndex > visible.count() - 1 then endIndex = visible.count() - 1
        for i = m.playlistWindowStart to endIndex
            maxIndex += 1
        end for
    end if
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
    uiPosterZoom(m.canvas, "pkg:/images/playlists/my_playlists_background_v3.jpg", 0, 0, 1280, 720, 0.56)
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.46)
    uiRect(m.canvas, 226, 86, 1054, 634, m.colors.bg, 0.66)
end sub

sub finishPlaylistActivation()
    if m.pendingActivationNavigateTo = "" then return
    target = m.pendingActivationNavigateTo
    m.pendingActivationNavigateTo = ""
    m.top.navigateTo = target
end sub

function drawPlaylistSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addPlaylistNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, true)
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
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: row, col: 0, page: page, mode: "row", noFocusShift: true
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
        item.opacity = 0.58
    end if
    m.focusItems.push(item)
end sub

sub addPlaylistProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: 5, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawPageHeader(row as Integer)
    summary = playlistSummary(m.playlists)
    uiLabel(m.canvas, "MY PLAYLISTS", 258, 106, 300, 34, 18, m.colors.text)
    uiLabel(m.canvas, summary.countText, 258, 140, 300, 26, 13, m.colors.greenFocus)
    if m.feedbackMessage <> "" then
        uiScaledLabel(m.canvas, m.feedbackMessage, 664, 176, 486, 24, 10, m.colors.textDim, "right", 0.72)
    end if

    addSearchAction(686, 24, 240, 40, 0, 3)
    addHeaderAction(664, 108, 230, 48, "plus", "Add Playlist", row, 2, "AddPlaylistPage", "")
    addHeaderAction(920, 108, 230, 48, "", "Manage Playlists", row, 3, "ManagePlaylistsPage", "")
end sub

sub addHeaderAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer, page as String, action as String)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    textColor = m.colors.text
    surfaceUri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    buttonOpacity = 0.46
    if focused then
        surfaceUri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        buttonOpacity = 0.64
    end if
    buttonCanvas = CreateObject("roSGNode", "Group")
    buttonCanvas.id = "playlistHeaderAction" + itemIndex.toStr()
    buttonCanvas.translation = [x, y]
    buttonCanvas.scaleRotateCenter = [w / 2, h / 2]
    m.canvas.appendChild(buttonCanvas)
    uiPoster(buttonCanvas, surfaceUri, 0, 0, w, h, buttonOpacity)
    if icon = "" then
        uiLabel(buttonCanvas, label, 0, 0, w, h, 15, textColor, "center")
    else
        uiDrawIcon(buttonCanvas, icon, 34, 14, 20, 20, focused, textColor, 12)
        uiLabel(buttonCanvas, label, 64, 0, w - 80, h, 15, textColor)
    end if
    if focused then uiAnimateActionFocus(m.canvas, buttonCanvas)
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 12, titleSize: 15, subSize: 10, bg: m.colors.panel, border: m.colors.greenFocus, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: page, action: action, mode: "manual" })
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
    uiSearchPill(m.canvas, x, y, w, h, focused, 0.54)
    uiDrawIcon(m.canvas, "search", x + 20, y + 10, 20, 20, focused, textColor, 11)
    uiLabel(m.canvas, label, x + 54, y + 1, w - 72, h, 14, textColor)
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: "search", label: label, subtitle: "", iconSize: 11, titleSize: 14, subSize: 10, bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text, row: row, col: col, page: "", action: "search", mode: "manual" })
end sub

sub drawPlaylistGrid(visible as Object, rowStart as Integer)
    x0 = 250
    y0 = 206
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
    fill = m.colors.purpleSoft
    border = m.colors.purpleLine
    titleColor = m.colors.textGreen
    if cardFocused then
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
    end if

    cardCanvas = CreateObject("roSGNode", "Group")
    cardCanvas.id = "playlistCard" + visibleIndex.toStr()
    cardCanvas.translation = [x, y]
    m.canvas.appendChild(cardCanvas)
    uiPoster(cardCanvas, "pkg:/images/playlists/playlist_card_background.png", 0, 0, w, h, 1.0)
    shellOpacity = 0.22
    if cardFocused then
        shellOpacity = 0.58
    end if
    drawPlaylistCardShell(cardCanvas, 0, 0, w, h, fill, border, shellOpacity)
    drawStatusPill(p, cardCanvas, 18, 18, cardFocused)
    uiLabel(cardCanvas, playlistStoreText(p, "title", "Playlist"), 18, 82, w - 36, 28, 14, titleColor)
    uiScaledLabel(cardCanvas, playlistTypeLabel(p), 18, 112, w - 36, 18, 8, m.colors.textDim, "left", 0.72)
    if cardFocused then uiAnimateCardFocus(m.canvas, cardCanvas, x, y)

    playlistTitle = playlistStoreText(p, "title", "Playlist")
    m.focusItems.push({ x: x, y: y, w: w, h: h, icon: playlistStoreText(p, "icon", "list"), label: playlistTitle, subtitle: playlistStoreText(p, "meta"), iconSize: 13, titleSize: 16, subSize: 12, bg: fill, border: border, textColor: titleColor, subColor: m.colors.textDim, focusBg: fill, focusBorder: border, focusTextColor: titleColor, row: row, col: col, page: "", action: "playlist", playlistId: playlistStoreText(p, "id"), playlistTitle: playlistTitle, visibleIndex: visibleIndex, mode: "manual" })
end sub

sub drawPlaylistCardShell(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, fill as String, border as String, opacity = 1.0 as Float)
    fillKey = "purpleSoft"
    borderKey = "purpleLine"
    if fill = m.colors.greenSoft then fillKey = "greenSoft"
    if border = m.colors.green or border = m.colors.greenFocus then borderKey = "greenFocus"
    if border = m.colors.purpleLine then borderKey = "purpleLine"
    uri = "pkg:/images/ui/thin_280x152_" + fillKey + "_" + borderKey + ".png"
    uiPoster(parent, uri, x, y, w, h, opacity)
end sub

function playlistStoreBoolField(item as Object, key as String, fallback as Boolean) as Boolean
    if item = invalid then return fallback
    value = invalid
    if item.doesExist(key) then
        value = item[key]
    else
        lowerKey = LCase(key)
        if lowerKey <> key and item.doesExist(lowerKey) then value = item[lowerKey]
    end if
    if value = invalid then return fallback
    return value = true
end function

function playlistTypeLabel(p as Object) as String
    typeText = playlistStoreText(p, "type", "M3U")
    if typeText = "Xtreme" then return "Xtreme Account"
    return "M3U Playlist"
end function

sub drawStatusPill(p as Object, parent as Object, x as Integer, y as Integer, focused as Boolean)
    status = playlistStoreText(p, "status", "Active")
    textColor = "0xFFFFFFFF"
    label = status
    isActive = playlistStoreText(p, "id") = playlistStoreActiveId()
    if isActive then
        label = "Active"
    else if status = "Active" then
        label = "Ready"
    end if
    if playlistStoreText(p, "id") = m.refreshingId then label = "Syncing"
    if status = "Offline" then
        textColor = "0xFFFFFFFF"
    else if status = "Expires soon" then
        label = "Expires"
        textColor = m.colors.amber
    end if
    badgeW = statusPillWidth(label)
    uiPoster(parent, statusPillUri(label), x, y, badgeW, 28, 0.96)
    uiScaledLabel(parent, label, x, y + 4, badgeW, 20, 10, textColor, "center", 0.78)
end sub

function statusPillWidth(label as String) as Integer
    if label = "Trial" then return 62
    if label = "Ready" then return 68
    if label = "Active" then return 74
    if label = "Offline" or label = "Expires" then return 84
    if label = "Syncing" then return 94
    return 84
end function

function statusPillUri(label as String) as String
    width = statusPillWidth(label)
    return "pkg:/images/ui/playlist_badge_" + width.toStr() + "x28.png"
end function

sub drawCardAction(label as String, action as String, playlistId as String, playlistTitle as String, playlistProtected as Boolean, x as Integer, y as Integer, row as Integer, col as Integer, visibleIndex as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    buttonUri = "pkg:/images/ui/movie_watch_140x40_panel_greenFocus.png"
    textColor = "0xFFFFFFFF"
    if focused then
        buttonUri = "pkg:/images/ui/movie_watch_140x40_greenSoft_greenFocus.png"
    end if
    uiPoster(m.canvas, buttonUri, x, y, 90, 28)
    uiLabel(m.canvas, label, x + 4, y, 82, 28, 7, textColor, "center")
    m.focusItems.push({ x: x, y: y, w: 90, h: 28, icon: "", label: label, subtitle: "", iconSize: 1, titleSize: 7, subSize: 7, bg: m.colors.panel, border: m.colors.greenFocus, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: textColor, row: row, col: col, page: "", action: action, playlistId: playlistId, playlistTitle: playlistTitle, playlistProtected: playlistProtected, visibleIndex: visibleIndex, mode: "manual", noFocusShift: true })
end sub

sub drawFooterSummary()
    summary = playlistSummary(m.playlists)
    uiRect(m.canvas, 258, 650, 7, 7, m.colors.green)
    uiLabel(m.canvas, summary.statusText, 278, 636, 560, 38, 13, m.colors.textDim)
end sub

sub drawPlaylistScrollbar(totalCount as Integer)
    if totalCount <= m.playlistWindowSize then return
    trackX = 1200
    trackY = 206
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

sub openManageDialog(playlistId as String, playlistTitle as String, isProtected as Boolean)
    m.pendingManageId = playlistId
    m.pendingManageTitle = playlistTitle
    m.manageProtected = isProtected
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Manage " + playlistTitle
    dialog.message = "Choose an action for this playlist."
    if isProtected then
        dialog.buttons = ["Refresh", "Cancel"]
    else
        dialog.buttons = ["Refresh", "Edit", "Delete", "Cancel"]
    end if
    dialog.observeField("buttonSelected", "onManageDialogButton")
    m.manageDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub closeManageDialog()
    if m.top <> invalid and m.top.getScene() <> invalid then m.top.getScene().dialog = invalid
    m.manageDialog = invalid
end sub

sub onManageDialogButton()
    if m.manageDialog = invalid then return
    selected = m.manageDialog.buttonSelected
    playlistId = m.pendingManageId
    playlistTitle = m.pendingManageTitle
    isProtected = m.manageProtected
    closeManageDialog()

    if selected = 0 then
        openRefreshConfirm(playlistId, playlistTitle)
    else if not isProtected and selected = 1 then
        playlistStoreSetPendingEdit(playlistId)
        m.top.navigateTo = "AddPlaylistPage"
    else if not isProtected and selected = 2 then
        openDeleteConfirm(playlistId, playlistTitle)
    end if
end sub

sub openRefreshConfirm(playlistId as String, playlistTitle as String)
    m.pendingManageId = playlistId
    m.pendingManageTitle = playlistTitle
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Refresh playlist?"
    dialog.message = "Validate " + playlistTitle + " and prepare it for the latest provider content."
    dialog.buttons = ["Cancel", "Refresh"]
    dialog.observeField("buttonSelected", "onRefreshDialogButton")
    m.refreshDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub closeRefreshDialog()
    if m.top <> invalid and m.top.getScene() <> invalid then m.top.getScene().dialog = invalid
    m.refreshDialog = invalid
end sub

sub onRefreshDialogButton()
    if m.refreshDialog = invalid then return
    selected = m.refreshDialog.buttonSelected
    playlistId = m.pendingManageId
    closeRefreshDialog()
    if selected = 1 then
        if playlistStoreBool(playlistStoreGet(playlistId), "backendManaged", false) then
            startBackendPlaylistRefresh(playlistId)
            return
        end if
        m.refreshingId = playlistId
        m.feedbackSuccess = true
        m.feedbackMessage = "Validating playlist details..."
        render()
        m.refreshTimer.control = "stop"
        m.refreshTimer.control = "start"
    end if
end sub

sub startBackendPlaylistRefresh(playlistId as String)
    p = playlistStoreGet(playlistId)
    backendId = playlistStoreText(p, "backendPlaylistId")
    if backendId = "" then
        m.feedbackSuccess = false
        m.feedbackMessage = "Backend playlist ID is missing."
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.feedbackSuccess = false
        m.feedbackMessage = "Backend connection is unavailable."
        render()
        return
    end if

    m.refreshingId = playlistId
    m.backendAction = "refresh"
    m.backendActionPlaylistId = playlistId
    m.feedbackSuccess = true
    m.feedbackMessage = "Starting backend refresh..."
    task.observeField("response", "onBackendPlaylistAction")
    task.request = backendApiRefreshPlaylistRequest(backendId)
    m.backendActionTask = task
    render()
    task.control = "RUN"
end sub

sub finishPlaylistRefresh()
    if m.refreshingId = "" then return
    result = playlistStoreRefreshResult(m.refreshingId)
    m.refreshingId = ""
    m.feedbackSuccess = result.success
    m.feedbackMessage = result.message
    m.playlists = playlistStoreList()
    render()
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
        if playlistStoreBool(playlistStoreGet(m.pendingDeleteId), "backendManaged", false) then
            playlistId = m.pendingDeleteId
            playlistTitle = m.pendingDeleteTitle
            closeDeleteDialog()
            startBackendPlaylistDelete(playlistId, playlistTitle)
            return
        end if
        deletedTitle = m.pendingDeleteTitle
        deleted = playlistStoreDelete(m.pendingDeleteId)
        m.playlists = playlistStoreList()
        m.feedbackSuccess = deleted
        if deleted then
            m.feedbackMessage = deletedTitle + " was deleted."
        else
            m.feedbackMessage = "This protected playlist cannot be deleted."
        end if
    end if
    closeDeleteDialog()
    normalizePlaylistFocus(filteredPlaylists().count())
    render()
end sub

sub startBackendPlaylistDelete(playlistId as String, playlistTitle as String)
    p = playlistStoreGet(playlistId)
    backendId = playlistStoreText(p, "backendPlaylistId")
    if backendId = "" then
        m.feedbackSuccess = false
        m.feedbackMessage = "Backend playlist ID is missing."
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.feedbackSuccess = false
        m.feedbackMessage = "Backend connection is unavailable."
        render()
        return
    end if

    m.backendAction = "delete"
    m.backendActionPlaylistId = playlistId
    m.pendingDeleteTitle = playlistTitle
    m.feedbackSuccess = true
    m.feedbackMessage = "Deleting playlist from backend..."
    task.observeField("response", "onBackendPlaylistAction")
    task.request = backendApiDeletePlaylistRequest(backendId)
    m.backendActionTask = task
    render()
    task.control = "RUN"
end sub

sub onBackendPlaylistAction()
    if m.backendActionTask = invalid then return
    response = m.backendActionTask.response
    action = m.backendAction
    playlistId = m.backendActionPlaylistId
    playlistTitle = m.pendingDeleteTitle

    m.backendActionTask = invalid
    m.backendAction = ""
    m.backendActionPlaylistId = ""
    m.refreshingId = ""

    if not backendApiResponseOk(response) then
        m.feedbackSuccess = false
        if action = "delete" then
            m.feedbackMessage = "Backend could not delete " + playlistTitle + "."
        else
            m.feedbackMessage = "Backend refresh could not be started."
        end if
        render()
        return
    end if

    if action = "delete" then
        deleted = playlistStoreDeleteBackendLocalOnly(playlistId)
        m.playlists = playlistStoreList()
        m.feedbackSuccess = deleted
        if deleted then
            m.feedbackMessage = playlistTitle + " was deleted."
        else
            m.feedbackMessage = "Playlist was deleted on backend, but local cleanup failed."
        end if
    else
        playlistStoreMarkBackendImporting(playlistId)
        m.playlists = playlistStoreList()
        m.feedbackSuccess = true
        m.feedbackMessage = "Backend refresh started."
    end if

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
    uiLabel(m.canvas, "Use Add Playlist to connect an M3U playlist.", 478, 392, 400, 24, 12, m.colors.textDim, "center")
end sub

function filteredPlaylists() as Object
    out = []
    active = invalid
    activeId = playlistStoreActiveId()
    query = LCase(m.searchQuery)
    for i = 0 to m.playlists.count() - 1
        p = m.playlists[i]
        searchable = LCase(playlistStoreText(p, "title") + " " + playlistStoreText(p, "meta") + " " + playlistStoreText(p, "status") + " " + playlistStoreText(p, "type"))
        if query = "" or Instr(1, searchable, query) > 0 then
            row = { playlist: p, index: i }
            if playlistStoreText(p, "id") = activeId then
                active = row
            else
                out.push(row)
            end if
        end if
    end for
    if active = invalid then return out
    sorted = [active]
    for each row in out
        sorted.push(row)
    end for
    return sorted
end function

function playlistSummary(items as Object) as Object
    activeCount = 0
    readyCount = 0
    offlineCount = 0
    total = 0
    activeId = playlistStoreActiveId()
    for each item in items
        if playlistStoreText(item, "id") = activeId then
            activeCount += 1
        else if playlistStoreText(item, "status") = "Offline" then
            offlineCount += 1
        else
            readyCount += 1
        end if
        total += playlistStoreNumber(item, "itemCount")
    end for
    playlistWord = " playlists"
    if items.count() = 1 then playlistWord = " playlist"
    return {
        countText: items.count().toStr() + playlistWord,
        totalText: formatCount(total) + " items total",
        statusText: activeCount.toStr() + " active - " + readyCount.toStr() + " ready - " + offlineCount.toStr() + " offline - last sync " + latestSyncText(items)
    }
end function

function latestSyncText(items as Object) as String
    if items.count() = 0 then return "not synced yet"
    for each item in items
        if playlistStoreText(item, "lastSync") = "just now" then return "just now"
    end for
    return "not synced yet"
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
    else if selected = "CASE" then
        m.searchKeyboardUpper = not m.searchKeyboardUpper
        render()
        return
    else
        if m.searchQuery.len() < 28 then m.searchQuery += uiKeyboardInputText(selected, m.searchKeyboardUpper)
    end if
    m.focusIndex = 7
    render()
end sub

sub closeSearchKeyboard()
    m.searchEditing = false
    render()
end sub

sub clearPlaylistSearchAndStay()
    m.searchQuery = ""
    m.playlistWindowStart = 0
    searchIndex = findPlaylistActionFocus("search")
    if searchIndex >= 0 then m.focusIndex = searchIndex
    render()
end sub

sub drawSearchKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", 220, 104, 840, 524, 1.0)
    uiLabel(m.canvas, "Search Playlists", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", 300, 188, 680, 48, 0.90)
    uiLabel(m.canvas, m.searchQuery, 324, 196, 632, 32, 17, m.colors.text, "left")

    keyW = 68
    keyH = 40
    gap = 7
    startX = 268
    startY = 268
    for i = 0 to m.searchKeys.count() - 1
        keyRect = uiKeyboardKeyRect(m.searchKeys, i, startX, startY, keyW, keyH, gap)
        keyLabel = m.searchKeys[i]
        uiDrawKeyboardKey(m.canvas, keyLabel, uiKeyboardDisplayText(keyLabel, m.searchKeyboardUpper), keyRect.x, keyRect.y, keyRect.w, keyRect.h, i = m.searchKeyboardIndex, m.colors)
    end for
end sub
