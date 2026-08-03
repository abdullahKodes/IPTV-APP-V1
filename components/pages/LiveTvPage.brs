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
    m.categoryResultsActive = false
    m.searchPreviousCategoryIndex = 0
    m.favoriteMessage = ""
    m.searchKeyboardIndex = 0
    m.searchKeyboardUpper = true
    m.backendLoading = false
    m.backendMessage = ""
    m.backendTask = invalid
    m.backendRepairAttempted = false
    m.backendPlaybackTask = invalid
    m.backendPlaybackChannel = invalid
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "CASE", "SPACE", "DEL", "CLEAR", "DONE"]
    m.activePlaylist = playlistStoreActive()
    m.activePlaylistId = playlistStoreText(m.activePlaylist, "id", playlistStoreDemoId())
    m.activePlaylistTitle = playlistStoreText(m.activePlaylist, "title", "Demo Playlist")
    contentProfile = playlistStoreEffectiveContentProfile(m.activePlaylist)
    if playlistStoreBool(m.activePlaylist, "backendManaged", false) and contentProfile <> "backend_live" then
        m.channels = []
        if contentProfile = "backend_movies" then
            m.backendMessage = "This is a movies playlist. Open Movies."
        else
            m.backendMessage = "This is a series playlist. Open Series."
        end if
    else if playlistStoreBool(m.activePlaylist, "backendManaged", false) then
        m.channels = []
        startBackendLiveLoad()
    else
        m.channels = mediaLiveCatalogForPlaylist(m.activePlaylistId)
        if m.channels.count() = 0 and playlistStoreText(m.activePlaylist, "sourceUrl") <> "" then
            m.backendMessage = "Add this playlist again to refresh its content."
        end if
    end if
    m.categories = liveCategoriesFromChannels(m.channels)
    render()
end sub

sub startBackendLiveLoad()
    backendId = playlistStoreText(m.activePlaylist, "backendPlaylistId")
    if backendId = "" then
        m.backendMessage = "This playlist needs to be added again."
        return
    end if
    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.backendMessage = "Playlist service is unavailable."
        return
    end if
    m.backendLoading = true
    m.backendMessage = ""
    task.observeField("response", "onBackendLiveLoaded")
    task.request = backendApiSyncChannelsRequest(backendId, 1000)
    m.backendTask = task
    task.control = "RUN"
end sub

sub startBackendLiveRepair()
    if m.backendRepairAttempted then return
    sourceUrl = playlistStoreText(m.activePlaylist, "sourceUrl")
    if sourceUrl = "" then return
    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then return
    m.backendRepairAttempted = true
    m.backendLoading = true
    m.backendMessage = ""
    task.observeField("response", "onBackendLiveRepairCreated")
    task.request = backendApiCreatePlaylistRequest(m.activePlaylistTitle, sourceUrl)
    m.backendTask = task
    task.control = "RUN"
    render()
end sub

sub onBackendLiveRepairCreated()
    if m.backendTask = invalid then return
    response = m.backendTask.response
    m.backendTask = invalid
    if backendApiResponseOk(response) then
        savedPlaylist = playlistStoreRepairBackendPlaylist(m.activePlaylistId, backendApiResponsePlaylist(response))
        if savedPlaylist <> invalid then
            playlistStoreSetActive(playlistStoreText(savedPlaylist, "id"))
            m.activePlaylist = savedPlaylist
            m.activePlaylistId = playlistStoreText(savedPlaylist, "id")
            m.activePlaylistTitle = playlistStoreText(savedPlaylist, "title", m.activePlaylistTitle)
            m.backendMessage = ""
            startBackendLiveLoad()
            return
        end if
    end if
    m.backendLoading = false
    m.backendMessage = backendApiUserMessage(response, "Playlist could not be opened.")
    render()
end sub

