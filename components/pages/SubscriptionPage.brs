sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("subscriptionCanvas")
    m.focusItems = []
    m.focusIndex = 0
    m.status = entitlementStatusLoad()
    m.feedbackTitle = ""
    m.feedbackMessage = ""
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
    if key = "back" then return false
    return false
end function

sub move(dx as Integer, dy as Integer)
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    action = m.focusItems[m.focusIndex].action
    if action = "subscribe" then m.top.navigateTo = "WelcomePage" : return
    if action = "restore" then
        entitlementRestoreMock()
        setSubscriptionFeedback("Restore simulated", "Monthly access is active in Roku Pay test mode.")
    end if
    m.status = entitlementStatusLoad()
    render()
end sub

sub setSubscriptionFeedback(title as String, message as String)
    m.feedbackTitle = title
    m.feedbackMessage = message
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
    drawFeedback()
end sub

sub drawSubscriptionHeader()
    title = uiLabel(m.canvas, "Manage Subscription", 300, 98, 620, 56, 28, m.colors.text)
    title.font.size = 28
end sub

sub drawStatusPanel()
    x = 300
    y = 184
    uiPoster(m.canvas, "pkg:/images/ui/rr_720x168_panel_whiteLine.png", x, y, 720, 168, 0.94)
    badge = entitlementProfileLabel(m.status)
    badgeW = 100
    if badge = "Canceled" or badge = "On Hold" then badgeW = 112
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", x + 34, y + 28, badgeW, 34, 0.95)
    uiScaledLabel(m.canvas, badge, x + 34, y + 35, badgeW, 20, 10, m.colors.text, "center", 0.78)

    uiLabel(m.canvas, entitlementStatusTitle(m.status), x + 34, y + 82, 300, 36, 24, m.colors.text)
    uiScaledLabel(m.canvas, entitlementText(m.status, "message", ""), x + 34, y + 120, 360, 24, 9, m.colors.textDim, "left", 0.66)

    uiLabel(m.canvas, entitlementText(m.status, "planName", "No subscription"), x + 460, y + 34, 210, 30, 18, m.colors.text, "right")
    uiLabel(m.canvas, entitlementText(m.status, "price", ""), x + 460, y + 66, 210, 30, 18, m.colors.textGreen, "right")
    uiScaledLabel(m.canvas, entitlementText(m.status, "renewsAt", "Not active"), x + 380, y + 104, 290, 28, 9, m.colors.textDim, "right", 0.66)
    modeLabel = "Roku Pay test mode"
    if not entitlementBillingUseMock() then modeLabel = "Roku Pay live mode"
    uiScaledLabel(m.canvas, modeLabel, x + 420, y + 132, 250, 22, 9, m.colors.textMuted, "right", 0.66)
end sub

sub drawActionPanel()
    x = 300
    y = 382
    panelH = 202
    uiPoster(m.canvas, "pkg:/images/ui/rr_720x218_panel_whiteLine.png", x, y, 720, panelH, 0.94)
    uiLabel(m.canvas, "Account Actions", x + 34, y + 22, 300, 34, 24, m.colors.textGreen)
    copy = "Review available plans and update your access from the plan screen."
    if entitlementBillingUseMock() then copy = "Restore uses local test mode until Roku Product Catalog and payout setup are ready."
    uiScaledLabel(m.canvas, copy, x + 34, y + 68, 620, 42, 11, m.colors.textMuted, "left", 0.72)
    drawSubscriptionAction(x + 34, y + 126, 190, "View Plans", "subscribe", 0, 0)

    if entitlementBillingUseMock() then
        drawSubscriptionAction(x + 242, y + 126, 190, "Restore", "restore", 0, 1)
    end if
end sub

sub drawSubscriptionAction(x as Integer, y as Integer, w as Integer, label as String, action as String, row as Integer, col as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    surfaceUri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    textColor = m.colors.textPurple
    opacity = 0.62
    if focused then
        surfaceUri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        textColor = m.colors.text
        opacity = 0.58
    end if
    h = 44
    uiPoster(m.canvas, surfaceUri, x, y, w, h, opacity)
    uiScaledLabel(m.canvas, label, x + 8, y + 10, w - 16, 24, 15, textColor, "center", 0.76)
    m.focusItems.push({ x: x, y: y, w: w, h: h, row: row, col: col, action: action, mode: "manual" })
end sub

sub drawFeedback()
    if m.feedbackTitle = "" and m.feedbackMessage = "" then return
    x = 300
    y = 646
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", x + 2, y, 128, 28, 0.82)
    uiScaledLabel(m.canvas, m.feedbackTitle, x + 2, y + 6, 128, 16, 9, m.colors.text, "center", 0.62)
    uiScaledLabel(m.canvas, m.feedbackMessage, x + 144, y + 3, 560, 24, 11, m.colors.textMuted, "left", 0.72)
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
