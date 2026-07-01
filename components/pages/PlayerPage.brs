sub init()
    m.colors = appColors()
    m.video = m.top.findNode("playerVideo")
    m.canvas = m.top.findNode("playerCanvas")
    m.settings = settingsStoreLoad()
    m.focusItems = []
    m.focusIndex = 2
    m.errorFocusIndex = 0
    m.finishedFocusIndex = 0
    m.trackMenuOpen = false
    m.trackMenuItems = []
    m.trackMenuIndex = 0
    m.audioTracks = []
    m.subtitleTracks = []
    m.playing = false
    m.captionsEnabled = settingsStoreText(m.settings, "captionMode", "System") = "On"
    m.loadedUrl = ""
    m.errorText = ""
    m.errorCode = 0
    m.playbackState = "preparing"
    m.controlsVisible = true
    m.isLive = false
    m.exiting = false
    m.retryPending = false
    m.retryCount = 0
    m.maxAutoRetries = 2

    m.video.translation = [0, 0]
    m.video.width = 1280
    m.video.height = 720
    m.video.enableUI = false
    m.video.observeField("state", "onVideoStateChange")
    m.video.observeField("errorMsg", "onVideoError")
    m.top.observeField("playbackUrl", "onPlaybackChanged")

    m.progressTimer = CreateObject("roSGNode", "Timer")
    m.progressTimer.repeat = true
    m.progressTimer.duration = 1
    m.progressTimer.observeField("fire", "onProgressTick")
    m.progressTimer.control = "start"

    m.hideTimer = CreateObject("roSGNode", "Timer")
    m.hideTimer.repeat = false
    m.hideTimer.duration = 7
    m.hideTimer.observeField("fire", "onHideControls")

    m.retryTimer = CreateObject("roSGNode", "Timer")
    m.retryTimer.repeat = false
    m.retryTimer.duration = 2
    m.retryTimer.observeField("fire", "onRetryTimer")

    resetHideTimer()
    render()
end sub

sub refreshClock()
end sub

function handleKey(key as String) as Boolean
    if m.trackMenuOpen then return handleTrackMenuKey(key)

    if key = "back" then
        exitPlayer()
        return true
    end if

    if key = "options" then
        openTrackMenu()
        return true
    end if

    if m.playbackState = "error" and not m.retryPending then
        if key = "left" or key = "right" then
            m.errorFocusIndex = 1 - m.errorFocusIndex
            render()
            return true
        end if
        if key = "OK" then
            if m.errorFocusIndex = 0 then
                manualRetry()
            else
                exitPlayer()
            end if
            return true
        end if
        return true
    end if

    if m.playbackState = "finished" then
        if key = "left" or key = "right" then
            m.finishedFocusIndex = 1 - m.finishedFocusIndex
            render()
            return true
        end if
        if key = "OK" then
            if m.finishedFocusIndex = 0 then
                replayMedia()
            else
                exitPlayer()
            end if
            return true
        end if
        return true
    end if

    if m.retryPending then return true

    if not m.controlsVisible and (key = "left" or key = "right" or key = "up" or key = "down" or key = "OK") then
        showControls()
        render()
        return true
    end if
    if key = "left" then showControls() : moveControl(-1) : return true
    if key = "right" then showControls() : moveControl(1) : return true
    if key = "up" or key = "down" then showControls() : render() : return true
    if key = "OK" then showControls() : activateControl() : return true
    if key = "play" then showControls() : togglePlayback() : return true
    if key = "replay" and not m.isLive then showControls() : seekPlayer(-30, false) : return true
    return true
end function

sub onPlaybackChanged()
    m.isLive = playbackMediaType() = "live"
    if m.isLive then m.focusIndex = 0 else m.focusIndex = 2
    startPlayback(false)
end sub

sub startPlayback(force as Boolean)
    url = m.top.playbackUrl
    if url = invalid or url = "" then
        m.playbackState = "preparing"
        render()
        return
    end if
    if not force and url = m.loadedUrl then return

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamFormat = streamFormat()
    content.title = playbackTitle()
    posterUrl = m.top.playbackPosterUrl
    if posterUrl <> invalid and posterUrl <> "" then content.HDPosterUrl = posterUrl
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    if content.hasField("Live") then content.Live = m.isLive
    applyQualityPreference(content)

    m.video.control = "stop"
    m.video.content = content
    applyCaptionMode()
    m.video.control = "play"
    m.loadedUrl = url
    m.playing = false
    m.playbackState = "preparing"
    m.errorText = ""
    m.errorCode = 0
    m.retryPending = false
    showControls()
    render()
