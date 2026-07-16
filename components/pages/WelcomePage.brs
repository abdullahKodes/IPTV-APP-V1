sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("welcomeCanvas")
    m.rokuPay = m.top.findNode("rokuPayStore")
    m.billingConfig = entitlementBillingConfig()
    m.plans = entitlementPlans()
    m.focusIndex = 0
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
    if m.rokuPay <> invalid then
        m.rokuPay.observeField("catalog", "onRokuCatalogLoaded")
        m.rokuPay.observeField("orderStatus", "onRokuOrderComplete")
        m.rokuPay.observeField("purchases", "onRokuPurchasesLoaded")
    end if
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
        startBillingFlow("restore", "")
        return
    end if

    if m.focusIndex = 0 then
        startBillingFlow("purchase", "trial")
    else if m.focusIndex = 1 then
        startBillingFlow("purchase", "monthly")
    else if m.focusIndex = 2 then
        startBillingFlow("purchase", "annual")
    end if
end sub

sub startBillingFlow(action as String, planId as String)
    if entitlementBillingUseMock() then
        startMockFlow(action, planId)
        return
    end if

    startRokuPayFlow(action, planId)
end sub

sub startMockFlow(action as String, planId as String)
    m.pendingAction = action
    m.pendingPlanId = planId
    m.mode = "loading"
    if action = "restore" then
        m.statusTitle = "Restoring Subscription"
        m.statusMessage = "Checking your Roku account in test mode."
    else
        plan = entitlementPlanById(planId)
        m.statusTitle = "Roku Pay Test Mode"
        m.statusMessage = "Preparing " + plan.label + " with placeholder product IDs."
    end if
    render()
    m.mockTimer.control = "start"
end sub

sub startRokuPayFlow(action as String, planId as String)
    if m.rokuPay = invalid then
        showBillingError("Roku Pay Unavailable", "This Roku build could not open ChannelStore.")
        return
    end if

    m.pendingAction = action
    m.pendingPlanId = planId
    m.mode = "loading"

    if action = "restore" then
        m.statusTitle = "Restoring Subscription"
        m.statusMessage = "Checking Roku Pay purchase history."
        render()
        m.rokuPay.command = "getAllPurchases"
    else
        plan = entitlementPlanById(planId)
        m.statusTitle = "Checking Roku Pay"
        m.statusMessage = "Looking for " + plan.label + " in the Roku Pay catalog."
        render()
        m.rokuPay.command = "getCatalog"
    end if
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

sub onRokuCatalogLoaded()
    catalog = m.rokuPay.catalog
    if not billingResultSucceeded(catalog) then
        showBillingError("Catalog Unavailable", billingStatusMessage(catalog, "Roku Pay products are not ready yet."))
        return
    end if

    code = entitlementPlanStoreCode(m.pendingPlanId)
    if code = "" or not catalogContainsCode(catalog, code) then
        showBillingError("Product Not Found", "The Roku Pay product ID is not linked to this app yet.")
        return
    end if

    order = CreateObject("roSGNode", "ContentNode")
    item = order.createChild("ContentNode")
    item.addFields({ code: code, qty: 1 })
    m.rokuPay.order = order
    plan = entitlementPlanById(m.pendingPlanId)
    m.statusTitle = "Opening Roku Pay"
    m.statusMessage = "Confirm " + plan.label + " on the Roku Pay screen."
    render()
    m.rokuPay.command = "doOrder"
end sub

sub onRokuOrderComplete()
    orderStatus = m.rokuPay.orderStatus
    if not billingResultSucceeded(orderStatus) then
        if billingStatusCode(orderStatus) = 2 then
            showBillingError("Purchase Canceled", "Roku Pay was closed before the subscription was completed.")
        else
            showBillingError("Purchase Failed", billingStatusMessage(orderStatus, "Roku Pay could not complete this purchase."))
        end if
        return
    end if

    purchase = firstBillingChild(orderStatus)
    entitlementActivateRokuPurchase(purchase, m.pendingPlanId, "purchase")
    plan = entitlementPlanById(m.pendingPlanId)
    m.statusTitle = plan.label + " Subscription Ready"
    if m.pendingPlanId = "trial" then m.statusTitle = plan.label + " Ready"
    m.statusMessage = entitlementText(entitlementStatusLoad(), "message", "Your subscription is active.")
    m.mode = "success"
    render()
end sub

sub onRokuPurchasesLoaded()
    purchases = m.rokuPay.purchases
    if not billingResultSucceeded(purchases) then
        showBillingError("Restore Failed", billingStatusMessage(purchases, "Roku Pay purchase history is not available."))
        return
    end if

    purchase = firstValidEntitlementPurchase(purchases)
    if purchase = invalid then
        showBillingError("No Subscription Found", "This Roku account does not have an active IPTV MAX subscription.")
        return
    end if

    entitlementActivateRokuPurchase(purchase, entitlementText(entitlementPlanByStoreCode(entitlementNodeText(purchase, "code", "")), "id", "monthly"), "restore")
    restored = entitlementStatusLoad()
    m.pendingPlanId = entitlementText(restored, "planId", "monthly")
    m.statusTitle = "Subscription Restored"
    m.statusMessage = entitlementText(restored, "message", "Your subscription is active.")
    m.mode = "success"
    render()
