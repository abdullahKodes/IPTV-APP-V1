sub init()
    m.colors = appColors()
    m.video = m.top.findNode("playerVideo")
    m.canvas = m.top.findNode("playerCanvas")
    m.focusItems = []
    m.focusIndex = 2
    m.playing = true
    m.captionsEnabled = false
    m.loadedUrl = ""
    m.errorText = ""
    m.controlsVisible = true

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
    resetHideTimer()

    render()
    playMedia()
end sub

sub refreshClock()
end sub

function handleKey(key as String) as Boolean
    if key = "back" then
        stopPlayback()
        target = m.top.returnPage
        if target = invalid or target = "" then target = "HomePage"
        m.top.navigateTo = target
        return true
    end if
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
    if key = "replay" then showControls() : seekPlayer(-30, false) : return true
    return true
end function

sub onPlaybackChanged()
    playMedia()
end sub

sub playMedia()
    url = m.top.playbackUrl
    if url = invalid or url = "" or url = m.loadedUrl then return

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamFormat = streamFormat()
    content.title = playbackTitle()
    posterUrl = m.top.playbackPosterUrl
    if posterUrl <> invalid and posterUrl <> "" then content.HDPosterUrl = posterUrl
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"

    m.video.control = "stop"
    m.video.content = content
    applyCaptionMode()
    m.video.control = "play"
    m.loadedUrl = url
    m.playing = true
    m.errorText = ""
    showControls()
    render()
end sub

sub stopPlayback()
    if m.video <> invalid then m.video.control = "stop"
end sub

sub onVideoStateChange()
    if m.video = invalid then return
    if m.video.state = "playing" then m.playing = true
    if m.video.state = "paused" or m.video.state = "stopped" or m.video.state = "finished" then m.playing = false
    if m.controlsVisible or not m.playing then render()
end sub

sub onVideoError()
    if m.video <> invalid then m.errorText = m.video.errorMsg
    showControls()
    render()
end sub

sub onProgressTick()
    if m.controlsVisible or m.errorText <> "" or m.loadedUrl = "" then render()
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
    if m.loadedUrl = "" or m.errorText <> "" then return
    m.controlsVisible = false
    render()
end sub

sub moveControl(delta as Integer)
    m.focusIndex += delta
    if m.focusIndex < 0 then m.focusIndex = 4
    if m.focusIndex > 4 then m.focusIndex = 0
    render()
end sub

sub activateControl()
    if m.focusIndex = 0 then seekPlayer(0, true) : return
    if m.focusIndex = 1 then seekPlayer(-30, false) : return
    if m.focusIndex = 2 then togglePlayback() : return
    if m.focusIndex = 3 then seekPlayer(30, false) : return
    if m.focusIndex = 4 then toggleCaptions() : return
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
    render()
end sub

sub seekPlayer(offset as Integer, absolute as Boolean)
    if m.video = invalid then return
    target = 0
    if not absolute then target = Int(m.video.position) + offset
    if target < 0 then target = 0
    duration = videoDuration()
    if duration > 0 and target > duration - 2 then target = duration - 2
    m.video.seek = target
    render()
end sub

sub toggleCaptions()
    m.captionsEnabled = not m.captionsEnabled
    applyCaptionMode()
    render()
end sub

sub applyCaptionMode()
    if m.video = invalid or not m.video.hasField("closedCaptionMode") then return
    if m.captionsEnabled then
        m.video.closedCaptionMode = "On"
    else
        m.video.closedCaptionMode = "Off"
    end if
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []

    showOverlay = m.controlsVisible or m.loadedUrl = "" or m.errorText <> ""
    if not showOverlay then return
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.06)

    if m.loadedUrl = "" then
        uiLabel(m.canvas, "Preparing video", 0, 310, 1280, 40, 22, m.colors.text, "center")
    end if

    uiRect(m.canvas, 0, 0, 1280, 78, "0x090D16FF", 0.76)
    uiRect(m.canvas, 0, 77, 1280, 1, "0xFFFFFF18", 0.32)
    uiLabel(m.canvas, playbackTitle(), 48, 20, 900, 42, 24, m.colors.text)

    if m.errorText <> "" then
        uiRect(m.canvas, 316, 292, 648, 96, m.colors.panel, 0.96)
        uiLabel(m.canvas, "Unable to play video", 336, 306, 608, 28, 17, m.colors.textGreen, "center")
        uiLabel(m.canvas, m.errorText, 348, 338, 584, 26, 10, m.colors.textDim, "center")
    end if

    if m.controlsVisible then drawControls()
end sub

sub drawControls()
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
    addIconControl(535, iconY, "backward", 1, "pkg:/images/ui/player_rewind.png", false)
    playIcon = "pkg:/images/ui/player_pause.png"
    if not m.playing then playIcon = "pkg:/images/ui/player_play.png"
    addIconControl(640, iconY, "playpause", 2, playIcon, true)
    addIconControl(745, iconY, "forward", 3, "pkg:/images/ui/player_forward.png", false)
    addIconControl(850, iconY, "captions", 4, "pkg:/images/ui/player_captions.png", false)
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
    item = {
        x: centerX - 48, y: y, w: 96, h: 64,
        icon: "", label: "", subtitle: "",
        iconSize: 1, titleSize: 12, subSize: 8,
        bg: m.colors.panel, border: m.colors.whiteLine, textColor: m.colors.textDim, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 0, col: col, page: "", action: action, mode: "manual", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

function playbackTitle() as String
    title = m.top.playbackTitle
    if title = invalid or title = "" then return "Demo Video"
    return title
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