end sub

sub stopPlayback()
    m.exiting = true
    m.retryTimer.control = "stop"
    if m.video <> invalid then m.video.control = "stop"
end sub

sub exitPlayer()
    stopPlayback()
    target = m.top.returnPage
    if target = invalid or target = "" then target = "HomePage"
    m.top.navigateTo = target
end sub

sub onVideoStateChange()
    if m.video = invalid or m.exiting then return
    state = m.video.state
    if state = "buffering" then
        m.playbackState = "buffering"
        m.playing = false
        showControls()
    else if state = "playing" then
        m.playbackState = "playing"
        m.playing = true
        m.errorText = ""
        m.errorCode = 0
        m.retryPending = false
        m.retryCount = 0
        refreshAvailableTracks()
        resetHideTimer()
    else if state = "paused" then
        m.playbackState = "paused"
        m.playing = false
        showControls()
    else if state = "finished" then
        m.playing = false
        if m.isLive then
            handlePlaybackFailure("The live stream ended unexpectedly.")
            return
        end if
        m.playbackState = "finished"
        m.finishedFocusIndex = 0
        showControls()
    else if state = "error" then
        handlePlaybackFailure(videoErrorMessage())
        return
    end if
    if m.controlsVisible or not m.playing then render()
end sub

sub onVideoError()
    if m.video = invalid or m.exiting then return
    if m.video.errorMsg <> invalid and m.video.errorMsg <> "" then m.errorText = m.video.errorMsg
    if m.video.hasField("errorCode") then m.errorCode = m.video.errorCode
    if m.video.state = "error" then handlePlaybackFailure(videoErrorMessage())
end sub

sub handlePlaybackFailure(message as String)
    if m.exiting or m.retryPending then return
    m.playing = false
    if message = invalid or message = "" then message = "The stream is unavailable."
    m.errorText = message
    showControls()

    if m.retryCount < m.maxAutoRetries then
        m.retryCount += 1
        m.retryPending = true
        m.playbackState = "reconnecting"
        m.retryTimer.control = "stop"
        m.retryTimer.control = "start"
    else
        m.playbackState = "error"
        m.errorFocusIndex = 0
    end if
    render()
end sub

sub onRetryTimer()
    if m.exiting then return
    m.retryPending = false
    m.loadedUrl = ""
    startPlayback(true)
end sub

sub manualRetry()
    m.retryCount = 0
    m.retryPending = false
    m.loadedUrl = ""
    startPlayback(true)
end sub

sub replayMedia()
    if m.video = invalid then return
    m.playbackState = "preparing"
    m.video.seek = 0
    m.video.control = "play"
    showControls()
    render()
end sub

sub onProgressTick()
    if m.controlsVisible or m.playbackState <> "playing" then render()
end sub

sub showControls()
    m.controlsVisible = true
    resetHideTimer()
end sub

sub resetHideTimer()
    if m.hideTimer = invalid then return
    m.hideTimer.control = "stop"
    m.hideTimer.control = "start"
end sub

sub onHideControls()
    if m.loadedUrl = "" or m.playbackState <> "playing" or m.trackMenuOpen then return
    m.controlsVisible = false
    render()
end sub

function controlCount() as Integer
    if m.isLive then return 2
    return 5
end function

sub moveControl(delta as Integer)
    count = controlCount()
    m.focusIndex += delta
    if m.focusIndex < 0 then m.focusIndex = count - 1
    if m.focusIndex > count - 1 then m.focusIndex = 0
    render()
end sub

sub activateControl()
    if m.isLive then
        if m.focusIndex = 0 then togglePlayback() : return
        if m.focusIndex = 1 then openTrackMenu() : return
    else
        if m.focusIndex = 0 then seekPlayer(0, true) : return
        if m.focusIndex = 1 then seekPlayer(-30, false) : return
        if m.focusIndex = 2 then togglePlayback() : return
        if m.focusIndex = 3 then seekPlayer(30, false) : return
        if m.focusIndex = 4 then openTrackMenu() : return
    end if
end sub

sub togglePlayback()
    if m.video = invalid then return
    if m.playing then
        m.video.control = "pause"
        m.playing = false
        m.playbackState = "paused"
    else
        m.video.control = "resume"
        m.playing = true
        m.playbackState = "playing"
    end if
    render()
end sub

