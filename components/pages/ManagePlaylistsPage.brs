sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("managePlaylistsCanvas")
    m.playlists = playlistStoreList()
    m.focusItems = []
    m.focusIndex = 0
    m.windowStart = 0
    m.windowSize = 6
    m.refreshDialog = invalid
    m.deleteDialog = invalid
    m.dropdownOpen = false
    m.dropdownOptions = ["Refresh", "Edit", "Delete"]
    m.dropdownIndex = 0
    m.dropdownX = 0
    m.dropdownY = 0
    m.dropdownPlaylistId = ""
    m.dropdownPlaylistTitle = ""
    m.dropdownProtected = false
    m.pendingId = ""
    m.pendingTitle = ""
    m.refreshingId = ""
    m.backendTask = invalid
    m.backendAction = ""
    m.backendActionPlaylistId = ""
    m.feedbackMessage = ""
    m.feedbackSuccess = true

    m.refreshTimer = CreateObject("roSGNode", "Timer")
    m.refreshTimer.repeat = false
    m.refreshTimer.duration = 0.7
    m.refreshTimer.observeField("fire", "finishPlaylistRefresh")
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
    if m.backendTask <> invalid then return true
    if m.refreshDialog <> invalid then
        if key = "back" then closeRefreshDialog() : return true
        return false
    end if
    if m.deleteDialog <> invalid then
        if key = "back" then closeDeleteDialog() : return true
        return false
    end if
    if m.dropdownOpen then return handleDropdownKey(key)
    if m.refreshingId <> "" then return true
    if key = "back" then m.top.navigateTo = "MyPlaylistsPage" : return true
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    if m.focusItems.count() = 0 then return
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then m.focusIndex = 0
    current = m.focusItems[m.focusIndex]

    if dy <> 0 and current.doesExist("playlistIndex") then
        targetPlaylist = current.playlistIndex + dy
        if targetPlaylist >= 0 and targetPlaylist < m.playlists.count() then
            targetAction = current.action
            if targetPlaylist < m.windowStart then m.windowStart = targetPlaylist
            if targetPlaylist >= m.windowStart + m.windowSize then m.windowStart = targetPlaylist - m.windowSize + 1
            render()
            target = findPlaylistActionFocus(targetPlaylist, targetAction)
            if target < 0 then target = findFirstPlaylistActionFocus(targetPlaylist)
            if target >= 0 then m.focusIndex = target
            render()
            return
        end if
        if dy < 0 then m.focusIndex = 0 : render() : return
    end if

    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

function handleDropdownKey(key as String) as Boolean
    if key = "back" then closeDropdown() : return true
    if key = "up" then
        if m.dropdownIndex > 0 then m.dropdownIndex -= 1
        render()
        return true
    end if
    if key = "down" then
        if m.dropdownIndex < m.dropdownOptions.count() - 1 then m.dropdownIndex += 1
        render()
        return true
    end if
    if key = "OK" then
        action = LCase(m.dropdownOptions[m.dropdownIndex])
        playlistId = m.dropdownPlaylistId
        playlistTitle = m.dropdownPlaylistTitle
        isLocked = m.dropdownProtected and action <> "refresh"
        closeDropdown()
        runPlaylistAction(action, playlistId, playlistTitle, isLocked)
        return true
    end if
    return true
end function

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.action = "actions" then
        openDropdown(item.playlistId, item.playlistTitle, item.playlistProtected, item.x, item.y + item.h + 4)
        return
    end if
    runPlaylistAction(item.action, item.playlistId, item.playlistTitle, item.locked)
end sub

sub runPlaylistAction(action as String, playlistId as String, playlistTitle as String, locked as Boolean)
    if locked then
        m.feedbackSuccess = false
        if action = "edit" then
            m.feedbackMessage = "Built-in playlists cannot be edited."
        else
            m.feedbackMessage = "Built-in playlists cannot be deleted."
        end if
        render()
        return
    end if
    if action = "edit" then
        playlistStoreSetPendingEdit(playlistId)
        m.top.navigateTo = "AddPlaylistPage"
        return
    end if
    if action = "refresh" then openRefreshConfirm(playlistId, playlistTitle) : return
    if action = "delete" then openDeleteConfirm(playlistId, playlistTitle)
