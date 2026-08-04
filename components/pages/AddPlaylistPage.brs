sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("addPlaylistCanvas")
    m.mode = "m3u"
    m.added = false
    m.editing = false
    m.editField = ""
    m.editLabel = ""
    m.errorMessage = ""
    m.errorField = ""
    m.submitState = ""
    m.backendTask = invalid
    m.editPlaylistId = ""
    m.showPlaylistTypeButtons = true
    m.showXtremeControls = true
    m.phoneLinkActive = false
    m.keyboardIndex = 0
    m.keyboardUpper = true
    m.previousFocusIndex = -1
    m.keyboardKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", "/", ":", "-", "_", "@", "CASE", "SPACE", "DEL", "CLEAR", "DONE"]
    m.inputs = {
        playlistTitle: "",
        m3uUrl: "",
        accountName: "",
        serverUrl: "",
        username: "",
        password: ""
    }
    loadPendingPlaylistEdit()
    m.focusItems = []
    m.focusIndex = 6

    m.submitTimer = CreateObject("roSGNode", "Timer")
    m.submitTimer.repeat = false
    m.submitTimer.duration = 0.6
    m.submitTimer.observeField("fire", "finishPlaylistSubmit")
    render()
end sub

sub loadPendingPlaylistEdit()
    editId = playlistStoreTakePendingEditId()
    if editId = "" then return
    item = playlistStoreGet(editId)
    if item = invalid or playlistStoreBool(item, "isProtected", false) then return

    m.editPlaylistId = editId
    if playlistStoreText(item, "type") = "Xtreme" and m.showXtremeControls then
        m.mode = "xtreme"
        m.inputs.accountName = playlistStoreText(item, "title")
        m.inputs.serverUrl = playlistStoreText(item, "serverUrl")
        m.inputs.username = playlistStoreText(item, "username")
        m.inputs.password = playlistStoreText(item, "password")
    else
        m.mode = "m3u"
        m.inputs.playlistTitle = playlistStoreText(item, "title")
        m.inputs.m3uUrl = playlistStoreText(item, "sourceUrl")
    end if
end sub

sub refreshClock()
    if m.clock <> invalid then
        now = uiNowStrings()
        m.clock.text = now.time
        m.date.text = now.date
    end if
end sub

function handleKey(key as String) as Boolean
    if m.submitState = "validating" then return true
    if m.editing then return handleKeyboardKey(key)
    if key = "back" then
        m.top.navigateTo = addPlaylistBackTarget()
        return true
    end if
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

function addPlaylistBackTarget() as String
    if m.editPlaylistId <> "" then return "ManagePlaylistsPage"
    if m.top <> invalid and m.top.hasField("returnPage") then
        target = m.top.returnPage
        if target <> invalid and target <> "" and target <> "AddPlaylistPage" then return target
    end if
    return "MyPlaylistsPage"
end function

sub move(dx as Integer, dy as Integer)
    if dx > 0 and focusPhoneLinkFromLeft() then
        render()
        return
    end if
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

function focusPhoneLinkFromLeft() as Boolean
    if m.editPlaylistId <> "" or m.phoneLinkActive then return false
    if m.focusItems.count() = 0 then return false
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return false
    current = m.focusItems[m.focusIndex]
    if current = invalid or current.col = invalid or current.col <= 0 then return false
    if current.action = "phoneLink" then return false
    if current.action = "m3u" then return false

    for i = 0 to m.focusItems.count() - 1
        candidate = m.focusItems[i]
        if candidate <> invalid and candidate.action = "phoneLink" then
            m.focusIndex = i
            return true
        end if
    end for
    return false
end function