sub seekPlayer(offset as Integer, absolute as Boolean)
    if m.video = invalid or m.isLive then return
    target = 0
    if not absolute then target = videoPosition() + offset
    if target < 0 then target = 0
    duration = videoDuration()
    if duration > 0 and target > duration - 2 then target = duration - 2
    m.video.seek = target
    render()
end sub

sub applyCaptionMode()
    if m.video = invalid then return
    mode = settingsStoreText(m.settings, "captionMode", "System")
    if mode = "System" then return

    globalMode = "Off"
    if mode = "On" then globalMode = "On"
    if mode = "Replay" then globalMode = "Instant replay"
    if mode = "Mute" then globalMode = "When mute"

    if m.video.hasField("globalCaptionMode") then
        m.video.globalCaptionMode = globalMode
    else if m.video.hasField("closedCaptionMode") then
        m.video.closedCaptionMode = globalMode
    end if
end sub

sub toggleCaptions()
    m.captionsEnabled = not m.captionsEnabled
    if m.captionsEnabled then
        m.settings.captionMode = "On"
    else
        m.settings.captionMode = "Off"
    end if
    settingsStoreSave(m.settings)
    applyCaptionMode()
end sub

sub applyQualityPreference(content as Object)
    if content = invalid then return
    quality = settingsStoreText(m.settings, "defaultQuality", "Auto")
    if quality = "Auto" or not content.hasField("maxBandwidth") then return
    maxBandwidth = 0
    if quality = "1080p" then maxBandwidth = 8000
    if quality = "720p" then maxBandwidth = 4500
    if quality = "480p" then maxBandwidth = 2000
    if maxBandwidth > 0 then content.maxBandwidth = maxBandwidth
end sub

sub refreshAvailableTracks()
    m.audioTracks = []
    m.subtitleTracks = []
    if settingsStoreText(m.settings, "captionMode", "System") = "System" then
        currentMode = ""
        if m.video.hasField("globalCaptionMode") then currentMode = m.video.globalCaptionMode
        if currentMode = "" and m.video.hasField("closedCaptionMode") then currentMode = m.video.closedCaptionMode
        if currentMode <> invalid and currentMode <> "" then m.captionsEnabled = currentMode <> "Off"
    end if
    if m.video.hasField("availableAudioTracks") then
        tracks = m.video.availableAudioTracks
        if tracks <> invalid and type(tracks) = "roArray" then m.audioTracks = tracks
    end if
    if m.video.hasField("availableSubtitleTracks") then
        tracks = m.video.availableSubtitleTracks
        if tracks <> invalid and type(tracks) = "roArray" then m.subtitleTracks = tracks
    end if
end sub

sub openTrackMenu()
    refreshAvailableTracks()
    m.trackMenuItems = []
    captionLabel = "Captions: Off"
    if m.captionsEnabled then captionLabel = "Captions: On"
    m.trackMenuItems.push({ label: captionLabel, action: "captions", value: "" })

    for i = 0 to m.audioTracks.count() - 1
        track = m.audioTracks[i]
        m.trackMenuItems.push({ label: "Audio: " + trackDisplayName(track, i + 1), action: "audio", value: trackIdentifier(track) })
    end for
    for i = 0 to m.subtitleTracks.count() - 1
        track = m.subtitleTracks[i]
        m.trackMenuItems.push({ label: "Subtitle: " + trackDisplayName(track, i + 1), action: "subtitle", value: trackIdentifier(track) })
    end for

    m.trackMenuIndex = 0
    m.trackMenuOpen = true
    showControls()
    render()
end sub

function handleTrackMenuKey(key as String) as Boolean
    if key = "back" or key = "options" then
        m.trackMenuOpen = false
        render()
        return true
    end if
    if key = "up" and m.trackMenuIndex > 0 then m.trackMenuIndex -= 1 : render() : return true
    if key = "down" and m.trackMenuIndex < m.trackMenuItems.count() - 1 then m.trackMenuIndex += 1 : render() : return true
    if key = "OK" then
        applyTrackMenuSelection()
        return true
    end if
    return true
end function

sub applyTrackMenuSelection()
    if m.trackMenuIndex < 0 or m.trackMenuIndex >= m.trackMenuItems.count() then return
    item = m.trackMenuItems[m.trackMenuIndex]
    if item.action = "captions" then
        toggleCaptions()
        openTrackMenu()
        return
    end if
    if item.action = "audio" and item.value <> "" and m.video.hasField("audioTrack") then m.video.audioTrack = item.value
    if item.action = "subtitle" and item.value <> "" and m.video.hasField("subtitleTrack") then
        m.video.subtitleTrack = item.value
        if not m.captionsEnabled then toggleCaptions()
    end if
    m.trackMenuOpen = false
    render()
