sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("profileCanvas")
    m.rokuPay = m.top.findNode("rokuPayStore")
    m.focusItems = []
    m.focusIndex = 0
    m.settings = settingsStoreLoad()
    m.status = entitlementStatusLoad()
    m.feedbackTitle = ""
    m.feedbackMessage = ""
    m.restoreInProgress = false
    if m.rokuPay <> invalid then m.rokuPay.observeField("purchases", "onProfileRokuPurchasesLoaded")
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
    if m.restoreInProgress then
        if key = "back" then
            m.restoreInProgress = false
            setProfileFeedback("Restore Canceled", "Try Restore Subscription again when ready.")
            render()
        end if
        return true
    end if
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "subscribe" then m.top.navigateTo = "WelcomePage" : return
    if item.action = "restore" then
        startProfileRestoreSubscriptionFlow()
        return
    end if
    m.status = entitlementStatusLoad()
    render()
end sub

sub render()
    m.settings = settingsStoreLoad()
    m.status = entitlementStatusLoad()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.canvas, 0, 86, 1280, 634, m.colors.bg, 0.96)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()
    drawProfileHeader()
    drawProfileSummary()
    drawManageSubscriptionPanel()
    drawProfileFeedback(258, 584)
end sub

function drawProfileSideNav() as Integer
    uiRect(m.canvas, 0, 86, 226, 634, m.colors.panel, 0.66)
    uiRect(m.canvas, 225, 86, 1, 634, "0xFFFFFF14")

    addProfileNavItem(12, 112, "home", "Home", "HomePage", 0, false)
    addProfileNavItem(12, 168, "tv", "Live TV", "LiveTvPage", 1, false)
    addProfileNavItem(12, 224, "series", "Series", "SeriesPage", 2, false)
    addProfileNavItem(12, 280, "movies", "Movies", "MoviesPage", 3, false)
    addProfileNavItem(12, 336, "settings", "Settings", "SettingsPage", 4, false)
    addProfileProfileItem()
    return 6
end function

sub addProfileNavItem(x as Integer, y as Integer, icon as String, label as String, page as String, row as Integer, active as Boolean)
    item = {
        x: x, y: y, w: 204, h: 52,
        icon: icon, label: label, subtitle: "",
        iconSize: 12, titleSize: 12, subSize: 10,
        bg: m.colors.bg, border: m.colors.whiteLine, textColor: m.colors.textPurple, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.42, focusOpacity: 0.66,
        row: row, col: 0, page: page, mode: "row", noFocusShift: true
    }
    if active then
        item.bg = m.colors.purpleSoft
        item.border = m.colors.greenFocus
        item.textColor = m.colors.text
        item.opacity = 0.58
    end if
    m.focusItems.push(item)
end sub

sub addProfileProfileItem()
    item = {
        x: 12, y: 640, w: 204, h: 52,
        icon: "profile", label: "My Profile", subtitle: "",
        iconSize: 14, iconW: 32, iconH: 32, iconX: 18, titleSize: 11, subSize: 7,
        bg: m.colors.purpleSoft, border: m.colors.greenFocus, textColor: m.colors.text, subColor: m.colors.textDim,
        focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: m.colors.text,
        opacity: 0.58, focusOpacity: 0.66,
        row: 5, col: 0, page: "ProfilePage", mode: "row", noFocusShift: true
    }
    m.focusItems.push(item)
end sub

sub drawProfileHeader()
    title = uiLabel(m.canvas, "Profile", 258, 106, 520, 46, 30, m.colors.text)
    title.font.size = 28
end sub

sub drawProfileSummary()
    x = 258
    y = 174
    w = 840
    h = 168
    drawProfilePanel(x, y, w, h, 0.94)

    uiPoster(m.canvas, "pkg:/images/ui/profile_avatar_circle.png", x + 38, y + 39, 90, 90)
    initials = profileInitials(settingsStoreText(m.settings, "userName", "John Doe"))
    initialsLabel = uiLabel(m.canvas, initials, x + 38, y + 39, 90, 90, 32, m.colors.text, "center")
    initialsLabel.font.size = 32

    nameLabel = uiLabel(m.canvas, settingsStoreText(m.settings, "userName", "John Doe"), x + 158, y + 48, 390, 34, 23, m.colors.text)
    nameLabel.font.size = 23
    uiLabel(m.canvas, profilePlanNameLine(), x + 158, y + 86, 390, 28, 16, m.colors.textGreen)

    badge = profileStatusLabel()
    badgeW = 100
    if badge = "Canceled" or badge = "On Hold" or badge = "Restored" then badgeW = 112
    infoX = x + 584
    badgeX = infoX + Int((210 - badgeW) / 2)
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", badgeX, y + 52, badgeW, 34, 0.95)
    uiScaledLabel(m.canvas, badge, badgeX, y + 59, badgeW, 20, 10, m.colors.text, "center", 0.78)
    priceLine = profilePlanPriceLine()
    if priceLine <> "" then uiScaledLabel(m.canvas, priceLine, infoX, y + 94, 210, 28, 12, m.colors.textGreen, "center", 0.74)
