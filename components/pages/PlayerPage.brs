sub init()
    m.colors = appColors()
    m.video = m.top.findNode("playerVideo")
    m.canvas = m.top.findNode("playerCanvas")
    m.focusItems = []
    m.focusIndex = 1
    m.playing = true
    m.loadedUrl = ""
    m.errorText = ""

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

    render()
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
    if key = "left" then moveControl(-1) : return true
    if key = "right" then moveControl(1) : return true
    if key = "up" or key = "down" then render() : return true
    if key = "OK" then activateControl() : return true
    if key = "play" then togglePlayback() : return true
    if key = "replay" then seekPlayer(-15, false) : return true
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
    content.streamformat = streamFormat()
    content.title = playbackTitle()
    posterUrl = m.top.playbackPosterUrl
    if posterUrl <> invalid and posterUrl <> "" then content.HDPosterUrl = posterUrl
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"

    m.video.content = content
    m.video.control = "play"
    m.loadedUrl = url
    m.playing = true
    m.errorText = ""
    render()
end sub

sub stopPlayback()
    if m.video <> invalid then m.video.control = "stop"
end sub

sub onVideoStateChange()
    if m.video = invalid then return
    if m.video.state = "playing" then m.playing = true
    if m.video.state = "paused" or m.video.state = "stopped" or m.video.state = "finished" then m.playing = false
    render()
end sub

sub onVideoError()
    if m.video <> invalid then m.errorText = m.video.errorMsg
    render()
end sub

sub onProgressTick()
    render()
end sub

sub moveControl(delta as Integer)
    m.focusIndex += delta
    if m.focusIndex < 0 then m.focusIndex = 3
    if m.focusIndex > 3 then m.focusIndex = 0
    render()
end sub

sub activateControl()
    if m.focusIndex = 0 then seekPlayer(-15, false) : return
    if m.focusIndex = 1 then togglePlayback() : return
    if m.focusIndex = 2 then seekPlayer(15, false) : return
    if m.focusIndex = 3 then seekPlayer(0, true) : return
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

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.18)

    if m.loadedUrl = "" then
        uiLabel(m.canvas, "Preparing video", 0, 310, 1280, 40, 22, m.colors.text, "center")
    end if

    uiRect(m.canvas, 0, 0, 1280, 96, "0x090D16FF", 0.78)
    uiLabel(m.canvas, playbackTitle(), 54, 24, 650, 32, 20, m.colors.text)
    uiLabel(m.canvas, playbackSubtitle(), 54, 56, 690, 24, 12, m.colors.textDim)
    uiLabel(m.canvas, "IPTV MAX", 1060, 30, 150, 28, 14, m.colors.textGreen, "right")

    if m.errorText <> "" then
        uiRect(m.canvas, 316, 292, 648, 96, m.colors.panel, 0.96)
        uiLabel(m.canvas, "Unable to play video", 336, 306, 608, 28, 17, m.colors.textGreen, "center")
        uiLabel(m.canvas, m.errorText, 348, 338, 584, 26, 10, m.colors.textDim, "center")
    end if

    drawControls()
end sub

sub drawControls()
    panelY = 558
    uiRect(m.canvas, 0, panelY, 1280, 162, "0x090D16FF", 0.84)
    playPosition = videoPosition()
    dur = videoDuration()
    progressW = 880
    progressX = 200
    progressY = panelY + 34
    uiRect(m.canvas, progressX, progressY, progressW, 4, "0xFFFFFF18", 0.72)
    fillW = 0
    if dur > 0 then fillW = Int(progressW * playPosition / dur)
    if fillW > progressW then fillW = progressW
    uiRect(m.canvas, progressX, progressY, fillW, 4, m.colors.greenFocus, 0.95)
    uiLabel(m.canvas, formatTime(playPosition), 80, panelY + 20, 92, 26, 12, m.colors.textDim, "right")
    uiLabel(m.canvas, formatTime(dur), 1108, panelY + 20, 92, 26, 12, m.colors.textDim)

    addControl(452, panelY + 68, 88, "REW", "backward", 0)
    playLabel = "PAUSE"
    if not m.playing then playLabel = "PLAY"
    addControl(558, panelY + 60, 112, playLabel, "playpause", 1)
    addControl(688, panelY + 68, 88, "FWD", "forward", 2)
    addControl(794, panelY + 68, 108, "RESTART", "restart", 3)
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
end sub

sub addControl(x as Integer, y as Integer, w as Integer, label as String, action as String, col as Integer)
    item = {
        x: x, y: y, w: w, h: 44,
        icon: "", label: label, subtitle: "",
        iconSize: 1, titleSize: 12, subSize: 8,
        bg: m.colors.panel, border: m.colors.whiteLine, textColor: m.colors.textDim, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        row: 0, col: col, page: "", action: action, mode: "row", noFocusShift: true
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
