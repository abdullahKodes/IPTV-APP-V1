sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("liveTvCanvas")
    m.focusItems = []
    m.focusIndex = 1
    m.focusArea = "normal"
    m.categoryIndex = 0
    m.focusedCategoryIndex = 0
    m.categoryWindowStart = 0
    m.categoryWindowSize = 8
    m.selectedChannelIndex = 0
    m.channelWindowStart = 0
    m.channelColumns = 5
    m.channelRows = 2
    m.channelWindowSize = m.channelColumns * m.channelRows
    m.searchQuery = ""
    m.searchEditing = false
    m.searchReturnPending = false
    m.searchPreviousCategoryIndex = 0
    m.searchKeyboardIndex = 0
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    m.activePlaylist = playlistStoreActive()
    m.activePlaylistId = playlistStoreText(m.activePlaylist, "id", playlistStoreDemoId())
    m.activePlaylistTitle = playlistStoreText(m.activePlaylist, "title", "Demo Playlist")
    m.channels = mediaLiveCatalogForPlaylist(m.activePlaylistId)
    m.categories = liveCategoriesFromChannels(m.channels)
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
    if key = "back" and (m.searchQuery <> "" or m.searchReturnPending) then clearLiveSearchAndStay() : return true
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

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "search" then openSearchKeyboard() : return
    if item.action = "category" then selectLiveCategory(item.categoryIndex) : return
    if item.action = "channel" then openLiveChannel(item.channelIndex) : return
end sub

sub openLiveChannel(channelIndex as Integer)
    if channelIndex < 0 or channelIndex >= m.channels.count() then return
    channel = m.channels[channelIndex]
    playbackUrl = mediaPlaybackUrl(channel)
    if playbackUrl = "" then return

    channelName = liveText(channel, "name", liveText(channel, "title", "Live TV"))
    m.top.playbackTitle = channelName
    m.top.playbackSubtitle = liveChannelCategory(channel)
    m.top.playbackUrl = playbackUrl
    m.top.playbackFormat = mediaPlaybackFormat(channel)
    m.top.playbackPosterUrl = liveLogoArtUrl(channel)
    if liveFlag(channel, "live") then
        m.top.playbackMediaType = "live"
    else
        m.top.playbackMediaType = "movie"
    end if
    m.top.returnPage = "LiveTvPage"
    m.top.navigateTo = "PlayerPage"
end sub

sub selectLiveCategory(categoryIndex as Integer)
    if categoryIndex < 0 or categoryIndex >= m.categories.count() then return
    query = LCase(m.searchQuery)
    fromSearch = query <> "" and Instr(1, LCase(m.categories[categoryIndex]), query) > 0
    if not fromSearch then m.searchPreviousCategoryIndex = m.categoryIndex
    m.searchReturnPending = categoryIndex > 0
    if fromSearch then m.searchQuery = ""
    m.categoryIndex = categoryIndex
    m.focusedCategoryIndex = categoryIndex
    m.selectedChannelIndex = 0
    m.channelWindowStart = 0
    m.focusArea = "categories"
    normalizeCategoryWindow()
    render()
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    liveBackground = uiPoster(m.canvas, "pkg:/images/live/live_tv_background_v4_full.jpg", 0, 0, 1280, 720, 0.54)
    liveBackground.loadDisplayMode = "scaleToFill"
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.30)
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.08)

    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    drawLiveSideNav()
    drawSearchBox()
    drawCategoryPills()

    visible = filteredChannels()
    normalizeChannelWindow(visible.count())
    sectionTitle = "LIVE TV"
    if m.categoryIndex > 0 and m.categoryIndex < m.categories.count() then sectionTitle = UCase(m.categories[m.categoryIndex])
    uiLabel(m.canvas, sectionTitle, 244, 174, 520, 32, 18, m.colors.text)
    uiLabel(m.canvas, visible.count().toStr() + " channels", 926, 179, 188, 24, 11, m.colors.textDim, "right")

    if visible.count() = 0 then
        uiLabel(m.canvas, "No live channels in " + m.activePlaylistTitle, 316, 338, 724, 34, 18, m.colors.textDim, "center")
        uiLabel(m.canvas, "Choose another category or switch playlists.", 316, 378, 724, 26, 12, m.colors.textMuted, "center")
    else
        drawChannelGrid(visible)
        drawChannelScrollbar(visible.count())
    end if

    ensureLiveFocus()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

