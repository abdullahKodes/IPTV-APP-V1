sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("seriesDetailCanvas")
    m.focusItems = []
    m.focusIndex = 1
    m.seasonIndex = 0
    m.episodeIndex = 0
    m.episodeWindowStart = 0
    render()
end sub

sub refreshClock()
end sub

sub syncDetail()
    normalizeSeasonIndex()
    normalizeEpisodeIndex()
    render()
end sub

function handleKey(key as String) as Boolean
    if key = "back" then goBack() : return true
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    if m.focusItems.count() = 0 then return
    if routeSeriesDetailFocus(dx, dy) then render() : return
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    syncDetailFocus()
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    action = detailText(item, "action")
    if action = "back" then goBack() : return
    if action = "resume" or action = "episode" then playDetail() : return
    if action = "favorite" then toggleFavorite() : return
    if action = "season" then
        if item.doesExist("seasonIndex") then m.seasonIndex = item.seasonIndex
        selectSeasonEpisodes()
        render()
        return
    end if
end sub

sub syncDetailFocus()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.doesExist("episodeIndex") then m.episodeIndex = item.episodeIndex
end sub

sub selectSeasonEpisodes()
    m.episodeIndex = 0
    m.episodeWindowStart = 0
    m.focusIndex = episodeFocusIndexForColumn(0)
end sub

function routeSeriesDetailFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return false
    item = m.focusItems[m.focusIndex]
    if item.doesExist("episodeIndex") then m.episodeIndex = item.episodeIndex
    action = detailText(item, "action")

    if dy < 0 then
        if action = "resume" or action = "favorite" then m.focusIndex = 0 : return true
        if action = "season" then
            if item.doesExist("seasonIndex") and item.seasonIndex >= 4 then
                m.focusIndex = seasonFocusIndexForColumn(item.seasonIndex - 4)
            else
                m.focusIndex = 1
                if item.col > 0 then m.focusIndex = 2
            end if
            return true
        end if
        if action = "episode" then
            if m.episodeIndex > 0 then
                m.episodeIndex = m.episodeIndex - 1
                ensureEpisodeWindow()
                m.focusIndex = episodeFocusIndexForColumn(m.episodeIndex - m.episodeWindowStart)
            else
                m.focusIndex = seasonFocusIndexForColumn(m.seasonIndex)
            end if
            return true
        end if
    else if dy > 0 then
        if action = "back" then m.focusIndex = 1 : return true
        if action = "resume" or action = "favorite" then m.focusIndex = seasonFocusIndexForColumn(item.col) : return true
        if action = "season" then
            focusedSeason = m.seasonIndex
            if item.doesExist("seasonIndex") then focusedSeason = item.seasonIndex
            if focusedSeason + 4 < visibleSeasonCount() then
                m.focusIndex = seasonFocusIndexForColumn(focusedSeason + 4)
            else
                m.seasonIndex = focusedSeason
                selectSeasonEpisodes()
            end if
            return true
        end if
        if action = "episode" then
            newEpisode = m.episodeIndex + 1
            if newEpisode < selectedSeasonEpisodeCount() then
                m.episodeIndex = newEpisode
                ensureEpisodeWindow()
                m.focusIndex = episodeFocusIndexForColumn(m.episodeIndex - m.episodeWindowStart)
            end if
            return true
        end if
    else if dx <> 0 then
        if action = "resume" then if dx > 0 then m.focusIndex = 2 : return true
        if action = "favorite" then if dx < 0 then m.focusIndex = 1 : return true
        if action = "season" then
            focusedSeason = m.seasonIndex
            if item.doesExist("seasonIndex") then focusedSeason = item.seasonIndex
            newSeason = focusedSeason + dx
            if newSeason >= 0 and newSeason < visibleSeasonCount() then
                m.focusIndex = seasonFocusIndexForColumn(newSeason)
                return true
            end if
        end if
        if action = "episode" then
            if dx < 0 then m.focusIndex = seasonFocusIndexForColumn(m.seasonIndex) : return true
        end if
    end if

    return false
end function

function seasonFocusIndexForColumn(col as Integer) as Integer
    if col < 0 then col = 0
    maxCol = visibleSeasonCount() - 1
    if col > maxCol then col = maxCol
    return 3 + col
end function