end sub

function trackDisplayName(track as Dynamic, index as Integer) as String
    if track = invalid then return "Track " + index.toStr()
    for each key in ["description", "language", "name", "id"]
        value = trackValue(track, key)
        if value <> "" then return value
    end for
    return "Track " + index.toStr()
end function

function trackIdentifier(track as Dynamic) as String
    for each key in ["id", "name", "language"]
        value = trackValue(track, key)
        if value <> "" then return value
    end for
    return ""
end function

function trackValue(track as Dynamic, key as String) as String
    if track = invalid then return ""
    if track.doesExist(key) and track[key] <> invalid then return track[key].toStr()
    lowerKey = LCase(key)
    if lowerKey <> key and track.doesExist(lowerKey) and track[lowerKey] <> invalid then return track[lowerKey].toStr()
    return ""
end function

sub render()
    uiClear(m.canvas)
    m.focusItems = []

    showOverlay = m.controlsVisible or m.playbackState <> "playing" or m.trackMenuOpen
    if not showOverlay then return
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.08)
    drawHeader()

    if m.playbackState = "preparing" then drawCenterStatus("Preparing video", "Opening the selected stream...")
    if m.playbackState = "buffering" then drawCenterStatus("Buffering", "Playback will continue automatically.")
    if m.playbackState = "reconnecting" then drawCenterStatus("Reconnecting", "Attempt " + m.retryCount.toStr() + " of " + m.maxAutoRetries.toStr())

    if m.playbackState = "error" then
        drawErrorPanel()
    else if m.playbackState = "finished" then
        drawFinishedPanel()
    else if m.controlsVisible and not m.retryPending then
        drawControls()
    end if

    if m.trackMenuOpen then drawTrackMenu()
end sub

sub drawHeader()
    headerHeight = 78
    if playbackMediaType() = "series" then headerHeight = 94
    uiRect(m.canvas, 0, 0, 1280, headerHeight, "0x090D16FF", 0.76)
    uiRect(m.canvas, 0, headerHeight - 1, 1280, 1, "0xFFFFFF18", 0.32)
    uiLabel(m.canvas, playbackTitle(), 48, 12, 830, 42, 24, m.colors.text)
    if playbackMediaType() = "series" and playbackSubtitle() <> "" then
        uiLabel(m.canvas, playbackSubtitle(), 48, 52, 430, 24, 13, m.colors.textDim)
    end if

    if m.isLive then
        uiPoster(m.canvas, "pkg:/images/ui/live_badge.png", 1134, 22, 78, 29, 1.0)
    end if
end sub

sub drawCenterStatus(title as String, subtitle as String)
    drawLoadingSpinner(640, 316)
    uiLabel(m.canvas, title, 430, 370, 420, 34, 20, m.colors.text, "center")
    uiLabel(m.canvas, subtitle, 410, 408, 460, 28, 11, m.colors.textMuted, "center")
end sub

sub drawLoadingSpinner(centerX as Integer, centerY as Integer)
    spinner = m.canvas.createChild("Group")
    spinner.id = "playerLoadingSpinner"
    spinner.translation = [centerX - 30, centerY - 30]
    spinner.scaleRotateCenter = [30, 30]

    dotPositions = [
        [25, 0], [43, 7], [50, 25], [43, 43],
        [25, 50], [7, 43], [0, 25], [7, 7]
    ]
    dotOpacity = [1.0, 0.88, 0.76, 0.64, 0.52, 0.40, 0.28, 0.18]
    for dotIndex = 0 to dotPositions.count() - 1
        point = dotPositions[dotIndex]
        uiPoster(spinner, "pkg:/images/ui/scroll_cap_6_greenFocus.png", point[0], point[1], 10, 10, dotOpacity[dotIndex])
    end for

    animation = m.canvas.createChild("Animation")
    animation.id = "playerLoadingAnimation"
    animation.duration = 0.9
    animation.repeat = true
    rotationAnimation = animation.createChild("FloatFieldInterpolator")
    rotationAnimation.key = [0.0, 1.0]
    rotationAnimation.keyValue = [0.0, 6.28318]
    rotationAnimation.fieldToInterp = "playerLoadingSpinner.rotation"
    animation.control = "start"
end sub