end sub

sub drawManageSubscriptionPanel()
    x = 258
    y = 374
    w = 840
    h = 188
    uiPoster(m.canvas, "pkg:/images/ui/profile_panel_840x188_panel_whiteLine.png", x, y, w, h, 0.94)

    uiLabel(m.canvas, "Manage Subscription", x + 34, y + 20, 420, 34, 24, m.colors.textGreen)
    copy = "Review plans or restore a subscription on this Roku account."
    uiScaledLabel(m.canvas, copy, x + 34, y + 62, 700, 28, 11, m.colors.textMuted, "left", 0.72)
    drawProfileAction(x + 34, y + 112, 224, "View Plans", "subscribe", "", 0, 0)
    drawProfileAction(x + 286, y + 112, 276, "Restore Subscription", "restore", "", 0, 1)
end sub

sub drawProfilePanel(x as Integer, y as Integer, w as Integer, h as Integer, opacity as Float)
    uiPoster(m.canvas, "pkg:/images/ui/profile_panel_840x168_panel_whiteLine.png", x, y, w, h, opacity)
end sub

sub drawProfileAction(x as Integer, y as Integer, w as Integer, label as String, action as String, page as String, row as Integer, col as Integer)
    index = m.focusItems.count()
    focused = index = m.focusIndex
    textColor = m.colors.textPurple
    opacity = 0.78
    if focused then
        textColor = m.colors.text
        opacity = 0.92
    end if
    buttonUri = profileButtonUri(w, focused)
    uiPoster(m.canvas, buttonUri, x, y, w, 44, opacity)
    uiScaledLabel(m.canvas, label, x + 12, y, w - 24, 44, 15, textColor, "center", 0.76)
    m.focusItems.push({ x: x, y: y, w: w, h: 44, icon: "", label: label, subtitle: "", iconSize: 1, titleSize: 14, subSize: 10, bg: m.colors.bg2, border: m.colors.bg2, textColor: textColor, subColor: m.colors.textDim, focusBg: m.colors.greenSoft, focusBorder: m.colors.greenFocus, focusTextColor: textColor, row: row, col: col, page: page, action: action, mode: "manual", noFocusShift: true })
end sub

function profileButtonUri(w as Integer, focused as Boolean) as String
    widthKey = "276"
    if w <= 224 then widthKey = "224"
    stateKey = "panel"
    if focused then stateKey = "greenSoft"
    return "pkg:/images/ui/profile_button_" + widthKey + "x44_" + stateKey + "_greenFocus.png"
end function

sub drawProfileFeedback(x as Integer, y as Integer)
    if m.feedbackTitle = "" and m.feedbackMessage = "" then return
    message = m.feedbackTitle
    if m.feedbackMessage <> "" then message += ". " + m.feedbackMessage
    uiScaledLabel(m.canvas, message, x, y, 840, 28, 12, m.colors.textMuted, "left", 0.72)
end sub

sub setProfileFeedback(title as String, message as String)
    m.feedbackTitle = title
    m.feedbackMessage = message
end sub

sub startProfileRestoreSubscriptionFlow()
    currentStatus = entitlementStatusLoad()
    if profileSubscriptionAlreadyActive(currentStatus) then
        setProfileFeedback("Subscription already active", profileActiveSubscriptionMessage(currentStatus))
        render()
        return
    end if

    m.restoreInProgress = true
    setProfileFeedback("Restoring", "Checking Roku Pay purchase history...")
    render()

    if entitlementBillingUseMock() then
        entitlementRestoreMock()
        m.restoreInProgress = false
        m.status = entitlementStatusLoad()
        setProfileFeedback("Subscription restored", profileActiveSubscriptionMessage(m.status))
        render()
        return
    end if

    if m.rokuPay = invalid then
        m.restoreInProgress = false
        setProfileFeedback("Restore Failed", "This Roku build could not open ChannelStore.")
        render()
        return
    end if

    m.rokuPay.command = "getAllPurchases"
end sub

