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
    if action = "favorite" then render() : return
    if action = "season" then syncDetailFocus() : render() : return
end sub

sub syncDetailFocus()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.doesExist("seasonIndex") then m.seasonIndex = item.seasonIndex
    if item.doesExist("episodeIndex") then m.episodeIndex = item.episodeIndex
end sub

function routeSeriesDetailFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return false
    item = m.focusItems[m.focusIndex]
    if item.doesExist("seasonIndex") then m.seasonIndex = item.seasonIndex
    if item.doesExist("episodeIndex") then m.episodeIndex = item.episodeIndex
    action = detailText(item, "action")

    if dy < 0 then
        if action = "resume" or action = "favorite" then m.focusIndex = 0 : return true
        if action = "season" then
            m.focusIndex = 1
            if item.col > 0 then m.focusIndex = 2
            return true
        end if
        if action = "episode" then m.focusIndex = seasonFocusIndexForColumn(m.seasonIndex) : return true
    else if dy > 0 then
        if action = "back" then m.focusIndex = 1 : return true
        if action = "resume" or action = "favorite" then m.focusIndex = seasonFocusIndexForColumn(item.col) : return true
        if action = "season" then
            m.episodeIndex = 0
            m.episodeWindowStart = 0
            m.focusIndex = episodeFocusIndexForColumn(0)
            return true
        end if
    else if dx <> 0 then
        if action = "resume" then if dx > 0 then m.focusIndex = 2 : return true
        if action = "favorite" then if dx < 0 then m.focusIndex = 1 : return true
        if action = "season" then
            newSeason = m.seasonIndex + dx
            if newSeason >= 0 and newSeason < visibleSeasonCount() then
                m.seasonIndex = newSeason
                m.episodeIndex = 0
                m.episodeWindowStart = 0
                m.focusIndex = seasonFocusIndexForColumn(newSeason)
                return true
            end if
        end if
        if action = "episode" then
            newEpisode = m.episodeIndex + dx
            if newEpisode >= 0 and newEpisode < selectedSeasonEpisodeCount() then
                m.episodeIndex = newEpisode
                ensureEpisodeWindow()
                m.focusIndex = episodeFocusIndexForColumn(m.episodeIndex - m.episodeWindowStart)
                return true
            end if
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
    if m.episodeIndex > m.episodeWindowStart + 3 then m.episodeWindowStart = m.episodeIndex - 3
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
    m.top.playbackSubtitle = "S" + (m.seasonIndex + 1).toStr() + " E" + selectedSeasonEpisodeNumber(m.episodeIndex).toStr() + " - " + detailHeaderMeta()
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
    drawActionButton(72, 394, 146, "play", seriesPrimaryActionLabel(), "resume", 2, 0)
    drawActionButton(234, 394, 146, "heart", "Favorite", "favorite", 2, 1)
end sub

sub drawActionButton(x as Integer, y as Integer, w as Integer, icon as String, label as String, action as String, row as Integer, col as Integer)
    idx = m.focusItems.count()
    focused = idx = m.focusIndex
    h = 48
    addFocusAction(x, y, w, h, action, row, col)
    textColor = "0xE9F1FAFF"
    fill = m.colors.panel
    border = m.colors.whiteLine
    opacity = 0.48
    if focused then
        textColor = "0xFFFFFFFF"
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
        opacity = 0.88
    end if
    uiRoundRect(m.canvas, x, y, w, h, fill, border, opacity)
    uiRoundRect(m.canvas, x + 12, y + 9, 30, 30, "0xFFFFFF10", "0xFFFFFF10", 0.70)
    drawDetailIcon(icon, focused, x + 19, y + 16, 16, 16, textColor)
    uiScaledLabel(m.canvas, label, x + 52, y + 11, w - 66, 24, 12, textColor, "left", 0.90)
end sub

