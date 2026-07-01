sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("managePlaylistsCanvas")
    m.playlists = playlistStoreList()
    m.focusItems = []
    m.focusIndex = 0
    m.windowStart = 0
    m.windowSize = 5
    m.refreshDialog = invalid
    m.deleteDialog = invalid
    m.pendingId = ""
    m.pendingTitle = ""
    m.refreshingId = ""
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
    if m.refreshDialog <> invalid then
        if key = "back" then closeRefreshDialog() : return true
        return false
    end if
    if m.deleteDialog <> invalid then
        if key = "back" then closeDeleteDialog() : return true
        return false
    end if
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

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.doesExist("locked") and item.locked then
        m.feedbackSuccess = false
        if item.action = "edit" then
            m.feedbackMessage = "Built-in playlists cannot be edited."
        else
            m.feedbackMessage = "Built-in playlists cannot be deleted."
        end if
        render()
        return
    end if
    if item.action = "edit" then
        playlistStoreSetPendingEdit(item.playlistId)
        m.top.navigateTo = "AddPlaylistPage"
        return
    end if
    if item.action = "refresh" then openRefreshConfirm(item.playlistId, item.playlistTitle) : return
    if item.action = "delete" then openDeleteConfirm(item.playlistId, item.playlistTitle)
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.canvas, 0, 86, 1280, 634, m.colors.bg2, 0.96)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    uiLabel(m.canvas, "MANAGE PLAYLISTS", 130, 102, 520, 42, 24, m.colors.text)
    uiScaledLabel(m.canvas, "Edit, validate, or remove playlists from this Roku.", 132, 140, 700, 24, 11, m.colors.textMuted, "left", 0.72)
    drawFeedback()
    drawPlaylistRows()
    drawScrollbar()
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
    y = 180 + slot * 98
    w = 1020
    h = 84
    active = playlistStoreText(p, "id") = playlistStoreActiveId()
    protected = playlistStoreBool(p, "isProtected", false)
    actionsLocked = protected

    uiPoster(m.canvas, "pkg:/images/ui/thin_280x152_purpleSoft_purpleLine.png", x, y, w, h, 0.54)
    uiLabel(m.canvas, playlistStoreText(p, "title", "Playlist"), x + 24, y + 10, 390, 28, 16, m.colors.text)
    uiScaledLabel(m.canvas, managePlaylistSource(p), x + 25, y + 42, 610, 22, 10, m.colors.textDim, "left", 0.66)

    badge = playlistStoreText(p, "status", "Ready")
    if active then badge = "Active"
    if protected and not active then badge = "Protected"
    if playlistStoreText(p, "id") = m.refreshingId then badge = "Syncing"

    refreshW = manageActionWidth("Refresh")
    editW = manageActionWidth("Edit")
    deleteW = manageActionWidth("Delete")
    actionsRight = x + w - 20
    deleteX = actionsRight - deleteW
    editX = deleteX - 12 - editW
    refreshX = editX - 12 - refreshW

    badgeW = manageBadgeWidth(badge)
    badgeX = refreshX - 18 - badgeW
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", badgeX, y + 24, badgeW, 32, 0.92)
    uiLabel(m.canvas, badge, badgeX + 6, y + 24, badgeW - 12, 30, 9, m.colors.text, "center")

    drawManageAction(refreshX, y + 22, refreshW, "Refresh", "refresh", p, playlistIndex, 1, false)
    drawManageAction(editX, y + 22, editW, "Edit", "edit", p, playlistIndex, 2, actionsLocked)
    drawManageAction(deleteX, y + 22, deleteW, "Delete", "delete", p, playlistIndex, 3, actionsLocked)
end sub

function manageBadgeWidth(label as String) as Integer
    width = 52 + label.len() * 8
    if width < 88 then width = 88
    if width > 136 then width = 136
    return width
end function

function manageActionWidth(label as String) as Integer
    width = 64 + label.len() * 8
    if width < 92 then width = 92
    if width > 124 then width = 124
    return width
end function

sub drawManageAction(x as Integer, y as Integer, w as Integer, label as String, action as String, p as Object, playlistIndex as Integer, col as Integer, locked as Boolean)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    uri = "pkg:/images/ui/movie_watch_140x40_panel_greenFocus.png"
    textColor = m.colors.text
    if focused then uri = "pkg:/images/ui/movie_watch_140x40_greenSoft_greenFocus.png"
    if action = "delete" and not focused then textColor = "0xFFB2A8FF"
    opacity = 0.78
    if locked then
        textColor = m.colors.textDim
        opacity = 0.44
    end if
    uiPoster(m.canvas, uri, x, y, w, 40, opacity)
    uiLabel(m.canvas, label, x, y + 7, w, 28, 11, textColor, "center")
    m.focusItems.push({
        x: x, y: y, w: w, h: 40,
        action: action,
        playlistId: playlistStoreText(p, "id"),
        playlistTitle: playlistStoreText(p, "title", "Playlist"),
        playlistIndex: playlistIndex,
        locked: locked,
        row: playlistIndex + 1, col: col, mode: "manual"
    })
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
        m.refreshingId = playlistId
        m.feedbackMessage = "Validating playlist details..."
        m.feedbackSuccess = true
        render()
        m.refreshTimer.control = "stop"
        m.refreshTimer.control = "start"
    end if
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
        wasActive = playlistStoreActiveId() = playlistId
        deleted = playlistStoreDelete(playlistId)
        m.playlists = playlistStoreList()
        m.feedbackSuccess = deleted
        if deleted then
            m.feedbackMessage = playlistTitle + " was deleted."
            if wasActive then m.feedbackMessage += " Empty M3U Playlist is now active."
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
