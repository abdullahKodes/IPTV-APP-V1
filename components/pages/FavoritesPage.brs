sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("favoritesCanvas")
    m.focusItems = []
    m.focusIndex = 4
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.searchKeyboardUpper = true
    m.searchReturnNavRow = 4
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "CASE", "SPACE", "DEL", "CLEAR", "DONE"]
    m.selectedSection = 0
    m.selectedIndexes = [0, 0, 0]
    m.windowStarts = [0, 0, 0]
    m.windowSize = 6
    m.focusArea = "nav"
    m.playbackMessage = ""
    m.backendPlaybackTask = invalid
    m.backendPlaybackChannel = invalid
    loadFavorites()
    render()
end sub

sub loadFavorites()
    m.activePlaylist = playlistStoreActive()
    m.activePlaylistId = playlistStoreText(m.activePlaylist, "id", playlistStoreDemoId())
    m.activePlaylistTitle = playlistStoreText(m.activePlaylist, "title", "Demo Playlist")
    m.favorites = favoriteStoreList(m.activePlaylistId)
end sub

sub refreshClock()
    if m.clock <> invalid then now = uiNowStrings() : m.clock.text = now.time : m.date.text = now.date
end sub

sub refreshFavorites()
    loadFavorites()
    normalizeFavoritesSelection()
    render()
end sub

function handleKey(key as String) as Boolean
    if m.searchEditing then return handleSearchKeyboardKey(key)
    if key = "back" and m.searchQuery <> "" then clearSearchAndStay() : return true
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    if routeFavoritesFocus(dx, dy) then render() : return
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    syncFavoritesFocus()
    render()
end sub

function routeFavoritesFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    ensureFavoritesFocus()
    current = m.focusItems[m.focusIndex]
    action = favItemText(current, "action")

    if action = "favorite" then
        section = current.section
        items = sectionItems(section)
        if current.doesExist("visibleIndex") then m.selectedIndexes[section] = current.visibleIndex
        if dx < 0 and m.selectedIndexes[section] > 0 then
            m.selectedIndexes[section] = m.selectedIndexes[section] - 1
            m.focusArea = "cards"
            normalizeSectionWindow(section, items.count())
            return true
        end if
        if dx > 0 and m.selectedIndexes[section] < items.count() - 1 then
            m.selectedIndexes[section] = m.selectedIndexes[section] + 1
            m.focusArea = "cards"
            normalizeSectionWindow(section, items.count())
            return true
        end if
        if dx < 0 then
            navIndex = findFavoriteFocusByRowCol(4, 0)
            if navIndex >= 0 then m.focusArea = "nav" : m.focusIndex = navIndex : return true
        end if
        if dy < 0 then
            targetSection = adjacentVisibleSection(section, -1)
            if targetSection < 0 then
                searchIndex = findFavoriteFocusAction("search")
                if searchIndex >= 0 then m.focusArea = "search" : m.focusIndex = searchIndex : return true
            else
                targetIndex = firstFavoriteFocusInSection(targetSection)
                if targetIndex >= 0 then m.focusArea = "cards" : m.selectedSection = targetSection : m.focusIndex = targetIndex : return true
            end if
        end if
        if dy > 0 then
            targetSection = adjacentVisibleSection(section, 1)
            if targetSection <= 2 then
                targetIndex = firstFavoriteFocusInSection(targetSection)
                if targetIndex >= 0 then m.focusArea = "cards" : m.selectedSection = targetSection : m.focusIndex = targetIndex : return true
            end if
        end if
        return true
    end if

    if action = "search" then
        if dy > 0 then
            cardIndex = firstFavoriteFocusInSection(0)
            if cardIndex < 0 then cardIndex = firstFavoriteFocusInSection(1)
            if cardIndex < 0 then cardIndex = firstFavoriteFocusInSection(2)
            if cardIndex >= 0 then m.focusArea = "cards" : m.focusIndex = cardIndex : return true
            navRow = m.searchReturnNavRow
            if navRow = invalid then navRow = 4
            targetRow = navRow + 1
            navIndex = findFavoriteFocusByRowCol(targetRow, 0)
            if navIndex < 0 then navIndex = findFavoriteFocusByRowCol(navRow, 0)
            if navIndex >= 0 then m.focusArea = "nav" : m.focusIndex = navIndex : return true
            navIndex = findFavoriteFocusByRowCol(4, 0)
            if navIndex >= 0 then m.focusArea = "nav" : m.focusIndex = navIndex : return true
        end if
        if dy < 0 and totalFavoriteCount() = 0 then
            navRow = m.searchReturnNavRow
            if navRow = invalid then navRow = 4
            targetRow = navRow - 1
            if targetRow < 0 then targetRow = navRow
            navIndex = findFavoriteFocusByRowCol(targetRow, 0)
            if navIndex < 0 then navIndex = findFavoriteFocusByRowCol(navRow, 0)
            if navIndex < 0 then navIndex = findFavoriteFocusByRowCol(4, 0)
            if navIndex >= 0 then m.focusArea = "nav" : m.focusIndex = navIndex : return true
            return true
        end if
        if dx < 0 then
            navRow = m.searchReturnNavRow
            if navRow = invalid then navRow = 4
            navIndex = findFavoriteFocusByRowCol(navRow, 0)
            if navIndex < 0 then navIndex = findFavoriteFocusByRowCol(4, 0)
            if navIndex >= 0 then m.focusArea = "nav" : m.focusIndex = navIndex : return true
        end if
    end if

    if current.col = 0 then
        if dy <> 0 then
            nextNav = findFavoriteFocusByRowCol(current.row + dy, 0)
            if nextNav >= 0 then m.focusArea = "nav" : m.focusIndex = nextNav
            return true
        end if
        if dx > 0 then
            searchIndex = findFavoriteFocusAction("search")
            if searchIndex >= 0 then m.searchReturnNavRow = current.row : m.focusArea = "search" : m.focusIndex = searchIndex : return true
        end if
    end if

    return false
