sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("seriesCanvas")
    m.focusItems = []
    m.focusIndex = 7
    m.selectedGenre = "All"
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.seriesWindowStart = 0
    m.seriesWindowSize = 4
    m.selectedSeriesIndex = 0
    m.resumeWindowStart = 0
    m.resumeWindowSize = 2
    m.selectedResumeIndex = 0
    m.focusArea = "normal"
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    m.activePlaylist = playlistStoreActive()
    m.activePlaylistId = playlistStoreText(m.activePlaylist, "id", playlistStoreDemoId())
    m.activePlaylistTitle = playlistStoreText(m.activePlaylist, "title", "Demo Playlist")
    m.series = mediaSeriesCatalogForPlaylist(m.activePlaylistId)
    render()
end sub

sub refreshClock()
    if m.clock <> invalid then now = uiNowStrings() : m.clock.text = now.time : m.date.text = now.date
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
    if routeSeriesFocus(dx, dy) then render() : return
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    syncSeriesFocus()
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "search" then openSearchKeyboard() : return
    if item.action = "genre" then m.selectedGenre = item.label : resetSeriesWindow() : render() : return
    if item.action = "play" then openSeriesDetail(m.series[item.sourceIndex]) : return
    if item.action = "series" then openSeriesDetail(m.series[item.sourceIndex]) : return
end sub

sub openSeriesDetail(series as Object)
    if series = invalid then return
    m.top.detailId = seriesText(series, "id")
    m.top.detailTitle = seriesText(series, "title", "Series")
    m.top.detailSubtitle = seriesText(series, "seasons") + " - " + seriesText(series, "episodeCount")
    m.top.detailMeta = seriesText(series, "genre") + " - " + seriesText(series, "rating")
    m.top.detailDescription = seriesDescription(series)
    m.top.detailPosterUrl = seriesText(series, "posterUrl")
    m.top.detailBackdropUrl = seriesBackdropUrl(series)
    m.top.detailPlaybackUrl = mediaPlaybackUrl(series)
    m.top.detailPlaybackFormat = mediaPlaybackFormat(series)
    m.top.detailReturnPage = "SeriesPage"
    m.top.navigateTo = "SeriesDetailPage"
end sub

sub playSeries(series as Object)
    if series = invalid then return
    subtitle = seriesText(series, "seasons")
    episode = seriesText(series, "activeEpisodeTitle")
    if episode <> "" then subtitle = episode + " - " + subtitle
    m.top.playbackTitle = seriesText(series, "title", "Demo Video")
    m.top.playbackSubtitle = subtitle
    m.top.playbackUrl = mediaPlaybackUrl(series)
    m.top.playbackFormat = mediaPlaybackFormat(series)
    m.top.playbackPosterUrl = seriesCardUrl(series)
    m.top.returnPage = "SeriesPage"
    m.top.navigateTo = "PlayerPage"
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    visible = filteredSeries()
    normalizeSeriesWindow(visible.count())
    drawSelectedSeriesBackdrop(visible)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    row = drawSeriesSideNav()
    drawSearchBox()
    if visible.count() = 0 then
        uiLabel(m.canvas, "No series in " + m.activePlaylistTitle, 244, 332, 746, 28, 15, m.colors.textDim, "center")
        uiLabel(m.canvas, "Switch playlist or add one with series content.", 244, 366, 746, 24, 11, m.colors.textMuted, "center")
        uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
        if m.searchEditing then drawSearchKeyboardOverlay()
        return
    end if
    drawCategoryPills(row)

    uiLabel(m.canvas, "CONTINUE WATCHING", 244, 158, 300, 26, 13, m.colors.textDim)
    drawResumeSeriesCards()

    sectionLabel = "POPULAR SERIES"
    if m.selectedGenre <> "All" then sectionLabel = m.selectedGenre + " series"
    countText = visible.count().toStr() + " titles"
    uiLabel(m.canvas, sectionLabel, 244, 362, 250, 26, 13, m.colors.textDim)
    uiLabel(m.canvas, countText, 824, 362, 190, 26, 12, m.colors.textDim, "right")
    endIndex = m.seriesWindowStart + m.seriesWindowSize - 1
    if endIndex > visible.count() - 1 then endIndex = visible.count() - 1
    slot = 0
    for i = m.seriesWindowStart to endIndex
        rowData = visible[i]
        drawMediaCard(rowData.series, i, rowData.index, 244 + slot * 212, 402, 200, 202, 3, slot + 1)
        slot += 1
    end for
    drawSeriesScrollbar(visible.count(), 1130, 402, 202)

    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

function drawSeriesSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    seriesActive = (m.focusIndex = 2) or (m.focusIndex > 5)
    addSeriesNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addSeriesNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addSeriesNavItem(12, 224, "series", "Series", "SeriesPage", 2, seriesActive)
    addSeriesNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addSeriesNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)

    addSeriesProfileItem()
    return 6
end function

function seriesDescription(series as Dynamic) as String
    title = seriesText(series, "title", "This series")
    genre = seriesText(series, "genre", "premium episodes")
    return title + " is ready for series browsing, resume playback, and episode selection from the active playlist."
end function

sub addSeriesNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: m.colors.textGreen, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: 0, page: page, mode: "row", noFocusShift: true
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
    end if
    m.focusItems.push(item)
end sub

sub addSeriesProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: "0xFFFFFF10", border: m.colors.panel, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 5, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
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

    label = "Search series"
    if m.searchQuery <> "" then label = m.searchQuery

    uiRoundRect(m.canvas, 686, 24, 260, 40, bg, border)
    uiDrawIcon(m.canvas, "search", 704, 34, 18, 18, focused, textColor, 11)
    uiLabel(m.canvas, label, 734, 27, 198, 28, 12, textColor)

    m.focusItems.push({
        x: 686, y: 24, w: 260, h: 40,
        icon: "search", label: label, subtitle: "",
        iconSize: 11, titleSize: 13, subSize: 10,
        bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 0, col: 1, page: "", action: "search", mode: "manual"
    })
end sub

sub drawCategoryPills(row as Integer)
    categories = [
        { label: "All", x: 244, y: 106, w: 100, h: 34 },
        { label: "Drama", x: 356, y: 106, w: 100, h: 34 },
        { label: "Action", x: 468, y: 106, w: 100, h: 34 },
        { label: "Comedy", x: 580, y: 106, w: 140, h: 34 },
        { label: "Sci-Fi", x: 732, y: 106, w: 100, h: 34 },
        { label: "Thriller", x: 844, y: 106, w: 100, h: 34 }
    ]
    for i = 0 to categories.count() - 1
        cat = categories[i]
        itemIndex = m.focusItems.count()
        focused = itemIndex = m.focusIndex
        selected = cat.label = m.selectedGenre
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

        uiRoundRect(m.canvas, cat.x, cat.y, cat.w, cat.h, bg, border)
        uiLabel(m.canvas, cat.label, cat.x, cat.y + 1, cat.w, 30, 12, textColor, "center")

        m.focusItems.push({
            x: cat.x, y: cat.y, w: cat.w, h: cat.h,
            icon: "", label: cat.label, subtitle: "",
            iconSize: 1, titleSize: 12, subSize: 10,
            bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
            focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
            row: 1, col: i + 1, page: "", action: "genre", mode: "manual"
        })
    end for
end sub

sub drawResumeSeriesCards()
    items = resumeSeriesRows()
    maxCards = items.count()
    normalizeResumeWindow(maxCards)
    endIndex = m.resumeWindowStart + m.resumeWindowSize - 1
    if endIndex > maxCards - 1 then endIndex = maxCards - 1
    slot = 0
    for i = m.resumeWindowStart to endIndex
        rowData = items[i]
        drawContinueCard(rowData.series, rowData.index, i, 244 + slot * 432, 194, 410, 136, 2, slot + 1)
        slot += 1
    end for
    drawResumeScrollbar(maxCards, 1130, 194, 136)
end sub