sub activate()
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "m3u" or item.action = "xtreme" then
        if item.action = "xtreme" and not m.showXtremeControls then return
        if m.editPlaylistId = "" then m.mode = item.action
        render()
        return
    end if
    if item.action = "field" then openKeyboard(item.fieldKey, item.fieldLabel) : return
    if item.action = "phoneLink" then
        m.phoneLinkActive = true
        render()
        return
    end if
    if item.action = "submit" then
        errorText = validatePlaylistInput()
        if errorText <> "" then
            render()
            return
        end if
        normalizePlaylistInputForSave()
        m.submitState = "validating"
        render()
        m.submitTimer.control = "stop"
        m.submitTimer.control = "start"
        return
    end if
end sub

sub finishPlaylistSubmit()
    savedPlaylist = invalid
    if m.editPlaylistId <> "" then
        savedPlaylist = playlistStoreUpdate(m.editPlaylistId, m.inputs, m.mode)
    else
        startBackendPlaylistCreate()
        return
    end if

    m.submitState = ""
    if savedPlaylist = invalid then
        if m.mode = "m3u" then
            setFieldError("m3uUrl", "Playlist details could not be saved.")
        else
            setFieldError("serverUrl", "Account details could not be saved.")
        end if
        render()
        return
    end if

    m.added = true
    m.errorMessage = ""
    m.errorField = ""
    if m.editPlaylistId = "" then onboardingCompleteWithPlaylist()
    if m.editPlaylistId <> "" then
        m.top.navigateTo = "ManagePlaylistsPage"
    else
        m.top.navigateTo = "MyPlaylistsPage"
    end if
end sub

sub startBackendPlaylistCreate()
    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.submitState = ""
        if m.mode = "xtreme" then
            setFieldError("serverUrl", "Playlist service is unavailable.")
        else
            setFieldError("m3uUrl", "Playlist service is unavailable.")
        end if
        render()
        return
    end if

    task.observeField("response", "onBackendPlaylistCreated")
    if m.mode = "xtreme" then
        task.request = backendApiCreateXtremePlaylistRequest(m.inputs.accountName, m.inputs.serverUrl, m.inputs.username, m.inputs.password)
    else
        task.request = backendApiCreatePlaylistRequest(m.inputs.playlistTitle, m.inputs.m3uUrl)
    end if
    m.backendTask = task
    task.control = "RUN"
end sub

sub onBackendPlaylistCreated()
    if m.backendTask = invalid then return
    response = m.backendTask.response
    m.backendTask = invalid
    m.submitState = ""

    if not backendApiResponseOk(response) then
        if m.mode = "xtreme" then
            setFieldError("serverUrl", "Account could not be connected.")
        else
            setFieldError("m3uUrl", "Playlist could not be added.")
        end if
        render()
        return
    end if

    apiPlaylist = backendApiResponsePlaylist(response)
    importJob = backendApiResponseImportJob(response)
    savedPlaylist = playlistStoreUpsertBackendPlaylist(apiPlaylist, importJob)
    if savedPlaylist = invalid then
        if m.mode = "xtreme" then
            setFieldError("serverUrl", "Account was connected, but could not be saved.")
        else
            setFieldError("m3uUrl", "Playlist was added, but could not be saved.")
        end if
        render()
        return
    end if

    playlistStoreSetActive(playlistStoreText(savedPlaylist, "id"))
    m.added = true
    m.errorMessage = ""
    m.errorField = ""
    onboardingCompleteWithPlaylist()
    m.top.navigateTo = "MyPlaylistsPage"
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    drawAddPlaylistArtwork()
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    row = drawAddPlaylistSideNav()

    pageTitle = "ADD PLAYLIST"
    if m.editPlaylistId <> "" then pageTitle = "EDIT M3U PLAYLIST"
    titleX = 292
    titleW = 520
    titleAlign = "center"
    if m.editPlaylistId <> "" then
        titleX = 380
        titleW = 760
    end if
    uiScaledLabel(m.canvas, pageTitle, titleX, 112, titleW, 52, 31, m.colors.text, titleAlign, 1.12)

    if m.editPlaylistId <> "" then
        drawEditPlaylistForm(row)
    else
        drawAddPlaylistSplitForm(row)
    end if

    if m.focusIndex >= m.focusItems.count() then m.focusIndex = m.focusItems.count() - 1
    if m.focusIndex < 0 then m.focusIndex = 0
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.editing then drawKeyboardOverlay()
    if m.submitState = "validating" then drawValidationOverlay()
    m.previousFocusIndex = m.focusIndex
