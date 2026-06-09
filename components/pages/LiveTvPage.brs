sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("liveTvCanvas")
    m.video = m.top.findNode("livePlayerVideo")
    m.overlay = m.top.findNode("liveTvOverlay")
    m.focusItems = []
    m.focusIndex = 1
    m.categoryIndex = 0
    m.channelIndex = 0
    m.playing = true
    m.fullscreen = false
    m.searchQuery = ""
    m.searchEditing = false
    m.searchKeyboardIndex = 0
    m.searchKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "CLEAR", "DONE"]
    demoUrl = "https://roku.s.cpl.delvenetworks.com/media/59021fabe3b645968e382ac726cd6c7b/60b4a471ffb74809beb2f7d5a15b3193/roku_ep_111_segment_1_final-cc_mix_033015-a7ec8a288c4bcec001c118181c668de321108861.m3u8"
    m.channels = [
        { name: "ESPN HD", now: "Premier League Live", icon: "sport", live: true, videoUrl: demoUrl },
        { name: "BBC World", now: "Evening News", icon: "NW", live: false, videoUrl: demoUrl },
        { name: "CNN Intl", now: "Breaking News", icon: "CNN", live: false, videoUrl: demoUrl },
        { name: "beIN Sports", now: "La Liga Live", icon: "sport", live: true, videoUrl: demoUrl },
        { name: "MTV Hits", now: "Top 40 Charts", icon: "MTV", live: false, videoUrl: demoUrl },
        { name: "Cartoon Net.", now: "Kids Shows", icon: "KD", live: false, videoUrl: demoUrl }
    ]
    setupVideo()
    render()
end sub

sub refreshClock()
    if m.clock <> invalid then now = uiNowStrings() : m.clock.text = now.time : m.date.text = now.date
end sub

function handleKey(key as String) as Boolean
    if m.searchEditing then return handleSearchKeyboardKey(key)
    if m.fullscreen and key = "back" then m.fullscreen = false : render() : return true
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    if routeLiveFocus(dx, dy) then render() : return
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

function routeLiveFocus(dx as Integer, dy as Integer) as Boolean
    if m.focusItems.count() = 0 then return false
    current = m.focusItems[m.focusIndex]
    searchIndex = findFocusAction("search")
    if searchIndex < 0 then return false
    action = ""
    if current.doesExist("action") then action = current.action

    if dy < 0 and (action = "cat" or action = "playerControl") then
        m.focusIndex = searchIndex
        return true
    end if
    if dx > 0 and action = "cat" and (current.label = "News" or current.label = "Music") then
        m.focusIndex = searchIndex
        return true
    end if
    if action = "search" and dy > 0 then
        categoryIndex = findCategoryFocus(m.categoryIndex)
        if categoryIndex >= 0 then m.focusIndex = categoryIndex : return true
    end if
    if action = "search" and dx < 0 then
        categoryIndex = findCategoryFocus(2)
        if categoryIndex >= 0 then m.focusIndex = categoryIndex : return true
    end if
    return false
end function

