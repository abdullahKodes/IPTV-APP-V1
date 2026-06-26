sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("liveTvCanvas")
    m.video = m.top.findNode("livePlayerVideo")
    m.overlay = m.top.findNode("liveTvOverlay")
    m.focusItems = []
    m.focusIndex = 1
    m.focusArea = "normal"
    m.categoryIndex = 0
    m.focusedCategoryIndex = 0
    m.categoryWindowStart = 0
    m.categoryWindowSize = 6
    m.categoryColumns = 3
    m.channelIndex = 0
    m.selectedChannelIndex = 0
    m.channelWindowStart = 0
    m.channelWindowSize = 6
    m.playing = true
    m.fullscreen = false
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    m.activePlaylist = playlistStoreActive()
    m.activePlaylistId = playlistStoreText(m.activePlaylist, "id", playlistStoreDemoId())
    m.activePlaylistTitle = playlistStoreText(m.activePlaylist, "title", "Demo Playlist")
    m.channels = mediaLiveCatalogForPlaylist(m.activePlaylistId)
    applyLiveFavoriteState()
    m.categories = liveCategoriesFromChannels(m.channels)
    setupVideo()
    render()
end sub

sub refreshClock()
    if m.clock <> invalid then now = uiNowStrings() : m.clock.text = now.time : m.date.text = now.date
end sub

function handleKey(key as String) as Boolean
    if m.searchEditing then return handleSearchKeyboardKey(key)
    if m.fullscreen and key = "back" then m.fullscreen = false : render() : return true
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    if routeLiveFocus(dx, dy) then render() : return
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    syncLiveFocus()
    render()
end sub

function routeLiveFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then m.focusIndex = 0
    current = m.focusItems[m.focusIndex]
    action = ""
    if current.doesExist("action") then action = current.action

    if action <> "channel" and action <> "cat" then m.focusArea = "normal"
    searchIndex = findFocusAction("search")

    if dx > 0 and liveItemCol(current) = 0 then
        m.focusedCategoryIndex = m.categoryIndex
        m.focusArea = "categories"
        normalizeCategoryWindow()
        categoryFocus = findCategoryFocus(m.focusedCategoryIndex)
        if categoryFocus >= 0 then m.focusIndex = categoryFocus
        return true
    end if

    if action = "search" then
        if dy > 0 then
            m.focusedCategoryIndex = m.categoryIndex
            m.focusArea = "categories"
            normalizeCategoryWindow()
            return true
        end if
        if dx < 0 then
            m.focusedCategoryIndex = m.categoryIndex
            m.focusArea = "categories"
            normalizeCategoryWindow()
            return true
        end if
    end if

    if action = "cat" then
        if current.doesExist("catIndex") then m.focusedCategoryIndex = current.catIndex
        nextCat = m.focusedCategoryIndex
        if dx < 0 then nextCat = m.focusedCategoryIndex - 1
        if dx > 0 then nextCat = m.focusedCategoryIndex + 1
        if dy < 0 then nextCat = m.focusedCategoryIndex - m.categoryColumns
        if dy > 0 then nextCat = m.focusedCategoryIndex + m.categoryColumns
        if dx < 0 and nextCat < 0 then
            m.focusArea = "normal"
            m.focusIndex = 1
            return true
        end if
        if dx > 0 and nextCat > m.categories.count() - 1 then
            return true
        end if
        if dy > 0 and nextCat > m.categories.count() - 1 then
            firstChannel = findChannelFocus(0)
            if firstChannel >= 0 then
                m.focusArea = "channels"
                m.selectedChannelIndex = m.channelWindowStart
                m.focusIndex = firstChannel
                return true
            end if
        end if
        if dy < 0 and nextCat < 0 then
            if searchIndex >= 0 then
                m.focusArea = "normal"
                m.focusIndex = searchIndex
                return true
            end if
        end if
        if nextCat >= 0 and nextCat <= m.categories.count() - 1 then
            m.focusedCategoryIndex = nextCat
            m.focusArea = "categories"
            normalizeCategoryWindow()
            return true
        end if
    end if

    if action = "channel" then
        visible = filteredChannels()
        if current.doesExist("visibleIndex") then m.selectedChannelIndex = current.visibleIndex
        if dy < 0 and m.selectedChannelIndex > 0 then
            m.selectedChannelIndex -= 1
            m.focusArea = "channels"
            normalizeChannelWindow(visible.count())
            return true
        end if
        if dy > 0 and m.selectedChannelIndex < visible.count() - 1 then
            m.selectedChannelIndex += 1
            m.focusArea = "channels"
            normalizeChannelWindow(visible.count())
            return true
        end if
        if dy < 0 then
            m.focusedCategoryIndex = m.categoryIndex
            m.focusArea = "categories"
            normalizeCategoryWindow()
            return true
        end if
        if dx > 0 then
            playIndex = findPlayerControl("playpause")
            if playIndex >= 0 then
                m.focusArea = "normal"
                m.focusIndex = playIndex
                return true
            end if
        end if
        if dx < 0 then
            m.focusedCategoryIndex = m.categoryIndex
            m.focusArea = "categories"
            normalizeCategoryWindow()
            return true
        end if
    end if

    if dy < 0 and action = "playerControl" then
        control = ""
        if current.doesExist("control") then control = current.control
        if control <> "favorite" then
            favoriteIndex = findPlayerControl("favorite")
            if favoriteIndex >= 0 then m.focusIndex = favoriteIndex : return true
        end if
        if searchIndex >= 0 then m.focusIndex = searchIndex : return true
    end if

    if dy > 0 and action = "playerControl" then
        control = ""
        if current.doesExist("control") then control = current.control
        if control = "favorite" then
            playIndex = findPlayerControl("playpause")
            if playIndex >= 0 then m.focusIndex = playIndex : return true
        end if
    end if

    if dx < 0 and action = "playerControl" then
        control = ""
        if current.doesExist("control") then control = current.control
        if control <> "playpause" then return false
        visible = filteredChannels()
        if visible.count() > 0 then
            m.focusArea = "channels"
            normalizeChannelWindow(visible.count())
            channelFocus = findChannelFocus(m.selectedChannelIndex)
            if channelFocus >= 0 then m.focusIndex = channelFocus
            return true
        end if
    end if

    return false