end function

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "search" then openSearchKeyboard() : return
    if item.action = "favorite" then openFavorite(item) : return
end sub

sub openFavorite(focus as Object)
    items = sectionItems(focus.section)
    if focus.visibleIndex < 0 or focus.visibleIndex >= items.count() then return
    fav = items[focus.visibleIndex]
    kind = favItemText(fav, "favoriteKind")
    if kind = "movie" then openMovieFavorite(fav) : return
    if kind = "series" then openSeriesFavorite(fav) : return
    playLiveFavorite(fav)
end sub

sub openMovieFavorite(movie as Object)
    m.top.detailId = favItemText(movie, "id")
    m.top.detailTitle = favItemText(movie, "title", "Movie")
    m.top.detailSubtitle = favItemText(movie, "year") + " - " + favItemText(movie, "duration")
    m.top.detailMeta = favItemText(movie, "genre")
    m.top.detailDescription = favoriteDescription(movie, "movie")
    m.top.detailPosterUrl = favoritePosterUrl(movie)
    m.top.detailHeroUrl = favItemText(movie, "heroUrl")
    m.top.detailBackdropUrl = favItemText(movie, "backdropUrl")
    m.top.detailPlaybackUrl = mediaPlaybackUrl(movie)
    m.top.detailPlaybackFormat = mediaPlaybackFormat(movie)
    m.top.detailPlaylistId = m.activePlaylistId
    m.top.detailMediaType = "movie"
    m.top.detailReturnPage = "FavoritesPage"
    m.top.navigateTo = "MovieDetailPage"
end sub

sub openSeriesFavorite(series as Object)
    m.top.detailId = favItemText(series, "id")
    m.top.detailTitle = favItemText(series, "title", "Series")
    m.top.detailSubtitle = favItemText(series, "seasons") + " - " + favItemText(series, "episodeCount")
    m.top.detailMeta = favItemText(series, "genre") + " - " + favItemText(series, "rating")
    m.top.detailDescription = favoriteDescription(series, "series")
    m.top.detailPosterUrl = favoritePosterUrl(series)
    m.top.detailHeroUrl = favItemText(series, "heroUrl")
    m.top.detailBackdropUrl = favItemText(series, "backdropUrl")
    m.top.detailPlaybackUrl = mediaPlaybackUrl(series)
    m.top.detailPlaybackFormat = mediaPlaybackFormat(series)
    m.top.detailEpisodeNames = favItemText(series, "episodeNames")
    m.top.detailSeasonNames = favItemText(series, "seasonNames")
    m.top.detailEpisodeDurations = favItemText(series, "episodeDurations")
    m.top.detailActiveEpisodeTitle = favItemText(series, "activeEpisodeTitle")
    m.top.detailPlaylistId = m.activePlaylistId
    m.top.detailMediaType = "series"
    m.top.detailReturnPage = "FavoritesPage"
    m.top.navigateTo = "SeriesDetailPage"