function findFocusAction(action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        if m.focusItems[i].action = action then return i
    end for
    return -1
end function

function findCategoryFocus(catIndex as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.action = "cat" and item.catIndex = catIndex then return i
    end for
    return -1
end function

sub activate()
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page
    if item.action = "cat" then m.categoryIndex = item.catIndex : render() : return
    if item.action = "channel" then m.channelIndex = item.channelIndex : playSelectedChannel() : render() : return
    if item.action = "playerControl" then handlePlayerControl(item.control) : render() : return
    if item.action = "search" then openSearchKeyboard() : return
end sub

sub render()
    uiClear(m.canvas)
    if m.overlay <> invalid then uiClear(m.overlay)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = drawLiveSideNav()

    drawSearchBox()
    uiRect(m.canvas, 534, 86, 1, 634, "0xFFFFFF12")
    channelRow = drawCategoryPills(row)
    drawChannelDivider()
    visible = filteredChannels()
    for i = 0 to visible.count() - 1
        rowData = visible[i]
        drawChannel(rowData.channel, rowData.index, 244, 250 + i * 60, channelRow + i, 1)
    end for
    if visible.count() = 0 then
        uiLabel(m.canvas, "No channels found", 244, 262, 276, 28, 15, m.colors.textDim, "center")
    end if
    drawPlayer()
    updateVideoLayout()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.searchEditing then drawSearchKeyboardOverlay()
end sub

sub setupVideo()
    if m.video = invalid then return
    m.video.enableUI = false
    m.video.loop = true
    m.video.observeField("state", "onVideoStateChange")
    m.video.observeField("errorMsg", "onVideoError")
    playSelectedChannel()
end sub

sub playSelectedChannel()
    if m.video = invalid then return
    channel = m.channels[m.channelIndex]
    content = CreateObject("roSGNode", "ContentNode")
    content.url = channel.videoUrl
    content.streamformat = "hls"
    content.title = channel.name
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    m.video.content = content
    m.playing = true
    m.video.control = "play"
end sub

sub onVideoStateChange()
    if m.video <> invalid then print "Live TV video state: "; m.video.state
end sub

sub onVideoError()
    if m.video <> invalid then print "Live TV video error: "; m.video.errorMsg
end sub

sub handlePlayerControl(control as String)
    if control = "favorite" then return
    if control = "volume" then return
    if control = "restart" then seekPlayer(0, true) : return
    if control = "rewind" then seekPlayer(-15, false) : return
    if control = "playpause" then togglePlayback() : return
    if control = "forward" then seekPlayer(15, false) : return
    if control = "fullscreen" then m.fullscreen = not m.fullscreen : return
end sub

sub togglePlayback()
    if m.video = invalid then return
    if m.playing then
        m.video.control = "pause"
        m.playing = false
    else
        m.video.control = "resume"
        m.playing = true
    end if
end sub

sub seekPlayer(offset as Integer, absolute as Boolean)
    if m.video = invalid then return
    target = 0
    if not absolute then
        target = m.video.position + offset
        if target < 0 then target = 0
    end if
    m.video.seek = target
end sub

sub updateVideoLayout()
    if m.video = invalid then return
    if m.searchEditing then
        m.video.visible = false
        if m.overlay <> invalid then m.overlay.visible = false
        return
    end if
    if m.fullscreen then
        m.video.translation = [0, 0]
        m.video.width = 1280
        m.video.height = 720
        if m.overlay <> invalid then m.overlay.visible = false
    else
        m.video.translation = [592, 220]
        m.video.width = 552
        m.video.height = 190
        if m.overlay <> invalid then m.overlay.visible = true
    end if
    m.video.visible = true
end sub

function drawLiveSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    liveActive = (m.focusIndex = 1) or (m.focusIndex > 5)
    addLiveNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addLiveNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, liveActive)
    addLiveNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addLiveNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addLiveNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)

    addLiveProfileItem()
    return 6
end function

sub addLiveNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
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

