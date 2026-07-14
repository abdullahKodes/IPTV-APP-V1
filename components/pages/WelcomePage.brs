sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("welcomeCanvas")
    m.plans = entitlementPlans()
    m.focusIndex = 1
    m.mode = "plans"
    m.pendingAction = ""
    m.pendingPlanId = ""
    m.statusTitle = ""
    m.statusMessage = ""
    m.previousFocusIndex = -1
    m.mockTimer = CreateObject("roSGNode", "Timer")
    m.mockTimer.repeat = false
    m.mockTimer.duration = 0.75
    m.mockTimer.observeField("fire", "onMockFlowComplete")
    render()
end sub

sub refreshClock()
end sub

function handleKey(key as String) as Boolean
    if m.mode = "loading" then return true
    if key = "left" then moveWelcomeFocus(-1, 0) : return true
    if key = "right" then moveWelcomeFocus(1, 0) : return true
    if key = "up" then moveWelcomeFocus(0, -1) : return true
    if key = "down" then moveWelcomeFocus(0, 1) : return true
    if key = "OK" then activate() : return true
    if key = "back" then
        if m.mode <> "plans" then
            m.mode = "plans"
            render()
        end if
        return true
    end if
    return true
end function

sub moveWelcomeFocus(dx as Integer, dy as Integer)
    if m.mode <> "plans" then return
    previous = m.focusIndex
    if dy < 0 and m.focusIndex > 0 then m.focusIndex -= 1
    if dy > 0 and m.focusIndex < 3 then m.focusIndex += 1
    if previous <> m.focusIndex then m.previousFocusIndex = previous
    render()
end sub

sub activate()
    if m.mode = "success" then
        if m.pendingPlanId = "trial" then
            m.top.navigateTo = "HomePage"
        else
            m.top.navigateTo = "AddPlaylistPage"
        end if
        return
    end if

    if m.mode = "error" then
        m.mode = "plans"
        render()
        return
    end if

    if m.focusIndex = 3 then
        startMockFlow("restore", "")
        return
    end if

    if m.focusIndex = 0 then
        startMockFlow("purchase", "trial")
    else if m.focusIndex = 1 then
        startMockFlow("purchase", "monthly")
    else if m.focusIndex = 2 then
        startMockFlow("purchase", "annual")
    end if
end sub

sub startMockFlow(action as String, planId as String)
    m.pendingAction = action
    m.pendingPlanId = planId
    m.mode = "loading"
    if action = "restore" then
        m.statusTitle = "Restoring Subscription"
        m.statusMessage = "Checking your Roku account."
    else
        plan = entitlementPlanById(planId)
        m.statusTitle = "Preparing Roku Pay"
        m.statusMessage = "Opening Roku Pay for " + plan.label + "."
    end if
    render()
    m.mockTimer.control = "start"
end sub

sub onMockFlowComplete()
    if m.pendingAction = "restore" then
        entitlementRestoreMock()
        m.statusTitle = "Subscription Restored"
        m.statusMessage = "Your subscription is active."
        m.pendingPlanId = "monthly"
    else
        entitlementActivateMockPlan(m.pendingPlanId)
        plan = entitlementPlanById(m.pendingPlanId)
        if m.pendingPlanId = "trial" then
            m.statusTitle = plan.label + " Ready"
            m.statusMessage = "Your trial is active."
        else
            m.statusTitle = plan.label + " Subscription Ready"
            m.statusMessage = "Your subscription is active."
        end if
    end if
    m.mode = "success"
    render()
end sub

sub render()
    uiClear(m.canvas)
    drawWelcomeBackground()
    if m.mode = "plans" then
        drawPlanSelection()
    else
        drawStatusState()
    end if
end sub

sub drawWelcomeBackground()
    background = uiPoster(m.canvas, "pkg:/images/onboarding/welcome_background_v2.jpg", 0, 0, 1280, 720, 1.0)
    background.loadDisplayMode = "scaleToFill"
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.5)
    uiPoster(m.canvas, "pkg:/images/demo/overlays/detail_left_smoke.png", 0, 0, 900, 720, 1.0)
    uiRect(m.canvas, 760, 0, 520, 720, "0x000000FF", 0.12)
end sub

sub drawWelcomeIntro()
    uiPoster(m.canvas, "pkg:/images/logo_full_dark_modified.png", 112, 36, 190, 64)
end sub

sub drawPlanSelection()
    drawWelcomeIntro()
    uiLabel(m.canvas, "One subscription.", 112, 134, 400, 42, 33, m.colors.text)
    uiLabel(m.canvas, "Unlimited entertainment.", 112, 174, 430, 42, 33, m.colors.text)

    drawWelcomeBenefit(116, 246, "Unlimited Streaming Hours")
    drawWelcomeBenefit(116, 294, "Unlimited Playlist")
    drawWelcomeBenefit(116, 342, "Ad-free Experience")

    drawPlanButton(112, 408, "Free Trial", "trial", 0, m.focusIndex = 0)
    drawPlanButton(112, 478, "Monthly/$1.49", "monthly", 1, m.focusIndex = 1)
    drawPlanButton(112, 548, "Yearly/$5.99", "annual", 2, m.focusIndex = 2)
    drawRestoreButton(147, 634, m.focusIndex = 3)
    m.previousFocusIndex = m.focusIndex
