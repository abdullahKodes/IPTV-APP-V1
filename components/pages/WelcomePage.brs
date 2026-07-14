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

    plan = m.plans[m.focusIndex]
    startMockFlow("purchase", plan.id)
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
    uiRect(m.canvas, 0, 0, 1280, 720, "0x000000FF", 0.2)
    uiPoster(m.canvas, "pkg:/images/demo/overlays/detail_left_smoke.png", 0, 0, 900, 720, 0.96)
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.18)
end sub

sub drawWelcomeIntro()
    uiPoster(m.canvas, "pkg:/images/logo_full_dark_modified.png", 64, 44, 190, 64)
    uiLabel(m.canvas, "IPTV MAX", 66, 130, 460, 52, 34, m.colors.text)
    uiScaledLabel(m.canvas, "Premium playlist access, managed through Roku billing.", 68, 186, 520, 34, 13, m.colors.textMuted, "left", 0.72)

    drawWelcomeStep(70, 288, "1", "Choose a plan")
    drawWelcomeStep(70, 346, "2", "Confirm with Roku Pay")
    drawWelcomeStep(70, 404, "3", "Connect your playlist")
    uiScaledLabel(m.canvas, "Roku handles payment prompts. IPTV MAX only stores account access after entitlement validation.", 70, 502, 560, 38, 11, m.colors.textDim, "left", 0.66)
end sub

sub drawWelcomeStep(x as Integer, y as Integer, num as String, label as String)
    uiRoundRect(m.canvas, x, y, 34, 34, m.colors.green, m.colors.green, 0.72)
    uiLabel(m.canvas, num, x, y - 1, 34, 34, 14, m.colors.black, "center")
    uiLabel(m.canvas, label, x + 50, y - 2, 300, 36, 17, m.colors.text)
end sub

sub drawPlanSelection()
    drawWelcomeIntro()
    uiRect(m.canvas, 650, 110, 1, 500, "0xFFFFFF18", 0.34)
    uiScaledLabel(m.canvas, "Select Access", 790, 88, 330, 42, 25, m.colors.text, "left", 0.86)
    uiScaledLabel(m.canvas, "Mock catalog for frontend testing", 792, 130, 330, 28, 10, m.colors.textDim, "left", 0.68)

    startY = 174
    for i = 0 to m.plans.count() - 1
        drawPlanCard(790, startY + (i * 124), m.plans[i], i, i = m.focusIndex)
    end for

    drawRestoreButton(824, 570, m.focusIndex = 3)
    m.previousFocusIndex = m.focusIndex
end sub

sub drawPlanCard(x as Integer, y as Integer, plan as Object, index as Integer, focused as Boolean)
    g = CreateObject("roSGNode", "Group")
    g.id = "welcomePlan" + index.toStr()
    g.translation = [x, y]
    m.canvas.appendChild(g)

    surfaceUri = "pkg:/images/ui/rr_365x112_panel_panel.png"
    opacity = 0.94
    titleColor = m.colors.text
    metaColor = m.colors.textDim
    if focused then
        surfaceUri = "pkg:/images/ui/rr_365x112_greenSoft_greenFocus.png"
        opacity = 0.82
        titleColor = m.colors.text
        metaColor = m.colors.textGreen
    end if

    textureOpacity = 0.48
    if focused then textureOpacity = 0.58
    uiPosterZoom(g, "pkg:/images/onboarding/welcome_background_v2.jpg", 48, 8, 224, 92, textureOpacity)
    uiPoster(g, surfaceUri, 0, 0, 300, 108, opacity)
    badgeW = 56
    if plan.badge.len() > 5 then badgeW = 74
    uiPoster(g, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", 22, 16, badgeW, 24, 0.72)
    uiScaledLabel(g, plan.badge, 22, 21, badgeW, 16, 7, m.colors.text, "center", 0.56)
    uiLabel(g, plan.label, 22, 52, 148, 32, 25, titleColor)
    uiLabel(g, plan.price, 166, 24, 106, 30, 24, m.colors.text, "right")
    uiLabel(g, plan.billingTerm, 150, 68, 122, 24, 14, metaColor, "right")

    if focused and m.previousFocusIndex <> index then uiAnimateActionFocus(m.canvas, g)
end sub

sub drawRestoreButton(x as Integer, y as Integer, focused as Boolean)
    g = CreateObject("roSGNode", "Group")
    g.id = "welcomeRestoreButton"
    g.translation = [x, y]
    m.canvas.appendChild(g)

    uri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    textColor = m.colors.textPurple
    opacity = 0.84
    if focused then
        uri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        textColor = m.colors.text
        opacity = 0.72
    end if
    uiPoster(g, uri, 0, 0, 230, 44, opacity)
    uiScaledLabel(g, "Restore Subscription", 0, 10, 230, 24, 15, textColor, "center", 0.76)

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