sub addLiveProfileItem()
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
    label = "Search channels"
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
        row: 6, col: 5, page: "", action: "search", mode: "manual"
    })
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
    uiLabel(m.canvas, "Search channels", 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiRect(m.canvas, 330, 188, 620, 48, m.colors.bg2)
    searchText = m.searchQuery
    if searchText = "" then searchText = "Search channels"
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

function filteredChannels() as Object
    results = []
    query = LCase(m.searchQuery)
    for i = 0 to m.channels.count() - 1
        ch = m.channels[i]
        searchable = LCase(ch.name + " " + ch.now)
        if query = "" or Instr(1, searchable, query) > 0 then
            results.push({ channel: ch, index: i })
        end if
    end for
    return results
end function

function drawCategoryPills(row as Integer) as Integer
    cats = [
        { label: "All", x: 244, y: 106, w: 62, row: row, col: 1 },
        { label: "Sports", x: 316, y: 106, w: 82, row: row, col: 2 },
        { label: "News", x: 244, y: 150, w: 76, row: row + 1, col: 1 },
        { label: "Kids", x: 330, y: 150, w: 70, row: row + 1, col: 2 },
        { label: "Music", x: 244, y: 194, w: 82, row: row + 2, col: 1 }
    ]
    for i = 0 to cats.count() - 1
        cat = cats[i]
        itemIndex = m.focusItems.count()
        focused = itemIndex = m.focusIndex
        selected = i = m.categoryIndex
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
        uiRoundRect(m.canvas, cat.x, cat.y, cat.w, 34, bg, border)
        uiLabel(m.canvas, cat.label, cat.x, cat.y + 1, cat.w, 30, 12, textColor, "center")
        item = {
            x: cat.x, y: cat.y, w: cat.w, h: 34,
            icon: "", label: cat.label, subtitle: "",
            iconSize: 1, titleSize: 12, subSize: 10,
            bg: bg, border: border, textColor: textColor, subColor: m.colors.textDim,
            focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text,
            row: cat.row, col: cat.col, page: "", action: "cat", catIndex: i, mode: "manual"
        }
        m.focusItems.push(item)
    end for
    return row + 3
end function

sub drawChannelDivider()
    uiRect(m.canvas, 244, 238, 276, 1, "0xFFFFFF18")
    uiRect(m.canvas, 244, 238, 72, 1, m.colors.greenFocus, 0.72)
end sub

sub drawChannel(ch as Object, channelIndex as Integer, x as Integer, y as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    selected = channelIndex = m.channelIndex
    w = 276
    h = 54
    bg = m.colors.panel
    border = m.colors.whiteLine
    iconBg = m.colors.purpleSoft
    titleColor = m.colors.text
    subColor = m.colors.textMuted
    if ch.live then iconBg = m.colors.greenSoft
    if selected then
        bg = m.colors.purpleSoft
        border = m.colors.greenFocus
        iconBg = m.colors.greenSoft
        subColor = m.colors.text
    end if
    if focused then
        bg = m.colors.greenSoft
        border = m.colors.greenFocus
        iconBg = m.colors.greenSoft
        subColor = m.colors.text
    end if

    textW = 200
    if ch.live then textW = 146

    uiRoundRect(m.canvas, x, y, w, h, bg, border)
    uiRoundRect(m.canvas, x + 12, y + 10, 34, 34, iconBg, iconBg)
    uiDrawIcon(m.canvas, ch.icon, x + 21, y + 19, 16, 16, focused, titleColor, 8)
    uiLabel(m.canvas, ch.name, x + 58, y + 6, textW, 18, 6, titleColor)
    uiLabel(m.canvas, ch.now, x + 58, y + 29, textW, 16, 5, subColor)
    if ch.live then
        drawLiveBadge(x + 212, y + 16)
    end if

    item = {
        x: x, y: y, w: w, h: h,
        icon: ch.icon, label: ch.name, subtitle: ch.now,
        iconSize: 8, iconW: 34, iconH: 34, iconX: 12,
        labelX: 58, labelW: textW, labelAlign: "left",
        titleSize: 6, subSize: 5,
        bg: bg, border: border, textColor: titleColor, subColor: subColor,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "channel", channelIndex: channelIndex, mode: "manual"
    }
    m.focusItems.push(item)
end sub

sub drawLiveBadge(x as Integer, y as Integer)
    uiRoundRect(m.canvas, x, y, 58, 22, "0x993C1DFF", "0x993C1DFF")
    uiLabel(m.canvas, "LIVE", x, y + 1, 58, 18, 8, m.colors.text, "center")
end sub

sub drawPlayer()
    panelX = 568
    panelY = 108
    panelW = 600
    panelH = 390
    ch = m.channels[m.channelIndex]
    uiRoundRect(m.canvas, panelX, panelY, panelW, panelH, m.colors.purpleActive, m.colors.greenFocus)

    if ch.live then drawLiveBadge(panelX + 24, panelY + 22)
    titleX = panelX + 24
    if ch.live then titleX = panelX + 94
    uiLabel(m.canvas, ch.name, titleX, panelY + 18, 170, 24, 13, m.colors.text)
    uiLabel(m.canvas, ch.now, panelX + 24, panelY + 50, 380, 26, 14, m.colors.text)
    addPlayerControl(panelX + panelW - 76, panelY + 28, 50, "player_heart", "Favorite", "favorite", 8, 8, 22)

    uiRoundRect(m.canvas, panelX + 24, panelY + 112, panelW - 48, 190, m.colors.black, m.colors.black)
    addPlayerControl(panelX + 268, panelY + 176, 64, "player_play", "Play", "playpause", 10, 5, 64, m.overlay)
    if ch.live then drawLiveBadge(panelX + 38, panelY + 274)
    uiLabel(m.canvas, "22:15 / LIVE", panelX + panelW - 164, panelY + 274, 126, 22, 10, m.colors.textDim, "right")

    drawPlayerControls(panelX + 24, panelY + 320)
    uiRect(m.canvas, panelX + 76, panelY + 337, 340, 3, "0xFFFFFF18")
    uiRect(m.canvas, panelX + 76, panelY + 337, 226, 3, m.colors.greenFocus, 0.72)

    uiLabel(m.canvas, "UP NEXT ON " + ch.name, panelX, 526, 300, 22, 10, m.colors.textDim)
    drawEpg("21:00", "NFL Highlights", 568)
    drawEpg("23:00", "SportsCenter", 764)
    drawEpg("01:00", "NBA Pre-game", 960)
end sub

sub drawPlayerControls(x as Integer, y as Integer)
    addPlayerControl(x, y, 42, "player_volume", "Volume", "volume", 8, 3, 22)
    addPlayerControl(x + 430, y, 42, "player_replay", "Replay", "restart", 8, 6, 22)
    addPlayerControl(x + 494, y, 42, "player_full", "Full", "fullscreen", 8, 7, 22)
end sub

sub addPlayerControl(x as Integer, y as Integer, w as Integer, icon as String, label as String, control as String, row as Integer, col as Integer, iconSize = 18 as Integer, target = invalid as Object)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    if target = invalid then target = m.canvas
    textColor = m.colors.textMuted
    if focused then
        textColor = m.colors.text
    end if
    iconX = x + Int((w - iconSize) / 2)
    iconY = y + Int((36 - iconSize) / 2)
    if iconSize > 36 then iconY = y
    uiDrawIcon(target, icon, iconX, iconY, iconSize, iconSize, focused, textColor, 10)
    if focused and iconSize <= 36 then uiRect(target, x + Int((w - 28) / 2), y + 32, 28, 2, m.colors.greenFocus, 0.9)
    controlH = 36
    if iconSize > controlH then controlH = iconSize
    m.focusItems.push({
        x: x, y: y, w: w, h: controlH,
        icon: icon, label: label, subtitle: "",
        iconSize: 10, titleSize: 10, subSize: 10,
        bg: m.colors.bg, border: m.colors.bg, textColor: textColor, subColor: m.colors.textDim,
        focusBg: m.colors.bg, focusBorder: m.colors.bg, focusTextColor: m.colors.text,
        row: row, col: col, page: "", action: "playerControl", control: control, mode: "manual"
    })
end sub

sub drawEpg(time as String, title as String, x as Integer)
    uiRoundRect(m.canvas, x, 562, 190, 54, m.colors.panel, m.colors.whiteLine)
    uiLabel(m.canvas, time, x + 12, 566, 80, 18, 8, m.colors.greenFocus)
    uiLabel(m.canvas, title, x + 12, 590, 158, 20, 8, m.colors.text)
end sub

sub drawBorderRect(x as Integer, y as Integer, w as Integer, h as Integer, fill as String, border as String, opacity = 1.0 as Float)
    uiRect(m.canvas, x, y, w, h, fill, opacity)
    uiRect(m.canvas, x, y, w, 1, border, 0.72)
    uiRect(m.canvas, x, y + h - 1, w, 1, border, 0.72)
    uiRect(m.canvas, x, y, 1, h, border, 0.72)
    uiRect(m.canvas, x + w - 1, y, 1, h, border, 0.72)
end sub