end function

function liveItemCol(item as Object) as Integer
    if item <> invalid and item.doesExist("col") then return item.col
    return -1
end function

function findFocusAction(action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = action then return i
    end for
    return -1
end function

function findCategoryFocus(catIndex as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "cat" and item.catIndex = catIndex then return i
    end for
    return -1
end function

function findChannelFocus(visibleIndex as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "channel" and item.visibleIndex = visibleIndex then return i
    end for
    return -1
end function

function findPlayerControl(control as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "playerControl" and item.control = control then return i
    end for
    return -1
end function

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "cat" then selectLiveCategory(item.catIndex) : return
    if item.action = "channel" then m.selectedChannelIndex = item.visibleIndex : m.channelIndex = item.channelIndex : playSelectedChannel() : render() : return
    if item.action = "playerControl" then handlePlayerControl(item.control) : render() : return
    if item.action = "search" then openSearchKeyboard() : return
end sub

sub selectLiveCategory(categoryIndex as Integer)
    if categoryIndex < 0 or categoryIndex >= m.categories.count() then return
    m.categoryIndex = categoryIndex
    m.focusedCategoryIndex = categoryIndex
    m.channelWindowStart = 0
    m.selectedChannelIndex = 0
    visible = filteredChannels()
    if visible.count() > 0 then
        m.channelIndex = visible[0].index
    end if
    render()
end sub

sub render()
    uiClear(m.canvas)
    if m.overlay <> invalid then uiClear(m.overlay)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = drawLiveSideNav()

    drawSearchBox()
    visible = filteredChannels()
    m.hasVisibleChannels = visible.count() > 0
    if not m.hasVisibleChannels then
        uiLabel(m.canvas, "No live channels in " + m.activePlaylistTitle, 392, 316, 520, 34, 18, m.colors.textDim, "center")
        uiLabel(m.canvas, "Switch playlist or add one with live TV.", 392, 354, 520, 26, 12, m.colors.textMuted, "center")
        updateVideoLayout()
        uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
        if m.searchEditing then drawSearchKeyboardOverlay()
        return
    end if
    if m.hasVisibleChannels then uiRect(m.canvas, 550, 86, 1, 634, "0xFFFFFF12")
    channelRow = drawCategoryPills(row)
    drawChannelDivider()
    syncSelectedChannelFromVisible(visible)
    normalizeChannelWindow(visible.count())
    drawRightSectionBackdrop(displayChannel(visible))
    endIndex = m.channelWindowStart + m.channelWindowSize - 1
    if endIndex > visible.count() - 1 then endIndex = visible.count() - 1
    slot = 0
    for i = m.channelWindowStart to endIndex
        rowData = visible[i]
        drawChannel(rowData.channel, rowData.index, i, 246, 234 + slot * 68, channelRow + slot, 1)
        slot += 1
    end for
    drawChannelScrollbar(visible.count(), 534, 234, 400)
    drawPlayer()
    updateVideoLayout()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

sub setupVideo()
    if m.video = invalid then return
    m.video.enableUI = false
    m.video.loop = true
    m.video.observeField("state", "onVideoStateChange")
    m.video.observeField("errorMsg", "onVideoError")
    playSelectedChannel()
end sub

sub playSelectedChannel()
    if m.video = invalid then return
    channel = selectedChannel()
    if channel = invalid then return
    content = CreateObject("roSGNode", "ContentNode")
    content.url = mediaPlaybackUrl(channel)
    content.streamFormat = mediaPlaybackFormat(channel)
    content.title = liveText(channel, "name", liveText(channel, "title", "Live TV"))
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    m.video.control = "stop"
    m.video.content = content
    m.playing = true
    m.video.control = "play"
end sub

sub onVideoStateChange()
    if m.video = invalid then return
    print "Live TV video state: "; m.video.state
    if m.video.state = "playing" then
        if not m.playing then m.playing = true : render()
    else if m.video.state = "paused" or m.video.state = "stopped" or m.video.state = "finished" then
        if m.playing then m.playing = false : render()
    end if
end sub

sub onVideoError()
    if m.video <> invalid then print "Live TV video error: "; m.video.errorMsg
end sub

sub handlePlayerControl(control as String)
    if control = "favorite" then toggleLiveFavorite() : return
    if control = "volume" then return
    if control = "restart" then seekPlayer(0, true) : return
    if control = "rewind" then seekPlayer(-15, false) : return
    if control = "playpause" then togglePlayback() : return
    if control = "forward" then seekPlayer(15, false) : return
    if control = "fullscreen" then m.fullscreen = not m.fullscreen : return
end sub

sub togglePlayback()
    if m.video = invalid then return
    if m.playing then
        m.video.control = "pause"
        m.playing = false
    else
        m.video.control = "resume"
        m.playing = true
    end if
end sub

sub seekPlayer(offset as Integer, absolute as Boolean)
    if m.video = invalid then return
    target = 0
    if not absolute then
        target = m.video.position + offset
        if target < 0 then target = 0
    end if
    m.video.seek = target
end sub

sub toggleLiveFavorite()
    ch = selectedChannel()
    if ch = invalid then return
    isFavorite = favoriteStoreToggle("live", ch, m.activePlaylistId)
    if m.channelIndex >= 0 and m.channelIndex < m.channels.count() then m.channels[m.channelIndex].favorite = isFavorite
end sub

sub applyLiveFavoriteState()
    if m.channels = invalid then return
    for i = 0 to m.channels.count() - 1
        m.channels[i].favorite = favoriteStoreIsFavorite("live", m.channels[i], m.activePlaylistId)
    end for
end sub

sub updateVideoLayout()
    if m.video = invalid then return
    if not m.hasVisibleChannels then
        m.video.visible = false
        if m.overlay <> invalid then m.overlay.visible = false
        return
    end if
    if m.searchEditing then
        m.video.visible = false
        if m.overlay <> invalid then m.overlay.visible = false
        return
    end if
    if m.fullscreen then
        m.video.translation = [0, 0]
        m.video.width = 1280
        m.video.height = 720
        if m.overlay <> invalid then m.overlay.visible = false
    else if liveUsesDemoArtwork() then
        m.video.translation = [669, 190]
        m.video.width = 398
        m.video.height = 224
        if m.overlay <> invalid then m.overlay.visible = true
    else
        m.video.translation = [592, 212]
        m.video.width = 552
        m.video.height = 310
        if m.overlay <> invalid then m.overlay.visible = true
    end if
    m.video.visible = true
end sub

function drawLiveSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addLiveNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addLiveNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, true)
    addLiveNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addLiveNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addLiveNavItem(12, 336, "heart", "Favorites", "FavoritesPage", 4, false)
    addLiveNavItem(12, 392, "settings", "Settings", "SettingsPage", 5, false)

    addLiveProfileItem()
    return 6
end function

sub addLiveNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
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

sub addLiveProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: 6, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawSearchBox()
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    bg = m.colors.panel
    border = m.colors.whiteLine
    textColor = m.colors.textDim
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    label = "Search channels"
    if m.searchQuery <> "" then label = m.searchQuery
    uiRoundRect(m.canvas, 686, 24, 260, 40, bg, border)
    uiDrawIcon(m.canvas, "search", 704, 34, 18, 18, focused, textColor, 11)
    uiLabel(m.canvas, label, 734, 27, 198, 28, 12, textColor)
    m.focusItems.push({
        x: 686, y: 24, w: 260, h: 40,
        icon: "search", label: label, subtitle: "",
        iconSize: 11, titleSize: 13, subSize: 10,
        bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 0, col: 1, page: "", action: "search", mode: "manual"
    })
end sub

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
    current = m.searchQuery
    if selected = "DONE" then
        closeSearchKeyboard()
        return
    end if
    if selected = "CLEAR" then
        current = ""
    else if selected = "DEL" then
        if current.len() > 0 then current = current.left(current.len() - 1)
    else if selected = "SPACE" then
        if current.len() >= 64 then return
        current += " "
    else
        if current.len() >= 64 then return
        current += selected
    end if
    m.searchQuery = current
    m.channelWindowStart = 0
    m.selectedChannelIndex = 0
    m.focusArea = "normal"
    render()
end sub

sub closeSearchKeyboard()
    m.searchEditing = false
    render()
end sub

sub drawSearchKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiRect(m.canvas, 260, 116, 760, 488, m.colors.panel, 0.98)
    uiLabel(m.canvas, "Search channels", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiRect(m.canvas, 330, 188, 620, 48, m.colors.bg2)
    searchText = m.searchQuery
    if searchText = "" then searchText = "Search channels"
    uiLabel(m.canvas, searchText, 350, 196, 580, 32, 17, m.colors.text, "left")

    keyW = 56
    keyH = 42
    gap = 8
    startX = 324
    startY = 268
    for i = 0 to m.searchKeys.count() - 1
        row = Int(i / 10)
        col = i mod 10
        x = startX + col * (keyW + gap)
        y = startY + row * (keyH + gap)
        keyLabel = m.searchKeys[i]
        if keyLabel = "SPACE" then keyLabel = "Space"
        if keyLabel = "DEL" then keyLabel = "Del"
        if keyLabel = "CLEAR" then keyLabel = "Clear"
        if keyLabel = "DONE" then keyLabel = "Done"
        bg = m.colors.bg
        border = m.colors.whiteLine
        text = m.colors.text
        if i = m.searchKeyboardIndex then
            bg = m.colors.purpleSoft
            border = m.colors.greenFocus
        end if
        uiRect(m.canvas, x, y, keyW, keyH, bg)
        uiRect(m.canvas, x, y, keyW, 2, border)
        uiRect(m.canvas, x, y + keyH - 2, keyW, 2, border)
        uiRect(m.canvas, x, y, 2, keyH, border)
        uiRect(m.canvas, x + keyW - 2, y, 2, keyH, border)
        uiLabel(m.canvas, keyLabel, x, y + 5, keyW, 28, 12, text, "center")
    end for
end sub

function filteredChannels() as Object
    results = []
    query = LCase(m.searchQuery)
    category = liveCategoryLabel(m.categoryIndex)
    for i = 0 to m.channels.count() - 1
        ch = m.channels[i]
        channelCategory = liveChannelCategory(ch)
        searchable = LCase(liveText(ch, "name") + " " + liveText(ch, "title") + " " + liveText(ch, "now") + " " + channelCategory + " " + liveText(ch, "channelNumber"))
        matchSearch = (query = "") or (Instr(1, searchable, query) > 0)
        matchCategory = (category = "All") or (LCase(channelCategory) = LCase(category))
        if matchSearch and matchCategory then
            results.push({ channel: ch, index: i })
        end if
    end for
    return results
end function

function liveCategoryLabel(index as Integer) as String
    if index >= 0 and index < m.categories.count() then return m.categories[index]
    return "All"
end function

function drawCategoryPills(row as Integer) as Integer
    slots = [
        { x: 246, y: 104, w: 62, row: row, col: 1 },
        { x: 320, y: 104, w: 82, row: row, col: 2 },
        { x: 414, y: 104, w: 76, row: row, col: 3 },
        { x: 246, y: 150, w: 82, row: row + 1, col: 1 },
        { x: 340, y: 150, w: 70, row: row + 1, col: 2 },
        { x: 422, y: 150, w: 70, row: row + 1, col: 3 }
    ]
    m.categoryWindowSize = slots.count()
    normalizeCategoryWindow()
    endIndex = m.categoryWindowStart + m.categoryWindowSize - 1
    if endIndex > m.categories.count() - 1 then endIndex = m.categories.count() - 1
    slot = 0
    for i = m.categoryWindowStart to endIndex
        cat = slots[slot]
        itemIndex = m.focusItems.count()
        focused = itemIndex = m.focusIndex
        if m.focusArea = "categories" then
            focused = i = m.focusedCategoryIndex
            if focused then m.focusIndex = itemIndex
        end if
        selected = i = m.categoryIndex
        bg = m.colors.bg
        border = m.colors.whiteLine
        textColor = m.colors.textPurple
        if selected then
            bg = m.colors.purpleSoft
            border = m.colors.greenFocus
            textColor = m.colors.text
        end if
        if focused then
            bg = m.colors.greenSoft
            border = m.colors.greenFocus
            textColor = m.colors.text
        end if
        label = liveCategoryDisplayLabel(m.categories[i])
        uiRoundRect(m.canvas, cat.x, cat.y, cat.w, 34, bg, border)
        uiLabel(m.canvas, label, cat.x, cat.y + 1, cat.w, 30, 12, textColor, "center")
        item = {
            x: cat.x, y: cat.y, w: cat.w, h: 34,
            icon: "", label: label, subtitle: "",
            iconSize: 1, titleSize: 12, subSize: 10,
            bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
            focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
            row: cat.row, col: cat.col, page: "", action: "cat", catIndex: i, mode: "manual"
        }
        m.focusItems.push(item)
        slot += 1
    end for
    drawCategoryWindowIndicator()
    return row + 2
end function

sub drawCategoryWindowIndicator()
    if m.categories.count() <= m.categoryWindowSize then return
    trackX = 246
    trackY = 196
    trackW = 246
    uiRect(m.canvas, trackX, trackY, trackW, 2, "0xFFFFFF18", 0.70)
    maxStart = m.categories.count() - m.categoryWindowSize
    if maxStart < 1 then maxStart = 1
    thumbW = Int(trackW * m.categoryWindowSize / m.categories.count())
    if thumbW < 42 then thumbW = 42
    if thumbW > trackW then thumbW = trackW
    thumbX = trackX
    if trackW > thumbW then thumbX = trackX + Int((trackW - thumbW) * m.categoryWindowStart / maxStart)
    uiRect(m.canvas, thumbX, trackY, thumbW, 2, m.colors.greenFocus, 0.86)
end sub

sub drawChannelDivider()
    uiRect(m.canvas, 246, 218, 280, 1, "0xFFFFFF18")
    uiRect(m.canvas, 246, 218, 72, 1, m.colors.greenFocus, 0.72)
end sub

sub drawChannel(ch as Object, channelIndex as Integer, visibleIndex as Integer, x as Integer, y as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if m.focusArea = "channels" then
        focused = visibleIndex = m.selectedChannelIndex
        if focused then m.focusIndex = itemIndex
    end if
    selected = channelIndex = m.channelIndex
    w = 276
    h = 60
    bg = m.colors.panel
    border = m.colors.whiteLine
    titleColor = m.colors.text
    subColor = m.colors.textMuted
    logoOpacity = 0.96
    if selected then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        subColor = m.colors.text
        logoOpacity = 1.0
    end if
    if focused then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
        subColor = m.colors.text
        logoOpacity = 1.0
    end if

    title = liveText(ch, "name", liveText(ch, "title", "Untitled"))
    nowText = liveText(ch, "now", liveText(ch, "programTitle"))
    if liveUsesDemoArtwork() then
        badgeUrl = liveArtUrl(ch, false)
        hasBadge = badgeUrl <> ""
        textX = x + 74
        textW = 174
        if hasBadge then
            textX = x + 18
            textW = 170
        end if
        if liveFlag(ch, "live") then textW = 120

        if hasBadge then
            uiPoster(m.canvas, badgeUrl, x, y, w, h, 1.0)
            if selected then uiRoundRect(m.canvas, x, y, w, h, m.colors.purpleSoft, m.colors.greenFocus, 0.28)
            if focused then uiRoundRect(m.canvas, x, y, w, h, m.colors.greenSoft, m.colors.greenFocus, 0.46)
        else
            uiRoundRect(m.canvas, x, y, w, h, bg, border)
            brandColor = liveText(ch, "brandColor", m.colors.greenFocus)
            uiRect(m.canvas, x + 1, y + 9, 3, h - 18, brandColor, 0.86)
            logoUrl = liveText(ch, "logoUrl")
            if logoUrl <> "" then
                uiPoster(m.canvas, logoUrl, x + 12, y + 15, 48, 30, logoOpacity)
            else
                uiRect(m.canvas, x + 12, y + 12, 42, 36, m.colors.purpleSoft, 0.9)
                uiDrawIcon(m.canvas, liveText(ch, "icon", "tv"), x + 19, y + 20, 18, 18, focused, titleColor, 8)
            end if
        end if
    else
        logoUrl = liveLogoArtUrl(ch)
        brandColor = liveText(ch, "brandColor", m.colors.greenFocus)
        textX = x + 68
        textW = w - 88
        if liveFlag(ch, "live") then textW = 126

        uiRoundRect(m.canvas, x, y, w, h, bg, border)
        uiRect(m.canvas, x + 1, y + 8, 3, h - 16, brandColor, 0.88)
        drawChannelRowBrand(ch, logoUrl, x, y, w, h, focused or selected)
    end if

    uiLabel(m.canvas, title, textX, y + 7, textW, 22, 9, titleColor)
    uiLabel(m.canvas, nowText, textX, y + 32, textW, 18, 6, subColor)
    if liveFlag(ch, "live") then
        drawLiveBadge(x + 202, y + 19)
    end if

    item = {
        x: x, y: y, w: w, h: h,
        icon: liveText(ch, "icon", "tv"), label: title, subtitle: nowText,
        iconSize: 8, iconW: 36, iconH: 36, iconX: 12,
        labelX: 74, labelW: textW, labelAlign: "left",
        titleSize: 6, subSize: 5,
        bg: bg, border: border, textColor: titleColor, subColor: subColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "channel", channelIndex: channelIndex, visibleIndex: visibleIndex, mode: "manual"
    }
    m.focusItems.push(item)
end sub

sub drawChannelRowBrand(ch as Object, logoUrl as String, x as Integer, y as Integer, w as Integer, h as Integer, emphasized as Boolean)
    brandColor = liveText(ch, "brandColor", m.colors.greenFocus)
    uiRect(m.canvas, x + 10, y + 10, 46, 40, m.colors.bg, 0.48)
    uiRectBorder(m.canvas, x + 10, y + 10, 46, 40, "0xFFFFFF18", 1, 0.72)
    if logoUrl <> "" then
        uiPoster(m.canvas, logoUrl, x + 15, y + 17, 36, 26, 0.96)
        uiRect(m.canvas, x + w - 58, y + 1, 56, h - 2, brandColor, 0.08)
    else
        uiRect(m.canvas, x + 16, y + 15, 34, 30, brandColor, 0.22)
        uiDrawIcon(m.canvas, liveText(ch, "icon", "tv"), x + 23, y + 21, 18, 18, emphasized, m.colors.text, 8)
    end if
end sub

sub drawLiveBadge(x as Integer, y as Integer)
    uiPoster(m.canvas, "pkg:/images/ui/live_badge.png", x, y, 64, 22)
end sub

sub drawPlayer()
    panelX = 568
    panelY = 108
    panelW = 600
    panelH = 500
    videoX = panelX + 24
    videoY = panelY + 104
    videoW = panelW - 48
    videoH = 310
    controlsY = panelY + 424
    progressY = panelY + 441
    epgTitleY = 622
    epgY = 650
    if liveUsesDemoArtwork() then
        panelH = 390
        videoX = panelX + 101
        videoY = panelY + 82
        videoW = 398
        videoH = 224
        controlsY = panelY + 320
        progressY = panelY + 337
        epgTitleY = 526
        epgY = 562
    end if
    ch = displayChannel(invalid)
    channelTitle = liveText(ch, "name", liveText(ch, "title", "Live TV"))
    nowText = liveText(ch, "now", liveText(ch, "programTitle", "Select a channel"))
    uiRoundRect(m.canvas, panelX, panelY, panelW, panelH, m.colors.purpleActive, m.colors.greenFocus, 0.32)
    if not liveUsesDemoArtwork() then drawPlayerPanelBrand(ch, panelX, panelY, panelW, panelH)

    if liveFlag(ch, "live") then drawLiveBadge(panelX + 24, panelY + 22)
    titleX = panelX + 24
    if liveFlag(ch, "live") then titleX = panelX + 94
    uiLabel(m.canvas, channelTitle, titleX, panelY + 18, 246, 24, 13, m.colors.text)
    uiLabel(m.canvas, nowText, panelX + 24, panelY + 50, 380, 26, 14, m.colors.text)
    addPlayerControl(panelX + panelW - 76, panelY + 28, 50, "player_heart", "Favorite", "favorite", 8, 6, 32, invalid, liveFlag(ch, "favorite"))

    uiRoundRect(m.canvas, videoX, videoY, videoW, videoH, m.colors.black, m.colors.black, 0.94)
    if not m.playing then addPlayerControl(videoX + 244, videoY + Int((videoH - 64) / 2), 64, "player_play", "Play", "playpause", 9, 5, 64, m.overlay)

    drawPlayerControls(panelX + 24, controlsY)
    uiRect(m.canvas, panelX + 82, progressY, 330, 3, "0xFFFFFF18")
    uiRect(m.canvas, panelX + 82, progressY, 220, 3, m.colors.greenFocus, 0.72)

    uiLabel(m.canvas, "UP NEXT ON " + channelTitle, panelX, epgTitleY, 360, 22, 10, m.colors.textDim)
    epg = currentEpgRows(ch)
    for i = 0 to epg.count() - 1
        item = epg[i]
        drawEpg(liveText(item, "time"), liveText(item, "title", "Upcoming"), 568 + i * 196, epgY)
    end for
end sub

sub drawPlayerControls(x as Integer, y as Integer)
    addPlayerControl(x, y, 48, "player_play", "Play", "playpause", 10, 3, 32)
    addPlayerControl(x + 394, y, 48, "player_volume", "Volume", "volume", 10, 4, 32)
    addPlayerControl(x + 448, y, 48, "player_replay", "Replay", "restart", 10, 5, 32)
    addPlayerControl(x + 502, y, 48, "player_full", "Full", "fullscreen", 10, 6, 32)
end sub

sub drawPlayerPanelBrand(ch as Dynamic, x as Integer, y as Integer, w as Integer, h as Integer)
    brandColor = liveText(ch, "brandColor", m.colors.greenFocus)
    brandColor2 = liveText(ch, "brandColor2", m.colors.purpleActive)
    brandText = liveBrandText(ch)
    uiRect(m.canvas, x + 2, y + 2, w - 4, 78, brandColor2, 0.22)
    uiRect(m.canvas, x + 2, y + 78, w - 4, 1, brandColor, 0.18)
    uiRect(m.canvas, x + w - 180, y + 2, 178, h - 4, brandColor, 0.08)
    uiRect(m.canvas, x + w - 172, y + 18, 118, 48, m.colors.bg, 0.18)
    uiRectBorder(m.canvas, x + w - 172, y + 18, 118, 48, brandColor, 1, 0.22)
    uiLabel(m.canvas, brandText, x + w - 164, y + 24, 102, 34, 16, "0xFFFFFF18", "center")
    uiLabel(m.canvas, brandText, x + w - 184, y + h - 98, 136, 58, 28, "0xFFFFFF0E", "right")
    uiRect(m.canvas, x + 2, y + 2, w - 4, h - 4, m.colors.bg, 0.16)
end sub

sub addPlayerControl(x as Integer, y as Integer, w as Integer, icon as String, label as String, control as String, row as Integer, col as Integer, iconSize = 18 as Integer, target = invalid as Object, active = false as Boolean)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if target = invalid then target = m.canvas
    textColor = m.colors.textMuted
    if active then textColor = m.colors.amber
    if focused then
        textColor = m.colors.text
        if active then textColor = m.colors.amber
    end if
    iconX = x + Int((w - iconSize) / 2)
    iconY = y + Int((36 - iconSize) / 2)
    if iconSize > 36 then iconY = y
    if icon = "player_play" and iconSize > 36 then
        circleBorder = m.colors.textMuted
        if focused then circleBorder = m.colors.greenFocus
        uiRoundRect(target, iconX, iconY, iconSize, iconSize, m.colors.black, circleBorder, 0.58)
    end if
    uiDrawIcon(target, icon, iconX, iconY, iconSize, iconSize, focused, textColor, 10)
    if focused and iconSize <= 36 then uiRect(target, x + Int((w - 28) / 2), y + 32, 28, 2, m.colors.greenFocus, 0.9)
    controlH = 36
    if iconSize > controlH then controlH = iconSize
    m.focusItems.push({
        x: x, y: y, w: w, h: controlH,
        icon: icon, label: label, subtitle: "",
        iconSize: 10, titleSize: 10, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.bg, focusBorder: m.colors.bg, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "playerControl", control: control, mode: "manual"
    })
end sub

sub drawEpg(time as String, title as String, x as Integer, y as Integer)
    uiRoundRect(m.canvas, x, y, 190, 54, m.colors.panel, m.colors.whiteLine, 0.88)
    uiLabel(m.canvas, time, x + 12, y + 4, 80, 18, 8, m.colors.greenFocus)
    uiLabel(m.canvas, title, x + 12, y + 28, 158, 20, 8, m.colors.text)
end sub

sub drawChannelScrollbar(total as Integer, x as Integer, y as Integer, h as Integer)
    if total <= m.channelWindowSize then return
    uiVerticalPill(m.canvas, x, y, 3, h, "0xFFFFFF18", "pkg:/images/ui/scroll_cap_4_whiteLine.png", 0.56)
    maxStart = total - m.channelWindowSize
    if maxStart < 1 then maxStart = 1
    thumbH = Int(h * m.channelWindowSize / total)
    if thumbH < 42 then thumbH = 42
    if thumbH > h then thumbH = h
    thumbY = y
    if h > thumbH then thumbY = y + Int((h - thumbH) * m.channelWindowStart / maxStart)
    uiVerticalPill(m.canvas, x - 1, thumbY, 5, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.92)
end sub

sub drawRightSectionBackdrop(channel as Dynamic)
    x = 552
    y = 86
    w = 728
    h = 634
    backdropUrl = liveCategoryArtworkUrl(channel)
    if liveUsesDemoArtwork() then backdropUrl = liveArtUrl(channel, true)
    if backdropUrl <> "" then
        uiPosterZoom(m.canvas, backdropUrl, x, y, w, h, 1.0)
        if not liveUsesDemoArtwork() then drawChannelBrandBackground(channel, x, y, w, h, 0.22, true)
        bgOpacity = 0.38
        blackOpacity = 0.10
        if not liveUsesDemoArtwork() then
            bgOpacity = 0.62
            blackOpacity = 0.16
        end if
        uiRect(m.canvas, x, y, w, h, m.colors.bg, bgOpacity)
        uiRect(m.canvas, x, y, w, h, "0x000000FF", blackOpacity)
    else
        drawChannelBrandBackground(channel, x, y, w, h, 0.46, true)
        uiRect(m.canvas, x, y, w, h, m.colors.bg, 0.50)
    end if
    uiRect(m.canvas, x, y, 1, h, "0xFFFFFF12")
end sub

function liveUsesDemoArtwork() as Boolean
    return m.activePlaylistId = playlistStoreDemoId()
end function

sub drawChannelBrandBackground(channel as Dynamic, x as Integer, y as Integer, w as Integer, h as Integer, opacity as Float, large as Boolean)
    bg1 = liveText(channel, "brandColor", m.colors.purpleActive)
    bg2 = liveText(channel, "brandColor2", m.colors.bg2)
    uiRect(m.canvas, x, y, w, h, bg2, opacity)
    if large then
        uiRect(m.canvas, x, y, 108, h, bg1, opacity * 0.18)
        uiRect(m.canvas, x + 108, y, 2, h, m.colors.greenFocus, 0.12)
        uiRect(m.canvas, x, y + h - 128, w, 128, bg1, opacity * 0.10)
        uiRect(m.canvas, x + w - 260, y, 260, h, bg1, opacity * 0.07)
    else
        uiRect(m.canvas, x, y, w, h, bg2, opacity)
        uiRect(m.canvas, x, y, 58, h, bg1, opacity * 0.24)
    end if

    logoText = liveBrandText(channel)
    fontSize = 28
    logoX = x + Int(w * 0.48)
    logoY = y + Int((h - 42) / 2)
    logoW = Int(w * 0.46)
    logoH = 50
    logoColor = "0xFFFFFF16"
    if large then
        fontSize = 54
        logoX = x + Int(w * 0.56)
        logoY = y + Int((h - 78) / 2)
        logoW = Int(w * 0.36)
        logoH = 78
        logoColor = "0xFFFFFF12"
    end if
    uiLabel(m.canvas, logoText, logoX, logoY, logoW, logoH, fontSize, logoColor, "right")
end sub

sub syncLiveFocus()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    action = ""
    if item.doesExist("action") then action = item.action
    if action = "channel" then
        if item.doesExist("visibleIndex") then m.selectedChannelIndex = item.visibleIndex
        m.focusArea = "channels"
    else if action = "cat" then
        if item.doesExist("catIndex") then m.focusedCategoryIndex = item.catIndex
        m.focusArea = "categories"
    else
        m.focusArea = "normal"
    end if
end sub

sub normalizeCategoryWindow()
    if m.categories.count() <= 0 then
        m.categoryWindowStart = 0
        m.focusedCategoryIndex = 0
        return
    end if
    if m.focusedCategoryIndex < 0 then m.focusedCategoryIndex = 0
    if m.focusedCategoryIndex > m.categories.count() - 1 then m.focusedCategoryIndex = m.categories.count() - 1
    if m.categoryWindowStart < 0 then m.categoryWindowStart = 0
    maxStart = m.categories.count() - m.categoryWindowSize
    if maxStart < 0 then maxStart = 0
    if m.categoryWindowStart > maxStart then m.categoryWindowStart = maxStart
    if m.focusedCategoryIndex < m.categoryWindowStart then m.categoryWindowStart = m.focusedCategoryIndex
    if m.focusedCategoryIndex >= m.categoryWindowStart + m.categoryWindowSize then
        m.categoryWindowStart = m.focusedCategoryIndex - m.categoryWindowSize + 1
    end if
end sub

sub normalizeChannelWindow(total as Integer)
    if total <= 0 then
        m.channelWindowStart = 0
        m.selectedChannelIndex = 0
        if m.focusArea = "channels" then m.focusArea = "normal"
        return
    end if
    if m.selectedChannelIndex < 0 then m.selectedChannelIndex = 0
    if m.selectedChannelIndex > total - 1 then m.selectedChannelIndex = total - 1
    if m.channelWindowStart < 0 then m.channelWindowStart = 0
    maxStart = total - m.channelWindowSize
    if maxStart < 0 then maxStart = 0
    if m.channelWindowStart > maxStart then m.channelWindowStart = maxStart
    if m.selectedChannelIndex < m.channelWindowStart then m.channelWindowStart = m.selectedChannelIndex
    if m.selectedChannelIndex >= m.channelWindowStart + m.channelWindowSize then
        m.channelWindowStart = m.selectedChannelIndex - m.channelWindowSize + 1
    end if
end sub

sub syncSelectedChannelFromVisible(visible as Object)
    if visible.count() <= 0 then return
    for i = 0 to visible.count() - 1
        if visible[i].index = m.channelIndex then
            if m.focusArea <> "channels" then m.selectedChannelIndex = i
            return
        end if
    end for
    if m.focusArea <> "channels" then m.selectedChannelIndex = 0
end sub

function selectedChannel() as Dynamic
    if m.channels = invalid or m.channels.count() = 0 then return invalid
    if m.channelIndex < 0 or m.channelIndex >= m.channels.count() then m.channelIndex = 0
    return m.channels[m.channelIndex]
end function

function displayChannel(visible = invalid as Dynamic) as Dynamic
    if visible = invalid then visible = filteredChannels()
    if m.focusArea = "channels" and visible.count() > 0 then
        if m.selectedChannelIndex >= 0 and m.selectedChannelIndex < visible.count() then return visible[m.selectedChannelIndex].channel
    end if
    return selectedChannel()
end function

function currentEpgRows(channel as Dynamic) as Object
    if channel <> invalid and channel.doesExist("epg") and channel.epg <> invalid and type(channel.epg) = "roArray" then
        rows = []
        for i = 0 to channel.epg.count() - 1
            if rows.count() < 3 then rows.push(channel.epg[i])
        end for
        if rows.count() > 0 then return rows
    end if
    return [
        { time: "Now", title: liveText(channel, "now", "Live Program") },
        { time: "Next", title: "Up next" },
        { time: "Later", title: "Schedule unavailable" }
    ]
end function

function liveText(item as Dynamic, key as String, fallback = "" as String) as String
    value = liveValue(item, key)
    if value = invalid then return fallback
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function liveFlag(item as Dynamic, key as String) as Boolean
    value = liveValue(item, key)
    if value = invalid then return false
    return value = true
end function

function liveValue(item as Dynamic, key as String) as Dynamic
    if item = invalid then return invalid
    if item.doesExist(key) then return item[key]
    lowerKey = LCase(key)
    if lowerKey <> key and item.doesExist(lowerKey) then return item[lowerKey]
    return invalid
end function

function liveChannelCategory(channel as Dynamic) as String
    category = liveText(channel, "category")
    if category <> "" then return category
    category = liveText(channel, "groupTitle")
    if category <> "" then return category
    return "Uncategorized"
end function

function liveCategoryDisplayLabel(category as String) as String
    if category = "Documentary" then return "Docs"
    if category = "Entertainment" then return "Ent."
    return category
end function

function liveStatusText(channel as Dynamic) as String
    statusText = liveText(channel, "statusText")
    if statusText <> "" then return statusText
    numberText = liveText(channel, "channelNumber")
    if liveFlag(channel, "live") then
        if numberText <> "" then return "CH " + numberText + " / LIVE"
        return "LIVE"
    end if
    if numberText <> "" then return "CH " + numberText
    return "ON AIR"
end function

function liveLogoArtUrl(channel as Dynamic) as String
    logoUrl = liveText(channel, "logoUrl")
    if logoUrl <> "" then return logoUrl
    badgeUrl = liveText(channel, "badgeUrl")
    if badgeUrl <> "" then return badgeUrl
    cardUrl = liveText(channel, "cardUrl")
    if cardUrl <> "" then return cardUrl
    backdropUrl = liveText(channel, "backdropUrl")
    if backdropUrl <> "" then return backdropUrl
    return ""
end function

function liveCategoryArtworkUrl(channel as Dynamic) as String
    text = LCase(liveChannelCategory(channel) + " " + liveText(channel, "name") + " " + liveText(channel, "title"))
    if Instr(1, text, "sport") > 0 or Instr(1, text, "football") > 0 or Instr(1, text, "bein") > 0 then return "pkg:/images/logos/live/backdrops/bein_sports_backdrop.jpg"
    if Instr(1, text, "news") > 0 or Instr(1, text, "cnn") > 0 then return "pkg:/images/logos/live/backdrops/cnn_backdrop.jpg"
    if Instr(1, text, "bbc") > 0 then return "pkg:/images/logos/live/backdrops/bbc_news_backdrop.jpg"
    if Instr(1, text, "doc") > 0 or Instr(1, text, "discovery") > 0 then return "pkg:/images/logos/live/backdrops/discovery_backdrop.jpg"
    if Instr(1, text, "music") > 0 or Instr(1, text, "mtv") > 0 then return "pkg:/images/logos/live/backdrops/mtv_hits_backdrop.jpg"
    if Instr(1, text, "kid") > 0 or Instr(1, text, "cartoon") > 0 then return "pkg:/images/logos/live/backdrops/cartoon_network_backdrop.jpg"
    if Instr(1, text, "movie") > 0 or Instr(1, text, "entertain") > 0 or Instr(1, text, "mix") > 0 then return "pkg:/images/logos/live/backdrops/movie_channel_backdrop.jpg"
    return "pkg:/images/logos/live/backdrops/bbc_news_backdrop.jpg"
end function

function liveBrandText(channel as Dynamic) as String
    logoText = liveText(channel, "logoText")
    if logoText <> "" then return logoText
    title = liveText(channel, "name", liveText(channel, "title", "TV"))
    letters = ""
    words = title.Tokenize(" ")
    for each word in words
        if word <> "" and letters.len() < 4 then letters += Left(UCase(word), 1)
    end for
    if letters = "" then letters = Left(UCase(title), 4)
    return letters
end function

function liveArtUrl(channel as Dynamic, preferBackdrop as Boolean) as String
    if preferBackdrop then
        backdropUrl = liveText(channel, "backdropUrl")
        if backdropUrl <> "" then return backdropUrl
        return ""
    end if
    badgeUrl = liveText(channel, "badgeUrl")
    if badgeUrl <> "" then return badgeUrl
    cardUrl = liveText(channel, "cardUrl")
    if cardUrl <> "" then return cardUrl
    backdropUrl = liveText(channel, "backdropUrl")
    if backdropUrl <> "" then return backdropUrl
    return ""
end function

function liveCategoriesFromChannels(channels as Object) as Object
    categories = ["All"]
    for i = 0 to channels.count() - 1
        category = liveChannelCategory(channels[i])
        if category <> "" and not liveCategoryExists(categories, category) then categories.push(category)
    end for
    return categories
end function

function liveCategoryExists(categories as Object, category as String) as Boolean
    needle = LCase(category)
    for i = 0 to categories.count() - 1
        if LCase(categories[i]) = needle then return true
    end for
    return false
end function

sub drawBorderRect(x as Integer, y as Integer, w as Integer, h as Integer, fill as String, border as String, opacity = 1.0 as Float)
    uiRect(m.canvas, x, y, w, h, fill, opacity)
    uiRect(m.canvas, x, y, w, 1, border, 0.72)
    uiRect(m.canvas, x, y + h - 1, w, 1, border, 0.72)
    uiRect(m.canvas, x, y, 1, h, border, 0.72)
    uiRect(m.canvas, x + w - 1, y, 1, h, border, 0.72)
end sub