end sub

sub drawAddPlaylistArtwork()
    backdrop = uiPoster(m.canvas, "pkg:/images/add_playlist/add_playlist_background_v4.png", 0, 0, 1280, 720, 0.48)
    backdrop.loadDisplayMode = "scaleToFill"
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.5)
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.16)
    uiRect(m.canvas, 334, 92, 850, 604, m.colors.bg, 0.08)
end sub

sub drawAddPlaylistSplitForm(row as Integer)
    if m.showPlaylistTypeButtons then
        addSmallButton(331, 188, 204, 42, "", "M3U Playlist", row, 1, "m3u")
        if m.showXtremeControls then addSmallButton(569, 188, 204, 42, "", "Xtreme Account", row, 2, "xtreme")
    end if

    if m.mode = "m3u" then
        addInputField(292, 276, 520, "Playlist Title", "playlistTitle", row + 1, 1, false)
        addInputField(292, 384, 520, "M3U URL", "m3uUrl", row + 2, 1, false)
        addWideAction(362, 520, 380, 56, "plus", "Add Playlist", row + 3, 1)
    else
        addInputField(292, 252, 520, "Account Name", "accountName", row + 1, 1, false)
        addInputField(292, 336, 520, "Server URL", "serverUrl", row + 2, 1, false)
        addInputField(292, 420, 520, "Username", "username", row + 3, 1, false)
        addInputField(292, 504, 520, "Password", "password", row + 4, 1, true)
        addWideAction(362, 608, 380, 56, "link", "Connect Account", row + 5, 1)
    end if

    drawPhoneLinkPanel(896, 222, 284, 284, row + 3)
end sub

sub drawEditPlaylistForm(row as Integer)
    uiScaledLabel(m.canvas, "Update the saved playlist details.", 380, 166, 760, 28, 15, m.colors.textMuted, "center", 0.92)

    if m.showPlaylistTypeButtons then
        addSmallButton(505, 218, 230, 48, "", "M3U Playlist", row, 1, "m3u")
        if m.showXtremeControls then addSmallButton(765, 218, 230, 48, "", "Xtreme Account", row, 2, "xtreme")
    end if

    if m.mode = "m3u" then
        addInputField(380, 306, 760, "Playlist Title", "playlistTitle", row + 1, 1, false)
        addInputField(380, 414, 760, "M3U URL", "m3uUrl", row + 2, 1, false)
        addWideAction(530, 562, 460, 56, "plus", "Save Changes", row + 3, 1)
    else
        addInputField(380, 250, 760, "Account Name", "accountName", row + 1, 1, false)
        addInputField(380, 334, 760, "Server URL", "serverUrl", row + 2, 1, false)
        addInputField(380, 418, 760, "Username", "username", row + 3, 1, false)
        addInputField(380, 502, 760, "Password", "password", row + 4, 1, true)
        addWideAction(530, 602, 460, 56, "link", "Save Changes", row + 5, 1)
    end if
end sub

sub drawPhoneLinkPanel(x as Integer, y as Integer, w as Integer, h as Integer, row as Integer)
    uiRect(m.canvas, x, y, w, h, m.colors.panel, 0.34)
    uiRectBorder(m.canvas, x, y, w, h, m.colors.whiteLine, 1, 0.38)
    uiRect(m.canvas, x + 8, y + 8, w - 16, h - 16, m.colors.purpleSoft, 0.20)

    qrSize = 236
    qrX = x + Int((w - qrSize) / 2)
    qrY = y + Int((h - qrSize) / 2)
    drawMockQr(m.canvas, qrX, qrY, qrSize, m.phoneLinkActive)

    if not m.phoneLinkActive then
        uiRect(m.canvas, qrX, qrY, qrSize, qrSize, m.colors.bg, 0.20)
        addPhoneLinkAction(x + 39, y + 121, 206, 42, row, 2)
    end if