sub onBackendLiveLoaded()
    if m.backendTask = invalid then return
    response = m.backendTask.response
    m.backendTask = invalid
    m.backendLoading = false
    if backendApiResponseOk(response) then
        items = backendApiResponseItems(response)
        m.channels = backendApiMapSyncItems(items, m.activePlaylistId, "live")
        m.categories = liveCategoriesFromChannels(m.channels)
        if m.channels.count() > 0 then
            m.backendMessage = ""
        else
            m.backendMessage = "No live channels found in this playlist."
        end if
        m.selectedChannelIndex = 0
        m.channelWindowStart = 0
    else
        if backendApiResponseStatusCode(response) = 404 and not m.backendRepairAttempted then
            startBackendLiveRepair()
            return
        end if
        m.backendMessage = backendApiUserMessage(response, "Live channels could not be loaded.")
    end if
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
    if key = "back" and (m.searchQuery <> "" or m.searchReturnPending or m.categoryResultsActive) then clearLiveSearchAndStay() : return true
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "options" then toggleSelectedChannelFavorite() : return true
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
    if playbackUrl = "" then
        backendChannelId = liveText(channel, "backendChannelId")
        if backendChannelId <> "" then startBackendLivePlaybackLoad(channel)
        return
    end if

    playLiveChannel(channel, playbackUrl)
end sub

sub startBackendLivePlaybackLoad(channel as Object)
    backendChannelId = liveText(channel, "backendChannelId")
    if backendChannelId = "" then return
    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.favoriteMessage = "Playlist service is unavailable."
        render()
        return
    end if
    m.favoriteMessage = ""
    m.backendPlaybackChannel = channel
    m.backendPlaybackTask = task
    task.observeField("response", "onBackendLivePlaybackLoaded")
    task.request = backendApiGetChannelRequest(backendChannelId)
    task.control = "RUN"
    render()
end sub

sub onBackendLivePlaybackLoaded()
    if m.backendPlaybackTask = invalid then return
    response = m.backendPlaybackTask.response
    channel = m.backendPlaybackChannel
    m.backendPlaybackTask = invalid
    m.backendPlaybackChannel = invalid
    playbackUrl = backendApiChannelStreamUrl(response)
    if backendApiResponseOk(response) and playbackUrl <> "" and channel <> invalid then
        m.favoriteMessage = ""
        playLiveChannel(channel, playbackUrl)
    else
        m.favoriteMessage = "Stream URL could not be loaded."
        render()
    end if
end sub

sub playLiveChannel(channel as Object, playbackUrl as String)
    if channel = invalid or playbackUrl = "" then return
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

sub selectLiveCategory(categoryIndex as Integer, fromSearch = false as Boolean)
    if categoryIndex < 0 or categoryIndex >= m.categories.count() then return
    m.searchPreviousCategoryIndex = m.categoryIndex
    m.searchReturnPending = false
    m.categoryResultsActive = categoryIndex > 0
    m.searchQuery = ""
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
    visible = filteredChannels()
    hasChannels = visible.count() > 0
    if hasChannels then
        liveBackground = uiPoster(m.canvas, "pkg:/images/live/live_tv_background_v6_art.jpg", 0, 0, 1280, 720, 0.44)
        liveBackground.loadDisplayMode = "scaleToFill"
        uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.42)
        uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.16)
    end if

    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    drawLiveSideNav()
    drawSearchBox()

    normalizeChannelWindow(visible.count())

    if visible.count() = 0 then
        emptyTitle = "No live channels in " + m.activePlaylistTitle
        emptySubtitle = "Choose another category or switch playlists."
        if m.backendLoading then
            emptyTitle = ""
            emptySubtitle = ""
        else if m.backendMessage <> "" then
            emptyTitle = m.backendMessage
            emptySubtitle = "Switch playlist or add this playlist again."
        end if
        if not m.backendLoading then
            uiLabel(m.canvas, emptyTitle, 244, 332, 860, 28, 15, m.colors.textDim, "center")
            uiLabel(m.canvas, emptySubtitle, 244, 366, 860, 24, 11, m.colors.textMuted, "center")
        else
            uiContentLoader(m.canvas, m.colors, "Loading Live TV")
        end if
    else
        drawCategoryPills()
        sectionTitle = "LIVE TV"
        if m.categoryIndex > 0 and m.categoryIndex < m.categories.count() then sectionTitle = UCase(m.categories[m.categoryIndex])
        uiLabel(m.canvas, sectionTitle, 244, 160, 520, 32, 18, m.colors.text)
        uiLabel(m.canvas, visible.count().toStr() + " channels", 926, 156, 188, 24, 11, m.colors.textDim, "right")
        drawLiveFavoriteHint(visible)
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

    addLiveNavItem(12, 112, "home", "Home", "HomePage", 0, false)
    addLiveNavItem(12, 171, "tv", "Live TV", "LiveTvPage", 1, true)
    addLiveNavItem(12, 230, "series", "Series", "SeriesPage", 2, false)
    addLiveNavItem(12, 289, "movies", "Movies", "MoviesPage", 3, false)
    addLiveNavItem(12, 348, "heart", "Favorites", "FavoritesPage", 4, false)
    addLiveNavItem(12, 407, "settings", "Settings", "SettingsPage", 5, false)
    addLiveProfileItem()