function episodeFocusIndexForColumn(col as Integer) as Integer
    if col < 0 then col = 0
    maxCol = visibleEpisodeCount() - 1
    if col > maxCol then col = maxCol
    return 3 + visibleSeasonCount() + col
end function

sub normalizeSeasonIndex()
    maxIndex = visibleSeasonCount() - 1
    if maxIndex < 0 then maxIndex = 0
    if m.seasonIndex > maxIndex then m.seasonIndex = maxIndex
    if m.seasonIndex < 0 then m.seasonIndex = 0
end sub

sub normalizeEpisodeIndex()
    maxIndex = selectedSeasonEpisodeCount() - 1
    if maxIndex < 0 then maxIndex = 0
    if m.episodeIndex > maxIndex then m.episodeIndex = maxIndex
    if m.episodeIndex < 0 then m.episodeIndex = 0
    ensureEpisodeWindow()
end sub

sub ensureEpisodeWindow()
    if m.episodeWindowStart = invalid then m.episodeWindowStart = 0
    if m.episodeIndex < m.episodeWindowStart then m.episodeWindowStart = m.episodeIndex
    if m.episodeIndex > m.episodeWindowStart + 4 then m.episodeWindowStart = m.episodeIndex - 4
    maxStart = selectedSeasonEpisodeCount() - visibleEpisodeCount()
    if maxStart < 0 then maxStart = 0
    if m.episodeWindowStart > maxStart then m.episodeWindowStart = maxStart
    if m.episodeWindowStart < 0 then m.episodeWindowStart = 0
end sub

sub goBack()
    target = m.top.detailReturnPage
    if target = invalid or target = "" then target = "SeriesPage"
    m.top.navigateTo = target
end sub

sub playDetail()
    url = m.top.detailPlaybackUrl
    if url = invalid or url = "" then return
    m.top.playbackTitle = detailTitle()
    m.top.playbackSubtitle = "S" + (m.seasonIndex + 1).toStr() + "-E" + selectedSeasonEpisodeNumber(m.episodeIndex).toStr()
    m.top.playbackUrl = url
    m.top.playbackFormat = detailPlaybackFormat()
    m.top.playbackPosterUrl = m.top.detailPosterUrl
    m.top.returnPage = "SeriesDetailPage"
    m.top.navigateTo = "PlayerPage"
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    drawBackdrop()
    drawTopBar()
    drawHeroCopy()
    drawActions()
    drawSeasonTabs()
    drawEpisodes()
end sub

sub drawBackdrop()
    heroUrl = m.top.detailHeroUrl
    if heroUrl = invalid or heroUrl = "" then
        backdropUrl = m.top.detailBackdropUrl
        if backdropUrl <> invalid and backdropUrl <> "" and not seriesDetailBackdropIsComposed(backdropUrl) then heroUrl = backdropUrl
    end if
    if heroUrl <> invalid and heroUrl <> "" then
        drawSeriesDetailHeroPoster(heroUrl)
    else
        bg = uiPoster(m.canvas, "pkg:/images/demo/backgrounds/iptv_max_art_backdrop.jpg", 0, 0, 1280, 720, 0.74)
        bg.loadDisplayMode = "scaleToFill"
        uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.52)
        uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.12)
    end if
end sub

sub drawTopBar()
    addFocusAction(48, 34, 112, 42, "back", 0, 0)
end sub

sub drawSeriesPosterAnchor(posterUrl as String)
    x = 884
    y = 126
    w = 220
    h = 330
    uiRect(m.canvas, x + 16, y + 20, w, h, "0x000000FF", 0.40)
    poster = uiPoster(m.canvas, posterUrl, x, y, w, h, 0.96)
    poster.loadDisplayMode = "scaleToFit"
    uiRectBorder(m.canvas, x, y, w, h, "0xFFFFFF30", 1, 0.88)
end sub

sub drawSeriesDetailHeroPoster(posterUrl as String)
    poster = uiPoster(m.canvas, posterUrl, 0, 0, 1280, 720, 1.0)
    poster.loadDisplayMode = "scaleToZoom"
    drawSeriesDetailSmokeBlend()
end sub

sub drawSeriesDetailSmokeBlend()
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.18)
    uiPoster(m.canvas, "pkg:/images/demo/overlays/detail_left_smoke.png", 0, 0, 900, 720, 1.0)
