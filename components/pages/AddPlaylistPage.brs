sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("addPlaylistCanvas")
    m.mode = "m3u"
    m.added = false
    m.editing = false
    m.editField = ""
    m.editLabel = ""
    m.keyboardIndex = 0
    m.keyboardKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "SPACE", "DEL", "DONE"]
    m.inputs = {
        playlistTitle: "",
        m3uUrl: "",
        accountName: "",
        serverUrl: "",
        username: "",
        password: ""
    }
    m.focusItems = []
    m.focusIndex = 6
    render()
end sub

sub refreshClock()
    if m.clock <> invalid then
        now = uiNowStrings()
        m.clock.text = now.time
        m.date.text = now.date
    end if
end sub

function handleKey(key as String) as Boolean
    if m.editing then return handleKeyboardKey(key)
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

sub activate()
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "m3u" or item.action = "xtreme" then m.mode = item.action : render() : return
    if item.action = "field" then openKeyboard(item.fieldKey, item.fieldLabel) : return
    if item.action = "submit" then
        playlistStoreAdd(m.inputs, m.mode)
        m.added = true
        m.top.navigateTo = "MyPlaylistsPage"
        return
    end if
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = drawAddPlaylistSideNav()

    uiLabel(m.canvas, "Add New Playlist", 380, 108, 760, 56, 36, m.colors.text, "center")
    addSmallButton(505, 198, 230, 48, "", "M3U Playlist", row, 1, "m3u")
    addSmallButton(765, 198, 230, 48, "", "Xtreme Account", row, 2, "xtreme")

    if m.mode = "m3u" then
        addInputField(380, 292, 760, "Playlist Title", "playlistTitle", row + 1, 1, false)
        addInputField(380, 398, 760, "M3U URL", "m3uUrl", row + 2, 1, false)
        addWideAction(530, 510, 460, 56, "plus", "Add Playlist", row + 3, 1)
    else
        addInputField(380, 250, 760, "Account Name", "accountName", row + 1, 1, false)
        addInputField(380, 334, 760, "Server URL", "serverUrl", row + 2, 1, false)
        addInputField(380, 418, 760, "Username", "username", row + 3, 1, false)
        addInputField(380, 502, 760, "Password", "password", row + 4, 1, true)
        addWideAction(530, 602, 460, 56, "link", "Connect Account", row + 5, 1)
    end if

    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.editing then drawKeyboardOverlay()
end sub

function drawAddPlaylistSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addAddNavItem(12, 112, "list", "My Playlists", "MyPlaylistsPage", 0, false)
    addAddNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addAddNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addAddNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addAddNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)

    addAddProfileItem()
    return 6
end function

sub addAddNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
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
        item.border = m.colors.purpleLine
        item.textColor = m.colors.text
    end if
    m.focusItems.push(item)
end sub

sub addAddProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: "0xFFFFFF10", border: m.colors.panel, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.purpleSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 5, col: 0, page: "ProfilePage", mode: "row"
    }
    m.focusItems.push(item)
end sub

sub addInputField(x as Integer, y as Integer, w as Integer, label as String, fieldKey as String, row as Integer, col as Integer, secure as Boolean)
    uiLabel(m.canvas, label, x, y, w, 24, 13, m.colors.textGreen)
    value = m.inputs[fieldKey]
    displayValue = value
    if secure and value <> "" then displayValue = maskText(value)
    item = {
        x: x, y: y + 30, w: w, h: 48,
        icon: "", label: displayValue, subtitle: "",
        iconSize: 0, titleSize: 16, subSize: 10,
        bg: m.colors.panel, border: m.colors.panel, textColor: m.colors.text,
        subColor: m.colors.textDim, focusBg: m.colors.panel, focusBorder: m.colors.purpleLine,
        focusTextColor: m.colors.text, row: row, col: col, action: "field",
        fieldKey: fieldKey, fieldLabel: label, page: "", mode: "row",
        labelX: 24, labelW: w - 48, labelAlign: "left", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub addSmallButton(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer, action as String)
    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 14, titleSize: 15, subSize: 10, bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text, row: row, col: col, action: action, page: "", mode: "row", noFocusShift: true }
    m.focusItems.push(item)