end sub

sub addLiveNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    itemIndex = m.focusItems.count()
    focused = m.focusArea = "normal" and itemIndex = m.focusIndex
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
    uiPoster(m.canvas, uiSidebarPillUri(fill, border), x, y, 204, 52, opacity)
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
    focused = m.focusArea = "normal" and itemIndex = m.focusIndex
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
    uiPoster(m.canvas, uiSidebarPillUri(fill, border), 12, 640, 204, 52, opacity)
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
    focused = m.focusArea = "normal" and itemIndex = m.focusIndex
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
    uiSearchPill(m.canvas, 686, 22, 240, 40, focused, 0.54)
    uiDrawIcon(m.canvas, "search", 706, 32, 20, 20, focused, textColor, 11)
    uiLabel(m.canvas, label, 740, 23, 166, 40, 12, textColor)
    m.focusItems.push({
        x: 686, y: 22, w: 240, h: 40,
        icon: "search", label: label, subtitle: "",
        iconSize: 11, titleSize: 13, subSize: 10,
        bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 0, col: 1, page: "", action: "search", mode: "manual"
    })
end sub

sub drawCategoryPills()
    normalizeCategoryWindow()
    maxX = 1142
    endIndex = m.categoryWindowStart - 1
    slot = 0
    x = 244
    for i = m.categoryWindowStart to m.categories.count() - 1
        categoryLabel = liveCategoryDisplayLabel(m.categories[i])
        pillW = liveCategoryPillWidth(categoryLabel)
        if slot > 0 and x + pillW > maxX then exit for
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
        pillUri = uiCategoryPillUri(pillW, selected, focused)
        uiPoster(m.canvas, pillUri, x, 105, pillW, 34, opacity)
        labelScale = 0.80
        if categoryLabel = "All" then labelScale = 0.74
        uiScaledLabel(m.canvas, categoryLabel, x, 105, pillW, 34, 11, textColor, "center", labelScale)
        m.focusItems.push({
            x: x, y: 105, w: pillW, h: 34,
            icon: "", label: m.categories[i], subtitle: "",
            iconSize: 1, titleSize: 12, subSize: 10,
            bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
            focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
            row: 1, col: slot + 1, page: "", action: "category", categoryIndex: i, mode: "manual"
        })
        slot += 1
        endIndex = i
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
    drawChannelFavoriteBadge(cardCanvas, channel, focused, cardW)

    channelName = liveText(channel, "name", liveText(channel, "title", "Untitled channel"))
    uiRect(cardCanvas, 0, artH, cardW, textH, "0x000000FF", 0.34)
    uiScaledLabel(cardCanvas, channelName, 10, artH + 6, cardW - 20, 24, 11, m.colors.text, "center", 0.78)
    meta = liveChannelCategoryLabel(channel)
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

sub drawChannelFavoriteBadge(parent as Object, channel as Object, focused as Boolean, cardW as Integer)
    if not favoriteStoreIsFavorite("live", liveFavoriteItem(channel), m.activePlaylistId) then return
    badgeBg = m.colors.bg2
    badgeBorder = m.colors.whiteLine
    if focused then
        badgeBg = m.colors.greenSoft
        badgeBorder = m.colors.greenFocus
    end if
    uiRoundRect(parent, cardW - 38, 8, 30, 24, badgeBg, badgeBorder, 0.78)
    uiDrawIcon(parent, "heart", cardW - 31, 14, 16, 14, true, m.colors.text, 10)