sub drawLiveSideNav()
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.24)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14", 0.26)

    addLiveNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addLiveNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, true)
    addLiveNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addLiveNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addLiveNavItem(12, 336, "heart", "Favorites", "FavoritesPage", 4, false)
    addLiveNavItem(12, 392, "settings", "Settings", "SettingsPage", 5, false)
    addLiveProfileItem()
end sub

sub addLiveNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    fill = m.colors.bg
    border = m.colors.whiteLine
    opacity = 0.42
    textColor = m.colors.textPurple
    if active then
        fill = m.colors.purpleSoft
        border = m.colors.greenFocus
        opacity = 0.58
        textColor = m.colors.text
    end if
    if focused then
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
        opacity = 0.66
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, x, y, 204, 52, fill, border, opacity)
    uiDrawIcon(m.canvas, icon, x + 22, y + 14, 24, 24, focused or active, textColor, 12)
    uiLabel(m.canvas, label, x + 62, y + 9, 128, 34, 12, textColor)
    m.focusItems.push({
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: fill, border: border, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: opacity, focusOpacity: 0.66,
        row: row, col: 0, page: page, mode: "manual", noFocusShift: true
    })
end sub

sub addLiveProfileItem()
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    fill = m.colors.bg
    border = m.colors.whiteLine
    opacity = 0.42
    textColor = m.colors.textPurple
    if focused then
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
        opacity = 0.66
        textColor = m.colors.text
    end if
    uiRoundRect(m.canvas, 12, 640, 204, 52, fill, border, opacity)
    uiDrawIcon(m.canvas, "profile", 30, 652, 24, 24, focused, textColor, 14)
    uiLabel(m.canvas, "My Profile", 70, 652, 126, 28, 11, textColor)
    m.focusItems.push({
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: fill, border: border, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: opacity, focusOpacity: 0.66,
        row: 6, col: 0, page: "ProfilePage", mode: "manual", noFocusShift: true
    })
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
    uiRoundRect(m.canvas, 686, 22, 260, 40, bg, border, 0.48)
    uiDrawIcon(m.canvas, "search", 704, 33, 18, 18, focused, textColor, 11)
    uiLabel(m.canvas, label, 734, 28, 198, 28, 12, textColor)
    m.focusItems.push({
        x: 686, y: 22, w: 260, h: 40,
        icon: "search", label: label, subtitle: "",
        iconSize: 11, titleSize: 13, subSize: 10,
        bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 0, col: 1, page: "", action: "search", mode: "manual"
    })
end sub

sub drawCategoryPills()
    normalizeCategoryWindow()
    endIndex = m.categoryWindowStart + m.categoryWindowSize - 1
    if endIndex > m.categories.count() - 1 then endIndex = m.categories.count() - 1
    slot = 0
    x = 244
    for i = m.categoryWindowStart to endIndex
        categoryLabel = liveCategoryDisplayLabel(m.categories[i])
        pillW = liveCategoryPillWidth(categoryLabel)
        assetW = 100
        if pillW > 100 then assetW = 140
        if pillW > 140 then assetW = 150
        itemIndex = m.focusItems.count()
        focused = m.focusArea = "categories" and i = m.focusedCategoryIndex
        if focused then m.focusIndex = itemIndex
        selected = i = m.categoryIndex
        bg = m.colors.bg
        border = m.colors.whiteLine
        textColor = m.colors.textPurple
        opacity = 0.42
        if selected then
            bg = m.colors.purpleSoft
            border = m.colors.greenFocus
            textColor = m.colors.text
            opacity = 0.58
        end if
        if focused then
            bg = m.colors.greenSoft
            border = m.colors.greenFocus
            textColor = m.colors.text
            opacity = 0.66
        end if
        pillUri = uiRoundUri(assetW, 40, bg, border)
        if pillW > 150 then
            pillUri = "pkg:/images/ui/rr_190x44_bg_whiteLine.png"
            if selected then pillUri = "pkg:/images/ui/rr_190x44_purpleSoft_greenFocus.png"
            if focused then pillUri = "pkg:/images/ui/rr_172x48_greenSoft_greenFocus.png"
        end if
        uiPoster(m.canvas, pillUri, x, 106, pillW, 40, opacity)
        uiScaledLabel(m.canvas, categoryLabel, x + 8, 115, pillW - 16, 20, 11, textColor, "center", 0.82)
        m.focusItems.push({
            x: x, y: 106, w: pillW, h: 40,
            icon: "", label: m.categories[i], subtitle: "",
            iconSize: 1, titleSize: 11, subSize: 9,
            bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
            focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
            row: 1, col: slot + 1, page: "", action: "category", categoryIndex: i, mode: "manual"
        })
        slot += 1
        x += pillW + 12
    end for
    if endIndex < m.categories.count() - 1 then
        uiLabel(m.canvas, ">", 1156, 113, 12, 22, 11, m.colors.textGreen, "center")
    else if m.categoryWindowStart > 0 then
        uiLabel(m.canvas, "<", 1156, 113, 12, 22, 11, m.colors.textGreen, "center")
    end if