end sub

sub openDropdown(playlistId as String, playlistTitle as String, isProtected as Boolean, x as Integer, y as Integer)
    m.dropdownOpen = true
    m.dropdownIndex = 0
    m.dropdownPlaylistId = playlistId
    m.dropdownPlaylistTitle = playlistTitle
    m.dropdownProtected = isProtected
    m.dropdownX = x
    m.dropdownY = y
    render()
end sub

sub closeDropdown()
    m.dropdownOpen = false
    m.dropdownIndex = 0
    m.dropdownPlaylistId = ""
    m.dropdownPlaylistTitle = ""
    m.dropdownProtected = false
    render()
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.canvas, 0, 86, 1280, 634, m.colors.bg, 0.96)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    uiLabel(m.canvas, "MANAGE PLAYLISTS", 130, 102, 520, 42, 24, m.colors.text)
    drawFeedback()
    drawPlaylistRows()
    drawScrollbar()
    if m.dropdownOpen then drawDropdown()
end sub

sub drawFeedback()
    if m.feedbackMessage = "" then return
    color = m.colors.textGreen
    if not m.feedbackSuccess then color = "0xFFB2A8FF"
    uiScaledLabel(m.canvas, m.feedbackMessage, 720, 140, 470, 24, 10, color, "right", 0.68)
end sub

sub drawPlaylistRows()
    if m.playlists.count() = 0 then
        uiLabel(m.canvas, "No playlists available.", 250, 320, 900, 36, 18, m.colors.textMuted, "center")
        return
    end if

    endIndex = m.windowStart + m.windowSize - 1
    if endIndex > m.playlists.count() - 1 then endIndex = m.playlists.count() - 1
    slot = 0
    for i = m.windowStart to endIndex
        drawPlaylistRow(m.playlists[i], i, slot)
        slot += 1
    end for
end sub

sub drawPlaylistRow(p as Object, playlistIndex as Integer, slot as Integer)
    x = 130
    y = 178 + slot * 70
    w = 1020
    h = 58
    active = playlistStoreText(p, "id") = playlistStoreActiveId()
    protected = playlistStoreBool(p, "isProtected", false)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex

    surfaceUri = "pkg:/images/ui/settings_row_590x50_bg2_bg2.png"
    textColor = m.colors.textPurple
    rowOpacity = 0.72
    if focused then
        surfaceUri = "pkg:/images/ui/settings_row_590x50_panelSoft_greenFocus.png"
        textColor = m.colors.text
        rowOpacity = 0.90
    end if
    uiPoster(m.canvas, surfaceUri, x, y, w, h, rowOpacity)

    actionX = x + w - 128
    badge = managePlaylistBadgeText(p, active, protected)
    badgeW = manageBadgeWidth(badge)
    badgeX = actionX - 22 - badgeW

    titleW = badgeX - x - 56
    if titleW < 420 then titleW = 420
    uiLabel(m.canvas, playlistStoreText(p, "title", "Playlist"), x + 24, y + 3, titleW, 30, 17, textColor)
    uiScaledLabel(m.canvas, managePlaylistSource(p), x + 25, y + 31, titleW, 22, 10, m.colors.textDim, "left", 0.66)

    drawManageBadge(badge, badgeX, y + 15, badgeW)
    drawManageSelect(actionX, y + 12, p, playlistIndex, protected)
end sub

function managePlaylistBadgeText(p as Object, active as Boolean, protected as Boolean) as String
    badge = playlistStoreText(p, "status", "Ready")
    if active then badge = "Active"
    if protected and not active then badge = "Protected"
    if playlistStoreText(p, "id") = m.refreshingId then badge = "Syncing"
    if badge = "Active" and not active then badge = "Ready"
    return badge