end sub

sub playLiveFavorite(channel as Object)
    playbackUrl = mediaPlaybackUrl(channel)
    if playbackUrl = "" then
        backendChannelId = favItemText(channel, "backendChannelId")
        if backendChannelId <> "" then
            startBackendFavoritePlaybackLoad(channel)
        else
            m.playbackMessage = "Stream URL could not be loaded."
            render()
        end if
        return
    end if

    playLiveFavoriteWithUrl(channel, playbackUrl)
end sub

sub startBackendFavoritePlaybackLoad(channel as Object)
    backendChannelId = favItemText(channel, "backendChannelId")
    if backendChannelId = "" then return
    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.playbackMessage = "Playlist service is unavailable."
        render()
        return
    end if
    m.playbackMessage = ""
    m.backendPlaybackChannel = channel
    m.backendPlaybackTask = task
    task.observeField("response", "onBackendFavoritePlaybackLoaded")
    task.request = backendApiGetChannelRequest(backendChannelId)
    task.control = "RUN"
    render()
end sub

sub onBackendFavoritePlaybackLoaded()
    if m.backendPlaybackTask = invalid then return
    response = m.backendPlaybackTask.response
    channel = m.backendPlaybackChannel
    m.backendPlaybackTask = invalid
    m.backendPlaybackChannel = invalid
    playbackUrl = backendApiChannelStreamUrl(response)
    if backendApiResponseOk(response) and playbackUrl <> "" and channel <> invalid then
        m.playbackMessage = ""
        playLiveFavoriteWithUrl(channel, playbackUrl)
    else
        m.playbackMessage = "Stream URL could not be loaded."
        render()
    end if
end sub

sub playLiveFavoriteWithUrl(channel as Object, playbackUrl as String)
    if channel = invalid or playbackUrl = "" then return
    m.top.playbackTitle = favoriteTitle(channel)
    m.top.playbackSubtitle = favItemText(channel, "category", favItemText(channel, "groupTitle", "Live TV")) + " - " + favItemText(channel, "now", "Live stream")
    m.top.playbackUrl = playbackUrl
    m.top.playbackFormat = mediaPlaybackFormat(channel)
    m.top.playbackPosterUrl = favoritePosterUrl(channel)
    if m.top.hasField("playbackPlaylistId") then m.top.playbackPlaylistId = m.activePlaylistId
    if m.top.hasField("playbackMediaId") then m.top.playbackMediaId = favItemText(channel, "id", favoriteTitle(channel))
    if favItemFlag(channel, "live") then
        m.top.playbackMediaType = "live"
    else
        m.top.playbackMediaType = "movie"
    end if
    m.top.returnPage = "FavoritesPage"
    m.top.navigateTo = "PlayerPage"
end sub

sub render()
    loadFavorites()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    drawFavoritesBackdrop()
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    drawFavoritesSideNav()
    drawSearchBox()
    drawVisibleSections()
    drawEmptyStateIfNeeded()
    drawPlaybackMessage()
    ensureFavoritesFocus()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

sub drawPlaybackMessage()
    if m.playbackMessage = invalid or m.playbackMessage = "" then return
    uiLabel(m.canvas, m.playbackMessage, 244, 684, 860, 24, 12, m.colors.textMuted, "center")
end sub

sub drawFavoritesBackdrop()
    item = selectedBackdropItem()
    url = ""
    if item <> invalid then
        url = favoriteBackgroundArtworkUrl(item)
    end if
    if url <> "" then
        poster = uiPoster(m.canvas, url, 0, 0, 1280, 720, 0.58)
        poster.loadDisplayMode = "scaleToZoom"
    end if
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.54)
    uiRect(m.canvas, 226, 86, 1054, 634, "0x000000FF", 0.10)
end sub