sub drawContinueCard(series as Object, sourceIndex as Integer, resumeIndex as Integer, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if m.focusArea = "resume" then
        focused = resumeIndex = m.selectedResumeIndex
        if focused then m.focusIndex = itemIndex
    end if
    bg = m.colors.panel
    border = "0xFFFFFF12"
    textColor = m.colors.text
    subColor = m.colors.textDim
    buttonUri = "pkg:/images/ui/movie_watch_140x40_panel_greenFocus.png"
    if focused then
        border = m.colors.greenFocus
        buttonUri = "pkg:/images/ui/movie_watch_140x40_greenSoft_greenFocus.png"
    end if

    title = seriesText(series, "title", "Untitled")
    episode = seriesText(series, "activeEpisodeTitle")
    progress = seriesText(series, "progressText")
    meta = episode
    if progress <> "" then
        if meta <> "" then meta += " - "
        meta += progress
    end if
    if meta = "" then meta = seriesText(series, "seasons")

    cardUri = "pkg:/images/ui/continue_card_410x136_panel_whiteSoft.png"
    if focused then cardUri = "pkg:/images/ui/continue_card_410x136_panel_greenFocus.png"
    uiPoster(m.canvas, cardUri, x, y, w, h)
    drawContinuePoster(series, x + 20, y + 17, 76, 102)
    uiLabel(m.canvas, title, x + 116, y + 20, w - 138, 28, 17, textColor)
    uiLabel(m.canvas, meta, x + 116, y + 52, w - 138, 22, 11, subColor)
    uiPoster(m.canvas, buttonUri, x + 116, y + 84, 126, 34)
    uiLabel(m.canvas, "Watch now", x + 123, y + 89, 112, 20, 8, "0xFFFFFFFF", "center")

    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        icon: "play", label: title, subtitle: meta,
        iconSize: 13, iconW: 36, iconH: 36, iconX: 20,
        labelX: 74, labelW: w - 96, labelAlign: "left",
        titleSize: 15, subSize: 11,
        bg: bg, border: border, textColor: textColor, subColor: subColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "play", mediaIndex: sourceIndex, sourceIndex: sourceIndex, resumeIndex: resumeIndex, mode: "manual"
    })
end sub

sub drawContinuePoster(series as Object, x as Integer, y as Integer, w as Integer, h as Integer)
    posterUrl = seriesText(series, "posterUrl")
    if posterUrl = "" then posterUrl = seriesCardUrl(series)
    if posterUrl <> "" then
        poster = uiPoster(m.canvas, posterUrl, x, y, w, h)
        poster.loadDisplayMode = "scaleToZoom"
        uiPoster(m.canvas, "pkg:/images/demo/frames/featured_poster_corner_mask.png", x, y, w, h)
        uiPoster(m.canvas, "pkg:/images/demo/frames/featured_poster_frame_neutral.png", x, y, w, h)
    else
        uiRoundRect(m.canvas, x, y, w, h, m.colors.purpleSoft, m.colors.greenFocus)
        uiDrawIcon(m.canvas, "cards_badge", x + 16, y + 28, 36, 36, false, "0xFFFFFFFF", 12)
    end if
end sub

sub drawMediaCard(series as Object, mediaIndex as Integer, sourceIndex as Integer, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if m.focusArea = "series" then
        focused = mediaIndex = m.selectedSeriesIndex
        if focused then m.focusIndex = itemIndex
    end if
    textColor = m.colors.textGreen
    metaColor = m.colors.textDim
    if focused then
        metaColor = m.colors.textGreen
    end if

    uiRect(m.canvas, x, y, w, h, m.colors.panel, 0.96)
    if focused then uiRect(m.canvas, x, y, w, h, m.colors.greenSoft, 0.24)
    drawSeriesPoster(series, x, y, w, 136, focused)
    uiRect(m.canvas, x + 12, y + 136, w - 24, 1, "0xFFFFFF12", 0.72)
    title = seriesText(series, "title", "Untitled")
    meta = seriesText(series, "seasons")
    if meta = "" then meta = seriesText(series, "episodeCount")
    uiLabel(m.canvas, title, x + 14, y + 143, w - 28, 22, 10, textColor)
    uiLabel(m.canvas, meta, x + 14, y + 167, w - 28, 20, 7, metaColor)
    drawSeriesCardBorder(x, y, w, h, focused)

    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        icon: "", label: title, subtitle: meta,
        iconSize: 17, iconW: 64, iconH: 64, iconX: Int((w - 64) / 2),
        titleSize: 14, subSize: 10,
        bg: m.colors.panel, border: "0xFFFFFF12", textColor: textColor, subColor: metaColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "series", mediaIndex: mediaIndex, sourceIndex: sourceIndex, mode: "manual"
    })