end sub

sub drawWelcomeBenefit(x as Integer, y as Integer, label as String)
    uiPoster(m.canvas, "pkg:/images/ui/scroll_cap_6_greenFocus.png", x + 6, y + 10, 12, 12, 0.95)
    uiScaledLabel(m.canvas, label, x + 36, y - 2, 360, 32, 15, m.colors.textMuted, "left", 0.76)
end sub

sub drawPlanButton(x as Integer, y as Integer, label as String, planId as String, index as Integer, focused as Boolean)
    g = CreateObject("roSGNode", "Group")
    g.id = "welcomePlanButton" + index.toStr()
    g.translation = [x, y]
    if focused then g.translation = [x - 3, y - 3]
    g.scaleRotateCenter = [150, 29]
    m.canvas.appendChild(g)

    artworkUri = "pkg:/images/onboarding/subscription_card_simple.png"

    surfaceUri = "pkg:/images/ui/rr_300x58_panel_panel.png"
    artworkOpacity = 0.58
    surfaceOpacity = 0.9
    textColor = m.colors.text
    tagColor = m.colors.textGreen
    if focused then
        surfaceUri = "pkg:/images/ui/rr_300x58_greenSoft_greenFocus.png"
        artworkOpacity = 0.42
        surfaceOpacity = 0.74
        tagColor = m.colors.text
    end if
    uiPoster(g, surfaceUri, 0, 0, 300, 58, surfaceOpacity)
    uiPoster(g, artworkUri, 8, 5, 284, 48, artworkOpacity)
    uiPoster(g, surfaceUri, 0, 0, 300, 58, surfaceOpacity)
    uiScaledLabel(g, label, 28, 13, 176, 30, 20, textColor, "left", 0.86)

    if planId = "trial" then
        uiScaledLabel(g, "7 DAYS", 206, 18, 74, 14, 8, tagColor, "center", 0.56)
    else
        uiPoster(g, "pkg:/images/ui/rr_92x36_greenSoft_greenFocus.png", 198, 15, 88, 26, 0.78)
        uiScaledLabel(g, "SUBSCRIBE", 198, 20, 88, 14, 8, tagColor, "center", 0.54)
    end if

    if focused and m.previousFocusIndex <> index then uiAnimateActionFocus(m.canvas, g)
end sub

sub drawRestoreButton(x as Integer, y as Integer, focused as Boolean)
    g = CreateObject("roSGNode", "Group")
    g.id = "welcomeRestoreButton"
    g.translation = [x, y]
    if focused then g.translation = [x - 3, y - 3]
    g.scaleRotateCenter = [115, 22]
    m.canvas.appendChild(g)

    uri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    textColor = m.colors.textPurple
    opacity = 0.54
    if focused then
        uri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        textColor = m.colors.text
        opacity = 0.68
    end if
    uiPoster(g, uri, 0, 0, 230, 44, opacity)
    uiScaledLabel(g, "Restore Subscription", 0, 10, 230, 22, 14, textColor, "center", 0.74)

    if focused and m.previousFocusIndex <> 3 then uiAnimateActionFocus(m.canvas, g)
end sub

sub drawStatusState()
    uiPoster(m.canvas, "pkg:/images/logo_full_dark_modified.png", 64, 44, 190, 64)
    uiPoster(m.canvas, "pkg:/images/ui/rr_590x206_panel_whiteLine.png", 375, 230, 530, 260, 0.7)

    if m.mode = "loading" then
        uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", 594, 256, 92, 26, 0.82)
        uiScaledLabel(m.canvas, "Roku Pay", 594, 261, 92, 16, 9, m.colors.text, "center", 0.62)
    else if m.mode = "success" then
        uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", 606, 256, 68, 24, 0.82)
        uiScaledLabel(m.canvas, "Ready", 606, 261, 68, 14, 10, m.colors.text, "center", 0.62)
    else
        uiRoundRect(m.canvas, 613, 252, 54, 54, m.colors.amber, m.colors.amber, 0.82)
        uiLabel(m.canvas, "!", 613, 251, 54, 54, 24, m.colors.black, "center")
    end if

    uiLabel(m.canvas, m.statusTitle, 390, 306, 500, 42, 27, m.colors.text, "center")
    uiScaledLabel(m.canvas, m.statusMessage, 420, 354, 440, 54, 13, m.colors.textMuted, "center", 0.72)

    if m.mode = "loading" then
        uiLabel(m.canvas, "Please wait...", 500, 410, 280, 34, 16, m.colors.textGreen, "center")
    else if m.mode = "success" then
        buttonText = "Continue"
        if m.pendingPlanId <> "trial" then buttonText = "Set Up Playlist"
        buttonW = 144
        buttonX = 568
        if buttonText <> "Continue" then
            buttonW = 184
            buttonX = 548
        end if
        uiPoster(m.canvas, "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png", buttonX, 410, buttonW, 44, 0.78)
        uiScaledLabel(m.canvas, buttonText, buttonX, 420, buttonW, 24, 15, m.colors.text, "center", 0.76)
    else
        uiPoster(m.canvas, "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png", 548, 410, 184, 44, 0.82)
        uiScaledLabel(m.canvas, "Back to Plans", 548, 420, 184, 24, 15, m.colors.text, "center", 0.76)
    end if
end sub

