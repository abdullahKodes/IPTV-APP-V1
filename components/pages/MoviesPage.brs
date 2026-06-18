sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("moviesCanvas")
    m.focusItems = []
    m.focusIndex = 3
    m.selectedGenre = "All"
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.movieWindowStart = 0
    m.movieWindowSize = 4
    m.selectedMovieIndex = 0
    m.featuredMovieIndex = -1
    m.focusArea = "normal"
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    m.activePlaylist = playlistStoreActive()
    m.activePlaylistId = playlistStoreText(m.activePlaylist, "id", playlistStoreDemoId())
    m.activePlaylistTitle = playlistStoreText(m.activePlaylist, "title", "Demo Playlist")
    m.movies = mediaMovieCatalogForPlaylist(m.activePlaylistId)
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
    if routeMoviesFocus(dx, dy) then render() : return
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    syncMovieFocus()
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "search" then openSearchKeyboard() : return
    if item.action = "genre" then m.selectedGenre = item.label : resetMovieWindow() : render() : return
    if item.action = "watch" then openMovieDetail(featuredMovie(filteredMovies())) : return
    if item.action = "movie" then openMovieDetail(m.movies[item.sourceIndex]) : return
end sub

sub openMovieDetail(movie as Object)
    if movie = invalid then return
    m.top.detailId = movieText(movie, "id")
    m.top.detailTitle = movieText(movie, "title", "Movie")
    m.top.detailSubtitle = movieText(movie, "year") + " - " + movieText(movie, "duration")
    m.top.detailMeta = movieText(movie, "genre") + " - " + movieText(movie, "rating")
    m.top.detailDescription = movieDescription(movie)
    m.top.detailPosterUrl = movieText(movie, "posterUrl")
    m.top.detailBackdropUrl = movieBackdropUrl(movie)
    m.top.detailPlaybackUrl = mediaPlaybackUrl(movie)
    m.top.detailPlaybackFormat = mediaPlaybackFormat(movie)
    m.top.detailReturnPage = "MoviesPage"
    m.top.navigateTo = "MovieDetailPage"
end sub

sub playMovie(movie as Object)
    if movie = invalid then return
    m.top.playbackTitle = movieText(movie, "title", "Demo Video")
    m.top.playbackSubtitle = movieText(movie, "year") + " - " + movieText(movie, "duration") + " - " + movieText(movie, "genre")
    m.top.playbackUrl = mediaPlaybackUrl(movie)
    m.top.playbackFormat = mediaPlaybackFormat(movie)
    m.top.playbackPosterUrl = movieCardUrl(movie)
    m.top.returnPage = "MoviesPage"
    m.top.navigateTo = "PlayerPage"
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    visible = filteredMovies()
    normalizeMovieWindow(visible.count())
    drawSelectedBackdrop(visible)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    row = drawMoviesSideNav()
    drawSearchBox()
    if visible.count() = 0 then
        uiLabel(m.canvas, "No movies in " + m.activePlaylistTitle, 244, 332, 746, 28, 15, m.colors.textDim, "center")
        uiLabel(m.canvas, "Switch playlist or add one with movie content.", 244, 366, 746, 24, 11, m.colors.textMuted, "center")
        ensureMovieFocus()
        uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
        if m.searchEditing then drawSearchKeyboardOverlay()
        return
    end if
    drawMoviePills(row)

    uiLabel(m.canvas, "FEATURED MOVIE", 244, 166, 250, 26, 13, m.colors.textDim)
    drawFeatured(featuredMovie(visible), row + 1)

    sectionLabel = "ALL MOVIES"
    if m.selectedGenre <> "All" then sectionLabel = m.selectedGenre + " movies"
    countText = visible.count().toStr() + " titles"
    uiLabel(m.canvas, sectionLabel, 244, 404, 250, 26, 13, m.colors.textDim)
    uiLabel(m.canvas, countText, 824, 404, 190, 26, 12, m.colors.textDim, "right")
    endIndex = m.movieWindowStart + m.movieWindowSize - 1
    if endIndex > visible.count() - 1 then endIndex = visible.count() - 1
    slot = 0
    for i = m.movieWindowStart to endIndex
        rowData = visible[i]
        drawMovieCard(rowData.movie, i, rowData.index, 244 + slot * 222, 444, 200, 202, 4, slot + 1)
        slot += 1
    end for
    drawMovieScrollbar(visible.count(), 1130, 444, 202)

    ensureMovieFocus()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

function drawMoviesSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    moviesActive = (m.focusIndex = 3) or (m.focusIndex > 5)
    addMoviesNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addMoviesNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addMoviesNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addMoviesNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, moviesActive)
    addMoviesNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)

    addMoviesProfileItem()
    return 6
end function

function movieDescription(movie as Dynamic) as String
    title = movieText(movie, "title", "This title")
    genre = movieText(movie, "genre", "premium entertainment")
    return title + " is ready to watch from this playlist, with artwork and playback metadata flowing through the same provider-ready detail model used by the library."
end function

sub addMoviesNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
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

sub addMoviesProfileItem()
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

    label = "Search movies"
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

sub drawMoviePills(row as Integer)
    cats = [
        { label: "All", x: 244, y: 106, w: 100, h: 34 },
        { label: "Action", x: 356, y: 106, w: 100, h: 34 },
        { label: "Horror", x: 468, y: 106, w: 100, h: 34 },
        { label: "Comedy", x: 580, y: 106, w: 140, h: 34 },
        { label: "Animation", x: 732, y: 106, w: 140, h: 34 },
        { label: "Sci-Fi", x: 884, y: 106, w: 100, h: 34 }
    ]

    for i = 0 to cats.count() - 1
        cat = cats[i]
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

sub drawFeatured(movie as Object, row as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    titleColor = m.colors.textGreen
    subColor = m.colors.textDim
    labelColor = "0xFFFFFFFF"
    buttonUri = "pkg:/images/ui/movie_watch_140x40_panel_greenFocus.png"
    buttonText = "0xFFFFFFFF"
    if focused then
        buttonUri = "pkg:/images/ui/movie_watch_140x40_greenSoft_greenFocus.png"
        buttonText = "0xFFFFFFFF"
    end if

    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_770x184_panel_whiteSoft.png", 244, 206, 770, 184)
    if focused then
        uiPoster(m.canvas, "pkg:/images/ui/movie_featured_770x184_panel_greenFocus.png", 244, 206, 770, 184)
    end if
    drawFeaturedPoster(movie, 278, 227, 92, 142)
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", 404, 226, 100, 34)
    uiLabel(m.canvas, "Featured", 404, 230, 100, 24, 12, labelColor, "center")
    title = movieText(movie, "title", "Untitled")
    meta = movieText(movie, "year") + " - " + movieText(movie, "duration") + " - " + movieText(movie, "genre")
    uiLabel(m.canvas, title, 404, 258, 300, 30, 20, titleColor)
    uiLabel(m.canvas, meta, 404, 290, 430, 24, 13, subColor)
    uiPoster(m.canvas, buttonUri, 404, 324, 140, 40)
    uiLabel(m.canvas, "Watch now", 414, 329, 120, 28, 12, buttonText, "center")

    m.focusItems.push({
        x: 404, y: 324, w: 140, h: 40,
        icon: "", label: title, subtitle: "Featured",
        iconSize: 1, titleSize: 1, subSize: 1,
        bg: m.colors.panel, border: m.colors.whiteSoft, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 3, col: 1, page: "", action: "watch", mode: "manual"
    })
end sub

sub drawMovieCard(movie as Object, mediaIndex as Integer, sourceIndex as Integer, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if m.focusArea = "movies" then
        focused = mediaIndex = m.selectedMovieIndex
        if focused then m.focusIndex = itemIndex
    end if
    titleColor = m.colors.text
    metaColor = m.colors.textDim
    if focused then
        titleColor = m.colors.textGreen
    end if
    title = movieText(movie, "title", "Untitled")
    meta = movieText(movie, "genre") + " - " + movieText(movie, "duration")

    uiRect(m.canvas, x, y, w, h, m.colors.panel, 0.96)
    if focused then uiRect(m.canvas, x, y, w, h, m.colors.greenSoft, 0.24)
    drawMoviePoster(movie, x, y, w, 136)
    uiRect(m.canvas, x + 12, y + 136, w - 24, 1, "0xFFFFFF12", 0.72)
    uiLabel(m.canvas, title, x + 14, y + 143, w - 28, 22, 10, titleColor)
    uiLabel(m.canvas, meta, x + 14, y + 167, w - 28, 20, 7, metaColor)
    drawMovieCardBorder(x, y, w, h, focused)

    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        icon: "", label: title, subtitle: movieText(movie, "genre"),
        iconSize: 14, titleSize: 13, subSize: 9,
        bg: m.colors.panel, border: "0xFFFFFF12", textColor: titleColor, subColor: metaColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "movie", mediaIndex: mediaIndex, sourceIndex: sourceIndex, mode: "manual"
    })