sub drawSeasonTabs()
    seasonCount = detailSeasonCount()
    visibleCount = visibleSeasonCount()
    uiLabel(m.canvas, "SEASONS", 72, 472, 190, 22, 10, m.colors.textDim)
    for i = 0 to visibleCount - 1
        x = 72 + i * 116
        label = "Season " + (i + 1).toStr()
        if seasonCount > 4 and i = 3 then label = "Season 4+"
        itemIndex = m.focusItems.count()
        addFocusAction(x, 506, 112, 36, "season", 3, i)
        m.focusItems[itemIndex].seasonIndex = i
        focused = itemIndex = m.focusIndex
        textColor = m.colors.textDim
        fill = m.colors.panel
        border = m.colors.whiteLine
        opacity = 0.48
        if i = m.seasonIndex then
            textColor = m.colors.text
            border = m.colors.greenFocus
            opacity = 0.68
        end if
        if focused then
            textColor = m.colors.text
            fill = m.colors.greenSoft
            border = m.colors.greenFocus
            opacity = 0.88
        end if
        uiRoundRect(m.canvas, x, 506, 112, 36, fill, border, opacity)
        uiLabel(m.canvas, label, x + 8, 511, 96, 24, 10, textColor, "center")
    end for
end sub

sub drawEpisodes()
    normalizeEpisodeIndex()
    visibleCount = visibleEpisodeCount()
    uiLabel(m.canvas, "EPISODES", 720, 284, 230, 24, 12, m.colors.textDim)
    for offset = 0 to visibleCount - 1
        episodeNumber = m.episodeWindowStart + offset
        drawEpisodeCard(episodeNumber, episodeCardTitle(episodeNumber), 770, 314 + offset * 94, 392, 86, offset)
    end for
end sub

sub drawEpisodeCard(index as Integer, title as String, x as Integer, y as Integer, w as Integer, h as Integer, visibleCol as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    addFocusAction(x, y, w, h, "episode", 4, visibleCol)
    m.focusItems[itemIndex].episodeIndex = index
    titleColor = m.colors.text
    if focused then titleColor = m.colors.textGreen
    fill = m.colors.panel
    border = m.colors.whiteLine
    opacity = 0.50
    if focused then
        fill = m.colors.greenSoft
        border = m.colors.greenFocus
        opacity = 0.90
    end if
    uiRect(m.canvas, x, y, w, h, fill, opacity)
    uiRectBorder(m.canvas, x, y, w, h, border, 2, 0.72)
    drawEpisodeThumb(x + 12, y + 10, 72, 66)
    uiRect(m.canvas, x + 12, y + 10, 72, 66, "0x000000FF", 0.18)
    uiLabel(m.canvas, title, x + 108, y + 24, w - 128, 30, 15, titleColor)
end sub

sub drawEpisodeThumb(x as Integer, y as Integer, w as Integer, h as Integer)
    thumbUrl = m.top.detailPosterUrl
    if thumbUrl <> invalid and thumbUrl <> "" then
        thumb = uiPoster(m.canvas, thumbUrl, x, y, w, h, 0.88)
        thumb.loadDisplayMode = "scaleToZoom"
    else
        uiRect(m.canvas, x, y, w, h, m.colors.panelSoft, 0.76)
    end if
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
    if m.seasonIndex = 0 and index = 0 and selectedSeasonEpisodeCount() > 1 then return "Continue"
    return "Episode " + selectedSeasonEpisodeNumber(index).toStr()
end function

function detailSeasonCount() as Integer
    return numberBeforeWord(detailSubtitle(), "season", 1)
end function

function detailEpisodeCount() as Integer
    return numberBeforeWord(detailSubtitle(), "episode", 1)
end function

function visibleSeasonCount() as Integer
    count = detailSeasonCount()
    if count > 4 then return 4
    if count < 1 then return 1
    return count
end function

function visibleEpisodeCount() as Integer
    count = selectedSeasonEpisodeCount()
    if count > 4 then return 4
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
    seasons = detailSeasonCount()
    total = detailEpisodeCount()
    if seasons < 1 then seasons = 1
    if total < 1 then total = 1
    baseCount = Int(total / seasons)
    if baseCount < 1 then baseCount = 1
    extra = total - (baseCount * seasons)
    if extra < 0 then extra = 0
    number = 1
    for i = 0 to m.seasonIndex - 1
        number = number + baseCount
        if i < extra then number = number + 1
    end for
    return number + localIndex
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