end sub

sub drawMockQr(parent as Object, x as Integer, y as Integer, size as Integer, active as Boolean)
    bgOpacity = 0.92
    cellOpacity = 0.76
    if not active then
        bgOpacity = 0.34
        cellOpacity = 0.18
    end if
    uiRect(parent, x, y, size, size, "0xF7F9FFFF", bgOpacity)
    cell = Int(size / 13)
    dark = m.colors.bg
    drawQrFinder(parent, x + cell, y + cell, cell, cellOpacity)
    drawQrFinder(parent, x + (cell * 8), y + cell, cell, cellOpacity)
    drawQrFinder(parent, x + cell, y + (cell * 8), cell, cellOpacity)

    for r = 0 to 12
        for c = 0 to 12
            if ((r * 3 + c * 5 + r * c) MOD 7) = 0 then
                skipFinder = (r < 5 and c < 5) or (r < 5 and c > 7) or (r > 7 and c < 5)
                if not skipFinder then uiRect(parent, x + (c * cell), y + (r * cell), cell - 2, cell - 2, dark, cellOpacity)
            end if
        end for
    end for
    uiRectBorder(parent, x, y, size, size, m.colors.textPurple, 2, cellOpacity)
end sub

sub drawQrFinder(parent as Object, x as Integer, y as Integer, cell as Integer, opacity as Float)
    dark = m.colors.bg
    uiRect(parent, x, y, cell * 4, cell * 4, dark, opacity)
    uiRect(parent, x + cell, y + cell, cell * 2, cell * 2, "0xF7F9FFFF", opacity)
    uiRect(parent, x + cell + 4, y + cell + 4, (cell * 2) - 8, (cell * 2) - 8, dark, opacity)
end sub

sub addPhoneLinkAction(x as Integer, y as Integer, w as Integer, h as Integer, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    buttonCanvas = CreateObject("roSGNode", "Group")
    buttonCanvas.id = "addPlaylistPhoneLinkButton" + itemIndex.toStr()
    buttonCanvas.translation = [x, y]
    m.canvas.appendChild(buttonCanvas)

    uiPoster(buttonCanvas, "pkg:/images/ui/add_playlist_tab_base_230x48.png", 0, 0, w, h, 0.82)
    if focused then
        focusOpacity = 0.86
        if m.previousFocusIndex <> itemIndex then focusOpacity = 0.0
        focusSurface = uiPoster(buttonCanvas, "pkg:/images/ui/add_playlist_tab_focus_230x48.png", 0, 0, w, h, focusOpacity)
        focusSurface.id = "addPlaylistPhoneLinkFocus" + itemIndex.toStr()
        if m.previousFocusIndex <> itemIndex then animateAddPlaylistButtonFocus(m.canvas, buttonCanvas, focusSurface, x, y, 0.86)
    end if
    textColor = m.colors.textPurple
    if focused then textColor = m.colors.text
    uiLabel(buttonCanvas, "Link with phone", 0, 1, w, h, 14, textColor, "center")

    item = { x: x, y: y, w: w, h: h, icon: "link", label: "Link with phone", subtitle: "", iconSize: 15, titleSize: 17, subSize: 10, bg: m.colors.greenSoft, border: m.colors.greenFocus, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.greenFocus, focusBorder: m.colors.text, focusTextColor: m.colors.text, row: row, col: col, action: "phoneLink", page: "", mode: "manual", noFocusShift: true }
    m.focusItems.push(item)
end sub

sub drawValidationOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.72)
    uiPoster(m.canvas, "pkg:/images/ui/rr_500x158_panel_purpleLine.png", 410, 302, 540, 92, 0.98)
    heading = "Adding playlist"
    if m.editPlaylistId <> "" then heading = "Saving changes"
    if m.mode = "xtreme" then heading = "Connecting account"
    uiLabel(m.canvas, heading, 450, 332, 460, 32, 20, m.colors.text, "center")