end function

function manageBadgeWidth(label as String) as Integer
    if label = "Ready" then return 68
    if label = "Active" then return 74
    if label = "Syncing" then return 94
    if label = "Protected" then return 94
    return 84
end function

sub drawManageBadge(label as String, x as Integer, y as Integer, w as Integer)
    uiPoster(m.canvas, "pkg:/images/ui/playlist_badge_" + w.toStr() + "x28.png", x, y, w, 28, 0.96)
    uiScaledLabel(m.canvas, label, x, y + 4, w, 20, 10, "0xFFFFFFFF", "center", 0.78)
end sub

sub drawManageSelect(x as Integer, y as Integer, p as Object, playlistIndex as Integer, isProtected as Boolean)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    w = 104
    h = 34
    textColor = m.colors.textPurple
    selectUri = "pkg:/images/ui/settings_select_104x34_bg2_whiteLine.png"
    chevronUri = "pkg:/images/ui/select_chevron_down.png"
    if focused then
        textColor = m.colors.text
        selectUri = "pkg:/images/ui/settings_select_104x34_purpleSoft_greenFocus.png"
        chevronUri = "pkg:/images/ui/select_chevron_down_focus.png"
    end if
    uiPoster(m.canvas, selectUri, x, y, w, h, 1.0)
    labelNode = uiLabel(m.canvas, "Actions", x + 9, y + 1, w - 34, h, 13, textColor, "center")
    labelNode.font.size = 13
    uiPoster(m.canvas, chevronUri, x + w - 25, y + 10, 14, 14)
    m.focusItems.push({
        x: x, y: y, w: w, h: h,
        action: "actions",
        playlistId: playlistStoreText(p, "id"),
        playlistTitle: playlistStoreText(p, "title", "Playlist"),
        playlistProtected: isProtected,
        playlistIndex: playlistIndex,
        locked: false,
        row: playlistIndex + 1, col: 1, mode: "manual", noFocusShift: true
    })
end sub

sub drawDropdown()
    if m.dropdownOptions = invalid or m.dropdownOptions.count() = 0 then return
    rowH = 40
    optionH = 34
    w = 104
    x = m.dropdownX
    if x < 8 then x = 8
    y = m.dropdownY
    totalH = (rowH * m.dropdownOptions.count()) - (rowH - optionH)
    if y + totalH > 704 then y = 704 - totalH
    panelH = totalH + 12
    panelUri = "pkg:/images/ui/settings_dropdown_panel_116x166_bg.png"
    if panelH <= 86 then
        panelUri = "pkg:/images/ui/settings_dropdown_panel_116x86_bg.png"
    else if panelH > 166 then
        panelUri = "pkg:/images/ui/settings_dropdown_panel_116x206_bg.png"
    end if
    uiPoster(m.canvas, panelUri, x - 6, y - 6, 116, panelH, 1.0)
    for i = 0 to m.dropdownOptions.count() - 1
        optionY = y + i * rowH
        optionUri = "pkg:/images/ui/settings_select_104x34_bg2_whiteLine.png"
        textColor = m.colors.textPurple
        if i = m.dropdownIndex then
            optionUri = "pkg:/images/ui/settings_select_104x34_purpleSoft_greenFocus.png"
            textColor = m.colors.text
        end if
        if m.dropdownOptions[i] = "Delete" and i <> m.dropdownIndex then textColor = "0xFFB2A8FF"
        uiPoster(m.canvas, optionUri, x, optionY, w, optionH, 1.0)
        optionLabel = uiLabel(m.canvas, m.dropdownOptions[i], x + 6, optionY + 1, w - 12, optionH, 14, textColor, "center")
        optionLabel.font.size = 14
    end for
end sub

