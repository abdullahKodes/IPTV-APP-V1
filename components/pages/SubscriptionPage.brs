sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("subscriptionCanvas")
    m.focusItems = []
    m.focusIndex = 0
    m.status = entitlementStatusLoad()
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
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    if key = "back" then m.top.navigateTo = "ProfilePage" : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    action = m.focusItems[m.focusIndex].action
    if action = "restore" then entitlementRestoreMock()
    if action = "monthly" then entitlementActivateMockPlan("monthly")
    if action = "annual" then entitlementActivateMockPlan("annual")
    if action = "grace" then entitlementSetMockState("grace")
    if action = "hold" then entitlementSetMockState("on_hold")
    if action = "cancel" then entitlementSetMockState("canceled")
    if action = "subscribe" then m.top.navigateTo = "WelcomePage" : return
    if action = "profile" then m.top.navigateTo = "ProfilePage" : return
    m.status = entitlementStatusLoad()
    render()
end sub

sub render()
    m.status = entitlementStatusLoad()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.canvas, 0, 86, 1280, 634, m.colors.bg, 0.96)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    drawSubscriptionHeader()
    drawStatusPanel()
    drawActionPanel()
    drawStatePanel()
end sub

sub drawSubscriptionHeader()
    uiLabel(m.canvas, "Subscription", 300, 88, 520, 70, 46, m.colors.text)
end sub

sub drawStatusPanel()
    x = 300
    y = 184
    uiRoundRect(m.canvas, x, y, 680, 168, m.colors.panel, m.colors.whiteLine, 0.94)
    badge = entitlementProfileLabel(m.status)
    badgeW = subscriptionBadgeWidth(badge)
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", x + 34, y + 34, badgeW, 24, 0.8)
    uiScaledLabel(m.canvas, badge, x + 34, y + 39, badgeW, 14, 8, m.colors.text, "center", 0.58)

    uiLabel(m.canvas, entitlementStatusTitle(m.status), x + 34, y + 82, 300, 36, 24, m.colors.text)

    uiLabel(m.canvas, entitlementText(m.status, "planName", "No subscription"), x + 410, y + 34, 210, 30, 18, m.colors.text, "right")
    uiLabel(m.canvas, entitlementText(m.status, "price", ""), x + 410, y + 66, 210, 30, 18, m.colors.textGreen, "right")
    uiScaledLabel(m.canvas, entitlementText(m.status, "renewsAt", "Not active"), x + 330, y + 104, 290, 28, 9, m.colors.textDim, "right", 0.66)
end sub

sub drawActionPanel()
    x = 300
    y = 390
    uiPoster(m.canvas, "pkg:/images/ui/rr_680x236_panel_whiteLine.png", x, y, 680, 194, 0.94)
    uiLabel(m.canvas, "Account Actions", x + 90, y + 20, 260, 34, 22, m.colors.textGreen)
    drawSubscriptionAction(x + 90, y + 70, 148, "Restore", "restore", 0, 0)
    drawSubscriptionAction(x + 400, y + 70, 166, "Subscribe", "subscribe", 0, 1)
    drawSubscriptionAction(x + 90, y + 130, 148, "Monthly", "monthly", 1, 0)
    drawSubscriptionAction(x + 400, y + 130, 138, "Annual", "annual", 1, 1)
end sub

sub drawStatePanel()
    x = 1010
    y = 184
    uiPoster(m.canvas, "pkg:/images/ui/rr_210x320_panel_panel.png", x, y, 210, 260, 0.94)
    uiScaledLabel(m.canvas, "Review States", x + 20, y + 20, 170, 34, 18, m.colors.text, "center", 0.78)
    drawSubscriptionAction(x + 48, y + 76, 114, "Grace", "grace", 0, 2)
    drawSubscriptionAction(x + 42, y + 134, 126, "On Hold", "hold", 1, 2)
    drawSubscriptionAction(x + 36, y + 192, 138, "Canceled", "cancel", 2, 2)
end sub

sub drawSubscriptionAction(x as Integer, y as Integer, w as Integer, label as String, action as String, row as Integer, col as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    surfaceUri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    textColor = m.colors.textPurple
    opacity = 0.76
    if focused then
        surfaceUri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        textColor = m.colors.text
        opacity = 0.82
    end if
    h = 44
    uiPoster(m.canvas, surfaceUri, x, y, w, h, opacity)
    uiScaledLabel(m.canvas, label, x + 8, y + 10, w - 16, 24, 15, textColor, "center", 0.76)
    m.focusItems.push({ x: x, y: y, w: w, h: h, row: row, col: col, action: action, mode: "manual" })
end sub

function subscriptionBadgeFill(state as String) as String
    if state = "on_hold" or state = "canceled" then return m.colors.bg2
    if state = "grace" then return m.colors.purpleSoft
    return m.colors.greenSoft
end function

function subscriptionBadgeBorder(state as String) as String
    if state = "on_hold" or state = "canceled" then return m.colors.whiteLine
    return m.colors.greenFocus
end function

function subscriptionBadgeWidth(label as String) as Integer
    if label = "Trial" then return 62
    if label = "Premium" then return 82
    if label = "Grace" then return 68
    if label = "On Hold" then return 82
    if label = "Canceled" then return 86
    return 76
end function