end sub

sub drawChannelGrid(visible as Object)
    endIndex = m.channelWindowStart + m.channelWindowSize - 1
    if endIndex > visible.count() - 1 then endIndex = visible.count() - 1
    for i = m.channelWindowStart to endIndex
        slot = i - m.channelWindowStart
        gridRow = Int(slot / m.channelColumns)
        gridCol = slot mod m.channelColumns
        x = 244 + gridCol * 176
        y = 218 + gridRow * 236
        rowData = visible[i]
        drawChannelCard(rowData.channel, rowData.index, i, x, y, gridRow + 2, gridCol + 1)
    end for
end sub

sub drawChannelCard(channel as Object, channelIndex as Integer, visibleIndex as Integer, x as Integer, y as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = m.focusArea = "channels" and visibleIndex = m.selectedChannelIndex
    if focused then m.focusIndex = itemIndex
    bg = m.colors.panel
    border = "0xFFFFFF18"
    opacity = 0.42
    if focused then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
        opacity = 0.66
    end if

    cardW = 164
    cardH = 208
    artH = 148
    textH = cardH - artH
    cardCanvas = CreateObject("roSGNode", "Group")
    cardCanvas.id = "liveChannelCard" + visibleIndex.toStr()
    cardCanvas.translation = [x, y]
    m.canvas.appendChild(cardCanvas)

    uiRect(cardCanvas, 0, 0, cardW, cardH, bg, opacity)
    posterUrl = liveCardPosterUrl(channel)
    backgroundUrl = liveCardBackgroundUrl(channel)
    if posterUrl <> "" then
        poster = uiPoster(cardCanvas, posterUrl, 0, 0, cardW, cardH, 1.0)
        poster.loadDisplayMode = "scaleToZoom"
    else
        if backgroundUrl <> "" then
            background = uiPoster(cardCanvas, backgroundUrl, 0, 0, cardW, cardH, 1.0)
            background.loadDisplayMode = "scaleToZoom"
            logoUrl = liveLogoArtUrl(channel)
            if logoUrl <> "" then
                logo = uiPoster(cardCanvas, logoUrl, 34, 45, 96, 58, 1.0)
                logo.loadDisplayMode = "scaleToFit"
            end if
        else
            logoBg = m.colors.panel
            if focused then logoBg = m.colors.greenSoft
            brandColor2 = liveText(channel, "brandColor2", m.colors.purpleActive)
            uiRect(cardCanvas, 0, 0, cardW, cardH, logoBg, 0.62)
            uiRect(cardCanvas, 0, 0, cardW, cardH, brandColor2, 0.50)
        end if
        if backgroundUrl = "" then
            logoUrl = liveLogoArtUrl(channel)
            if logoUrl <> "" then
                logo = uiPoster(cardCanvas, logoUrl, 27, 43, 110, 66, 1.0)
                logo.loadDisplayMode = "scaleToFit"
            else
                uiRoundRect(cardCanvas, 47, 40, 70, 70, m.colors.purpleSoft, m.colors.whiteLine, 0.84)
                uiScaledLabel(cardCanvas, liveBrandText(channel), 53, 61, 58, 26, 16, m.colors.text, "center", 0.86)
            end if
        end if
    end if
    if liveFlag(channel, "live") then
        uiPoster(cardCanvas, "pkg:/images/ui/live_badge.png", 8, 8, 52, 19, 1.0)
    end if

    channelName = liveText(channel, "name", liveText(channel, "title", "Untitled channel"))
    uiRect(cardCanvas, 0, artH, cardW, textH, "0x000000FF", 0.34)
    uiScaledLabel(cardCanvas, channelName, 10, artH + 6, cardW - 20, 24, 11, m.colors.text, "center", 0.78)
    meta = liveChannelCategory(channel)
    channelNumber = liveText(channel, "channelNumber")
    if channelNumber <> "" then meta = "CH " + channelNumber + "  /  " + meta
    uiScaledLabel(cardCanvas, meta, 10, artH + 33, cardW - 20, 18, 8, m.colors.textDim, "center", 0.66)
    uiCardFocusTint(cardCanvas, 0, 0, cardW, cardH, focused)
    borderWidth = 1
    if focused then borderWidth = 2
    uiRectBorder(cardCanvas, 0, 0, cardW, cardH, border, borderWidth, 1.0)
    if focused then animateLiveCardFocus(cardCanvas, x, y)

    m.focusItems.push({
        x: x, y: y, w: cardW, h: cardH,
        icon: "", label: channelName, subtitle: meta,
        iconSize: 1, titleSize: 13, subSize: 9,
        bg: bg, border: border, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "channel", channelIndex: channelIndex, visibleIndex: visibleIndex, mode: "manual"
    })
end sub

sub animateLiveCardFocus(cardCanvas as Object, x as Integer, y as Integer)
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

    m.canvas.appendChild(animation)
    animation.control = "start"
end sub

sub drawChannelScrollbar(total as Integer)
    if total <= m.channelWindowSize then return
    x = 1160
    y = 218
    h = 444
    uiRect(m.canvas, x, y, 4, h, "0xFFFFFF18", 0.10)
    thumbH = Int(h * m.channelWindowSize / total)
    if thumbH < 48 then thumbH = 48
    if thumbH > h then thumbH = h
    thumbY = y
    pageCount = Int((total - 1) / m.channelWindowSize) + 1
    pageIndex = Int(m.selectedChannelIndex / m.channelWindowSize)
    if pageCount > 1 and h > thumbH then thumbY = y + Int((h - thumbH) * pageIndex / (pageCount - 1))
    uiVerticalPill(m.canvas, x - 1, thumbY, 6, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.24)
end sub

function routeLiveFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then m.focusIndex = 0
    current = m.focusItems[m.focusIndex]
    action = ""
    if current.doesExist("action") then action = current.action

    if current.col = 0 and dx > 0 then
        m.focusArea = "categories"
        m.focusedCategoryIndex = m.categoryIndex
        normalizeCategoryWindow()
        return true
    end if

    if action = "search" then
        if dy > 0 then
            m.focusArea = "categories"
            m.focusedCategoryIndex = m.categoryIndex
            normalizeCategoryWindow()
            return true
        end if
        if dx < 0 then
            m.focusArea = "normal"
            m.focusIndex = 1
            return true
        end if
    end if

    if action = "category" then
        if current.doesExist("categoryIndex") then m.focusedCategoryIndex = current.categoryIndex
        nextIndex = m.focusedCategoryIndex
        if dx < 0 then nextIndex -= 1
        if dx > 0 then nextIndex += 1
        if dx < 0 and nextIndex < 0 then
            m.focusArea = "normal"
            m.focusIndex = 1
            return true
        end if
        if dx <> 0 and nextIndex >= 0 and nextIndex < m.categories.count() then
            m.focusedCategoryIndex = nextIndex
            m.focusArea = "categories"
            normalizeCategoryWindow()
            return true
        end if
        if dy < 0 then
            searchIndex = findFocusAction("search")
            if searchIndex >= 0 then m.focusArea = "normal" : m.focusIndex = searchIndex : return true
        end if
        if dy > 0 then
            visible = filteredChannels()
            if visible.count() > 0 then
                m.focusArea = "channels"
                normalizeChannelWindow(visible.count())
                return true
            end if
        end if
        return true
    end if

    if action = "channel" then
        visible = filteredChannels()
        if current.doesExist("visibleIndex") then m.selectedChannelIndex = current.visibleIndex
        nextChannel = m.selectedChannelIndex + dx + (dy * m.channelColumns)
        currentCol = m.selectedChannelIndex mod m.channelColumns
        if dx < 0 and currentCol = 0 then
            m.focusArea = "normal"
            m.focusIndex = 1
            return true
        end if
        if dx > 0 and currentCol = m.channelColumns - 1 then return true
        if dy < 0 and m.selectedChannelIndex < m.channelColumns then
            m.focusArea = "categories"
            m.focusedCategoryIndex = m.categoryIndex
            normalizeCategoryWindow()
            return true
        end if
        if nextChannel >= 0 and nextChannel < visible.count() then
            m.selectedChannelIndex = nextChannel
            m.focusArea = "channels"
            normalizeChannelWindow(visible.count())
            return true
        end if
        return true
    end if
    return false
end function

sub syncLiveFocus()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    action = ""
    if item.doesExist("action") then action = item.action
    if action = "category" then
        m.focusArea = "categories"
        if item.doesExist("categoryIndex") then m.focusedCategoryIndex = item.categoryIndex
    else if action = "channel" then
        m.focusArea = "channels"
        if item.doesExist("visibleIndex") then m.selectedChannelIndex = item.visibleIndex
    else
        m.focusArea = "normal"
    end if
end sub

sub ensureLiveFocus()
    if m.focusItems.count() = 0 then m.focusIndex = -1 : return
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then m.focusIndex = 1
end sub

function findFocusAction(action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = action then return i
    end for
    return -1
end function

sub normalizeCategoryWindow()
    total = m.categories.count()
    if total <= 0 then m.categoryWindowStart = 0 : m.focusedCategoryIndex = 0 : return
    if m.focusedCategoryIndex < 0 then m.focusedCategoryIndex = 0
    if m.focusedCategoryIndex > total - 1 then m.focusedCategoryIndex = total - 1
    maxStart = total - m.categoryWindowSize
    if maxStart < 0 then maxStart = 0
    if m.categoryWindowStart > maxStart then m.categoryWindowStart = maxStart
    if m.focusedCategoryIndex < m.categoryWindowStart then m.categoryWindowStart = m.focusedCategoryIndex
    if m.focusedCategoryIndex >= m.categoryWindowStart + m.categoryWindowSize then m.categoryWindowStart = m.focusedCategoryIndex - m.categoryWindowSize + 1
end sub

sub normalizeChannelWindow(total as Integer)
    if total <= 0 then
        m.channelWindowStart = 0
        m.selectedChannelIndex = 0
        if m.focusArea = "channels" then m.focusArea = "categories"
        return
    end if
    if m.selectedChannelIndex < 0 then m.selectedChannelIndex = 0
    if m.selectedChannelIndex > total - 1 then m.selectedChannelIndex = total - 1
    windowPage = Int(m.selectedChannelIndex / m.channelWindowSize)
    m.channelWindowStart = windowPage * m.channelWindowSize
end sub

function filteredChannels() as Object
    result = []
    selectedCategory = "All"
    if m.categoryIndex >= 0 and m.categoryIndex < m.categories.count() then selectedCategory = m.categories[m.categoryIndex]
    query = LCase(m.searchQuery)
    for i = 0 to m.channels.count() - 1
        channel = m.channels[i]
        category = liveChannelCategory(channel)
        searchable = LCase(liveText(channel, "name") + " " + liveText(channel, "title") + " " + category + " " + liveText(channel, "channelNumber"))
        categoryMatches = selectedCategory = "All" or LCase(category) = LCase(selectedCategory)
        searchMatches = query = "" or Instr(1, searchable, query) > 0
        if categoryMatches and searchMatches then result.push({ channel: channel, index: i })
    end for
    return result
end function

function liveText(item as Dynamic, key as String, fallback = "" as String) as String
    value = liveValue(item, key)
    if value = invalid then return fallback
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function liveValue(item as Dynamic, key as String) as Dynamic
    if item = invalid then return invalid
    if item.doesExist(key) then return item[key]
    lowerKey = LCase(key)
    if lowerKey <> key and item.doesExist(lowerKey) then return item[lowerKey]
    return invalid
end function

function liveFlag(item as Dynamic, key as String) as Boolean
    value = liveValue(item, key)
    if value = invalid then return false
    valueType = type(value)
    if valueType = "Boolean" or valueType = "roBoolean" then return value
    if valueType = "String" or valueType = "roString" then
        text = LCase(value)
        return text = "true" or text = "1" or text = "yes" or text = "live"
    end if
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" then return value <> 0
    return false
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
    if category = "Entertainment" then return "Entertainment"
    return category
end function

function liveCategoryPillWidth(label as String) as Integer
    length = label.len()
    if length <= 3 then return 70
    if length <= 5 then return 82
    if length <= 7 then return 96
    if length <= 10 then return 116
    return 172
end function

function liveLogoArtUrl(channel as Dynamic) as String
    logoUrl = liveText(channel, "logoUrl")
    if logoUrl <> "" then return logoUrl
    badgeUrl = liveText(channel, "badgeUrl")
    if badgeUrl <> "" then return badgeUrl
    return ""
end function

function liveCardPosterUrl(channel as Dynamic) as String
    cardUrl = liveText(channel, "cardUrl")
    if cardUrl <> "" then return cardUrl
    posterUrl = liveText(channel, "posterUrl")
    if posterUrl <> "" then return posterUrl
    channelPosterUrl = liveText(channel, "channelPosterUrl")
    if channelPosterUrl <> "" then return channelPosterUrl
    return ""
end function

function liveCardBackgroundUrl(channel as Dynamic) as String
    return liveText(channel, "cardBackgroundUrl")
end function

function liveBrandText(channel as Dynamic) as String
    logoText = liveText(channel, "logoText")
    if logoText <> "" then return Left(UCase(logoText), 4)
    title = liveText(channel, "name", liveText(channel, "title", "TV"))
    letters = ""
    words = title.Tokenize(" ")
    for each word in words
        if word <> "" and letters.len() < 4 then letters += Left(UCase(word), 1)
    end for
    if letters = "" then letters = Left(UCase(title), 4)
    return letters
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

sub openSearchKeyboard()
    m.searchPreviousCategoryIndex = m.categoryIndex
    m.searchReturnPending = false
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
        categoryMatch = liveCategorySearchMatch()
        if categoryMatch >= 0 then
            m.searchEditing = false
            m.focusedCategoryIndex = categoryMatch
            m.focusArea = "categories"
            normalizeCategoryWindow()
            render()
            return
        end if
        closeSearchKeyboard()
        return
    end if
    if selected = "CLEAR" then
        current = ""
    else if selected = "DEL" then
        if current.len() > 0 then current = current.left(current.len() - 1)
    else if selected = "SPACE" then
        if current.len() < 64 then current += " "
    else
        if current.len() < 64 then current += selected
    end if
    m.searchQuery = current
    m.selectedChannelIndex = 0
    m.channelWindowStart = 0
    render()
end sub

function liveCategorySearchMatch() as Integer
    query = LCase(m.searchQuery)
    if query = "" then return -1
    partialMatch = -1
    for i = 1 to m.categories.count() - 1
        category = LCase(m.categories[i])
        if category = query then return i
        if partialMatch < 0 and Instr(1, category, query) > 0 then partialMatch = i
    end for
    return partialMatch
end function

sub closeSearchKeyboard()
    m.searchEditing = false
    render()
end sub

sub clearLiveSearchAndStay()
    m.searchQuery = ""
    if m.searchReturnPending then
        m.categoryIndex = m.searchPreviousCategoryIndex
        if m.categoryIndex < 0 or m.categoryIndex >= m.categories.count() then m.categoryIndex = 0
    end if
    m.searchReturnPending = false
    m.focusedCategoryIndex = m.categoryIndex
    m.categoryWindowStart = 0
    m.channelWindowStart = 0
    m.selectedChannelIndex = 0
    m.focusArea = "normal"
    searchIndex = findFocusAction("search")
    if searchIndex >= 0 then m.focusIndex = searchIndex
    render()
end sub

sub drawSearchKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiRect(m.canvas, 260, 116, 760, 488, m.colors.panel, 0.98)
    uiLabel(m.canvas, "Search Channels or Categories", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
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
        if i = m.searchKeyboardIndex then bg = m.colors.purpleSoft : border = m.colors.greenFocus
        uiRect(m.canvas, x, y, keyW, keyH, bg)
        uiRectBorder(m.canvas, x, y, keyW, keyH, border, 2, 0.9)
        uiLabel(m.canvas, keyLabel, x, y + 5, keyW, 28, 12, m.colors.text, "center")
    end for
end sub