end sub

sub drawSeriesCardBorder(x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean)
    borderColor = "0xFFFFFF18"
    thickness = 1
    opacity = 0.9
    if focused then
        borderColor = m.colors.greenFocus
        thickness = 1
        opacity = 1.0
    end if
    uiRectBorder(m.canvas, x, y, w, h, borderColor, thickness, opacity)
end sub

sub drawSeriesPoster(series as Object, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean)
    posterUrl = seriesText(series, "posterUrl")
    if posterUrl <> "" then
        uiPosterZoom(m.canvas, posterUrl, x, y, w, h, 0.72)
        uiRect(m.canvas, x, y, w, h, m.colors.bg, 0.42)
        posterH = h - 8
        posterW = Int(posterH * 2 / 3)
        posterX = x + Int((w - posterW) / 2)
        posterY = y + 4
        poster = uiPoster(m.canvas, posterUrl, posterX, posterY, posterW, posterH)
        poster.loadDisplayMode = "scaleToFit"
        uiRectBorder(m.canvas, posterX, posterY, posterW, posterH, "0xFFFFFF24", 1, 0.88)
    else
        iconW = 36
        iconH = 36
        iconX = x + Int((w - iconW) / 2)
        iconY = y + Int((h - iconH) / 2)
        uiDrawIcon(m.canvas, "cards_badge", iconX, iconY, iconW, iconH, focused, "0xFFFFFFFF", 12)
        uiLabel(m.canvas, seriesText(series, "year"), x + 16, y + h - 24, w - 32, 18, 8, m.colors.textMuted, "center")
    end if
end sub

sub drawSelectedSeriesBackdrop(visible as Object)
    series = selectedSeriesForBackdrop(visible)
    if series = invalid then return

    bgUrl = seriesBackdropUrl(series)
    if bgUrl <> "" then
        backdrop = uiPoster(m.canvas, bgUrl, 226, 86, 1054, 634, 0.36)
        backdrop.loadDisplayMode = "scaleToZoom"
    end if
    posterUrl = seriesText(series, "posterUrl")
    if posterUrl <> "" and not seriesBackdropIsComposed(bgUrl) then drawSeriesBackdropPosterAnchor(posterUrl, 226, 86, 1054, 634)
    uiRect(m.canvas, 226, 86, 1054, 634, m.colors.bg, 0.58)
end sub

sub drawSeriesBackdropPosterAnchor(posterUrl as String, x as Integer, y as Integer, w as Integer, h as Integer)
    posterH = Int(h * 0.76)
    posterW = Int(posterH * 2 / 3)
    posterX = x + w - posterW - 48
    posterY = y + Int((h - posterH) / 2)

    uiRect(m.canvas, posterX + 16, posterY + 20, posterW, posterH, "0x000000FF", 0.36)
    poster = uiPoster(m.canvas, posterUrl, posterX, posterY, posterW, posterH, 0.92)
    poster.loadDisplayMode = "scaleToFit"
    uiRectBorder(m.canvas, posterX, posterY, posterW, posterH, "0xFFFFFF28", 1, 0.86)
end sub

function seriesBackdropIsComposed(url as String) as Boolean
    if url = invalid or url = "" then return false
    return Instr(1, LCase(url), "/series_backdrops/") > 0
end function

