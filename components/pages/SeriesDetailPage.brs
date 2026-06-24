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
        if action = "episode" then m.focusIndex = seasonFocusIndexForColumn(item.col) : return true
    else if dy > 0 then
        if action = "back" then m.focusIndex = 1 : return true
        if action = "resume" or action = "favorite" then m.focusIndex = seasonFocusIndexForColumn(item.col) : return true
        if action = "season" then m.focusIndex = episodeFocusIndexForColumn(item.col) : return true
    else if dx <> 0 then
        if action = "resume" then if dx > 0 then m.focusIndex = 2 : return true
        if action = "favorite" then if dx < 0 then m.focusIndex = 1 : return true
        if action = "season" then
            newSeason = m.seasonIndex + dx
            if newSeason >= 0 and newSeason < visibleSeasonCount() then
                m.seasonIndex = newSeason
                m.focusIndex = seasonFocusIndexForColumn(newSeason)
                return true
            end if
        end if
        if action = "episode" then
            newEpisode = m.episodeIndex + dx
            if newEpisode >= 0 and newEpisode < detailEpisodeCount() then
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
    maxIndex = detailEpisodeCount() - 1
    if maxIndex < 0 then maxIndex = 0
    if m.episodeIndex > maxIndex then m.episodeIndex = maxIndex
    if m.episodeIndex < 0 then m.episodeIndex = 0
    ensureEpisodeWindow()
end sub

sub ensureEpisodeWindow()
    if m.episodeWindowStart = invalid then m.episodeWindowStart = 0
    if m.episodeIndex < m.episodeWindowStart then m.episodeWindowStart = m.episodeIndex
    if m.episodeIndex > m.episodeWindowStart + 3 then m.episodeWindowStart = m.episodeIndex - 3
    maxStart = detailEpisodeCount() - visibleEpisodeCount()
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
    m.top.playbackSubtitle = "Episode " + (m.episodeIndex + 1).toStr() + " - " + detailSubtitle()
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
    posterUrl = m.top.detailPosterUrl
    bg = uiPoster(m.canvas, "pkg:/images/demo/backgrounds/iptv_max_art_backdrop.jpg", 0, 0, 1280, 720, 0.74)
    bg.loadDisplayMode = "scaleToFill"
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.46)
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.08)
    if posterUrl <> invalid and posterUrl <> "" then
        drawSeriesDetailHeroPoster(posterUrl)
    else if posterUrl = invalid or posterUrl = "" then
        drawSeriesFallbackArt(884, 126, 220, 330)
    end if
end sub

sub drawTopBar()
    addFocusAction(48, 34, 112, 42, "back", 0, 0)
    focused = m.focusIndex = m.focusItems.count() - 1
    textColor = m.colors.textDim
    if focused then textColor = m.colors.text
    drawDetailSurface(48, 34, 112, 42, focused)
    uiDrawIcon(m.canvas, "back", 64, 45, 18, 18, focused, textColor, 9)
    uiLabel(m.canvas, "Back", 92, 40, 52, 28, 12, textColor)
    uiLabel(m.canvas, "IPTV MAX", 1050, 36, 170, 32, 16, m.colors.textGreen, "right")
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
    x = 370
    y = 28
    w = 770
    h = 664
    poster = uiPoster(m.canvas, posterUrl, x, y, w, h, 0.36)
    poster.loadDisplayMode = "scaleToZoom"
    drawSeriesDetailHeroEdgeBlend(x, y, w, h)
end sub

sub drawSeriesDetailHeroEdgeBlend(x as Integer, y as Integer, w as Integer, h as Integer)
    uiRect(m.canvas, x, y, 22, h, m.colors.bg, 0.34)
    uiRect(m.canvas, x + 22, y, 26, h, m.colors.bg, 0.20)
    uiRect(m.canvas, x + 48, y, 32, h, m.colors.bg, 0.10)
    uiRect(m.canvas, x + w - 22, y, 22, h, m.colors.bg, 0.34)
    uiRect(m.canvas, x + w - 48, y, 26, h, m.colors.bg, 0.20)
    uiRect(m.canvas, x + w - 80, y, 32, h, m.colors.bg, 0.10)
    uiRect(m.canvas, x, y, w, 14, m.colors.bg, 0.12)
    uiRect(m.canvas, x, y + h - 14, w, 14, m.colors.bg, 0.12)
end sub