end sub

sub drawHeroCopy()
    uiScaledLabel(m.canvas, detailTitle(), 70, 104, 500, 46, 24, m.colors.text, "left", 1.38)
    uiScaledLabel(m.canvas, detailHeaderMeta(), 72, 202, 520, 22, 12, m.colors.textDim, "left", 0.82)
    drawTwoLineText(detailDescription(), 72, 246, 520, 24, 13, m.colors.textMuted, 54)
end sub

sub drawActions()
    drawActionButton(72, 338, 176, "play", seriesPrimaryActionLabel(), "resume", 2, 0)
    drawActionButton(264, 338, 176, "heart", favoriteActionLabel(), "favorite", 2, 1)
end sub

sub drawActionButton(x as Integer, y as Integer, w as Integer, icon as String, label as String, action as String, row as Integer, col as Integer)
    idx = m.focusItems.count()
    focused = idx = m.focusIndex
    h = 40
    addFocusAction(x, y, w, h, action, row, col)
    textColor = "0xE9F1FAFF"
    opacity = 0.70
    if focused then
        textColor = "0xFFFFFFFF"
        opacity = 0.90
    end if
    buttonCanvas = CreateObject("roSGNode", "Group")
    buttonCanvas.id = "seriesDetailAction" + idx.toStr()
    buttonCanvas.translation = [x, y]
    buttonCanvas.scaleRotateCenter = [w / 2, h / 2]
    m.canvas.appendChild(buttonCanvas)
    drawActionButtonSurface(buttonCanvas, 0, 0, w, h, focused, opacity)
    drawActionIcon(buttonCanvas, icon, focused, 22, 10, 20, 20, textColor)
    uiScaledLabel(buttonCanvas, label, 56, 6, w - 72, 24, 12, textColor, "left", 0.96)
    if focused then uiAnimateActionFocus(m.canvas, buttonCanvas)
end sub

sub toggleFavorite()
    favoriteStoreToggle("series", seriesDetailFavoriteItem(), detailPlaylistId())
    render()
end sub

function seriesDetailFavoriteItem() as Object
    return {
        id: m.top.detailId,
        playlistId: detailPlaylistId(),
        title: detailTitle(),
        seasons: detailSeasonLabel(),
        episodeCount: detailEpisodeLabel(),
        genre: detailGenreLabel(),
        rating: detailRatingLabel(),
        posterUrl: m.top.detailPosterUrl,
        cardUrl: m.top.detailPosterUrl,
        heroUrl: m.top.detailHeroUrl,
        backdropUrl: m.top.detailBackdropUrl,
        streamUrl: m.top.detailPlaybackUrl,
        streamFormat: detailPlaybackFormat(),
        episodeNames: m.top.detailEpisodeNames,
        seasonNames: m.top.detailSeasonNames,
        episodeDurations: m.top.detailEpisodeDurations,
        activeEpisodeTitle: m.top.detailActiveEpisodeTitle,
        description: detailDescription()
    }
end function

function favoriteActionLabel() as String
    if favoriteStoreIsFavorite("series", seriesDetailFavoriteItem(), detailPlaylistId()) then return "Favorited"
    return "Favorite"
end function

function detailPlaylistId() as String
    playlistId = m.top.detailPlaylistId
    if playlistId = invalid or playlistId = "" then return playlistStoreActiveId()
    return playlistId
end function