end sub

sub drawLiveFavoriteHint(visible as Object)
    if visible.count() <= 0 then return
    text = "Press * to favorite"
    selected = selectedVisibleChannel()
    if selected <> invalid and favoriteStoreIsFavorite("live", liveFavoriteItem(selected), m.activePlaylistId) then
        text = "Press * to remove favorite"
    end if
    if m.favoriteMessage <> "" then text = m.favoriteMessage
    uiScaledLabel(m.canvas, text, 776, 190, 338, 18, 10, m.colors.textMuted, "right", 0.68)
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
        m.favoriteMessage = ""
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

sub toggleSelectedChannelFavorite()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    current = m.focusItems[m.focusIndex]
    if not current.doesExist("action") then return
    if current.action <> "channel" then return
    if current.doesExist("visibleIndex") then m.selectedChannelIndex = current.visibleIndex
    selected = selectedVisibleChannel()
    if selected = invalid then return
    saved = favoriteStoreToggle("live", liveFavoriteItem(selected), m.activePlaylistId)
    if saved then
        m.favoriteMessage = "Press * to remove favorite"
    else
        m.favoriteMessage = "Press * to favorite"
    end if
    render()
end sub

function selectedVisibleChannel() as Dynamic
    visible = filteredChannels()
    if visible.count() = 0 then return invalid
    if m.selectedChannelIndex < 0 then m.selectedChannelIndex = 0
    if m.selectedChannelIndex > visible.count() - 1 then m.selectedChannelIndex = visible.count() - 1
    data = visible[m.selectedChannelIndex]
    if data = invalid then return invalid
    if not data.doesExist("channel") then return invalid
    return data.channel
end function

function liveFavoriteItem(channel as Object) as Object
    return {
        id: liveText(channel, "id", liveText(channel, "name", liveText(channel, "title", ""))),
        playlistId: m.activePlaylistId,
        title: liveText(channel, "title", liveText(channel, "name", "Live TV")),
        name: liveText(channel, "name", liveText(channel, "title", "Live TV")),
        category: liveChannelCategory(channel),
        groupTitle: liveText(channel, "groupTitle"),
        now: liveText(channel, "now", liveText(channel, "programTitle", "Live stream")),
        programTitle: liveText(channel, "programTitle"),
        posterUrl: liveCardPosterUrl(channel),
        cardUrl: liveCardPosterUrl(channel),
        logoUrl: liveLogoArtUrl(channel),
        badgeUrl: liveText(channel, "badgeUrl"),
        backdropUrl: liveCardBackgroundUrl(channel),
        streamUrl: mediaPlaybackUrl(channel),
        streamFormat: mediaPlaybackFormat(channel),
        backendChannelId: liveText(channel, "backendChannelId"),
        contentType: liveText(channel, "contentType"),
        streamHost: liveText(channel, "streamHost"),
        logoText: liveText(channel, "logoText"),
        brandColor: liveText(channel, "brandColor"),
        brandColor2: liveText(channel, "brandColor2"),
        channelNumber: liveText(channel, "channelNumber"),
        live: liveFlag(channel, "live"),
        description: liveText(channel, "description")
    }
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
    while m.categoryWindowStart < m.focusedCategoryIndex and not liveCategoryWindowShows(m.categoryWindowStart, m.focusedCategoryIndex)
        m.categoryWindowStart += 1
    end while
end sub

function liveCategoryWindowShows(startIndex as Integer, targetIndex as Integer) as Boolean
    x = 244
    maxX = 1142
    slot = 0
    for i = startIndex to m.categories.count() - 1
        label = liveCategoryDisplayLabel(m.categories[i])
        pillW = liveCategoryPillWidth(label)
        if slot > 0 and x + pillW > maxX then return false
        if i = targetIndex then return true
        slot += 1
        x += pillW + 12
    end for
    return false