end sub

sub drawMoviePoster(movie as Object, x as Integer, y as Integer, w as Integer, h as Integer)
    posterUrl = movieText(movie, "posterUrl")
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
        iconY = y + Int((h - iconH) / 2) - 6
        uiPoster(m.canvas, "pkg:/images/icons/movie_cards.png", iconX, iconY, iconW, iconH)
        uiLabel(m.canvas, movieText(movie, "year"), x + 16, y + h - 24, w - 32, 18, 8, m.colors.textMuted, "center")
    end if
end sub

sub drawMovieCardBorder(x as Integer, y as Integer, w as Integer, h as Integer, focused as Boolean)
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

sub drawFeaturedPoster(movie as Object, x as Integer, y as Integer, w as Integer, h as Integer)
    posterUrl = movieText(movie, "posterUrl")
    if posterUrl <> "" then
        poster = uiPoster(m.canvas, posterUrl, x - 4, y - 4, w + 8, h + 8)
        poster.loadDisplayMode = "scaleToZoom"
        uiPoster(m.canvas, "pkg:/images/demo/frames/featured_poster_corner_mask.png", x - 4, y - 4, w + 8, h + 8)
        uiPoster(m.canvas, "pkg:/images/demo/frames/featured_poster_frame_neutral.png", x - 4, y - 4, w + 8, h + 8)
    else
        uiRoundRect(m.canvas, x, y, w, h, m.colors.purpleSoft, m.colors.greenFocus)
        uiPoster(m.canvas, "pkg:/images/icons/movie_featured.png", x + 15, y + 28, 44, 44)
        uiLabel(m.canvas, movie.year, x + 8, y + 86, w - 16, 20, 8, m.colors.textMuted, "center")
    end if
end sub

sub drawSelectedBackdrop(visible as Object)
    movie = selectedMovieForBackdrop(visible)
    if movie = invalid then return

    bgUrl = movieBackdropUrl(movie)
    if bgUrl <> "" then
        backdrop = uiPoster(m.canvas, bgUrl, 226, 86, 1054, 634, 0.36)
        backdrop.loadDisplayMode = "scaleToZoom"
    end if
    posterUrl = movieText(movie, "posterUrl")
    if posterUrl <> "" and not movieBackdropIsComposed(bgUrl) then drawMovieBackdropPosterAnchor(posterUrl, 226, 86, 1054, 634)
    uiRect(m.canvas, 226, 86, 1054, 634, m.colors.bg, 0.58)
end sub

sub drawMovieBackdropPosterAnchor(posterUrl as String, x as Integer, y as Integer, w as Integer, h as Integer)
    posterH = Int(h * 0.76)
    posterW = Int(posterH * 2 / 3)
    posterX = x + w - posterW - 48
    posterY = y + Int((h - posterH) / 2)

    uiRect(m.canvas, posterX + 16, posterY + 20, posterW, posterH, "0x000000FF", 0.36)
    poster = uiPoster(m.canvas, posterUrl, posterX, posterY, posterW, posterH, 0.92)
    poster.loadDisplayMode = "scaleToFit"
    uiRectBorder(m.canvas, posterX, posterY, posterW, posterH, "0xFFFFFF28", 1, 0.86)
end sub

function movieBackdropIsComposed(url as String) as Boolean
    if url = invalid or url = "" then return false
    return Instr(1, LCase(url), "/movie_backdrops/") > 0
end function

function movieCardUrl(movie as Object) as String
    posterUrl = movieText(movie, "posterUrl")
    if posterUrl <> "" then return posterUrl
    cardUrl = movieText(movie, "cardUrl")
    if cardUrl <> "" then return cardUrl
    return ""
end function

function movieBackdropUrl(movie as Object) as String
    backdropUrl = movieText(movie, "backdropUrl")
    if backdropUrl <> "" then return backdropUrl
    cardUrl = movieText(movie, "cardUrl")
    if cardUrl <> "" then return cardUrl
    posterUrl = movieText(movie, "posterUrl")
    if posterUrl <> "" then return posterUrl
    return ""
end function