function selectedSeriesForBackdrop(visible as Object) as Dynamic
    if m.focusArea = "resume" then
        resumeItems = resumeSeriesRows()
        if resumeItems.count() > 0 and m.selectedResumeIndex >= 0 and m.selectedResumeIndex < resumeItems.count() then return resumeItems[m.selectedResumeIndex].series
    end if
    if visible.count() > 0 and m.focusArea = "series" then
        if m.selectedSeriesIndex >= 0 and m.selectedSeriesIndex < visible.count() then return visible[m.selectedSeriesIndex].series
    end if
    if visible.count() > 0 then return visible[0].series
    if m.series.count() > 0 then return m.series[0]
    return invalid
end function

function seriesCardUrl(series as Object) as String
    posterUrl = seriesText(series, "posterUrl")
    if posterUrl <> "" then return posterUrl
    cardUrl = seriesText(series, "cardUrl")
    if cardUrl <> "" then return cardUrl
    backdropUrl = seriesText(series, "backdropUrl")
    if backdropUrl <> "" then return backdropUrl
    return ""
end function

function seriesBackdropUrl(series as Object) as String
    backdropUrl = seriesText(series, "backdropUrl")
    if backdropUrl <> "" then return backdropUrl
    cardUrl = seriesText(series, "cardUrl")
    if cardUrl <> "" then return cardUrl
    posterUrl = seriesText(series, "posterUrl")
    if posterUrl <> "" then return posterUrl
    return ""
end function

function seriesText(series as Dynamic, key as String, fallback = "" as String) as String
    value = seriesValue(series, key)
    if value = invalid then return fallback
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function seriesProgress(series as Dynamic) as Integer
    value = seriesValue(series, "resumePercent")
    if value = invalid then return 0
    valueType = type(value)
    if valueType <> "Integer" and valueType <> "roInteger" and valueType <> "roInt" and valueType <> "LongInteger" and valueType <> "roLongInteger" and valueType <> "roLongInt" and valueType <> "Float" and valueType <> "roFloat" and valueType <> "Double" and valueType <> "roDouble" then return 0
    percent = Int(value)
    if percent < 0 then percent = 0
    if percent > 100 then percent = 100
    return percent
end function

function seriesValue(series as Dynamic, key as String) as Dynamic
    if series = invalid then return invalid
    if series.doesExist(key) then return series[key]
    lowerKey = LCase(key)
    if lowerKey <> key and series.doesExist(lowerKey) then return series[lowerKey]
    return invalid
end function

function filteredSeries() as Object
    res = []
    query = LCase(m.searchQuery)
    for i = 0 to m.series.count() - 1
        s = m.series[i]
        searchable = LCase(seriesText(s, "title") + " " + seriesText(s, "genre") + " " + seriesText(s, "year") + " " + seriesText(s, "rating") + " " + seriesText(s, "seasons"))
        matchSearch = (query = "") or (Instr(1, searchable, query) > 0)
        matchGenre = (m.selectedGenre = "All") or (Instr(1, LCase(seriesText(s, "genre")), LCase(m.selectedGenre)) > 0)
        if matchSearch and matchGenre then
            res.push({ series: s, index: i })
        end if
    end for
    return res
end function

function resumeSeriesRows() as Object
    res = []
    for i = 0 to m.series.count() - 1
        s = m.series[i]
        if seriesProgress(s) > 0 then
            res.push({ series: s, index: i })
        end if
    end for
    return res
end function

sub normalizeResumeWindow(total as Integer)
    if total <= 0 then
        m.resumeWindowStart = 0
        m.selectedResumeIndex = 0
        if m.focusArea = "resume" then m.focusArea = "normal"
        return
    end if
    if m.selectedResumeIndex < 0 then m.selectedResumeIndex = 0
    if m.selectedResumeIndex > total - 1 then m.selectedResumeIndex = total - 1
    if m.resumeWindowStart < 0 then m.resumeWindowStart = 0
    maxStart = total - m.resumeWindowSize
    if maxStart < 0 then maxStart = 0
    if m.resumeWindowStart > maxStart then m.resumeWindowStart = maxStart
    if m.selectedResumeIndex < m.resumeWindowStart then m.resumeWindowStart = m.selectedResumeIndex
    if m.selectedResumeIndex >= m.resumeWindowStart + m.resumeWindowSize then
        m.resumeWindowStart = m.selectedResumeIndex - m.resumeWindowSize + 1
    end if