sub drawErrorPanel()
    uiPoster(m.canvas, "pkg:/images/ui/rr_500x158_panel_purpleLine.png", 340, 246, 600, 220, 0.96)
    uiLabel(m.canvas, "Unable to play this stream", 380, 270, 520, 34, 20, m.colors.textGreen, "center")
    message = m.errorText
    if message.len() > 76 then message = Left(message, 73) + "..."
    uiLabel(m.canvas, message, 390, 314, 500, 52, 11, m.colors.textMuted, "center")
    drawDialogAction(430, 386, 190, "Retry Stream", 0, m.errorFocusIndex)
    drawDialogAction(660, 386, 190, "Go Back", 1, m.errorFocusIndex)
end sub

sub drawFinishedPanel()
    uiPoster(m.canvas, "pkg:/images/ui/rr_500x158_panel_purpleLine.png", 340, 258, 600, 196, 0.96)
    uiLabel(m.canvas, "Playback finished", 380, 290, 520, 36, 21, m.colors.text, "center")
    drawDialogAction(430, 366, 190, "Replay", 0, m.finishedFocusIndex)
    drawDialogAction(660, 366, 190, "Go Back", 1, m.finishedFocusIndex)
end sub

sub drawDialogAction(x as Integer, y as Integer, w as Integer, label as String, index as Integer, focusedIndex as Integer)
    uri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    opacity = 0.70
    if index = focusedIndex then
        uri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        opacity = 0.92
    end if
    uiPoster(m.canvas, uri, x, y, w, 48, opacity)
    uiLabel(m.canvas, label, x, y + 8, w, 30, 13, m.colors.text, "center")
end sub

sub drawControls()
    if m.isLive then
        drawLiveControls()
    else
        drawVodControls()
    end if
end sub

sub drawLiveControls()
    panelY = 580
    uiRect(m.canvas, 0, panelY, 1280, 140, "0x090D16FF", 0.86)
    uiRect(m.canvas, 0, panelY, 1280, 1, "0xFFFFFF18", 0.42)

    iconY = panelY + 44
    playIcon = "pkg:/images/ui/player_pause.png"
    if not m.playing then playIcon = "pkg:/images/ui/player_play.png"
    addIconControl(585, iconY, "playpause", 0, playIcon, true)
    addIconControl(705, iconY, "tracks", 1, "pkg:/images/ui/player_captions.png", false)
end sub

sub drawVodControls()
    panelY = 548
    uiRect(m.canvas, 0, panelY, 1280, 172, "0x090D16FF", 0.86)
    uiRect(m.canvas, 0, panelY, 1280, 1, "0xFFFFFF18", 0.42)
    playPosition = videoPosition()
    dur = videoDuration()
    progressW = 980
    progressX = 150
    progressY = panelY + 30
    uiRect(m.canvas, progressX, progressY, progressW, 5, "0xFFFFFF18", 0.72)
    fillW = 0
    if dur > 0 then fillW = Int(progressW * playPosition / dur)
    if fillW > progressW then fillW = progressW
    uiRect(m.canvas, progressX, progressY, fillW, 5, m.colors.greenFocus, 0.98)
    if fillW > 0 then uiRect(m.canvas, progressX + fillW - 3, progressY - 3, 7, 11, m.colors.text, 1.0)
    uiLabel(m.canvas, formatTime(playPosition), 48, panelY + 18, 80, 26, 12, m.colors.text, "right")
    uiLabel(m.canvas, formatTime(dur), 1152, panelY + 18, 80, 26, 12, m.colors.text)

    iconY = panelY + 70
    addIconControl(430, iconY, "restart", 0, "pkg:/images/ui/player_restart.png", false)
    addIconControl(535, iconY, "backward", 1, "pkg:/images/ui/player_forward.png", false)
    playIcon = "pkg:/images/ui/player_pause.png"
    if not m.playing then playIcon = "pkg:/images/ui/player_play.png"
    addIconControl(640, iconY, "playpause", 2, playIcon, true)
    addIconControl(745, iconY, "forward", 3, "pkg:/images/ui/player_rewind.png", false)
    addIconControl(850, iconY, "tracks", 4, "pkg:/images/ui/player_captions.png", false)
end sub