end sub

function drawAddPlaylistSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addAddNavItem(12, 112, "home", "Home", "HomePage", 0, false)
    addAddNavItem(12, 171, "tv", "Live TV", "LiveTvPage", 1, false)
    addAddNavItem(12, 230, "series", "Series", "SeriesPage", 2, false)
    addAddNavItem(12, 289, "movies", "Movies", "MoviesPage", 3, false)
    addAddNavItem(12, 348, "settings", "Settings", "SettingsPage", 4, false)

    addAddProfileItem()
    return 6
end function

sub addAddNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: row, col: 0, page: page, mode: "row", pillStyle: "sidebar", noFocusShift: true
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
        item.opacity = 0.58
    end if
    m.focusItems.push(item)
end sub

sub addAddProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: 5, col: 0, page: "ProfilePage", mode: "row", pillStyle: "sidebar", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub addInputField(x as Integer, y as Integer, w as Integer, label as String, fieldKey as String, row as Integer, col as Integer, secure as Boolean)
    uiLabel(m.canvas, label, x, y, w, 24, 13, m.colors.textGreen)
    value = m.inputs[fieldKey]
    displayValue = value
    fieldH = 48
    useCompactField = w = 520
    if useCompactField then fieldH = 42
    textColor = m.colors.text
    borderColor = m.colors.panel
    focusBorder = m.colors.purpleLine
    if secure and value <> "" then displayValue = maskText(value)
    if m.errorField = fieldKey and m.errorMessage <> "" then
        displayValue = m.errorMessage
        textColor = "0xFFB2A8FF"
        borderColor = "0xFFB2A8FF"
        focusBorder = "0xFFB2A8FF"
    end if
    item = {
        x: x, y: y + 30, w: w, h: fieldH,
        icon: "", label: displayValue, subtitle: "",
        iconSize: 0, titleSize: 16, subSize: 10,
        bg: m.colors.panel, border: borderColor, textColor: textColor,
        subColor: m.colors.textDim, focusBg: m.colors.panel, focusBorder: focusBorder,
        focusTextColor: textColor, row: row, col: col, action: "field",
        fieldKey: fieldKey, fieldLabel: label, page: "", mode: "row",
        labelX: 24, labelW: w - 48, labelAlign: "left", noFocusShift: true
    }
    if useCompactField then
        item.bg = m.colors.panel
        item.border = m.colors.panel
        item.focusBg = m.colors.panel
        item.focusBorder = m.colors.purpleLine
        item.artUri = "pkg:/images/ui/add_playlist_input_520x42_base.png"
        item.artFocusUri = "pkg:/images/ui/add_playlist_input_520x42_focus.png"
        if m.errorField = fieldKey and m.errorMessage <> "" then
            item.artUri = "pkg:/images/ui/add_playlist_input_520x42_error.png"
            item.artFocusUri = "pkg:/images/ui/add_playlist_input_520x42_error.png"
        end if
    end if
    m.focusItems.push(item)
end sub