function movieText(movie as Dynamic, key as String, fallback = "" as String) as String
    value = movieValue(movie, key)
    if value = invalid then return fallback
    valueType = type(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return value.toStr()
    return fallback
end function

function movieFlag(movie as Dynamic, key as String) as Boolean
    value = movieValue(movie, key)
    if value = invalid then return false
    return value = true
end function

function movieValue(movie as Dynamic, key as String) as Dynamic
    if movie = invalid then return invalid
    if movie.doesExist(key) then return movie[key]
    lowerKey = LCase(key)
    if lowerKey <> key and movie.doesExist(lowerKey) then return movie[lowerKey]
    return invalid
end function

function selectedMovieForBackdrop(visible as Object) as Dynamic
    if visible.count() > 0 and m.focusArea = "movies" then
        if m.selectedMovieIndex >= 0 and m.selectedMovieIndex < visible.count() then return visible[m.selectedMovieIndex].movie
    end if
    return featuredMovie(visible)
end function

function featuredMovie(visible = invalid as Dynamic) as Object
    if m.movies.count() = 0 then return {
        title: "Featured Movie",
        year: "",
        duration: "",
        genre: "",
        rating: "",
        posterUrl: "",
        backdropUrl: "",
        streamUrl: demoPlaybackUrl(),
        streamFormat: "hls",
        resumePercent: 0,
        accent: "purple"
    }
    if m.featuredMovieIndex >= 0 and m.featuredMovieIndex < m.movies.count() then return m.movies[m.featuredMovieIndex]
    for i = 0 to m.movies.count() - 1
        movie = m.movies[i]
        if movieFlag(movie, "featured") then return movie
    end for
    return m.movies[0]
end function

sub drawMovieScrollbar(total as Integer, x as Integer, y as Integer, h as Integer)
    if total <= m.movieWindowSize then return
    uiVerticalPill(m.canvas, x, y, 4, h, "0xFFFFFF18", "pkg:/images/ui/scroll_cap_4_whiteLine.png", 0.56)
    maxStart = total - m.movieWindowSize
    if maxStart < 1 then maxStart = 1
    thumbH = Int(h * m.movieWindowSize / total)
    if thumbH < 42 then thumbH = 42
    if thumbH > h then thumbH = h
    thumbY = y
    if h > thumbH then thumbY = y + Int((h - thumbH) * m.movieWindowStart / maxStart)
    uiVerticalPill(m.canvas, x - 1, thumbY, 6, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.92)
end sub

function filteredMovies() as Object
    res = []
    query = LCase(m.searchQuery)
    for i = 0 to m.movies.count() - 1
        movie = m.movies[i]
        searchable = LCase(movieText(movie, "title") + " " + movieText(movie, "genre") + " " + movieText(movie, "year") + " " + movieText(movie, "rating"))
        matchSearch = (query = "") or (Instr(1, searchable, query) > 0)
        matchGenre = (m.selectedGenre = "All") or (Instr(1, LCase(movieText(movie, "genre")), LCase(m.selectedGenre)) > 0)
        if matchSearch and matchGenre then
            res.push({ movie: movie, index: i })
        end if
    end for
    return res
end function

sub resetMovieWindow()
    m.movieWindowStart = 0
    m.selectedMovieIndex = 0
    m.focusArea = "normal"
end sub

sub normalizeMovieWindow(total as Integer)
    if total <= 0 then
        m.movieWindowStart = 0
        m.selectedMovieIndex = 0
        if m.focusArea = "movies" then m.focusArea = "normal"
        return
    end if
    if m.selectedMovieIndex < 0 then m.selectedMovieIndex = 0
    if m.selectedMovieIndex > total - 1 then m.selectedMovieIndex = total - 1
    if m.movieWindowStart < 0 then m.movieWindowStart = 0
    maxStart = total - m.movieWindowSize
    if maxStart < 0 then maxStart = 0
    if m.movieWindowStart > maxStart then m.movieWindowStart = maxStart
    if m.selectedMovieIndex < m.movieWindowStart then m.movieWindowStart = m.selectedMovieIndex
    if m.selectedMovieIndex >= m.movieWindowStart + m.movieWindowSize then
        m.movieWindowStart = m.selectedMovieIndex - m.movieWindowSize + 1
    end if
end sub

function routeMoviesFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    ensureMovieFocus()
    current = m.focusItems[m.focusIndex]
    action = ""
    if current.doesExist("action") then action = current.action
    if action <> "movie" then m.focusArea = "normal"

    if current.col = 0 then
        if dy <> 0 then
            nextSidebar = findMovieFocusByRowCol(current.row + dy, 0)
            if nextSidebar >= 0 then m.focusIndex = nextSidebar : return true
            return true
        end if
        if dx > 0 then
            if filteredMovies().count() = 0 then
                sIndex = findMovieFocusAction("search")
                if sIndex >= 0 then m.focusIndex = sIndex : return true
            end if
            pIndex = findMovieFocusByRowCol(1, 1)
            if pIndex >= 0 then m.focusIndex = pIndex : return true
            fIndex = findMovieFocusAction("watch")
            if fIndex >= 0 then m.focusIndex = fIndex : return true
            sIndex = findMovieFocusAction("search")
            if sIndex >= 0 then m.focusIndex = sIndex : return true
        end if
        return false
    end if

    if dx < 0 and action = "search" then
        navIndex = findMovieFocusByRowCol(3, 0)
        if navIndex >= 0 then m.focusIndex = navIndex : return true
    end if

    if action = "search" and dy > 0 then
        pIndex = findMovieFocusByRowCol(1, 1)
        if pIndex >= 0 then m.focusIndex = pIndex : return true
    end if

    if action = "genre" then
        if dx < 0 and current.col = 1 then
            navIndex = findMovieFocusByRowCol(3, 0)
            if navIndex >= 0 then m.focusIndex = navIndex : return true
        end if
        if dy < 0 then
            sIndex = findMovieFocusAction("search")
            if sIndex >= 0 then m.focusIndex = sIndex : return true
        end if
        if dy > 0 then
            fIndex = findMovieFocusAction("watch")
            if fIndex >= 0 then m.focusIndex = fIndex : return true
        end if
    end if

    if action = "watch" then
        if dx < 0 then
            navIndex = findMovieFocusByRowCol(3, 0)
            if navIndex >= 0 then m.focusIndex = navIndex : return true
        end if
        if dy < 0 then
            pIndex = findMovieFocusByRowCol(1, 1)
            if pIndex >= 0 then m.focusIndex = pIndex : return true
        end if
        if dy > 0 then
            mIndex = findMovieFocusByRowCol(8, 1)
            if mIndex < 0 then mIndex = findMovieFocusByRowCol(4, 1)
            if mIndex >= 0 then
                m.selectedMovieIndex = m.movieWindowStart
                m.focusArea = "movies"
                m.focusIndex = mIndex
                return true
            end if
        end if
    end if

    if action = "movie" then
        visible = filteredMovies()
        if current.doesExist("mediaIndex") then m.selectedMovieIndex = current.mediaIndex
        if dx < 0 and m.selectedMovieIndex > 0 then
            m.selectedMovieIndex -= 1
            m.focusArea = "movies"
            normalizeMovieWindow(visible.count())
            return true
        end if
        if dx < 0 then
            m.focusArea = "normal"
            navIndex = findMovieFocusByRowCol(3, 0)
            if navIndex >= 0 then m.focusIndex = navIndex
            return true
        end if
        if dx > 0 and m.selectedMovieIndex < visible.count() - 1 then
            m.selectedMovieIndex += 1
            m.focusArea = "movies"
            normalizeMovieWindow(visible.count())
            return true
        end if
        if dx > 0 then return true
        if dy < 0 then
            m.focusArea = "normal"
            fIndex = findMovieFocusAction("watch")
            if fIndex >= 0 then m.focusIndex = fIndex : return true
        end if
    end if

    return false
end function

sub ensureMovieFocus()
    if m.focusItems.count() = 0 then
        m.focusIndex = 0
        return
    end if
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then
        navIndex = findMovieFocusByRowCol(3, 0)
        if navIndex >= 0 then
            m.focusIndex = navIndex
        else
            m.focusIndex = 0
        end if
    end if
end sub

function findMovieFocusByRowCol(row as Integer, col as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.row = row and item.col = col then return i
    end for
    return -1
end function

function findMovieFocusAction(action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.action = action then return i
    end for
    return -1
end function

sub syncMovieFocus()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    action = ""
    if item.doesExist("action") then action = item.action
    if action = "movie" then
        if item.doesExist("mediaIndex") then m.selectedMovieIndex = item.mediaIndex
        m.focusArea = "movies"
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
    m.movieWindowStart = 0
    m.selectedMovieIndex = 0
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
    uiLabel(m.canvas, "Search Movies", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiRect(m.canvas, 330, 188, 620, 48, m.colors.bg2)
    searchText = m.searchQuery
    if searchText = "" then searchText = "Search movies"
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
