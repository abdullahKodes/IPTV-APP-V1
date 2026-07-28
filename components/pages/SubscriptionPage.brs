sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("subscriptionCanvas")
    m.focusItems = []
    m.focusIndex = 0
    m.status = entitlementStatusLoad()
    m.feedbackTitle = ""
    m.feedbackMessage = ""
    m.recoveryOpen = false
    m.recoveryInput = ""
    m.recoveryMessage = ""
    m.recoveryKeyboardIndex = 0
    m.recoveryTask = invalid
    m.recoveryKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "-", "DEL", "CLEAR", "DONE"]
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
    if m.recoveryOpen then return handleRecoveryCodeKey(key)
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
        openRecoveryCodeFlow()
        return
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
    if m.recoveryOpen then drawRecoveryCodeOverlay()
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
    copy = "Review available plans or restore this account with your recovery code."
    if entitlementBillingUseMock() then copy = "Restore links the backend account by recovery code; plan status remains mocked until backend entitlement is ready."
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
    uiScaledLabel(m.canvas, label, x + 8, y, w - 16, h, 15, textColor, "center", 0.76)
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

sub openRecoveryCodeFlow()
    m.recoveryOpen = true
    m.recoveryInput = ""
    m.recoveryMessage = "Enter the recovery code you saved after purchase."
    m.recoveryKeyboardIndex = 0
    render()
end sub

sub closeRecoveryCodeFlow()
    if m.recoveryTask <> invalid then return
    m.recoveryOpen = false
    m.recoveryInput = ""
    m.recoveryMessage = ""
    render()
end sub

function handleRecoveryCodeKey(key as String) as Boolean
    if m.recoveryTask <> invalid then return true
    cols = 10
    if key = "back" then closeRecoveryCodeFlow() : return true
    nextIndex = uiKeyboardMoveIndex(m.recoveryKeys, m.recoveryKeyboardIndex, key, cols)
    if nextIndex <> m.recoveryKeyboardIndex then m.recoveryKeyboardIndex = nextIndex : render() : return true
    if key = "OK" then pressRecoveryCodeKey() : return true
    return true
end function

sub pressRecoveryCodeKey()
    selected = m.recoveryKeys[m.recoveryKeyboardIndex]
    m.recoveryMessage = ""
    if selected = "DEL" then
        if m.recoveryInput.len() > 0 then m.recoveryInput = Left(m.recoveryInput, m.recoveryInput.len() - 1)
        render()
        return
    end if
    if selected = "CLEAR" then
        m.recoveryInput = ""
        render()
        return
    end if
    if selected = "DONE" then
        submitRecoveryCode()
        return
    end if
    if m.recoveryInput.len() < 64 then m.recoveryInput += selected
    render()
end sub

sub submitRecoveryCode()
    code = cleanSubscriptionRecoveryCode(m.recoveryInput)
    if code = "" then
        m.recoveryMessage = "Recovery code is required."
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.recoveryMessage = "Backend connection is unavailable."
        render()
        return
    end if

    m.recoveryInput = code
    m.recoveryMessage = "Restoring your account..."
    task.observeField("response", "onRecoveryAuthLinked")
    task.request = backendApiRecoverAuthRequest(code)
    m.recoveryTask = task
    render()
    task.control = "RUN"
end sub

sub onRecoveryAuthLinked()
    if m.recoveryTask = invalid then return
    response = m.recoveryTask.response
    m.recoveryTask = invalid

    if backendApiResponseOk(response) then
        backendApiStoreAuthData(backendApiResponseData(response))
        entitlementRestoreMock()
        m.status = entitlementStatusLoad()
        m.recoveryOpen = false
        setSubscriptionFeedback("Account Restored", "Recovery code accepted. Plan status uses mock entitlement until backend subscription status is available.")
        render()
        return
    end if

    m.recoveryMessage = backendApiResponseProblem(response, "Recovery code could not be restored.")
    render()
end sub

sub drawRecoveryCodeOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.88)
    x = 220
    y = 104
    w = 840
    h = 524
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", x, y, w, h, 0.98)
    titleLabel = uiLabel(m.canvas, "Restore with Recovery Code", x + 40, y + 30, w - 80, 38, 24, m.colors.textGreen, "center")
    titleLabel.font.size = 24

    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", x + 80, y + 100, 680, 48, 0.90)
    displayCode = m.recoveryInput
    if displayCode = "" then displayCode = "ABCD-EFGH-JKLM-NPQR"
    codeColor = m.colors.text
    if m.recoveryInput = "" then codeColor = m.colors.textDim
    uiLabel(m.canvas, displayCode, x + 104, y + 108, 632, 32, 17, codeColor, "left")

    if m.recoveryMessage <> "" then
        msgColor = m.colors.textMuted
        lowerMessage = LCase(m.recoveryMessage)
        if Instr(1, lowerMessage, "could not") > 0 or Instr(1, lowerMessage, "required") > 0 or Instr(1, lowerMessage, "unavailable") > 0 then msgColor = m.colors.red
        uiScaledLabel(m.canvas, m.recoveryMessage, x + 70, y + 166, w - 140, 24, 11, msgColor, "center", 0.66)
    end if

    drawRecoveryCodeKeyboard(x + 58, y + 218)
end sub

sub drawRecoveryCodeKeyboard(startX as Integer, startY as Integer)
    keyW = 70
    keyH = 36
    gap = 7
    for i = 0 to m.recoveryKeys.count() - 1
        keyLabel = m.recoveryKeys[i]
        keyRect = uiKeyboardKeyRect(m.recoveryKeys, i, startX, startY, keyW, keyH, gap)
        uiDrawKeyboardKey(m.canvas, keyLabel, uiKeyboardDisplayText(keyLabel, true), keyRect.x, keyRect.y, keyRect.w, keyRect.h, i = m.recoveryKeyboardIndex, m.colors)
    end for
end sub

function cleanSubscriptionRecoveryCode(value as Dynamic) as String
    text = UCase(subscriptionCleanInput(value))
    out = ""
    for i = 1 to text.len()
        ch = Mid(text, i, 1)
        if Instr(1, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-", ch) > 0 then out += ch
    end for
    return out
end function

function subscriptionCleanInput(value as Dynamic) as String
    if value = invalid then return ""
    if Type(value) <> "String" and Type(value) <> "roString" then return ""
    text = value
    while text.len() > 0 and Left(text, 1) = " "
        text = Right(text, text.len() - 1)
    end while
    while text.len() > 0 and Right(text, 1) = " "
        text = Left(text, text.len() - 1)
    end while
    return text
end function

function subscriptionBadgeFill(state as String) as String
    if state = "on_hold" or state = "canceled" then return m.colors.bg2
    if state = "grace" then return m.colors.purpleSoft
    return m.colors.greenSoft
end function

function subscriptionBadgeBorder(state as String) as String
    if state = "on_hold" or state = "canceled" then return m.colors.whiteLine
    return m.colors.greenFocus
end function