sub addSmallButton(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer, action as String)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    selected = action = m.mode
    textColor = m.colors.textPurple
    opacity = 0.54
    if selected then
        textColor = m.colors.text
        opacity = 0.78
    end if
    if focused then
        textColor = m.colors.text
        opacity = 0.86
    end if

    buttonCanvas = CreateObject("roSGNode", "Group")
    buttonCanvas.id = "addPlaylistModeButton" + itemIndex.toStr()
    buttonCanvas.translation = [x, y]
    m.canvas.appendChild(buttonCanvas)

    if h <= 34 then
        baseUri = "pkg:/images/ui/feedback_category_156x34_base.png"
        if selected then baseUri = "pkg:/images/ui/feedback_category_156x34_selected.png"
        uiPoster(buttonCanvas, baseUri, 0, 0, w, h, opacity)
        if focused then
            focusOpacity = 0.86
            if m.previousFocusIndex <> itemIndex then focusOpacity = 0.0
            focusSurface = uiPoster(buttonCanvas, "pkg:/images/ui/feedback_category_156x34_focus.png", 0, 0, w, h, focusOpacity)
            focusSurface.id = "addPlaylistModeButtonFocus" + itemIndex.toStr()
            if m.previousFocusIndex <> itemIndex then animateAddPlaylistButtonFocus(m.canvas, buttonCanvas, focusSurface, x, y, 0.86)
        end if
        uiScaledLabel(buttonCanvas, label, 8, 0, w - 16, h, 12, textColor, "center", 0.70)
    else
        uiPoster(buttonCanvas, "pkg:/images/ui/add_playlist_tab_base_230x48.png", 0, 0, w, h, 0.38)
        if selected and not focused then
            uiPoster(buttonCanvas, "pkg:/images/ui/add_playlist_tab_focus_230x48.png", 0, 0, w, h, 0.48)
        end if
        if focused then
            focusOpacity = 0.70
            if m.previousFocusIndex <> itemIndex then focusOpacity = 0.0
            focusSurface = uiPoster(buttonCanvas, "pkg:/images/ui/add_playlist_tab_focus_230x48.png", 0, 0, w, h, focusOpacity)
            focusSurface.id = "addPlaylistModeButtonFocus" + itemIndex.toStr()
            if m.previousFocusIndex <> itemIndex then animateAddPlaylistButtonFocus(m.canvas, buttonCanvas, focusSurface, x, y, 0.70)
        end if
        uiLabel(buttonCanvas, label, 0, 1, w, h, 15, textColor, "center")
    end if

    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 14, titleSize: 15, subSize: 10, bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text, row: row, col: col, action: action, page: "", mode: "manual", noFocusShift: true }
    m.focusItems.push(item)
end sub

