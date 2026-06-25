sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("movieDetailCanvas")
    m.focusItems = []
    m.focusIndex = 0
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
    heroUrl = m.top.detailHeroUrl
    if heroUrl = invalid or heroUrl = "" then
        backdropUrl = m.top.detailBackdropUrl
        if backdropUrl <> invalid and backdropUrl <> "" and not movieDetailBackdropIsComposed(backdropUrl) then heroUrl = backdropUrl
    end if
    if heroUrl <> invalid and heroUrl <> "" then
        drawMovieDetailHeroPoster(heroUrl)
    else
        bg = uiPoster(m.canvas, "pkg:/images/demo/backgrounds/iptv_max_art_backdrop.jpg", 0, 0, 1280, 720, 0.74)
        bg.loadDisplayMode = "scaleToFill"
        uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.52)
        uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.12)
    end if
end sub

sub drawTopBar()
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

sub drawMovieDetailHeroPoster(posterUrl as String)
    poster = uiPoster(m.canvas, posterUrl, 0, 0, 1280, 720, 1.0)
    poster.loadDisplayMode = "scaleToZoom"
    drawMovieDetailSmokeBlend()
end sub

sub drawMovieDetailSmokeBlend()
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.18)
    uiPoster(m.canvas, "pkg:/images/demo/overlays/detail_left_smoke.png", 0, 0, 900, 720, 1.0)
end sub

sub drawHeroCopy()
    uiScaledLabel(m.canvas, detailTitle(), 70, 104, 520, 46, 24, m.colors.text, "left", 1.42)
    uiScaledLabel(m.canvas, detailSubtitle() + "    " + detailMeta(), 72, 202, 520, 22, 12, m.colors.textDim, "left", 0.82)
    drawTwoLineText(detailDescription(), 72, 246, 520, 24, 13, m.colors.textMuted, 54)
end sub

sub drawActions()
    drawActionButton(72, 394, 146, "play", "Play Now", "watch", 2, 0)
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
    uiDrawIcon(m.canvas, icon, x + 19, y + 16, 16, 16, focused, textColor, 11)
    uiScaledLabel(m.canvas, label, x + 52, y + 11, w - 66, 24, 12, textColor, "left", 0.90)
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
    opacity = 0.68
    if focused then
        uri = "pkg:/images/ui/movie_watch_" + w.toStr() + "x40_greenSoft_greenFocus.png"
        opacity = 0.86
    end if
    uiPoster(m.canvas, uri, x, y, w, h, opacity)
end sub

function detailTitle() as String
    title = m.top.detailTitle
    if title = invalid or title = "" then return "Movie"
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
    return "A premium title from the active playlist, ready with artwork and playback metadata for a polished IPTV Max viewing experience."
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