end sub

sub showBillingError(title as String, message as String)
    m.statusTitle = title
    m.statusMessage = message
    m.mode = "error"
    render()
end sub

function billingResultSucceeded(result as Object) as Boolean
    return billingStatusCode(result) = 1
end function

function billingStatusCode(result as Object) as Integer
    if result <> invalid and result.hasField("status") and result.status <> invalid then return Int(result.status)
    return -3
end function

function billingStatusMessage(result as Object, fallback as String) as String
    if result <> invalid and result.hasField("statusMessage") and result.statusMessage <> invalid and result.statusMessage <> "" then return result.statusMessage
    return fallback
end function

function catalogContainsCode(catalog as Object, code as String) as Boolean
    if catalog = invalid or code = "" then return false
    for i = 0 to catalog.getChildCount() - 1
        item = catalog.getChild(i)
        if entitlementNodeText(item, "code", "") = code then return true
    end for
    return false
end function

function firstBillingChild(result as Object) as Object
    if result <> invalid and result.getChildCount() > 0 then return result.getChild(0)
    return invalid
end function

function firstValidEntitlementPurchase(purchases as Object) as Object
    if purchases = invalid then return invalid
    for i = 0 to purchases.getChildCount() - 1
        purchase = purchases.getChild(i)
        code = entitlementNodeText(purchase, "code", "")
        if isKnownSubscriptionCode(code) then
            status = LCase(entitlementNodeText(purchase, "status", "Valid"))
            inDunning = LCase(entitlementNodeText(purchase, "inDunning", "false"))
            if status = "valid" or inDunning = "true" then return purchase
        end if
    end for
    return invalid
end function

function isKnownSubscriptionCode(code as String) as Boolean
    if code = "" then return false
    config = entitlementBillingConfig()
    return code = config.monthlyCode or code = config.annualCode or code = config.trialCode
end function

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
    uiLabel(m.canvas, "One account.", 112, 126, 400, 42, 33, m.colors.text)
    uiLabel(m.canvas, "Unlimited entertainment.", 112, 164, 430, 42, 33, m.colors.text)

    drawWelcomeBenefit(116, 236, "Unlimited streaming hours for live TV and VOD")
    drawWelcomeBenefit(116, 284, "Unlimited playlist access under one profile")
    drawWelcomeBenefit(116, 332, "Ad-free premium experience after activation")

    drawPlanButton(112, 388, "7 Days", "Free Trial", 0, m.focusIndex = 0)
    drawPlanButton(112, 458, "Monthly", "$3.49", 1, m.focusIndex = 1)
    drawPlanButton(112, 528, "Yearly", "$12.99", 2, m.focusIndex = 2)
    drawRestoreButton(147, 614, m.focusIndex = 3)
    m.previousFocusIndex = m.focusIndex
end sub

sub drawWelcomeBenefit(x as Integer, y as Integer, label as String)
    uiPoster(m.canvas, "pkg:/images/ui/scroll_cap_6_greenFocus.png", x + 6, y + 10, 12, 12, 0.95)
    uiScaledLabel(m.canvas, label, x + 36, y - 2, 440, 32, 15, m.colors.textMuted, "left", 0.74)
end sub

sub drawPlanButton(x as Integer, y as Integer, leftLabel as String, rightLabel as String, index as Integer, focused as Boolean)
    g = CreateObject("roSGNode", "Group")
    g.id = "welcomePlanButton" + index.toStr()
    g.translation = [x, y]
    if focused then g.translation = [x - 3, y - 3]
    g.scaleRotateCenter = [150, 29]
    m.canvas.appendChild(g)

    artworkUri = "pkg:/images/onboarding/subscription_card_simple.png"

    surfaceUri = "pkg:/images/ui/rr_300x58_panel_panel.png"
    artworkOpacity = 0.72
    surfaceOpacity = 0.76
    topSurfaceOpacity = 0.28
    textColor = m.colors.text
    if focused then
        surfaceUri = "pkg:/images/ui/rr_300x58_greenSoft_greenFocus.png"
        artworkOpacity = 0.46
        surfaceOpacity = 0.52
        topSurfaceOpacity = 0.42
    end if
    uiPoster(g, surfaceUri, 0, 0, 300, 58, surfaceOpacity)
    uiPoster(g, artworkUri, 2, 2, 296, 54, artworkOpacity)
    uiPoster(g, surfaceUri, 0, 0, 300, 58, topSurfaceOpacity)
    uiScaledLabel(g, leftLabel, 28, 13, 128, 30, 20, textColor, "left", 0.86)
    uiScaledLabel(g, rightLabel, 152, 13, 120, 30, 20, textColor, "right", 0.86)

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