sub addWideAction(x as Integer, y as Integer, w as Integer, h as Integer, icon as String, label as String, row as Integer, col as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex

    buttonCanvas = CreateObject("roSGNode", "Group")
    buttonCanvas.id = "addPlaylistSubmitButton" + itemIndex.toStr()
    buttonCanvas.translation = [x, y]
    m.canvas.appendChild(buttonCanvas)
    baseUri = "pkg:/images/ui/add_playlist_submit_base_460x56.png"
    focusUri = "pkg:/images/ui/add_playlist_submit_focus_460x56.png"
    if w = 380 and h = 56 then
        baseUri = "pkg:/images/ui/add_playlist_submit_380x56_base.png"
        focusUri = "pkg:/images/ui/add_playlist_submit_380x56_focus.png"
    end if
    uiPoster(buttonCanvas, baseUri, 0, 0, w, h, 0.80)
    if focused then
        focusOpacity = 0.82
        if m.previousFocusIndex <> itemIndex then focusOpacity = 0.0
        focusSurface = uiPoster(buttonCanvas, focusUri, 0, 0, w, h, focusOpacity)
        focusSurface.id = "addPlaylistSubmitButtonFocus" + itemIndex.toStr()
        if m.previousFocusIndex <> itemIndex then animateAddPlaylistButtonFocus(m.canvas, buttonCanvas, focusSurface, x, y, 0.82)
    end if
    labelW = Int(label.len() * 12)
    if labelW > w - 120 then labelW = w - 120
    if icon <> "" then
        contentW = labelW + 34
        iconX = Int((w - contentW) / 2)
        labelX = iconX + 34
        uiDrawIcon(buttonCanvas, icon, iconX, 17, 22, 22, focused, m.colors.text, 15)
        uiLabel(buttonCanvas, label, labelX, 1, labelW, h, 17, m.colors.text, "left")
    else
        uiLabel(buttonCanvas, label, 0, 1, w, h, 17, m.colors.text, "center")
    end if
    item = { x: x, y: y, w: w, h: h, icon: icon, label: label, subtitle: "", iconSize: 15, iconW: 22, iconH: 22, iconX: 124, labelX: 0, labelW: w, labelAlign: "center", titleSize: 17, subSize: 10, bg: m.colors.purpleActive, border: m.colors.purpleActive, textColor: m.colors.text, subColor: m.colors.textDim, focusBg: m.colors.purpleSoft, focusBorder: m.colors.purpleLine, focusTextColor: m.colors.text, row: row, col: col, action: "submit", page: "", mode: "manual", noFocusShift: true }
    m.focusItems.push(item)
end sub

sub animateAddPlaylistButtonFocus(parent as Object, buttonCanvas as Object, focusSurface as Object, x as Integer, y as Integer, finalOpacity as Float)
    animation = CreateObject("roSGNode", "Animation")
    animation.duration = 0.16
    animation.easeFunction = "outQuad"

    opacityAnimation = animation.createChild("FloatFieldInterpolator")
    opacityAnimation.key = [0.0, 1.0]
    opacityAnimation.keyValue = [0.0, finalOpacity]
    opacityAnimation.fieldToInterp = focusSurface.id + ".opacity"

    parent.appendChild(animation)
    animation.control = "start"
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
    m.errorMessage = ""
    m.errorField = ""
    m.keyboardIndex = 0
    render()
end sub

function handleKeyboardKey(key as String) as Boolean
    cols = 10
    if key = "back" then closeKeyboard() : return true
    nextIndex = uiKeyboardMoveIndex(m.keyboardKeys, m.keyboardIndex, key, cols)
    if nextIndex <> m.keyboardIndex then m.keyboardIndex = nextIndex : render() : return true
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
    if selected = "CASE" then
        m.keyboardUpper = not m.keyboardUpper
        render()
        return
    end if
    if selected = "CLEAR" then
        current = ""
    else if selected = "DEL" then
        if current.len() > 0 then current = current.left(current.len() - 1)
    else if selected = "SPACE" then
        current += " "
    else
        current += keyboardInputValue(selected)
    end if
    m.inputs[m.editField] = current
    render()
end sub

function validatePlaylistInput() as String
    m.errorMessage = ""
    m.errorField = ""
    if m.mode = "xtreme" then
        title = cleanInput(m.inputs.accountName)
        if title = "" then return setFieldError("accountName", "Account name is required.")
        if cleanInput(m.inputs.serverUrl) = "" then return setFieldError("serverUrl", "Server URL is required.")
        if not isValidHttpUrl(m.inputs.serverUrl) then return setFieldError("serverUrl", "Enter a valid URL like http://example.com.")
        if cleanInput(m.inputs.username) = "" then return setFieldError("username", "Username is required.")
        if cleanInput(m.inputs.password) = "" then return setFieldError("password", "Password is required.")
    else
        title = cleanInput(m.inputs.playlistTitle)
        if title = "" then return setFieldError("playlistTitle", "Playlist title is required.")
        if cleanInput(m.inputs.m3uUrl) = "" then return setFieldError("m3uUrl", "M3U URL is required.")
        if not isValidHttpUrl(m.inputs.m3uUrl) then return setFieldError("m3uUrl", "Enter a valid M3U URL.")
    end if

    if playlistStoreTitleExistsExcept(title, m.editPlaylistId) then
        if m.mode = "xtreme" then return setFieldError("accountName", "Playlist name already exists.")
        return setFieldError("playlistTitle", "Playlist name already exists.")
    end if
    return ""
end function

function setFieldError(fieldKey as String, message as String) as String
    m.errorField = fieldKey
    m.errorMessage = message
    return message
end function

sub normalizePlaylistInputForSave()
    m.inputs.playlistTitle = cleanInput(m.inputs.playlistTitle)
    m.inputs.m3uUrl = cleanInput(m.inputs.m3uUrl)
    m.inputs.accountName = cleanInput(m.inputs.accountName)
    m.inputs.serverUrl = cleanInput(m.inputs.serverUrl)
    m.inputs.username = cleanInput(m.inputs.username)
    m.inputs.password = cleanInput(m.inputs.password)
end sub

function cleanInput(value as Dynamic) as String
    if value = invalid then return ""
    if type(value) <> "String" and type(value) <> "roString" then return ""
    text = value
    while text.len() > 0 and Left(text, 1) = " "
        text = Right(text, text.len() - 1)
    end while
    while text.len() > 0 and Right(text, 1) = " "
        text = Left(text, text.len() - 1)
    end while
    return text
end function

function isValidHttpUrl(value as Dynamic) as Boolean
    text = LCase(cleanInput(value))
    if text.len() < 8 then return false
    if Instr(1, text, " ") > 0 then return false

    hostAndPath = ""
    if Left(text, 7) = "http://" then
        hostAndPath = Right(text, text.len() - 7)
    else if Left(text, 8) = "https://" then
        hostAndPath = Right(text, text.len() - 8)
    else
        return false
    end if

    if hostAndPath = "" then return false
    slashPos = Instr(1, hostAndPath, "/")
    host = hostAndPath
    if slashPos > 0 then host = Left(hostAndPath, slashPos - 1)
    if host = "" then return false
    if Instr(1, host, ".") = 0 then return false
    if Left(host, 1) = "." or Right(host, 1) = "." then return false
    if Instr(1, host, "..") > 0 then return false
    if Instr(1, host, ":") > 0 then
        colonPos = Instr(1, host, ":")
        hostName = Left(host, colonPos - 1)
        portText = Right(host, host.len() - colonPos)
        if hostName = "" or portText = "" then return false
        host = hostName
    end if
    if host.len() < 4 then return false
    return true
end function

sub closeKeyboard()
    m.editing = false
    m.editField = ""
    m.editLabel = ""
    render()
end sub

function keyboardInputValue(keyLabel as String) as String
    if not m.keyboardUpper and isKeyboardLetter(keyLabel) then return LCase(keyLabel)
    return keyLabel
end function

function keyboardDisplayLabel(keyLabel as String) as String
    if keyLabel = "SPACE" then return "Space"
    if keyLabel = "DEL" then return "Del"
    if keyLabel = "DONE" then return "Done"
    if keyLabel = "CASE" then
        if m.keyboardUpper then return "abc"
        return "ABC"
    end if
    return keyboardInputValue(keyLabel)
end function

function isKeyboardLetter(keyLabel as String) as Boolean
    if keyLabel.len() <> 1 then return false
    return Instr(1, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", keyLabel) > 0
end function

sub drawKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.92)
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", 220, 104, 840, 524, 0.98)
    uiLabel(m.canvas, m.editLabel, 300, 142, 680, 32, 20, m.colors.textGreen, "center")
    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", 300, 188, 680, 48, 0.90)
    uiLabel(m.canvas, m.inputs[m.editField], 324, 196, 632, 32, 17, m.colors.text, "left")

    keyW = 68
    keyH = 40
    gap = 7
    startX = 268
    startY = 268
    for i = 0 to m.keyboardKeys.count() - 1
        keyLabel = m.keyboardKeys[i]
        keyRect = uiKeyboardKeyRect(m.keyboardKeys, i, startX, startY, keyW, keyH, gap)
        uiDrawKeyboardKey(m.canvas, keyLabel, keyboardDisplayLabel(keyLabel), keyRect.x, keyRect.y, keyRect.w, keyRect.h, i = m.keyboardIndex, m.colors)
    end for
end sub