sub drawFavoritesSideNav()
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.26)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14", 0.26)
    addFavoriteNavItem(12, 112, "home", "Home", "HomePage", 0, false)
    addFavoriteNavItem(12, 171, "tv", "Live TV", "LiveTvPage", 1, false)
    addFavoriteNavItem(12, 230, "series", "Series", "SeriesPage", 2, false)
    addFavoriteNavItem(12, 289, "movies", "Movies", "MoviesPage", 3, false)
    addFavoriteNavItem(12, 348, "heart", "Favorites", "FavoritesPage", 4, true)
    addFavoriteNavItem(12, 407, "settings", "Settings", "SettingsPage", 5, false)
    addFavoriteProfileItem()
end sub

sub addFavoriteNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    itemIndex = m.focusItems.count()
    focused = m.focusArea = "nav" and itemIndex = m.focusIndex
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

sub addFavoriteProfileItem()
    itemIndex = m.focusItems.count()
    focused = m.focusArea = "nav" and itemIndex = m.focusIndex
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
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: 6, col: 0, page: "ProfilePage", mode: "manual", noFocusShift: true
    })
end sub

sub drawSearchBox()
    itemIndex = m.focusItems.count()
    focused = m.focusArea = "search" and itemIndex = m.focusIndex
    bg = m.colors.panel
    border = m.colors.whiteLine
    textColor = m.colors.textDim
    if focused then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        textColor = m.colors.text
    end if
    label = "Search favorites"
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

sub drawSection(section as Integer, title as String, items as Object, y as Integer)
    normalizeSectionWindow(section, items.count())
    uiLabel(m.canvas, title, 244, y, 260, 26, 13, m.colors.text)
    if m.searchQuery = "" then uiLabel(m.canvas, items.count().toStr() + " saved", 934, y, 190, 26, 11, m.colors.textDim, "right")
    if items.count() = 0 then
        emptyText = "No " + LCase(title) + " favorites in " + m.activePlaylistTitle
        uiRoundRect(m.canvas, 244, y + 38, 860, 126, m.colors.panel, m.colors.whiteLine, 0.34)
        uiLabel(m.canvas, emptyText, 270, y + 84, 780, 32, 13, m.colors.textMuted, "center")
        return
    end if

    startIndex = m.windowStarts[section]
    endIndex = startIndex + m.windowSize - 1
    if endIndex > items.count() - 1 then endIndex = items.count() - 1
    slot = 0
    for i = startIndex to endIndex
        fav = items[i]
        if section = 2 then
            drawLiveFavoriteCard(fav, section, i, 244 + slot * 130, y + 34, 116, 156, sectionRow(section), slot + 1)
        else
            drawPosterFavoriteCard(fav, section, i, 244 + slot * 130, y + 34, 116, 156, sectionRow(section), slot + 1)
        end if
        slot += 1
    end for
    drawSectionScrollbar(section, items.count(), 1134, y + 38, 150)
end sub

sub drawVisibleSections()
    movies = filteredFavorites("movie")
    series = filteredFavorites("series")
    live = filteredFavorites("live")
    searchActive = m.searchQuery <> ""
    if movies.count() + series.count() + live.count() = 0 then return
    rowY = 112
    rowGap = 196

    if (not searchActive) or movies.count() > 0 then
        drawSection(0, "MOVIES", movies, rowY)
        rowY += rowGap
    end if
    if (not searchActive) or series.count() > 0 then
        drawSection(1, "SERIES", series, rowY)
        rowY += rowGap
    end if
    if (not searchActive) or live.count() > 0 then
        drawSection(2, "LIVE TV CHANNELS", live, rowY)
    end if
end sub

