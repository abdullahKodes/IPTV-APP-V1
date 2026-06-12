sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("moviesCanvas")
    m.focusItems = []
    m.focusIndex = 7
    m.selectedGenre = "All"
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    m.movies = [
        { title: "Inception", meta: "Sci-Fi - 2h 28m", year: "2010", genre: "Sci-Fi - Thriller", icon: "IN", accent: "green" },
        { title: "The Dark Knight", meta: "Action - 2h 32m", year: "2008", genre: "Action - Crime", icon: "DK", accent: "purple" },
        { title: "Get Out", meta: "Horror - 1h 44m", year: "2017", genre: "Horror - Mystery", icon: "GO", accent: "green" },
        { title: "Dune Part 2", meta: "Sci-Fi - 2h 46m", year: "2024", genre: "Sci-Fi - Adventure", icon: "D2", accent: "purple" },
        { title: "Inside Out 2", meta: "Animation - 1h 36m", year: "2024", genre: "Animation - Family", icon: "IO", accent: "green" },
        { title: "The Fall Guy", meta: "Comedy - 2h 06m", year: "2024", genre: "Action - Comedy", icon: "FG", accent: "purple" }
    ]
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
    render()
end sub

sub activate()
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "search" then openSearchKeyboard() : return
    if item.action = "genre" then m.selectedGenre = item.label : render() : return
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    row = drawMoviesSideNav()
    drawSearchBox()
    drawMoviePills(row)

    uiLabel(m.canvas, "FEATURED MOVIE", 244, 166, 250, 26, 13, m.colors.textDim)
    drawFeatured(row + 1)

    sectionLabel = "ALL MOVIES"
    if m.selectedGenre <> "All" then sectionLabel = m.selectedGenre + " movies"
    uiLabel(m.canvas, sectionLabel, 244, 404, 250, 26, 13, m.colors.textDim)
    visible = filteredMovies()
    renderCount = visible.count()
    if renderCount > 4 then renderCount = 4
    if renderCount > 0 then
        for i = 0 to renderCount - 1
            rowData = visible[i]
            drawMovieCard(rowData.movie, 244 + i * 212, 444, 200, 190, 4, i + 1)
        end for
    end if
    if visible.count() = 0 then
        uiLabel(m.canvas, "No movies found", 244, 478, 746, 28, 15, m.colors.textDim, "center")
    end if

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

sub addMoviesNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: m.colors.textGreen, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: 0, page: page, mode: "row"
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
        row: 5, col: 0, page: "SettingsPage", mode: "row"
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

sub drawFeatured(row as Integer)
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
    uiPoster(m.canvas, "pkg:/images/icons/movie_featured.png", 288, 250, 64, 64)
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", 390, 226, 100, 34)
    uiLabel(m.canvas, "Featured", 390, 230, 100, 24, 12, labelColor, "center")
    uiLabel(m.canvas, "Interstellar", 390, 258, 260, 30, 20, titleColor)
    uiLabel(m.canvas, "2014 - 2h 49m - Sci-Fi - Adventure", 390, 290, 380, 24, 13, subColor)
    uiPoster(m.canvas, buttonUri, 390, 324, 140, 40)
    uiLabel(m.canvas, "Watch now", 400, 329, 120, 28, 12, buttonText, "center")

    m.focusItems.push({
        x: 390, y: 324, w: 140, h: 40,
        icon: "", label: "Interstellar", subtitle: "Featured",
        iconSize: 1, titleSize: 1, subSize: 1,
        bg: m.colors.panel, border: m.colors.whiteSoft, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 3, col: 1, page: "", action: "watch", mode: "manual"
    })
end sub

sub drawMovieCard(movie as Object, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    cardKey = "purple"
    titleColor = m.colors.textGreen
    metaColor = m.colors.textPurple
    if movie.accent = "green" then cardKey = "green"
    stateKey = "normal"
    if focused then
        stateKey = "focus"
        metaColor = m.colors.textGreen
    end if

    uiPoster(m.canvas, "pkg:/images/ui/series_card_poster_" + cardKey + "_" + stateKey + ".png", x, y, w, h)
    iconW = 36
    iconH = 36
    iconX = x + Int((w - iconW) / 2)
    iconY = y + 36
    uiPoster(m.canvas, "pkg:/images/icons/movie_cards.png", iconX, iconY, iconW, iconH)
    uiLabel(m.canvas, movie.title, x + 16, y + 126, w - 32, 26, 12, titleColor)
    uiLabel(m.canvas, movie.meta, x + 16, y + 154, w - 32, 22, 9, metaColor)

    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        icon: movie.icon, label: movie.title, subtitle: movie.meta,
        iconSize: 14, titleSize: 13, subSize: 9,
        bg: m.colors.panel, border: "0xFFFFFF12", textColor: titleColor, subColor: metaColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "movie", mode: "manual"
    })
end sub

function filteredMovies() as Object
    res = []
    query = LCase(m.searchQuery)
    for i = 0 to m.movies.count() - 1
        movie = m.movies[i]
        searchable = LCase(movie.title + " " + movie.genre + " " + movie.year)
        matchSearch = (query = "") or (Instr(1, searchable, query) > 0)
        matchGenre = (m.selectedGenre = "All") or (Instr(1, LCase(movie.genre), LCase(m.selectedGenre)) > 0)
        if matchSearch and matchGenre then
            res.push({ movie: movie, index: i })
        end if
    end for
    return res
end function

function routeMoviesFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    current = m.focusItems[m.focusIndex]
    action = ""
    if current.doesExist("action") then action = current.action

    if action = "search" and dy > 0 then
        pIndex = findMovieFocusByRowCol(1, 1)
        if pIndex >= 0 then m.focusIndex = pIndex : return true
    end if

    if action = "genre" then
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
        if dy < 0 then
            pIndex = findMovieFocusByRowCol(1, 1)
            if pIndex >= 0 then m.focusIndex = pIndex : return true
        end if
        if dy > 0 then
            mIndex = findMovieFocusByRowCol(8, 1)
            if mIndex < 0 then mIndex = findMovieFocusByRowCol(4, 1)
            if mIndex >= 0 then m.focusIndex = mIndex : return true
        end if
    end if

    if action = "movie" and dy < 0 then
        fIndex = findMovieFocusAction("watch")
        if fIndex >= 0 then m.focusIndex = fIndex : return true
    end if

    return false
end function

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
        current += " "
    else
        current += selected
    end if
    m.searchQuery = current
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