end sub

sub drawResumeScrollbar(total as Integer, x as Integer, y as Integer, h as Integer)
    if total <= m.resumeWindowSize then return
    uiVerticalPill(m.canvas, x, y, 4, h, "0xFFFFFF18", "pkg:/images/ui/scroll_cap_4_whiteLine.png", 0.56)
    maxStart = total - m.resumeWindowSize
    if maxStart < 1 then maxStart = 1
    thumbH = Int(h * m.resumeWindowSize / total)
    if thumbH < 36 then thumbH = 36
    if thumbH > h then thumbH = h
    thumbY = y
    if h > thumbH then thumbY = y + Int((h - thumbH) * m.resumeWindowStart / maxStart)
    uiVerticalPill(m.canvas, x - 1, thumbY, 6, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.92)
end sub

sub drawSeriesScrollbar(total as Integer, x as Integer, y as Integer, h as Integer)
    if total <= m.seriesWindowSize then return
    uiVerticalPill(m.canvas, x, y, 4, h, "0xFFFFFF18", "pkg:/images/ui/scroll_cap_4_whiteLine.png", 0.56)
    maxStart = total - m.seriesWindowSize
    if maxStart < 1 then maxStart = 1
    thumbH = Int(h * m.seriesWindowSize / total)
    if thumbH < 42 then thumbH = 42
    if thumbH > h then thumbH = h
    thumbY = y
    if h > thumbH then thumbY = y + Int((h - thumbH) * m.seriesWindowStart / maxStart)
    uiVerticalPill(m.canvas, x - 1, thumbY, 6, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.92)
end sub

sub resetSeriesWindow()
    m.seriesWindowStart = 0
    m.selectedSeriesIndex = 0
    m.focusArea = "normal"
end sub

sub normalizeSeriesWindow(total as Integer)
    if total <= 0 then
        m.seriesWindowStart = 0
        m.selectedSeriesIndex = 0
        if m.focusArea = "series" then m.focusArea = "normal"
        return
    end if
    if m.selectedSeriesIndex < 0 then m.selectedSeriesIndex = 0
    if m.selectedSeriesIndex > total - 1 then m.selectedSeriesIndex = total - 1
    if m.seriesWindowStart < 0 then m.seriesWindowStart = 0
    maxStart = total - m.seriesWindowSize
    if maxStart < 0 then maxStart = 0
    if m.seriesWindowStart > maxStart then m.seriesWindowStart = maxStart
    if m.selectedSeriesIndex < m.seriesWindowStart then m.seriesWindowStart = m.selectedSeriesIndex
    if m.selectedSeriesIndex >= m.seriesWindowStart + m.seriesWindowSize then
        m.seriesWindowStart = m.selectedSeriesIndex - m.seriesWindowSize + 1
    end if
end sub

function routeSeriesFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then m.focusIndex = 0
    current = m.focusItems[m.focusIndex]
    action = ""
    if current.doesExist("action") then action = current.action
    if action <> "series" then m.focusArea = "normal"
    if action = "play" then m.focusArea = "resume"

    if action = "search" and dy > 0 then
        pIndex = findFocusByRowCol(1, 1)
        if pIndex >= 0 then m.focusIndex = pIndex : return true
    end if

    if action = "genre" then
        if dy < 0 then
            sIndex = findFocusAction("search")
            if sIndex >= 0 then m.focusIndex = sIndex : return true
        end if
        if dy > 0 then
            col = current.col
            targetCol = 1
            if col > 1 then targetCol = 2
            cIndex = findFocusByRowCol(2, targetCol)
            if cIndex >= 0 then
                m.selectedResumeIndex = m.resumeWindowStart + targetCol - 1
                m.focusArea = "resume"
                m.focusIndex = cIndex
                return true
            end if
            sIndex = findFocusByRowCol(3, 1)
            if sIndex >= 0 then
                m.selectedSeriesIndex = m.seriesWindowStart
                m.focusArea = "series"
                m.focusIndex = sIndex
                return true
            end if
        end if
    end if

    if action = "play" then
        resumeItems = resumeSeriesRows()
        if current.doesExist("resumeIndex") then m.selectedResumeIndex = current.resumeIndex
        if dx < 0 and m.selectedResumeIndex > 0 then
            m.selectedResumeIndex -= 1
            m.focusArea = "resume"
            normalizeResumeWindow(resumeItems.count())
            return true
        end if
        if dx < 0 and resumeItems.count() > 0 then
            m.selectedResumeIndex = resumeItems.count() - 1
            m.focusArea = "resume"
            normalizeResumeWindow(resumeItems.count())
            return true
        end if
        if dx > 0 and m.selectedResumeIndex < resumeItems.count() - 1 then
            m.selectedResumeIndex += 1
            m.focusArea = "resume"
            normalizeResumeWindow(resumeItems.count())
            return true
        end if
        if dx > 0 and resumeItems.count() > 0 then
            m.selectedResumeIndex = 0
            m.focusArea = "resume"
            normalizeResumeWindow(resumeItems.count())
            return true
        end if
        if dy < 0 then
            m.focusArea = "normal"
            col = current.col
            pIndex = findFocusByRowCol(1, col)
            if pIndex >= 0 then m.focusIndex = pIndex : return true
        end if
        if dy > 0 then
            m.focusArea = "series"
            col = current.col
            sIndex = findFocusByRowCol(3, col)
            if sIndex >= 0 then
                m.selectedSeriesIndex = m.seriesWindowStart + col - 1
                m.focusArea = "series"
                m.focusIndex = sIndex
                return true
            end if
        end if
    end if

    if action = "series" then
        visible = filteredSeries()
        if current.doesExist("mediaIndex") then m.selectedSeriesIndex = current.mediaIndex
        if dx < 0 and m.selectedSeriesIndex > 0 then
            m.selectedSeriesIndex -= 1
            m.focusArea = "series"
            normalizeSeriesWindow(visible.count())
            return true
        end if
        if dx < 0 and visible.count() > 0 then
            m.selectedSeriesIndex = visible.count() - 1
            m.focusArea = "series"
            normalizeSeriesWindow(visible.count())
            return true
        end if
        if dx > 0 and m.selectedSeriesIndex < visible.count() - 1 then
            m.selectedSeriesIndex += 1
            m.focusArea = "series"
            normalizeSeriesWindow(visible.count())
            return true
        end if
        if dx > 0 and visible.count() > 0 then
            m.selectedSeriesIndex = 0
            m.focusArea = "series"
            normalizeSeriesWindow(visible.count())
            return true
        end if
        if dx <> 0 then
            m.focusArea = "normal"
            return false
        end if
        if dy < 0 then
            m.focusArea = "normal"
            col = current.col
            targetCol = 1
            if col > 2 then targetCol = 2
            cIndex = findFocusByRowCol(2, targetCol)
            if cIndex >= 0 then m.focusIndex = cIndex : return true
            pIndex = findFocusByRowCol(1, targetCol)
            if pIndex >= 0 then m.focusIndex = pIndex : return true
        end if
    end if

    return false
end function

function findFocusByRowCol(row as Integer, col as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.row = row and item.col = col then return i
    end for
    return -1
end function

function findFocusAction(action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.action = action then return i
    end for
    return -1
end function

sub syncSeriesFocus()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    action = ""
    if item.doesExist("action") then action = item.action
    if action = "series" then
        if item.doesExist("mediaIndex") then m.selectedSeriesIndex = item.mediaIndex
        m.focusArea = "series"
    else if action = "play" then
        if item.doesExist("resumeIndex") then m.selectedResumeIndex = item.resumeIndex
        m.focusArea = "resume"
    else
        m.focusArea = "normal"
    end if
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
    m.seriesWindowStart = 0
    m.selectedSeriesIndex = 0
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
    uiLabel(m.canvas, "Search Series", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiRect(m.canvas, 330, 188, 620, 48, m.colors.bg2)
    searchText = m.searchQuery
    if searchText = "" then searchText = "Search series"
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
