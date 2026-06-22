sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("movieDetailCanvas")
    m.focusItems = []
    m.focusIndex = 1
    render()
end sub

sub refreshClock()
end sub

sub syncDetail()
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
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    action = detailText(item, "action")
    if action = "back" then goBack() : return
    if action = "watch" then playDetail() : return
    if action = "favorite" then render() : return
end sub

sub goBack()
    target = m.top.detailReturnPage
    if target = invalid or target = "" then target = "MoviesPage"
    m.top.navigateTo = target
end sub

sub playDetail()
    url = m.top.detailPlaybackUrl
    if url = invalid or url = "" then return
    m.top.playbackTitle = detailTitle()
    m.top.playbackSubtitle = detailSubtitle()
    m.top.playbackUrl = url
    m.top.playbackFormat = detailPlaybackFormat()
    m.top.playbackPosterUrl = m.top.detailPosterUrl
    m.top.returnPage = "MovieDetailPage"
    m.top.navigateTo = "PlayerPage"
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    drawBackdrop()
    drawTopBar()
    drawHeroCopy()
    drawActions()
end sub

sub drawBackdrop()
    bgUrl = m.top.detailBackdropUrl
    posterUrl = m.top.detailPosterUrl
    if bgUrl <> invalid and bgUrl <> "" then
        bg = uiPoster(m.canvas, bgUrl, 0, 0, 1280, 720, 1.0)
        bg.loadDisplayMode = "scaleToZoom"
    else if posterUrl <> invalid and posterUrl <> "" then
        bg = uiPoster(m.canvas, posterUrl, 0, 0, 1280, 720, 0.52)
        bg.loadDisplayMode = "scaleToZoom"
    else
        uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    end if
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.58)
    if posterUrl <> invalid and posterUrl <> "" and not movieDetailBackdropIsComposed(bgUrl) then
        drawMoviePosterAnchor(posterUrl)
    else if (posterUrl = invalid or posterUrl = "") and (bgUrl = invalid or bgUrl = "") then
        drawMovieFallbackArt(884, 126, 220, 330)
    end if
end sub

sub drawTopBar()
    addFocusAction(48, 36, 100, 34, "back", 0, 0)
    focused = m.focusIndex = m.focusItems.count() - 1
    textColor = m.colors.textDim
    if focused then textColor = m.colors.text
    backFill = m.colors.panel
    backBorder = m.colors.whiteLine
    backOpacity = 0.72
    if focused then
        backFill = m.colors.greenSoft
        backBorder = m.colors.greenFocus
        backOpacity = 0.92
    end if
    uiRoundRect(m.canvas, 48, 36, 100, 34, backFill, backBorder, backOpacity)
    uiDrawIcon(m.canvas, "back", 62, 46, 14, 14, focused, textColor, 8)
    uiLabel(m.canvas, "Back", 84, 39, 48, 26, 11, textColor)
    uiLabel(m.canvas, "IPTV MAX", 1050, 36, 170, 32, 16, m.colors.textGreen, "right")
end sub

sub drawMoviePosterAnchor(posterUrl as String)
    x = 884
    y = 126
    w = 220
    h = 330
    uiRect(m.canvas, x + 16, y + 20, w, h, "0x000000FF", 0.40)
    poster = uiPoster(m.canvas, posterUrl, x, y, w, h, 0.96)
    poster.loadDisplayMode = "scaleToFit"
    uiRectBorder(m.canvas, x, y, w, h, "0xFFFFFF30", 1, 0.88)
end sub

sub drawHeroCopy()
    uiLabel(m.canvas, "MOVIE", 92, 132, 180, 24, 13, m.colors.textGreen)
    uiLabel(m.canvas, detailTitle(), 92, 162, 600, 70, 43, m.colors.text)
    uiLabel(m.canvas, detailSubtitle(), 94, 238, 560, 30, 17, m.colors.text)
    uiLabel(m.canvas, detailMeta(), 94, 276, 560, 30, 16, m.colors.text)
    drawTwoLineText(detailDescription(), 94, 328, 574, 24, 15, m.colors.text, 62)
end sub

sub drawActions()
    drawActionButton(94, 446, 176, "play", "Watch now", "watch", 2, 0)
    drawActionButton(292, 446, 166, "heart", "Favorite", "favorite", 2, 1)
end sub

sub drawActionButton(x as Integer, y as Integer, w as Integer, icon as String, label as String, action as String, row as Integer, col as Integer)
    idx = m.focusItems.count()
    focused = idx = m.focusIndex
    addFocusAction(x, y, w, 40, action, row, col)
    textColor = "0xFFFFFFFF"
    drawDetailSurface(x, y, w, 40, focused)
    uiDrawIcon(m.canvas, icon, x + 22, y + 10, 20, 20, focused, textColor, 12)
    uiLabel(m.canvas, label, x + 52, y + 5, w - 62, 28, 13, textColor)
end sub

sub drawMovieFallbackArt(x as Integer, y as Integer, w as Integer, h as Integer)
    uiRect(m.canvas, x, y, w, h, m.colors.purpleDeep, 0.98)
    uiRect(m.canvas, x, y, w, Int(h * 0.42), m.colors.greenDeep, 0.72)
    uiRect(m.canvas, x + 22, y + 24, w - 44, 3, m.colors.greenFocus, 0.74)
    uiLabel(m.canvas, "IPTV", x, y + 124, w, 52, 34, m.colors.textGreen, "center")
    uiLabel(m.canvas, "MAX", x, y + 174, w, 48, 31, m.colors.text, "center")
    uiLabel(m.canvas, detailTitle(), x + 28, y + h - 110, w - 56, 60, 18, m.colors.text, "center")
end sub

sub addFocusAction(x as Integer, y as Integer, w as Integer, h as Integer, action as String, row as Integer, col as Integer)
    m.focusItems.push({ x: x, y: y, w: w, h: h, action: action, row: row, col: col, mode: "manual" })
end sub

sub drawDetailSurface(x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean)
    uri = "pkg:/images/ui/movie_watch_" + w.toStr() + "x40_panel_greenFocus.png"
    if focused then
        uri = "pkg:/images/ui/movie_watch_" + w.toStr() + "x40_greenSoft_greenFocus.png"
    end if
    uiPoster(m.canvas, uri, x, y, w, h)
end sub

function detailTitle() as String
    title = m.top.detailTitle
    if title = invalid or title = "" then return "Movie"
    return UCase(title)
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
    if text = invalid or text = "" then return "A premium IPTV Max title from the active playlist."
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

function movieDetailBackdropIsComposed(url as String) as Boolean
    if url = invalid or url = "" then return false
    return Instr(1, LCase(url), "/movie_backdrops/") > 0
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