sub addIconControl(centerX as Integer, y as Integer, action as String, col as Integer, iconUri as String, primary as Boolean)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    iconSize = 42
    if primary then iconSize = 56
    if focused then
        if primary then
            uiPoster(m.canvas, "pkg:/images/ui/player_focus_halo.png", centerX - 36, y - 4, 72, 72)
            iconSize = 60
        else
            uiPoster(m.canvas, "pkg:/images/ui/player_focus_halo.png", centerX - 30, y + 2, 60, 60)
            iconSize = 46
        end if
    end if
    iconTop = y + Int((64 - iconSize) / 2)
    uiPoster(m.canvas, iconUri, centerX - Int(iconSize / 2), iconTop, iconSize, iconSize)
    m.focusItems.push({ x: centerX - 48, y: y, w: 96, h: 64, action: action, row: 0, col: col, mode: "manual" })
end sub

sub drawTrackMenu()
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.46)
    panelX = 770
    panelY = 104
    panelW = 440
    panelH = 500
    uiPoster(m.canvas, "pkg:/images/ui/rr_500x158_panel_purpleLine.png", panelX, panelY, panelW, panelH, 0.98)
    uiLabel(m.canvas, "AUDIO & SUBTITLES", panelX + 32, panelY + 24, panelW - 64, 34, 18, m.colors.text)

    maxVisible = 8
    startIndex = 0
    if m.trackMenuIndex >= maxVisible then startIndex = m.trackMenuIndex - maxVisible + 1
    endIndex = startIndex + maxVisible - 1
    if endIndex > m.trackMenuItems.count() - 1 then endIndex = m.trackMenuItems.count() - 1
    slot = 0
    for i = startIndex to endIndex
        item = m.trackMenuItems[i]
        y = panelY + 78 + slot * 48
        focused = i = m.trackMenuIndex
        uri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
        opacity = 0.50
        if focused then
            uri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
            opacity = 0.84
        end if
        uiPoster(m.canvas, uri, panelX + 28, y, panelW - 56, 40, opacity)
        uiLabel(m.canvas, item.label, panelX + 48, y + 6, panelW - 96, 28, 11, m.colors.text)
        slot += 1
    end for
end sub

function playbackTitle() as String
    title = m.top.playbackTitle
    if title = invalid or title = "" then return "Video"
    return title
end function

function playbackMediaType() as String
    mediaType = LCase(m.top.playbackMediaType)
    if mediaType <> "" then return mediaType
    if m.top.returnPage = "LiveTvPage" then return "live"
    if m.top.returnPage = "SeriesDetailPage" or m.top.returnPage = "SeriesPage" then return "series"
    return "movie"
end function

function streamFormat() as String
    format = m.top.playbackFormat
    if format = invalid or format = "" then return "hls"
    return format
end function

function playbackSubtitle() as String
    subtitle = m.top.playbackSubtitle
    if subtitle = invalid then return ""
    return subtitle
end function

function videoErrorMessage() as String
    errorCode = m.errorCode
    if m.video <> invalid and m.video.hasField("errorCode") then errorCode = m.video.errorCode
    if errorCode = -1 then return "Network error. Check the connection or stream server."
    if errorCode = -2 then return "The stream connection timed out."
    if errorCode = -4 then return "No playable stream was provided."
    if errorCode = -5 then return "This stream format is unsupported or invalid."
    if errorCode = -6 then return "The stream could not pass its DRM check."
    if m.video <> invalid and m.video.errorMsg <> invalid and m.video.errorMsg <> "" then return m.video.errorMsg
    if m.errorText <> "" then return m.errorText
    return "The stream is unavailable."
end function

function videoPosition() as Integer
    if m.video = invalid then return 0
    value = m.video.position
    if value = invalid then return 0
    valueType = type(value)
    if valueType <> "Integer" and valueType <> "roInteger" and valueType <> "roInt" and valueType <> "LongInteger" and valueType <> "roLongInteger" and valueType <> "roLongInt" and valueType <> "Float" and valueType <> "roFloat" and valueType <> "Double" and valueType <> "roDouble" then return 0
    return Int(value)
end function

function videoDuration() as Integer
    if m.video = invalid then return 0
    value = m.video.duration
    if value = invalid then return 0
    valueType = type(value)
    if valueType <> "Integer" and valueType <> "roInteger" and valueType <> "roInt" and valueType <> "LongInteger" and valueType <> "roLongInteger" and valueType <> "roLongInt" and valueType <> "Float" and valueType <> "roFloat" and valueType <> "Double" and valueType <> "roDouble" then return 0
    return Int(value)
end function

function formatTime(seconds as Integer) as String
    if seconds < 0 then seconds = 0
    mins = Int(seconds / 60)
    secs = seconds mod 60
    secText = secs.toStr()
    if secs < 10 then secText = "0" + secText
    return mins.toStr() + ":" + secText
end function