end sub

sub addWideAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer)
    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 15, iconW: 22, iconH: 22, iconX: 124, labelX: 0, labelW: w, labelAlign: "center", titleSize: 17, subSize: 10, bg: m.colors.purpleActive, border: m.colors.purpleActive, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text, row: row, col: col, action: "submit", page: "", mode: "row", noFocusShift: true }
    m.focusItems.push(item)
end sub

function maskText(value as String) as String
    out = ""
    for i = 1 to value.len()
        out += "*"
    end for
    return out
end function

sub openKeyboard(fieldKey as String, fieldLabel as String)
    m.editing = true
    m.editField = fieldKey
    m.editLabel = fieldLabel
    m.keyboardIndex = 0
    render()
end sub

function handleKeyboardKey(key as String) as Boolean
    cols = 10
    keyCount = m.keyboardKeys.count()
    if key = "left" and m.keyboardIndex > 0 then m.keyboardIndex -= 1 : render() : return true
    if key = "right" and m.keyboardIndex < keyCount - 1 then m.keyboardIndex += 1 : render() : return true
    if key = "up" and m.keyboardIndex - cols >= 0 then m.keyboardIndex -= cols : render() : return true
    if key = "down" and m.keyboardIndex + cols < keyCount then m.keyboardIndex += cols : render() : return true
    if key = "back" then closeKeyboard() : return true
    if key = "OK" then pressKeyboardKey() : return true
    return true
end function

sub pressKeyboardKey()
    selected = m.keyboardKeys[m.keyboardIndex]
    current = m.inputs[m.editField]
    if selected = "DONE" then
        closeKeyboard()
        return
    end if
    if selected = "DEL" then
        if current.len() > 0 then current = current.left(current.len() - 1)
    else if selected = "SPACE" then
        current += " "
    else
        current += selected
    end if
    m.inputs[m.editField] = current
    render()
end sub

sub closeKeyboard()
    m.editing = false
    m.editField = ""
    m.editLabel = ""
    render()
end sub

sub drawKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiRect(m.canvas, 260, 116, 760, 488, m.colors.panel, 0.98)
    uiLabel(m.canvas, m.editLabel, 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiRect(m.canvas, 330, 188, 620, 48, m.colors.bg2)
    uiLabel(m.canvas, m.inputs[m.editField], 350, 196, 580, 32, 17, m.colors.text, "left")

    keyW = 56
    keyH = 42
    gap = 8
    startX = 324
    startY = 268
    for i = 0 to m.keyboardKeys.count() - 1
        row = Int(i / 10)
        col = i mod 10
        x = startX + col * (keyW + gap)
        y = startY + row * (keyH + gap)
        keyLabel = m.keyboardKeys[i]
        w = keyW
        if keyLabel = "SPACE" then keyLabel = "Space"
        if keyLabel = "DEL" then keyLabel = "Del"
        if keyLabel = "DONE" then keyLabel = "Done"
        bg = m.colors.bg
        border = m.colors.whiteLine
        text = m.colors.text
        if i = m.keyboardIndex then
            bg = m.colors.purpleSoft
            border = m.colors.purpleLine
        end if
        uiRect(m.canvas, x, y, w, keyH, bg)
        uiRect(m.canvas, x, y, w, 2, border)
        uiRect(m.canvas, x, y + keyH - 2, w, 2, border)
        uiRect(m.canvas, x, y, 2, keyH, border)
        uiRect(m.canvas, x + w - 2, y, 2, keyH, border)
        uiLabel(m.canvas, keyLabel, x, y + 5, w, 28, 14, text, "center")
    end for
end sub