sub drawHeroCopy()
    uiLabel(m.canvas, "WEB SERIES", 92, 126, 220, 24, 13, m.colors.textGreen)
    uiLabel(m.canvas, detailTitle(), 92, 160, 620, 52, 30, m.colors.text)
    uiLabel(m.canvas, detailSubtitle(), 94, 228, 600, 28, 14, m.colors.textDim)
    uiLabel(m.canvas, detailMeta(), 94, 262, 600, 28, 13, m.colors.textPurple)
    drawTwoLineText(detailDescription(), 94, 312, 574, 20, 13, m.colors.textMuted, 70)
end sub

sub drawActions()
    drawActionButton(94, 422, 166, "play", seriesPrimaryActionLabel(), "resume", 2, 0)
    drawActionButton(278, 422, 156, "heart", "Favorite", "favorite", 2, 1)
end sub

sub drawActionButton(x as Integer, y as Integer, w as Integer, icon as String, label as String, action as String, row as Integer, col as Integer)
    idx = m.focusItems.count()
    focused = idx = m.focusIndex
    addFocusAction(x, y, w, 48, action, row, col)
    textColor = m.colors.textDim
    if focused then textColor = m.colors.text
    drawDetailSurface(x, y, w, 48, focused)
    drawDetailIcon(icon, focused, x + 22, y + 14, 20, 20, textColor)
    uiLabel(m.canvas, label, x + 56, y + 9, w - 76, 28, 13, textColor)
end sub

sub drawSeasonTabs()
    seasonCount = detailSeasonCount()
    visibleCount = visibleSeasonCount()
    for i = 0 to visibleCount - 1
        x = 94 + i * 128
        label = "Season " + (i + 1).toStr()
        if i = 3 and seasonCount > 4 then label = seasonCount.toStr() + " Seasons"
        itemIndex = m.focusItems.count()
        addFocusAction(x, 512, 112, 36, "season", 3, i)
        m.focusItems[itemIndex].seasonIndex = i
        focused = itemIndex = m.focusIndex
        textColor = m.colors.textDim
        if i = m.seasonIndex then textColor = m.colors.text
        if focused then textColor = m.colors.text
        drawDetailSurface(x, 512, 112, 36, focused)
        if i = m.seasonIndex and not focused then uiRectBorder(m.canvas, x, 512, 112, 36, m.colors.greenFocus, 1, 0.55)
        uiLabel(m.canvas, label, x, 517, 112, 24, 10, textColor, "center")
    end for
end sub

sub drawEpisodes()
    normalizeEpisodeIndex()
    count = detailEpisodeCount()
    visibleCount = visibleEpisodeCount()
    if count > visibleCount then
        rangeText = (m.episodeWindowStart + 1).toStr() + "-" + (m.episodeWindowStart + visibleCount).toStr() + " of " + count.toStr()
        uiLabel(m.canvas, rangeText, 826, 528, 170, 22, 9, m.colors.textDim, "right")
        if m.episodeWindowStart > 0 then uiLabel(m.canvas, "<", 74, 598, 18, 28, 16, m.colors.textGreen, "center")
        if m.episodeWindowStart + visibleCount < count then uiLabel(m.canvas, ">", 1010, 598, 18, 28, 16, m.colors.textGreen, "center")
    end if
    for offset = 0 to visibleCount - 1
        episodeNumber = m.episodeWindowStart + offset
        drawEpisodeCard(episodeNumber, episodeCardTitle(episodeNumber), 94 + offset * 232, 574, 210, 78, offset)
    end for
end sub

sub drawEpisodeCard(index as Integer, title as String, x as Integer, y as Integer, w as Integer, h as Integer, visibleCol as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    addFocusAction(x, y, w, h, "episode", 4, visibleCol)
    m.focusItems[itemIndex].episodeIndex = index
    titleColor = m.colors.text
    if focused then titleColor = m.colors.textGreen
    drawDetailSurface(x, y, w, h, focused)
    uiLabel(m.canvas, "E" + (index + 1).toStr(), x + 16, y + 12, 42, 24, 14, m.colors.textGreen)
    uiLabel(m.canvas, title, x + 58, y + 10, w - 70, 26, 12, titleColor)
    uiLabel(m.canvas, detailTitle(), x + 58, y + 40, w - 70, 22, 9, m.colors.textDim)
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
    if detailEpisodeCount() > 1 then return "Resume"
    return "Watch"
end function

function episodeCardTitle(index as Integer) as String
    if index = m.episodeIndex and detailEpisodeCount() > 1 then return "Continue"
    return "Episode " + (index + 1).toStr()
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
    count = detailEpisodeCount()
    if count > 4 then return 4
    if count < 1 then return 1
    return count
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