sub drawSeasonTabs()
    seasonCount = detailSeasonCount()
    visibleCount = visibleSeasonCount()
    uiLabel(m.canvas, "SEASONS", 72, 410, 190, 22, 10, m.colors.text)
    for i = 0 to visibleCount - 1
        col = i mod 4
        row = Int(i / 4)
        x = 72 + col * 148
        y = 456 + row * 46
        label = "Season " + (i + 1).toStr()
        if i = 7 and seasonCount > 8 then label = "Season 8+"
        itemIndex = m.focusItems.count()
        addFocusAction(x, y, 140, 40, "season", 3 + row, i)
        m.focusItems[itemIndex].seasonIndex = i
        focused = itemIndex = m.focusIndex
        textColor = m.colors.textDim
        fill = m.colors.panel
        border = m.colors.whiteLine
        opacity = 0.58
        selected = i = m.seasonIndex
        if i = m.seasonIndex then
            textColor = m.colors.text
            fill = m.colors.purpleSoft
            border = m.colors.greenFocus
            opacity = 0.68
        end if
        if focused then
            textColor = m.colors.text
            fill = m.colors.greenSoft
            border = m.colors.greenFocus
            opacity = 0.84
        end if
        seasonCanvas = CreateObject("roSGNode", "Group")
        seasonCanvas.id = "seriesSeasonButton" + i.toStr()
        seasonCanvas.translation = [x, y]
        seasonCanvas.scaleRotateCenter = [70, 20]
        m.canvas.appendChild(seasonCanvas)
        drawSeasonButtonSurface(seasonCanvas, 0, 0, focused, selected, opacity)
        uiLabel(seasonCanvas, label, 8, 7, 124, 24, 11, textColor, "center")
        if focused then uiAnimateActionFocus(m.canvas, seasonCanvas)
    end for
end sub

sub drawEpisodes()
    normalizeEpisodeIndex()
    visibleCount = visibleEpisodeCount()
    uiScaledLabel(m.canvas, selectedSeasonHeading(), 846, 232, 300, 24, 12, m.colors.text, "left", 0.90)
    for offset = 0 to visibleCount - 1
        episodeNumber = m.episodeWindowStart + offset
        drawEpisodeCard(episodeNumber, episodeCardTitle(episodeNumber), 846, 262 + offset * 82, 300, 74, offset)
    end for
    drawEpisodeScrollbar(1184, 262, 402)
end sub

