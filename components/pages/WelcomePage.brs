sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("welcomeCanvas")
    m.focusIndex = 0
    render()
end sub

sub refreshClock()
end sub

function handleKey(key as String) as Boolean
    if key = "up" then
        if m.focusIndex > 0 then m.focusIndex -= 1
        render()
        return true
    end if
    if key = "down" then
        if m.focusIndex < 1 then m.focusIndex += 1
        render()
        return true
    end if
    if key = "OK" then
        activate()
        return true
    end if
    if key = "back" then return true
    return true
end function

sub activate()
    if m.focusIndex = 0 then
        onboardingActivateTrial()
        m.top.navigateTo = "HomePage"
        return
    end if
    onboardingRecordPurchaseIntent()
    m.top.navigateTo = "AddPlaylistPage"
end sub

sub render()
    uiClear(m.canvas)
    background = uiPoster(m.canvas, "pkg:/images/onboarding/welcome_background_v2.jpg", 0, 0, 1280, 720, 1.0)
    background.loadDisplayMode = "scaleToFill"
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.12)
    uiPoster(m.canvas, "pkg:/images/demo/overlays/detail_left_smoke.png", 0, 0, 900, 720, 1.0)

    uiPoster(m.canvas, "pkg:/images/logo_full_dark_modified.png", 64, 46, 190, 64)
    uiLabel(m.canvas, "WELCOME TO IPTV MAX", 66, 130, 520, 46, 30, m.colors.text)
    uiScaledLabel(m.canvas, "Your television, your playlists, one premium experience.", 68, 180, 650, 30, 12, m.colors.textMuted, "left", 0.72)

    drawWelcomeButton(68, 274, "7-Day Free Trial", "Includes the Demo Playlist", 0)
    drawWelcomeButton(68, 364, "Buy Subscription", "Continue to playlist setup", 1)
    uiScaledLabel(m.canvas, "No card information is required for the free trial.", 70, 474, 650, 24, 10, m.colors.textMuted, "left", 0.66)
end sub

sub drawWelcomeButton(x as Integer, y as Integer, title as String, subtitle as String, index as Integer)
    focused = index = m.focusIndex
    surfaceUri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    titleColor = m.colors.text
    subtitleColor = m.colors.textDim
    surfaceOpacity = 0.46

    if focused then
        surfaceUri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        titleColor = m.colors.text
        subtitleColor = m.colors.textMuted
        surfaceOpacity = 0.62
    end if

    uiPoster(m.canvas, surfaceUri, x, y, 380, 72, surfaceOpacity)
    uiScaledLabel(m.canvas, title, x + 36, y + 8, 330, 30, 16, titleColor, "left", 0.92)
    uiScaledLabel(m.canvas, subtitle, x + 37, y + 41, 500, 20, 9, subtitleColor, "left", 0.57)
end sub