sub drawPosterFavoriteCard(fav as Object, section as Integer, visibleIndex as Integer, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if m.focusArea = "cards" and m.selectedSection = section then
        focused = visibleIndex = m.selectedIndexes[section]
        if focused then m.focusIndex = itemIndex
    end if
    cardCanvas = CreateObject("roSGNode", "Group")
    cardCanvas.id = "favoritePosterCard" + section.toStr() + "_" + visibleIndex.toStr()
    cardCanvas.translation = [x, y]
    m.canvas.appendChild(cardCanvas)
    uiRect(cardCanvas, 0, 0, w, h, m.colors.panel, 0.32)
    artUrl = favoritePosterUrl(fav)
    if artUrl <> "" then
        poster = uiPoster(cardCanvas, artUrl, 0, 0, w, h, 0.96)
        poster.loadDisplayMode = "scaleToZoom"
    else
        uiRoundRect(cardCanvas, 0, 0, w, h, m.colors.purpleSoft, m.colors.whiteLine, 0.64)
        uiDrawIcon(cardCanvas, "heart", 54, 46, 36, 36, focused, m.colors.text, 15)
    end if
    uiCardFocusTint(cardCanvas, 0, 0, w, h, focused)
    uiRectBorder(cardCanvas, 0, 0, w, h, favoriteBorderColor(focused), favoriteBorderWidth(focused), 1.0)
    if focused then uiAnimateCardFocus(m.canvas, cardCanvas, x, y)
    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        icon: "", label: favoriteTitle(fav), subtitle: favItemText(fav, "genre"),
        iconSize: 1, titleSize: 11, subSize: 9,
        bg: m.colors.panel, border: m.colors.whiteLine, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "favorite", section: section, visibleIndex: visibleIndex, mode: "manual"
    })
end sub

sub drawLiveFavoriteCard(fav as Object, section as Integer, visibleIndex as Integer, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if m.focusArea = "cards" and m.selectedSection = section then
        focused = visibleIndex = m.selectedIndexes[section]
        if focused then m.focusIndex = itemIndex
    end if
    bg = m.colors.panel
    border = m.colors.whiteLine
    if focused then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
    end if
    cardCanvas = CreateObject("roSGNode", "Group")
    cardCanvas.id = "favoriteLiveCard" + section.toStr() + "_" + visibleIndex.toStr()
    cardCanvas.translation = [x, y]
    m.canvas.appendChild(cardCanvas)
    uiRect(cardCanvas, 0, 0, w, h, bg, 0.62)
    brandColor = favItemText(fav, "brandColor", m.colors.greenFocus)
    brandColor2 = favItemText(fav, "brandColor2", m.colors.purpleActive)
    uiRect(cardCanvas, 0, 0, w, h, brandColor2, 0.50)
    uiRect(cardCanvas, 0, h - 42, w, 42, "0x000000FF", 0.34)
    logoUrl = favoritePosterUrl(fav)
    if logoUrl <> "" then
        logo = uiPoster(cardCanvas, logoUrl, 16, 38, w - 32, 54, 0.96)
        logo.loadDisplayMode = "scaleToFit"
    else
        uiDrawIcon(cardCanvas, "tv", 39, 52, 38, 38, focused, m.colors.text, 14)
    end if
    uiCardFocusTint(cardCanvas, 0, 0, w, h, focused)
    uiRectBorder(cardCanvas, 0, 0, w, h, border, favoriteBorderWidth(focused), 1.0)
    uiScaledLabel(cardCanvas, liveCardShortTitle(fav), 10, h - 36, w - 20, 22, 9, m.colors.text, "center", 0.78)
    if focused then uiAnimateCardFocus(m.canvas, cardCanvas, x, y)
    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        icon: "tv", label: favoriteTitle(fav), subtitle: favItemText(fav, "now"),
        iconSize: 12, titleSize: 10, subSize: 8,
        bg: bg, border: border, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "favorite", section: section, visibleIndex: visibleIndex, mode: "manual"
    })
end sub

sub drawSectionScrollbar(section as Integer, total as Integer, x as Integer, y as Integer, h as Integer)
    if total <= m.windowSize then return
    uiRect(m.canvas, x, y, 4, h, "0xFFFFFF18", 0.10)
    maxStart = total - m.windowSize
    if maxStart < 1 then maxStart = 1
    thumbH = Int(h * m.windowSize / total)
    if thumbH < 34 then thumbH = 34
    if thumbH > h then thumbH = h
    thumbY = y
    if h > thumbH then thumbY = y + Int((h - thumbH) * m.windowStarts[section] / maxStart)
    uiVerticalPill(m.canvas, x - 1, thumbY, 6, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.24)
end sub

sub drawEmptyStateIfNeeded()
    if filteredFavorites("movie").count() + filteredFavorites("series").count() + filteredFavorites("live").count() > 0 then return
    if m.searchQuery <> "" then
        uiEmptyShelf(m.canvas, m.colors, "search", "No favorites match this search")
    else
        uiEmptyShelf(m.canvas, m.colors, "heart", "No favorites yet")
    end if
