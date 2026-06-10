sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("seriesCanvas")
    m.focusItems = []
    m.focusIndex = 7 ' Start focus on "Series" side nav item
    m.selectedGenre = "All"
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    m.series = [
        { title: "Ozark", meta: "4 Seasons", genre: "Drama - Thriller", icon: "OZ" },
        { title: "Westworld", meta: "4 Seasons", genre: "Sci-Fi - Drama", icon: "AI" },
        { title: "The Crown", meta: "6 Seasons", genre: "Drama - History", icon: "CR" },
        { title: "Peaky Blinders", meta: "6 Seasons", genre: "Crime - Drama", icon: "PB" }
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
    if routeSeriesFocus(dx, dy) then render() : return
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
    
    row = drawSeriesSideNav()
    drawSearchBox()
    
    drawCategoryPills(row)

    uiLabel(m.canvas, "CONTINUE WATCHING", 244, 158, 300, 26, 13, m.colors.textDim)
    drawContinueCard(244, 198, 365, "Breaking Bad", "S3 - E7 - 22 min left", 70, 2, 1)
    drawContinueCard(640, 198, 365, "House of Dragon", "S2 - E3 - 44 min left", 30, 2, 2)
    
    uiLabel(m.canvas, "POPULAR SERIES", 244, 362, 250, 26, 13, m.colors.textDim)
    visible = filteredSeries()
    for i = 0 to visible.count() - 1
        rowData = visible[i]
        drawMediaCard(rowData.series, 244 + i * 228, 402, 214, 190, 3, i + 1)
    end for
    if visible.count() = 0 then
        uiLabel(m.canvas, "No series found", 244, 430, 746, 28, 15, m.colors.textDim, "center")
    end if

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

sub addSeriesNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
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

sub addSeriesProfileItem()
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
        { label: "All", x: 244, y: 106, w: 100, h: 40 },
        { label: "Drama", x: 356, y: 106, w: 100, h: 40 },
        { label: "Action", x: 468, y: 106, w: 100, h: 40 },
        { label: "Comedy", x: 580, y: 106, w: 140, h: 40 },
        { label: "Sci-Fi", x: 732, y: 106, w: 100, h: 40 },
        { label: "Thriller", x: 844, y: 106, w: 100, h: 40 }
    ]
    for i = 0 to categories.count() - 1
        cat = categories[i]
        catLabel = cat.label
        focused = (m.focusIndex = m.focusItems.count())
        selected = (catLabel = m.selectedGenre)
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
        uiLabel(m.canvas, catLabel, cat.x, cat.y + 2, cat.w, cat.h - 4, 13, textColor, "center")

        m.focusItems.push({
            x: cat.x, y: cat.y, w: cat.w, h: cat.h,
            icon: "", label: catLabel, subtitle: "",
            iconSize: 1, titleSize: 12, subSize: 10,
            bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
            focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
            row: 1, col: i + 1, page: "", action: "genre", mode: "manual"
        })
    end for
end sub

sub drawContinueCard(x as Integer, y as Integer, w as Integer, title as String, meta as String, progress as Integer, row as Integer, col as Integer)
    focused = (m.focusIndex = m.focusItems.count())
    bg = m.colors.panel
    border = "0xFFFFFF12"
    textColor = m.colors.text
    subColor = m.colors.textDim
    iconBg = m.colors.purpleSoft
    progFill = m.colors.green
    if focused then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
        progFill = m.colors.greenFocus
    end if

    uiRoundRect(m.canvas, x, y, w, 112, bg, border)
    uiRoundRect(m.canvas, x + 20, y + 26, 36, 36, iconBg, iconBg)
    uiDrawIcon(m.canvas, "play", x + 29, y + 35, 18, 18, focused, textColor, 10)
    uiLabel(m.canvas, title, x + 74, y + 18, w - 96, 24, 15, textColor)
    uiLabel(m.canvas, meta, x + 74, y + 46, w - 96, 20, 11, subColor)

    progBg = "0x7F77DD44"
    uiRect(m.canvas, x + 74, y + 82, w - 96, 4, progBg)
    uiRect(m.canvas, x + 74, y + 82, Int((w - 96) * progress / 100), 4, progFill)

    m.focusItems.push({
        x: x, y: y, w: w, h: 112,
        icon: "play", label: title, subtitle: meta,
        iconSize: 13, iconW: 36, iconH: 36, iconX: 20,
        labelX: 74, labelW: w - 96, labelAlign: "left",
        titleSize: 15, subSize: 11,
        bg: bg, border: border, textColor: textColor, subColor: subColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 2, col: col, page: "", action: "play", mode: "manual"
    })