function managePlaylistSource(p as Object) as String
    playlistType = playlistStoreText(p, "type", "M3U")
    if playlistType = "Xtreme" then
        server = playlistStoreText(p, "serverUrl", "Server not configured")
        user = playlistStoreText(p, "username")
        if user <> "" then return "Xtreme - " + server + " - " + user
        return "Xtreme - " + server
    end if
    source = playlistStoreText(p, "sourceUrl")
    if source = "" then source = playlistStoreText(p, "meta", "Built-in playlist")
    if source.len() > 72 then source = Left(source, 69) + "..."
    return "M3U - " + source
end function

function findPlaylistActionFocus(playlistIndex as Integer, action as String) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("playlistIndex") and item.playlistIndex = playlistIndex and item.action = action then return i
    end for
    return -1
end function

function findFirstPlaylistActionFocus(playlistIndex as Integer) as Integer
    for i = 0 to m.focusItems.count() - 1
        item = m.focusItems[i]
        if item.doesExist("playlistIndex") and item.playlistIndex = playlistIndex then return i
    end for
    return -1
end function

sub drawScrollbar()
    if m.playlists.count() <= m.windowSize then return
    x = 1194
    y = 180
    h = 476
    uiVerticalPill(m.canvas, x, y, 3, h, "0xFFFFFF18", "pkg:/images/ui/scroll_cap_4_whiteLine.png", 0.28)
    thumbH = Int(h * m.windowSize / m.playlists.count())
    if thumbH < 70 then thumbH = 70
    maxStart = m.playlists.count() - m.windowSize
    thumbY = y
    if maxStart > 0 then thumbY = y + Int((h - thumbH) * m.windowStart / maxStart)
    uiVerticalPill(m.canvas, x - 1, thumbY, 5, thumbH, m.colors.greenFocus, "pkg:/images/ui/scroll_cap_6_greenFocus.png", 0.58)
end sub

sub openRefreshConfirm(playlistId as String, playlistTitle as String)
    m.pendingId = playlistId
    m.pendingTitle = playlistTitle
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Refresh playlist?"
    dialog.message = "Validate " + playlistTitle + " and prepare it for provider synchronization."
    dialog.buttons = ["Cancel", "Refresh"]
    dialog.observeField("buttonSelected", "onRefreshDialogButton")
    m.refreshDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub closeRefreshDialog()
    if m.top <> invalid and m.top.getScene() <> invalid then m.top.getScene().dialog = invalid
    m.refreshDialog = invalid
end sub

sub onRefreshDialogButton()
    if m.refreshDialog = invalid then return
    selected = m.refreshDialog.buttonSelected
    playlistId = m.pendingId
    closeRefreshDialog()
    if selected = 1 then
        if playlistStoreBool(playlistStoreGet(playlistId), "backendManaged", false) then
            startBackendPlaylistRefresh(playlistId)
            return
        end if
        m.refreshingId = playlistId
        m.feedbackMessage = "Validating playlist details..."
        m.feedbackSuccess = true
        render()
        m.refreshTimer.control = "stop"
        m.refreshTimer.control = "start"
    end if
end sub

sub startBackendPlaylistRefresh(playlistId as String)
    p = playlistStoreGet(playlistId)
    backendId = playlistStoreText(p, "backendPlaylistId")
    if backendId = "" then
        m.feedbackMessage = "Backend playlist ID is missing."
        m.feedbackSuccess = false
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.feedbackMessage = "Backend connection is unavailable."
        m.feedbackSuccess = false
        render()
        return
    end if

    m.refreshingId = playlistId
    m.backendAction = "refresh"
    m.backendActionPlaylistId = playlistId
    m.feedbackMessage = "Starting backend refresh..."
    m.feedbackSuccess = true
    task.observeField("response", "onBackendPlaylistAction")
    task.request = backendApiRefreshPlaylistRequest(backendId)
    m.backendTask = task
    render()
    task.control = "RUN"
end sub

sub finishPlaylistRefresh()
    if m.refreshingId = "" then return
    result = playlistStoreRefreshResult(m.refreshingId)
    m.refreshingId = ""
    m.feedbackMessage = result.message
    m.feedbackSuccess = result.success
    m.playlists = playlistStoreList()
    render()