end sub

function totalFavoriteCount() as Integer
    return filteredFavorites("movie").count() + filteredFavorites("series").count() + filteredFavorites("live").count()
end function

function filteredFavorites(kind as String) as Object
    res = []
    query = LCase(m.searchQuery)
    for i = 0 to m.favorites.count() - 1
        fav = m.favorites[i]
        if favItemText(fav, "favoriteKind") = kind then
            text = LCase(favoriteTitle(fav) + " " + favItemText(fav, "genre") + " " + favItemText(fav, "category") + " " + favItemText(fav, "groupTitle") + " " + favItemText(fav, "now") + " " + favItemText(fav, "year") + " " + favItemText(fav, "channelNumber"))
            if query = "" or Instr(1, text, query) > 0 then res.push(fav)
        end if
    end for
    return res
end function

function sectionItems(section as Integer) as Object
    if section = 0 then return filteredFavorites("movie")
    if section = 1 then return filteredFavorites("series")
    return filteredFavorites("live")
end function

function adjacentVisibleSection(section as Integer, direction as Integer) as Integer
    nextSection = section + direction
    while nextSection >= 0 and nextSection <= 2
        if firstFavoriteFocusInSection(nextSection) >= 0 then return nextSection
        nextSection += direction
    end while
    return -1
end function

function sectionRow(section as Integer) as Integer
    if section = 0 then return 2
    if section = 1 then return 4
    return 6
end function

sub normalizeSectionWindow(section as Integer, total as Integer)
    if total <= 0 then
        m.selectedIndexes[section] = 0
        m.windowStarts[section] = 0
        return
    end if
    if m.selectedIndexes[section] < 0 then m.selectedIndexes[section] = 0
    if m.selectedIndexes[section] > total - 1 then m.selectedIndexes[section] = total - 1
    if m.windowStarts[section] < 0 then m.windowStarts[section] = 0
    maxStart = total - m.windowSize
    if maxStart < 0 then maxStart = 0
    if m.windowStarts[section] > maxStart then m.windowStarts[section] = maxStart
    if m.selectedIndexes[section] < m.windowStarts[section] then m.windowStarts[section] = m.selectedIndexes[section]
    if m.selectedIndexes[section] >= m.windowStarts[section] + m.windowSize then m.windowStarts[section] = m.selectedIndexes[section] - m.windowSize + 1
end sub

function selectedBackdropItem() as Dynamic
    items = sectionItems(m.selectedSection)
    if items.count() > 0 then return items[m.selectedIndexes[m.selectedSection]]
    for section = 0 to 2
        other = sectionItems(section)
        if other.count() > 0 then return other[0]
    end for
    return invalid
end function