sub onProfileRokuPurchasesLoaded()
    purchases = m.rokuPay.purchases
    m.restoreInProgress = false
    if not profileBillingResultSucceeded(purchases) then
        setProfileFeedback("Restore Failed", profileBillingStatusMessage(purchases, "Roku Pay purchase history is not available."))
        render()
        return
    end if

    purchase = firstValidProfileSubscriptionPurchase(purchases)
    if purchase = invalid then
        setProfileFeedback("No Subscription", "This Roku account does not have an active IPTV MAX subscription.")
        render()
        return
    end if

    planId = entitlementText(entitlementPlanByStoreCode(entitlementNodeText(purchase, "code", "")), "id", "monthly")
    entitlementActivateRokuPurchase(purchase, planId, "restore")
    m.status = entitlementStatusLoad()
    setProfileFeedback("Subscription restored", profileActiveSubscriptionMessage(m.status))
    render()
end sub

function profileInitials(name as String) as String
    if name = invalid or name = "" then return "JD"
    parts = name.Tokenize(" ")
    if parts.count() = 1 then return UCase(Left(parts[0], 2))
    return UCase(Left(parts[0], 1) + Left(parts[1], 1))
end function

function profileSubscriptionLabel(value as String) as String
    if value = invalid or value = "" then return "Demo"
    lower = LCase(value)
    if Instr(1, lower, "trial") > 0 then return "Trial"
    if Instr(1, lower, "demo") > 0 then return "Demo"
    return value
end function

function profileStatusLabel() as String
    entitlement = entitlementStatusLoad()
    entitlementLabel = entitlementProfileLabel(entitlement)
    if entitlementLabel <> "Preview" then return entitlementLabel
    activePlaylist = playlistStoreActive()
    playlistType = playlistStoreText(activePlaylist, "type")
    status = playlistStoreText(activePlaylist, "status")
    if Instr(1, LCase(status), "trial") > 0 then return "Trial"
    subscription = profileSubscriptionLabel(settingsStoreText(m.settings, "subscription", ""))
    if LCase(subscription) = "premium" then return "Premium"
    if status <> "" then return profileSubscriptionLabel(status)
    if subscription <> "" then return subscription
    if playlistType <> "" then return playlistType
    return "Demo"
end function

function profilePlanLine() as String
    status = entitlementStatusLoad()
    planName = entitlementText(status, "planName", "")
    if planName = "" or planName = "No subscription" then return "Plan: No subscription"
    return "Plan: " + planName
end function

function profilePlanNameLine() as String
    status = entitlementStatusLoad()
    state = entitlementText(status, "state", "none")
    if state = "account_restored" then return "No active subscription"
    planName = entitlementText(status, "planName", "")
    if planName = "" or planName = "No subscription" then return "No subscription"
    return planName + " plan"
end function

function profileSubscriptionAlreadyActive(status as Object) as Boolean
    state = entitlementText(status, "state", "none")
    return state = "active" or state = "trial" or state = "grace"
end function

function profileActiveSubscriptionMessage(status as Object) as String
    planName = entitlementText(status, "planName", "")
    if planName = "" or planName = "No subscription" then return "Your subscription is active."
    return planName + " plan is active."
end function

function profilePlanPriceLine() as String
    status = entitlementStatusLoad()
    if not profileSubscriptionAlreadyActive(status) then return ""
    price = entitlementText(status, "price", "")
    term = entitlementText(status, "billingTerm", "")
    if price = "" then return ""
    if term <> "" then return price + " " + term
    return price
end function

function profileBillingResultSucceeded(result as Object) as Boolean
    return profileBillingStatusCode(result) = 1
end function

function profileBillingStatusCode(result as Object) as Integer
    if result <> invalid and result.hasField("status") and result.status <> invalid then return Int(result.status)
    return -3
end function

function profileBillingStatusMessage(result as Object, fallback as String) as String
    if result <> invalid and result.hasField("statusMessage") and result.statusMessage <> invalid and result.statusMessage <> "" then return result.statusMessage
    return fallback
end function

function firstValidProfileSubscriptionPurchase(purchases as Object) as Object
    if purchases = invalid then return invalid
    for i = 0 to purchases.getChildCount() - 1
        purchase = purchases.getChild(i)
        code = entitlementNodeText(purchase, "code", "")
        if isKnownProfileSubscriptionCode(code) then
            status = LCase(entitlementNodeText(purchase, "status", "Valid"))
            inDunning = LCase(entitlementNodeText(purchase, "inDunning", "false"))
            if status = "valid" or inDunning = "true" then return purchase
        end if
    end for
    return invalid
end function

function isKnownProfileSubscriptionCode(code as String) as Boolean
    if code = "" then return false
    config = entitlementBillingConfig()
    return code = config.monthlyCode or code = config.annualCode or code = config.trialCode
end function