end sub

sub openDeleteConfirm(playlistId as String, playlistTitle as String)
    m.pendingId = playlistId
    m.pendingTitle = playlistTitle
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Delete playlist?"
    dialog.message = "Remove " + playlistTitle + " from this Roku?"
    dialog.buttons = ["Cancel", "Delete"]
    dialog.observeField("buttonSelected", "onDeleteDialogButton")
    m.deleteDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub closeDeleteDialog()
    if m.top <> invalid and m.top.getScene() <> invalid then m.top.getScene().dialog = invalid
    m.deleteDialog = invalid
end sub

sub onDeleteDialogButton()
    if m.deleteDialog = invalid then return
    selected = m.deleteDialog.buttonSelected
    playlistId = m.pendingId
    playlistTitle = m.pendingTitle
    closeDeleteDialog()
    if selected = 1 then
        if playlistStoreBool(playlistStoreGet(playlistId), "backendManaged", false) then
            startBackendPlaylistDelete(playlistId, playlistTitle)
            return
        end if
        deleted = playlistStoreDelete(playlistId)
        m.playlists = playlistStoreList()
        m.feedbackSuccess = deleted
        if deleted then
            m.feedbackMessage = playlistTitle + " was deleted."
        else
            m.feedbackMessage = "This protected playlist cannot be deleted."
        end if
        maxStart = m.playlists.count() - m.windowSize
        if maxStart < 0 then maxStart = 0
        if m.windowStart > maxStart then m.windowStart = maxStart
        m.focusIndex = 0
        render()
    end if
end sub

sub startBackendPlaylistDelete(playlistId as String, playlistTitle as String)
    p = playlistStoreGet(playlistId)
    backendId = playlistStoreText(p, "backendPlaylistId")
    if backendId = "" then
        m.feedbackMessage = "Backend playlist ID is missing."
        m.feedbackSuccess = false
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.feedbackMessage = "Backend connection is unavailable."
        m.feedbackSuccess = false
        render()
        return
    end if

    m.backendAction = "delete"
    m.backendActionPlaylistId = playlistId
    m.pendingTitle = playlistTitle
    m.feedbackMessage = "Deleting playlist from backend..."
    m.feedbackSuccess = true
    task.observeField("response", "onBackendPlaylistAction")
    task.request = backendApiDeletePlaylistRequest(backendId)
    m.backendTask = task
    render()
    task.control = "RUN"
end sub

sub onBackendPlaylistAction()
    if m.backendTask = invalid then return
    response = m.backendTask.response
    action = m.backendAction
    playlistId = m.backendActionPlaylistId
    playlistTitle = m.pendingTitle

    m.backendTask = invalid
    m.backendAction = ""
    m.backendActionPlaylistId = ""
    m.refreshingId = ""

    if not backendApiResponseOk(response) then
        m.feedbackSuccess = false
        if action = "delete" then
            m.feedbackMessage = "Backend could not delete " + playlistTitle + "."
        else
            m.feedbackMessage = "Backend refresh could not be started."
        end if
        render()
        return
    end if

    if action = "delete" then
        deleted = playlistStoreDeleteBackendLocalOnly(playlistId)
        m.feedbackSuccess = deleted
        if deleted then
            m.feedbackMessage = playlistTitle + " was deleted."
        else
            m.feedbackMessage = "Playlist was deleted on backend, but local cleanup failed."
        end if
    else
        playlistStoreMarkBackendImporting(playlistId)
        m.feedbackSuccess = true
        m.feedbackMessage = "Backend refresh started."
    end if

    m.playlists = playlistStoreList()
    maxStart = m.playlists.count() - m.windowSize
    if maxStart < 0 then maxStart = 0
    if m.windowStart > maxStart then m.windowStart = maxStart
    m.focusIndex = 0
    render()
end sub