function firstFavoriteFocusInSection(section as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = "favorite" and item.section = section then return i
    end for
    return -1
end function

function findFavoriteFocusByRowCol(row as Integer, col as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.row = row and item.col = col then return i
    end for
    return -1
end function

function findFavoriteFocusAction(action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("action") and item.action = action then return i
    end for
    return -1
end function

sub syncFavoritesFocus()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.doesExist("action") and item.action = "favorite" then
        m.focusArea = "cards"
        m.selectedSection = item.section
        m.selectedIndexes[item.section] = item.visibleIndex
    else if item.doesExist("action") and item.action = "search" then
        m.focusArea = "search"
    else if item.col = 0 then
        m.focusArea = "nav"
    end if
end sub

sub ensureFavoritesFocus()
    if m.focusItems.count() = 0 then
        m.focusIndex = 0
        return
    end if
    if totalFavoriteCount() = 0 and m.focusArea = "cards" then
        searchIndex = findFavoriteFocusAction("search")
        if searchIndex >= 0 then
            m.focusArea = "search"
            m.focusIndex = searchIndex
            return
        end if
    end if
    if m.focusIndex >= 0 and m.focusIndex < m.focusItems.count() then return
    searchIndex = findFavoriteFocusAction("search")
    if searchIndex >= 0 then
        m.focusIndex = searchIndex
    else
        m.focusIndex = 0
    end if
end sub

sub normalizeFavoritesSelection()
    for section = 0 to 2
        items = sectionItems(section)
        normalizeSectionWindow(section, items.count())
    end for
    if sectionItems(m.selectedSection).count() <= 0 then
        for section = 0 to 2
            if sectionItems(section).count() > 0 then
                m.selectedSection = section
                exit for
            end if
        end for
    end if
end sub

function favoriteTitle(item as Dynamic) as String
    title = favItemText(item, "title")
    if title <> "" then return title
    title = favItemText(item, "name")
    if title <> "" then return title
    return "Favorite"
end function

function liveCardShortTitle(item as Dynamic) as String
    title = favoriteTitle(item)
    if title.len() <= 12 then return title
    words = title.Tokenize(" ")
    letters = ""
    for each word in words
        if word <> "" and letters.len() < 5 then letters += Left(UCase(word), 1)
    end for
    if letters <> "" then return letters
    return Left(title, 12)
end function

function favoritePosterUrl(item as Dynamic) as String
    posterUrl = favItemText(item, "posterUrl")
    if posterUrl <> "" then return posterUrl
    cardUrl = favItemText(item, "cardUrl")
    if cardUrl <> "" then return cardUrl
    logoUrl = favItemText(item, "logoUrl")
    if logoUrl <> "" then return logoUrl
    badgeUrl = favItemText(item, "badgeUrl")
    if badgeUrl <> "" then return badgeUrl
    backdropUrl = favItemText(item, "backdropUrl")
    if backdropUrl <> "" then return backdropUrl
    return ""
end function

function favoriteBackgroundArtworkUrl(item as Dynamic) as String
    if favItemText(item, "favoriteKind") = "live" then return "pkg:/images/live/live_tv_background_v6_art.jpg"
    heroUrl = favItemText(item, "heroUrl")
    if heroUrl <> "" then return heroUrl
    backdropUrl = favItemText(item, "backdropUrl")
    if backdropUrl = "" then return ""
    lowerUrl = LCase(backdropUrl)
    if Instr(1, lowerUrl, "/movie_backdrops/") > 0 then return ""
    if Instr(1, lowerUrl, "/series_backdrops/") > 0 then return ""
    return backdropUrl
end function

function favoriteDescription(item as Object, kind as String) as String
    text = favItemText(item, "description")
    if text <> "" then return text
    return favoriteTitle(item) + " is saved in Favorites for " + m.activePlaylistTitle + "."
end function

function favoriteBorderColor(focused as Boolean) as String
    if focused then return m.colors.greenFocus
    return "0xFFFFFF18"
end function

function favoriteBorderWidth(focused as Boolean) as Integer
    if focused then return 2
    return 1
end function

function favItemText(item as Dynamic, key as String, fallback = "" as String) as String
    value = favItemValue(item, key)
    if value = invalid then return fallback
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function favItemValue(item as Dynamic, key as String) as Dynamic
    if item = invalid then return invalid
    if item.doesExist(key) then return item[key]
    lowerKey = LCase(key)
    if lowerKey <> key and item.doesExist(lowerKey) then return item[lowerKey]
    return invalid
end function

function favItemFlag(item as Dynamic, key as String) as Boolean
    value = favItemValue(item, key)
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

sub openSearchKeyboard()
    m.focusArea = "search"
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
    else if selected = "CASE" then
        m.searchKeyboardUpper = not m.searchKeyboardUpper
        render()
        return
    else
        if current.len() >= 64 then return
        current += uiKeyboardInputText(selected, m.searchKeyboardUpper)
    end if
    m.searchQuery = current
    m.selectedIndexes = [0, 0, 0]
    m.windowStarts = [0, 0, 0]
    render()
end sub

sub closeSearchKeyboard()
    m.searchEditing = false
    render()
end sub

sub clearSearchAndStay()
    m.searchQuery = ""
    m.selectedIndexes = [0, 0, 0]
    m.windowStarts = [0, 0, 0]
    m.focusArea = "cards"
    render()
end sub

sub drawSearchKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", 220, 104, 840, 524, 0.98)
    uiLabel(m.canvas, "Search Favorites", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", 300, 188, 680, 48, 0.90)
    searchText = m.searchQuery
    if searchText = "" then searchText = "Search movies, series, or live TV"
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