end function

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
        categories = liveChannelCategories(channel)
        searchable = LCase(liveText(channel, "name") + " " + liveText(channel, "title") + " " + liveChannelCategorySearchText(categories) + " " + liveText(channel, "channelNumber"))
        categoryMatches = query <> "" or selectedCategory = "All" or liveChannelHasCategory(categories, selectedCategory)
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
    categories = liveChannelCategories(channel)
    if categories.count() > 0 then return categories[0]
    return "Uncategorized"
end function

function liveChannelCategoryLabel(channel as Dynamic) as String
    categories = liveChannelCategories(channel)
    if categories.count() = 0 then return "Uncategorized"
    label = categories[0]
    if categories.count() > 1 then label += " +" + (categories.count() - 1).toStr()
    return label
end function

function liveChannelCategories(channel as Dynamic) as Object
    raw = liveText(channel, "category")
    if raw = "" then raw = liveText(channel, "groupTitle")
    categories = []
    if raw = "" then return categories
    parts = raw.Tokenize(";")
    for each part in parts
        category = liveCleanCategory(part)
        if category <> "" and not liveCategoryExists(categories, category) then categories.push(category)
    end for
    return categories
end function

function liveCleanCategory(value as Dynamic) as String
    if value = invalid then return ""
    if Type(value) <> "String" and Type(value) <> "roString" then return ""
    text = value
    while text.len() > 0 and Left(text, 1) = " "
        text = Right(text, text.len() - 1)
    end while
    while text.len() > 0 and Right(text, 1) = " "
        text = Left(text, text.len() - 1)
    end while
    return text
end function

function liveChannelHasCategory(categories as Object, selectedCategory as String) as Boolean
    if selectedCategory = "All" then return true
    needle = LCase(selectedCategory)
    for each category in categories
        if LCase(category) = needle then return true
    end for
    return false
end function

function liveChannelCategorySearchText(categories as Object) as String
    text = ""
    for each category in categories
        if text <> "" then text += " "
        text += category
    end for
    return text
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
        channelCategories = liveChannelCategories(channels[i])
        for each category in channelCategories
            if category <> "" and not liveCategoryExists(categories, category) then categories.push(category)
        end for
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
    m.categoryResultsActive = false
    m.searchEditing = true
    m.searchKeyboardIndex = 0
    render()
end sub

function handleSearchKeyboardKey(key as String) as Boolean
    cols = 10
    if key = "back" then closeSearchKeyboard() : return true
    nextIndex = uiKeyboardMoveIndex(m.searchKeys, m.searchKeyboardIndex, key, cols)
    if nextIndex <> m.searchKeyboardIndex then m.searchKeyboardIndex = nextIndex : render() : return true
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
            selectLiveCategory(categoryMatch, true)
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
    else if selected = "CASE" then
        m.searchKeyboardUpper = not m.searchKeyboardUpper
        render()
        return
    else
        if current.len() < 64 then current += uiKeyboardInputText(selected, m.searchKeyboardUpper)
    end if
    m.searchQuery = current
    m.categoryResultsActive = false
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
    returnToCategory = m.categoryResultsActive and m.searchQuery = ""
    m.searchQuery = ""
    if m.searchReturnPending then
        m.categoryIndex = m.searchPreviousCategoryIndex
        if m.categoryIndex < 0 or m.categoryIndex >= m.categories.count() then m.categoryIndex = 0
    else if returnToCategory then
        m.categoryIndex = 0
    end if
    m.searchReturnPending = false
    m.categoryResultsActive = false
    m.focusedCategoryIndex = m.categoryIndex
    normalizeCategoryWindow()
    m.channelWindowStart = 0
    m.selectedChannelIndex = 0
    if returnToCategory then
        m.focusArea = "categories"
        render()
        return
    end if
    m.focusArea = "normal"
    searchIndex = findFocusAction("search")
    if searchIndex >= 0 then m.focusIndex = searchIndex
    render()
end sub

sub drawSearchKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", 220, 104, 840, 524, 0.98)
    uiLabel(m.canvas, "Search Channels or Categories", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", 300, 188, 680, 48, 0.90)
    searchText = m.searchQuery
    if searchText = "" then searchText = "Search channels"
    uiLabel(m.canvas, searchText, 324, 196, 632, 32, 17, m.colors.text, "left")

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