end sub

sub drawMediaCard(media as Object, x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    focused = (m.focusIndex = m.focusItems.count())
    bg = m.colors.panel
    border = m.colors.purpleLine
    textColor = m.colors.text
    subColor = m.colors.textDim
    if focused then
        border = m.colors.greenFocus
    end if

    posterKey = "purpleSoft"
    if media.icon = "AI" or media.icon = "PB" then posterKey = "greenSoft"
    stateKey = "normal"
    if focused then stateKey = "focus"

    uiPoster(m.canvas, "pkg:/images/ui/series_card_tiny_" + posterKey + "_" + stateKey + ".png", x, y, w, h)
    iconX = x + Int((w - 40) / 2)
    badgeBg = m.colors.greenSoft
    seasonColor = m.colors.purpleLine
    if posterKey = "greenSoft" then
        badgeBg = m.colors.purpleSoft
        seasonColor = m.colors.green
    end if
    uiRoundRect(m.canvas, iconX, y + 30, 40, 40, badgeBg, badgeBg)
    uiDrawIcon(m.canvas, media.icon, iconX, y + 30, 40, 40, focused, m.colors.text, 12)
    uiLabel(m.canvas, media.title, x + 16, y + 112, w - 32, 24, 12, textColor)
    uiLabel(m.canvas, media.meta, x + 16, y + 138, w - 32, 20, 11, seasonColor)
    uiLabel(m.canvas, media.genre, x + 16, y + 160, w - 32, 22, 9, subColor)

    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        icon: media.icon, label: media.title, subtitle: media.meta + " - " + media.genre,
        iconSize: 17, iconW: 64, iconH: 64, iconX: Int((w - 64) / 2),
        titleSize: 14, subSize: 10,
        bg: bg, border: border, textColor: textColor, subColor: subColor,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 3, col: col, page: "", action: "series", mode: "manual"
    })
end sub

function filteredSeries() as Object
    res = []
    for i = 0 to m.series.count() - 1
        s = m.series[i]
        matchSearch = (m.searchQuery = "") or (Instr(1, LCase(s.title), LCase(m.searchQuery)) > 0)
        matchGenre = (m.selectedGenre = "All") or (Instr(1, LCase(s.genre), LCase(m.selectedGenre)) > 0)
        if matchSearch and matchGenre then
            res.push({ series: s, index: i })
        end if
    end for
    return res
end function

function routeSeriesFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    current = m.focusItems[m.focusIndex]
    action = ""
    if current.doesExist("action") then action = current.action

    if action = "search" then
        if dy > 0 then
            pIndex = findFocusByRowCol(1, 1)
            if pIndex >= 0 then m.focusIndex = pIndex : return true
        end if
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
            if cIndex >= 0 then m.focusIndex = cIndex : return true
        end if
    end if

    if action = "play" then
        if dy < 0 then
            col = current.col
            pIndex = findFocusByRowCol(1, col)
            if pIndex >= 0 then m.focusIndex = pIndex : return true
        end if
        if dy > 0 then
            col = current.col
            mIndex = findFocusByRowCol(3, col)
            if mIndex >= 0 then m.focusIndex = mIndex : return true
        end if
    end if

    if action = "series" then
        if dy < 0 then
            col = current.col
            targetCol = 1
            if col > 2 then targetCol = 2
            cIndex = findFocusByRowCol(2, targetCol)
            if cIndex >= 0 then m.focusIndex = cIndex : return true
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
        w = keyW
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
        uiRect(m.canvas, x, y, w, keyH, bg)
        uiRect(m.canvas, x, y, w, 2, border)
        uiRect(m.canvas, x, y + keyH - 2, w, 2, border)
        uiRect(m.canvas, x, y, 2, keyH, border)
        uiRect(m.canvas, x + w - 2, y, 2, keyH, border)
        uiLabel(m.canvas, keyLabel, x, y + 5, w, 28, 14, text, "center")
    end for
end sub