sub drawEpisodeCard(index as Integer, title as String, x as Integer, y as Integer, w as Integer, h as Integer, visibleCol as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    addFocusAction(x, y, w, h, "episode", 4, visibleCol)
    m.focusItems[itemIndex].episodeIndex = index
    titleColor = m.colors.text
    if focused then titleColor = m.colors.textGreen
    fill = m.colors.panel
    border = m.colors.whiteSoft
    opacity = 0.56
    if focused then
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
        opacity = 0.92
    end if
    episodeCanvas = CreateObject("roSGNode", "Group")
    episodeCanvas.id = "seriesEpisodeCard" + index.toStr()
    episodeCanvas.translation = [x, y]
    m.canvas.appendChild(episodeCanvas)
    drawEpisodeSurface(episodeCanvas, 0, 0, w, h, focused, opacity)
    uiCardFocusTint(episodeCanvas, 0, 0, w, h, focused)
    drawEpisodeThumb(episodeCanvas, 16, 10, 54, 54)
    duration = episodeDurationFromData(index)
    titleY = 22
    if duration <> "" then titleY = 12
    uiScaledLabel(episodeCanvas, title, 90, titleY, w - 106, 30, 14, titleColor, "left", 1.06)
    if duration <> "" then uiScaledLabel(episodeCanvas, duration, 90, 43, w - 106, 20, 10, m.colors.textMuted, "left", 0.88)
    if focused then uiAnimateCardFocus(m.canvas, episodeCanvas, x, y)
end sub

sub drawEpisodeThumb(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer)
    thumbUrl = m.top.detailPosterUrl
    if thumbUrl <> invalid and thumbUrl <> "" then
        thumb = uiPoster(parent, thumbUrl, x, y, w, h, 0.92)
        thumb.loadDisplayMode = "scaleToZoom"
    else
        uiRect(parent, x, y, w, h, m.colors.panelSoft, 0.76)
    end if
end sub

sub drawActionButtonSurface(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean, opacity as Float)
    uri = "pkg:/images/ui/movie_watch_" + w.toStr() + "x40_panel_greenFocus.png"
    if focused then uri = "pkg:/images/ui/movie_watch_" + w.toStr() + "x40_greenSoft_greenFocus.png"
    uiPoster(parent, uri, x, y, w, h, opacity)
end sub

sub drawSeasonButtonSurface(parent as Object, x as Integer, y as Integer, focused as Boolean, selected as Boolean, opacity as Float)
    uri = "pkg:/images/ui/rr_140x40_bg_whiteLine.png"
    if selected then uri = "pkg:/images/ui/rr_140x40_purpleSoft_greenFocus.png"
    if focused then uri = "pkg:/images/ui/rr_140x40_greenSoft_greenFocus.png"
    uiPoster(parent, uri, x, y, 140, 40, opacity)
end sub

sub drawEpisodeSurface(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean, opacity as Float)
    uri = "pkg:/images/ui/rr_365x112_panel_whiteSoft.png"
    if focused then uri = "pkg:/images/ui/rr_365x112_greenSoft_greenFocus.png"
    uiPoster(parent, uri, x, y, w, h, opacity)
end sub

sub drawEpisodeScrollbar(x as Integer, y as Integer, h as Integer)
    total = selectedSeasonEpisodeCount()
    visible = visibleEpisodeCount()
    if total <= visible then return
    uiVerticalPill(m.canvas, x, y, 3, h, "0xFFFFFF18", "pkg:/images/ui/scroll_cap_4_whiteLine.png", 0.12)
    thumbH = Int(h * visible / total)
    if thumbH < 36 then thumbH = 36
    maxStart = total - visible
    thumbTravel = h - thumbH
    thumbY = y
    if maxStart > 0 then thumbY = y + Int(thumbTravel * m.episodeWindowStart / maxStart)
    uiVerticalPill(m.canvas, x - 1, thumbY, 6, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.16)
end sub

sub drawSeriesFallbackArt(x as Integer, y as Integer, w as Integer, h as Integer)
    uiRect(m.canvas, x, y, w, h, m.colors.purpleDeep, 0.98)
    uiRect(m.canvas, x, y, w, Int(h * 0.42), m.colors.greenDeep, 0.72)
    uiLabel(m.canvas, "IPTV", x, y + 108, w, 48, 30, m.colors.textGreen, "center")
    uiLabel(m.canvas, "SERIES", x, y + 158, w, 46, 24, m.colors.text, "center")
    uiLabel(m.canvas, detailTitle(), x + 24, y + h - 104, w - 48, 58, 17, m.colors.text, "center")
end sub

sub addFocusAction(x as Integer, y as Integer, w as Integer, h as Integer, action as String, row as Integer, col as Integer)
    m.focusItems.push({ x: x, y: y, w: w, h: h, action: action, row: row, col: col, mode: "manual" })
end sub

sub drawDetailSurface(x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean)
    fill = m.colors.panel
    border = m.colors.whiteLine
    opacity = 0.60
    if focused then
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
        opacity = 0.84
    end if
    uiRoundRect(m.canvas, x, y, w, h, fill, border, opacity)
end sub

sub drawDetailIcon(icon as String, focused as Boolean, x as Integer, y as Integer, w as Integer, h as Integer, tint as String)
    uri = "pkg:/images/icons/detail_" + icon + ".png"
    if focused then uri = "pkg:/images/icons/detail_" + icon + "_focus.png"
    poster = uiPoster(m.canvas, uri, x, y, w, h)
    poster.blendColor = tint
end sub

sub drawActionIcon(parent as Object, icon as String, focused as Boolean, x as Integer, y as Integer, w as Integer, h as Integer, tint as String)
    uri = "pkg:/images/ui/detail_action_" + icon + ".png"
    if focused then uri = "pkg:/images/ui/detail_action_" + icon + "_focus.png"
    poster = uiPoster(parent, uri, x, y, w, h, 0.96)
    poster.blendColor = tint
end sub

function detailTitle() as String
    title = m.top.detailTitle
    if title = invalid or title = "" then return "Series"
    return title
end function

function detailSubtitle() as String
    subtitle = m.top.detailSubtitle
    if subtitle = invalid then return ""
    return subtitle
end function

function detailMeta() as String
    meta = m.top.detailMeta
    if meta = invalid then return ""
    return meta
end function

function detailHeaderMeta() as String
    seasons = detailSeasonLabel()
    genre = detailGenreLabel()
    if genre = "" then return seasons
    return seasons + "    " + genre
end function

function detailSeasonLabel() as String
    subtitle = detailSubtitle()
    marker = Instr(1, subtitle, " - ")
    if marker > 0 then return Left(subtitle, marker - 1)
    return subtitle
end function

function detailGenreLabel() as String
    meta = detailMeta()
    if meta = invalid then return ""
    marker = Instr(1, meta, " - TV-")
    if marker > 0 then return Left(meta, marker - 1)
    marker = Instr(1, meta, " - PG")
    if marker > 0 then return Left(meta, marker - 1)
    marker = Instr(1, meta, " - R")
    if marker > 0 then return Left(meta, marker - 1)
    return meta
end function

function detailEpisodeLabel() as String
    subtitle = detailSubtitle()
    marker = Instr(1, subtitle, " - ")
    if marker > 0 then return Mid(subtitle, marker + 3)
    return ""
end function

function detailRatingLabel() as String
    meta = detailMeta()
    markers = [" - TV-", " - PG", " - R"]
    for each marker in markers
        markerPos = Instr(1, meta, marker)
        if markerPos > 0 then return Mid(meta, markerPos + 3)
    end for
    return ""
end function

function detailDescription() as String
    text = m.top.detailDescription
    if text = invalid or text = "" then return "A premium IPTV Max series from the active playlist."
    return text
end function

function detailPlaybackFormat() as String
    format = m.top.detailPlaybackFormat
    if format = invalid or format = "" then return "hls"
    return format
end function

function detailHeroUrl() as String
    heroUrl = m.top.detailHeroUrl
    if heroUrl = invalid then return ""
    return heroUrl
end function

function detailText(item as Dynamic, key as String) as String
    if item = invalid then return ""
    if item.doesExist(key) then return item[key]
    return ""
end function

function seriesDetailBackdropIsComposed(url as String) as Boolean
    if url = invalid or url = "" then return false
    return Instr(1, LCase(url), "/series_backdrops/") > 0
end function

function seriesPrimaryActionLabel() as String
    if selectedSeasonEpisodeCount() > 1 then return "Resume"
    return "Watch"
end function

function episodeCardTitle(index as Integer) as String
    explicitTitle = episodeTitleFromData(index)
    if explicitTitle <> "" then return explicitTitle
    return "Episode " + (index + 1).toStr()
end function

function episodeTitleFromData(localIndex as Integer) as String
    names = m.top.detailEpisodeNames
    if names <> invalid and names <> "" then
        delimiter = "|"
        if Instr(1, names, delimiter) = 0 then delimiter = ";"
        if Instr(1, names, delimiter) = 0 then delimiter = ","
        tokens = names.Tokenize(delimiter)
        tokenIndex = localIndex
        if tokens.count() >= detailEpisodeCount() then tokenIndex = selectedSeasonEpisodeOffset() + localIndex
        if tokenIndex >= 0 and tokenIndex < tokens.count() then
            candidate = trimLeftText(tokens[tokenIndex])
            if candidate <> "" then return candidate
        end if
    end if

    if localIndex = 0 then
        activeTitle = m.top.detailActiveEpisodeTitle
        if activeTitle <> invalid and activeTitle <> "" and not isEpisodeCodeLabel(activeTitle) then return activeTitle
    end if

    return ""
end function

function selectedSeasonHeading() as String
    seasonName = seasonNameFromData(m.seasonIndex)
    if seasonName <> "" then return UCase(seasonName)
    return "SEASON " + (m.seasonIndex + 1).toStr()
end function

function seasonNameFromData(index as Integer) as String
    names = m.top.detailSeasonNames
    if names = invalid or names = "" then return ""
    delimiter = "|"
    if Instr(1, names, delimiter) = 0 then delimiter = ";"
    if Instr(1, names, delimiter) = 0 then delimiter = ","
    tokens = names.Tokenize(delimiter)
    if index < 0 or index >= tokens.count() then return ""
    return trimLeftText(tokens[index])
end function

function episodeDurationFromData(localIndex as Integer) as String
    durations = m.top.detailEpisodeDurations
    if durations <> invalid and durations <> "" then
        delimiter = "|"
        if Instr(1, durations, delimiter) = 0 then delimiter = ";"
        if Instr(1, durations, delimiter) = 0 then delimiter = ","
        tokens = durations.Tokenize(delimiter)
        tokenIndex = localIndex
        if tokens.count() >= detailEpisodeCount() then tokenIndex = selectedSeasonEpisodeOffset() + localIndex
        if tokenIndex >= 0 and tokenIndex < tokens.count() then
            duration = trimLeftText(tokens[tokenIndex])
            if duration <> "" then return duration
        end if
    end if
    return placeholderEpisodeDuration(localIndex)
end function

function placeholderEpisodeDuration(localIndex as Integer) as String
    durations = ["52 min", "55 min", "58 min", "54 min", "57 min", "60 min", "51 min", "56 min"]
    durationIndex = (m.seasonIndex + localIndex) mod durations.count()
    return durations[durationIndex]
end function

function isEpisodeCodeLabel(text as String) as Boolean
    normalized = LCase(text)
    hasSeason = Instr(1, normalized, "s") > 0 or Instr(1, normalized, "season") > 0
    hasEpisode = Instr(1, normalized, "e") > 0 or Instr(1, normalized, "episode") > 0
    return hasSeason and hasEpisode and text.len() <= 14
end function

function detailSeasonCount() as Integer
    return numberBeforeWord(detailSubtitle(), "season", 1)
end function

function detailEpisodeCount() as Integer
    return numberBeforeWord(detailSubtitle(), "episode", 1)
end function

function visibleSeasonCount() as Integer
    count = detailSeasonCount()
    if count > 8 then return 8
    if count < 1 then return 1
    return count
end function

function visibleEpisodeCount() as Integer
    count = selectedSeasonEpisodeCount()
    if count > 5 then return 5
    if count < 1 then return 1
    return count
end function

function selectedSeasonEpisodeCount() as Integer
    seasons = detailSeasonCount()
    total = detailEpisodeCount()
    if seasons < 1 then seasons = 1
    if total < 1 then total = 1
    baseCount = Int(total / seasons)
    if baseCount < 1 then baseCount = 1
    extra = total - (baseCount * seasons)
    if extra < 0 then extra = 0
    count = baseCount
    if m.seasonIndex < extra then count = count + 1
    return count
end function

function selectedSeasonEpisodeNumber(localIndex as Integer) as Integer
    return localIndex + 1
end function

function selectedSeasonEpisodeOffset() as Integer
    seasons = detailSeasonCount()
    total = detailEpisodeCount()
    if seasons < 1 then seasons = 1
    if total < 1 then total = 1
    baseCount = Int(total / seasons)
    if baseCount < 1 then baseCount = 1
    extra = total - (baseCount * seasons)
    if extra < 0 then extra = 0
    offset = 0
    for i = 0 to m.seasonIndex - 1
        offset = offset + baseCount
        if i < extra then offset = offset + 1
    end for
    return offset
end function

function numberBeforeWord(text as String, word as String, fallback as Integer) as Integer
    if text = invalid or text = "" then return fallback
    wordIndex = Instr(1, LCase(text), word)
    if wordIndex <= 1 then return fallback
    i = wordIndex - 1
    digits = ""
    while i > 0
        ch = Mid(text, i, 1)
        if Instr(1, "0123456789", ch) > 0 then
            digits = ch + digits
        else if digits <> "" then
            exit while
        end if
        i = i - 1
    end while
    if digits = "" then return fallback
    value = Val(digits)
    if value < 1 then return fallback
    return value
end function

sub drawTwoLineText(text as String, x as Integer, y as Integer, w as Integer, lineH as Integer, size as Integer, color as String, maxChars as Integer)
    line1 = fitLineText(text, maxChars)
    uiLabel(m.canvas, line1, x, y, w, lineH + 6, size, color)
    rest = trimLeftText(Right(text, text.len() - line1.len()))
    if rest <> "" then
        line2 = fitLineText(rest, maxChars)
        if rest.len() > line2.len() then line2 = line2 + "..."
        uiLabel(m.canvas, line2, x, y + lineH, w, lineH + 6, size, color)
    end if
end sub

function fitLineText(text as String, maxChars as Integer) as String
    if text = invalid then return ""
    if text.len() <= maxChars then return text
    cut = maxChars
    while cut > 1 and Right(Left(text, cut), 1) <> " "
        cut = cut - 1
    end while
    if cut <= 1 then cut = maxChars
    return trimRightText(Left(text, cut))
end function

function trimLeftText(text as String) as String
    if text = invalid then return ""
    while text.len() > 0 and Left(text, 1) = " "
        text = Right(text, text.len() - 1)
    end while
    return text
end function

function trimRightText(text as String) as String
    if text = invalid then return ""
    while text.len() > 0 and Right(text, 1) = " "
        text = Left(text, text.len() - 1)
    end while
    return text
end function
