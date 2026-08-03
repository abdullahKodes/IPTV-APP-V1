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
    m.confirmFocusIndex = 0
    m.recoveryCode = ""
    m.recoverySource = ""
    m.authTask = invalid
    m.recoveryConfirmDialog = invalid
    m.restoreInput = ""
    m.restoreMessage = ""
    m.restoreKeyboardIndex = 0
    m.restoreTask = invalid
    m.restoreKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "-", "DEL", "CLEAR", "DONE"]
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
    if m.mode = "confirm" then return handlePlanConfirmKey(key)
    if m.mode = "recovery" then return handleRecoveryPageKey(key)
    if m.mode = "restore" then return handleRestoreCodeKey(key)
    if key = "left" then moveWelcomeFocus(-1, 0) : return true
    if key = "right" then moveWelcomeFocus(1, 0) : return true
    if key = "up" then moveWelcomeFocus(0, -1) : return true
    if key = "down" then moveWelcomeFocus(0, 1) : return true
    if key = "OK" then activate() : return true
    if key = "back" then
        if m.mode <> "plans" then
            m.mode = "plans"
            render()
            return true
        end if
        return false
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
        openRestoreCodeFlow()
        return
    end if

    if m.focusIndex = 0 then
        openPlanConfirm("trial")
    else if m.focusIndex = 1 then
        openPlanConfirm("monthly")
    else if m.focusIndex = 2 then
        openPlanConfirm("annual")
    end if
end sub

sub openPlanConfirm(planId as String)
    m.pendingAction = "purchase"
    m.pendingPlanId = planId
    m.confirmFocusIndex = 0
    m.mode = "confirm"
    render()
end sub

function handlePlanConfirmKey(key as String) as Boolean
    if key = "back" then
        closePlanConfirm()
        return true
    end if
    if key = "left" or key = "right" or key = "up" or key = "down" then
        m.confirmFocusIndex = 1 - m.confirmFocusIndex
        render()
        return true
    end if
    if key = "OK" then
        if m.confirmFocusIndex = 0 then
            startBillingFlow("purchase", m.pendingPlanId)
        else
            closePlanConfirm()
        end if
        return true
    end if
    return true
end function

sub closePlanConfirm()
    m.mode = "plans"
    m.pendingAction = ""
    m.pendingPlanId = ""
    m.confirmFocusIndex = 0
    render()
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
        m.statusMessage = ""
    else
        plan = entitlementPlanById(planId)
        m.statusTitle = "Starting Subscription"
        m.statusMessage = ""
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
        m.statusMessage = ""
        render()
        m.rokuPay.command = "getAllPurchases"
    else
        plan = entitlementPlanById(planId)
        m.statusTitle = "Opening Roku Pay"
        m.statusMessage = ""
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
        m.mode = "success"
    else
        entitlementActivateMockPlan(m.pendingPlanId)
        plan = entitlementPlanById(m.pendingPlanId)
        if m.pendingPlanId = "trial" then
            m.statusTitle = plan.label + " Ready"
            m.statusMessage = "Your trial is active."
            m.mode = "success"
        else
            m.statusTitle = plan.label + " Subscription Ready"
            m.statusMessage = ""
            beginRecoveryCodeSetup()
            return
        end if
    end if
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
    if m.pendingPlanId <> "trial" then
        beginRecoveryCodeSetup()
        return
    end if
    m.mode = "success"
    render()
end sub

sub beginRecoveryCodeSetup()
    m.recoveryCode = storedRecoveryCode()
    m.recoverySource = "backend"
    if m.recoveryCode <> "" then
        m.mode = "recovery"
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        showBillingError("Recovery Code Unavailable", "Account service is unavailable.")
        return
    end if

    m.authTask = task
    m.mode = "loading"
    m.statusTitle = "Setting Up"
    m.statusMessage = ""
    task.observeField("response", "onAnonymousAuthCreated")
    task.request = backendApiAnonymousAuthRequest()
    render()
    task.control = "RUN"
end sub

sub onAnonymousAuthCreated()
    if m.authTask = invalid then return
    response = m.authTask.response
    m.authTask = invalid

    if backendApiResponseOk(response) then
        data = backendApiResponseData(response)
        backendApiStoreAuthData(data)
        m.recoveryCode = backendApiText(data, "recovery_code")
        m.recoverySource = "backend"
        if m.recoveryCode = "" then m.recoveryCode = storedRecoveryCode()
        if m.recoveryCode <> "" then
            m.mode = "recovery"
            render()
            return
        end if
    end if

    showBillingError("Recovery Code Unavailable", backendApiResponseProblem(response, "Recovery code could not be created."))
end sub

function handleRecoveryPageKey(key as String) as Boolean
    if key = "OK" then openRecoveryConfirmDialog() : return true
    if key = "back" then
        m.mode = "plans"
        render()
        return true
    end if
    return true
end function

sub openRecoveryConfirmDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Did you save your recovery code?"
    dialog.message = "You need this code if the app is removed or installed again. Choose Yes only after you have noted it."
    dialog.buttons = ["No", "Yes"]
    dialog.observeField("buttonSelected", "onRecoveryConfirmButton")
    m.recoveryConfirmDialog = dialog
    m.top.getScene().dialog = dialog
end sub

sub onRecoveryConfirmButton()
    if m.recoveryConfirmDialog = invalid then return
    selected = m.recoveryConfirmDialog.buttonSelected
    m.top.getScene().dialog = invalid
    m.recoveryConfirmDialog = invalid
    if selected = 1 then
        m.top.navigateTo = "AddPlaylistPage"
    else
        m.mode = "recovery"
        render()
    end if
end sub

sub openRestoreCodeFlow()
    m.mode = "restore"
    m.pendingAction = "restoreAccount"
    m.pendingPlanId = ""
    m.restoreInput = ""
    m.restoreMessage = "Enter the recovery code saved for this account."
    m.restoreKeyboardIndex = 0
    m.uiKeyboardReturnTargetIndex = -1
    m.uiKeyboardReturnSourceIndex = -1
    render()
end sub

function handleRestoreCodeKey(key as String) as Boolean
    if m.restoreTask <> invalid then return true
    if key = "back" then m.mode = "plans" : render() : return true
    nextIndex = restoreKeyboardMoveIndex(m.restoreKeyboardIndex, key)
    if nextIndex <> m.restoreKeyboardIndex then m.restoreKeyboardIndex = nextIndex : render() : return true
    if key = "OK" then pressRestoreCodeKey() : return true
    return true
end function

sub pressRestoreCodeKey()
    selected = m.restoreKeys[m.restoreKeyboardIndex]
    m.restoreMessage = ""
    if selected = "DEL" then
        if m.restoreInput.len() > 0 then m.restoreInput = Left(m.restoreInput, m.restoreInput.len() - 1)
        render()
        return
    end if
    if selected = "CLEAR" then
        m.restoreInput = ""
        render()
        return
    end if
    if selected = "DONE" then
        submitRestoreCode()
        return
    end if
    if m.restoreInput.len() < 64 then m.restoreInput += selected
    render()
end sub

sub submitRestoreCode()
    code = cleanWelcomeRecoveryCode(m.restoreInput)
    if code = "" then
        m.restoreMessage = "Recovery code is required."
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.restoreMessage = "Account service is unavailable."
        render()
        return
    end if

    m.restoreInput = code
    m.restoreMessage = ""
    m.statusTitle = "Restoring Account"
    m.statusMessage = ""
    m.mode = "loading"
    task.observeField("response", "onRestoreAuthLinked")
    task.request = backendApiRecoverAuthRequest(code)
    m.restoreTask = task
    render()
    task.control = "RUN"
end sub

sub onRestoreAuthLinked()
    if m.restoreTask = invalid then return
    response = m.restoreTask.response
    m.restoreTask = invalid

    if backendApiResponseOk(response) then
        data = backendApiResponseData(response)
        if backendApiText(data, "access_token") <> "" then
            backendApiStoreAuthData(data)
            entitlementMarkAccountRestored()
            m.top.navigateTo = "HomePage"
            return
        end if
    end if

    m.mode = "restore"
    m.restoreMessage = backendApiResponseProblem(response, "Recovery code could not restore this account.")
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
    else if m.mode = "confirm" then
        drawPlanConfirmState()
    else if m.mode = "recovery" then
        drawRecoveryCodeState()
    else if m.mode = "restore" then
        drawRestoreCodeState()
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
    uiScaledLabel(g, "Restore Account", 0, 0, 230, 44, 14, textColor, "center", 0.74)

    if focused and m.previousFocusIndex <> 3 then uiAnimateActionFocus(m.canvas, g)
end sub

sub drawPlanConfirmState()
    uiPoster(m.canvas, "pkg:/images/logo_full_dark_modified.png", 64, 44, 190, 64)
    plan = entitlementPlanById(m.pendingPlanId)
    x = 340
    y = 204
    w = 600
    h = 276
    uiPoster(m.canvas, "pkg:/images/ui/rr_590x206_panel_whiteLine.png", x, y, w, h, 0.82)
    badgeLabel = "Confirm"
    badgeW = confirmBadgeWidth(badgeLabel)
    badgeX = x + Int((w - badgeW) / 2)
    uiPoster(m.canvas, "pkg:/images/ui/playlist_badge_" + badgeW.toStr() + "x28.png", badgeX, y + 30, badgeW, 28, 0.94)
    uiScaledLabel(m.canvas, badgeLabel, badgeX, y + 36, badgeW, 16, 10, m.colors.text, "center", 0.68)

    title = "Confirm Subscription"
    if m.pendingPlanId = "trial" then title = "Confirm Free Trial"
    uiLabel(m.canvas, title, x + 50, y + 80, w - 100, 40, 28, m.colors.text, "center")

    selectedText = "You selected " + plan.label + " at " + plan.price + " " + plan.billingTerm + "."
    if m.pendingPlanId = "trial" then selectedText = "You selected the 7-day free trial."
    uiScaledLabel(m.canvas, selectedText, x + 70, y + 132, w - 140, 28, 15, m.colors.textMuted, "center", 0.76)

    drawConfirmAction(x + 110, y + 192, 174, "Back to Plans", 1)
    drawConfirmAction(x + 326, y + 192, 170, "Continue", 0)
end sub

function confirmBadgeWidth(label as String) as Integer
    if label.len() <= 5 then return 68
    if label.len() <= 7 then return 84
    return 94
end function

sub drawConfirmAction(x as Integer, y as Integer, w as Integer, label as String, index as Integer)
    focused = index = m.confirmFocusIndex
    uri = "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png"
    textColor = m.colors.textPurple
    opacity = 0.72
    if focused then
        uri = "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png"
        textColor = m.colors.text
        opacity = 0.84
    end if
    uiPoster(m.canvas, uri, x, y, w, 44, opacity)
    uiScaledLabel(m.canvas, label, x + 8, y, w - 16, 44, 15, textColor, "center", 0.76)
end sub

sub drawStatusState()
    uiPoster(m.canvas, "pkg:/images/logo_full_dark_modified.png", 64, 44, 190, 64)

    if m.mode = "loading" then
        x = 385
        y = 252
        w = 510
        h = 204
        uiPoster(m.canvas, "pkg:/images/ui/rr_590x206_panel_whiteLine.png", x, y, w, h, 0.7)
        uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", x + 209, y + 26, 92, 26, 0.82)
        uiScaledLabel(m.canvas, "Working", x + 209, y + 31, 92, 16, 9, m.colors.text, "center", 0.62)
        uiLabel(m.canvas, m.statusTitle, x + 35, y + 78, w - 70, 42, 27, m.colors.text, "center")
        if m.statusMessage <> "" then
            uiScaledLabel(m.canvas, m.statusMessage, x + 60, y + 120, w - 120, 28, 13, m.colors.textMuted, "center", 0.72)
            uiLabel(m.canvas, "Please wait...", x + 115, y + 154, 280, 34, 16, m.colors.textGreen, "center")
        else
            uiLabel(m.canvas, "Please wait...", x + 115, y + 126, 280, 34, 16, m.colors.textGreen, "center")
        end if
        return
    end if

    uiPoster(m.canvas, "pkg:/images/ui/rr_590x206_panel_whiteLine.png", 375, 230, 530, 260, 0.7)

    if m.mode = "success" then
        uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", 606, 256, 68, 24, 0.82)
        uiScaledLabel(m.canvas, "Ready", 606, 261, 68, 14, 10, m.colors.text, "center", 0.62)
    else
        uiRoundRect(m.canvas, 613, 252, 54, 54, m.colors.amber, m.colors.amber, 0.82)
        uiLabel(m.canvas, "!", 613, 251, 54, 54, 24, m.colors.black, "center")
    end if

    uiLabel(m.canvas, m.statusTitle, 390, 306, 500, 42, 27, m.colors.text, "center")
    uiScaledLabel(m.canvas, m.statusMessage, 420, 354, 440, 54, 13, m.colors.textMuted, "center", 0.72)

    if m.mode = "success" then
        buttonText = "Continue"
        if m.pendingPlanId <> "trial" then buttonText = "Set Up Playlist"
        buttonW = 144
        buttonX = 568
        if buttonText <> "Continue" then
            buttonW = 184
            buttonX = 548
        end if
        uiPoster(m.canvas, "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png", buttonX, 410, buttonW, 44, 0.78)
        uiScaledLabel(m.canvas, buttonText, buttonX, 410, buttonW, 44, 15, m.colors.text, "center", 0.76)
    else if m.mode = "error" then
        uiPoster(m.canvas, "pkg:/images/ui/movie_watch_176x40_panel_greenFocus.png", 548, 410, 184, 44, 0.82)
        uiScaledLabel(m.canvas, "Back to Plans", 548, 410, 184, 44, 15, m.colors.text, "center", 0.76)
    end if
end sub

sub drawRecoveryCodeState()
    uiPoster(m.canvas, "pkg:/images/logo_full_dark_modified.png", 64, 44, 190, 64)
    x = 240
    y = 118
    w = 800
    h = 456
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", x, y, w, h, 0.90)
    uiPoster(m.canvas, "pkg:/images/ui/movie_featured_badge_100x34_purpleDeep.png", x + 342, y + 34, 116, 26, 0.84)
    uiScaledLabel(m.canvas, "Recovery Code", x + 342, y + 39, 116, 16, 9, m.colors.text, "center", 0.62)

    uiLabel(m.canvas, "Save this code", x + 40, y + 86, w - 80, 40, 28, m.colors.amber, "center")
    uiScaledLabel(m.canvas, "Use it to restore this account and playlist identity", x + 80, y + 136, w - 160, 24, 12, m.colors.textMuted, "center", 0.72)
    uiScaledLabel(m.canvas, "if this app is removed or installed again.", x + 80, y + 164, w - 160, 24, 12, m.colors.textMuted, "center", 0.72)

    codePanelY = y + 228
    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", x + 90, codePanelY, 620, 58, 0.90)
    uiScaledLabel(m.canvas, m.recoveryCode, x + 112, codePanelY + 8, 576, 40, 21, m.colors.textGreen, "center", 0.84)

    note = "Keep this code private."
    uiScaledLabel(m.canvas, note, x + 110, codePanelY + 78, 580, 28, 11, m.colors.textDim, "center", 0.66)

    uiPoster(m.canvas, "pkg:/images/ui/movie_watch_176x40_greenSoft_greenFocus.png", x + 298, codePanelY + 128, 204, 44, 0.78)
    uiScaledLabel(m.canvas, "Set Up Playlist", x + 298, codePanelY + 128, 204, 44, 15, m.colors.text, "center", 0.76)
end sub

sub drawRestoreCodeState()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.88)
    x = 220
    y = 104
    w = 840
    h = 524
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", x, y, w, h, 0.98)
    titleLabel = uiLabel(m.canvas, "Restore Account", x + 40, y + 30, w - 80, 38, 24, m.colors.textGreen, "center")
    titleLabel.font.size = 24

    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", x + 80, y + 100, 680, 48, 0.90)
    displayCode = m.restoreInput
    if displayCode = "" then displayCode = "ABCD-EFGH-JKLM-NPQR"
    codeColor = m.colors.text
    if m.restoreInput = "" then codeColor = m.colors.textDim
    uiLabel(m.canvas, displayCode, x + 104, y + 108, 632, 32, 17, codeColor, "left")

    if m.restoreMessage <> "" then
        msgColor = m.colors.textMuted
        lowerMessage = LCase(m.restoreMessage)
        if Instr(1, lowerMessage, "could not") > 0 or Instr(1, lowerMessage, "required") > 0 or Instr(1, lowerMessage, "unavailable") > 0 then msgColor = m.colors.red
        uiScaledLabel(m.canvas, m.restoreMessage, x + 70, y + 166, w - 140, 24, 11, msgColor, "center", 0.66)
    end if

    drawRestoreCodeKeyboard(x + 58, y + 218)
end sub

sub drawRestoreCodeKeyboard(startX as Integer, startY as Integer)
    keyW = 70
    keyH = 36
    gap = 7
    for i = 0 to m.restoreKeys.count() - 1
        keyLabel = m.restoreKeys[i]
        keyRect = restoreKeyboardKeyRect(i, startX, startY, keyW, keyH, gap)
        uiDrawKeyboardKey(m.canvas, keyLabel, uiKeyboardDisplayText(keyLabel, true), keyRect.x, keyRect.y, keyRect.w, keyRect.h, i = m.restoreKeyboardIndex, m.colors)
    end for
end sub

function restoreKeyboardMoveIndex(currentIndex as Integer, key as String) as Integer
    keyCount = m.restoreKeys.count()
    if keyCount = 0 then return 0
    if currentIndex < 0 then currentIndex = 0
    if currentIndex >= keyCount then currentIndex = keyCount - 1

    if key = "left" and currentIndex > 0 then return restoreKeyboardHorizontalMoveIndex(currentIndex - 1)
    if key = "right" and currentIndex < keyCount - 1 then return restoreKeyboardHorizontalMoveIndex(currentIndex + 1)
    if key = "up" then
        returnIndex = uiKeyboardStoredReturnIndex(currentIndex)
        if returnIndex >= 0 and returnIndex < keyCount then return returnIndex
        return restoreKeyboardVerticalMoveIndex(currentIndex, -1)
    end if
    if key = "down" then
        nextIndex = restoreKeyboardVerticalMoveIndex(currentIndex, 1)
        if nextIndex <> currentIndex then uiKeyboardStoreReturnIndex(nextIndex, currentIndex)
        return nextIndex
    end if
    return currentIndex
end function

function restoreKeyboardHorizontalMoveIndex(nextIndex as Integer) as Integer
    returnIndex = restoreKeyboardDefaultReturnIndex(nextIndex)
    if returnIndex >= 0 then uiKeyboardStoreReturnIndex(nextIndex, returnIndex)
    return nextIndex
end function

function restoreKeyboardVerticalMoveIndex(currentIndex as Integer, rowDelta as Integer) as Integer
    cols = 10
    currentRow = Int(currentIndex / cols)
    targetRow = currentRow + rowDelta
    if targetRow < 0 then return currentIndex
    first = restoreKeyboardRowFirst(targetRow)
    if first < 0 or first >= m.restoreKeys.count() then return currentIndex
    last = restoreKeyboardRowLast(targetRow)
    targetOffset = currentIndex - (currentRow * cols)
    rowCount = last - first + 1
    if targetOffset > rowCount - 1 then targetOffset = rowCount - 1
    if targetOffset < 0 then targetOffset = 0
    return first + targetOffset
end function

function restoreKeyboardRowFirst(row as Integer) as Integer
    if row < 0 then return -1
    first = row * 10
    if first >= m.restoreKeys.count() then return -1
    return first
end function

function restoreKeyboardRowLast(row as Integer) as Integer
    first = restoreKeyboardRowFirst(row)
    if first < 0 then return -1
    last = first + 9
    if last > m.restoreKeys.count() - 1 then last = m.restoreKeys.count() - 1
    return last
end function

function restoreKeyboardDefaultReturnIndex(targetIndex as Integer) as Integer
    cols = 10
    targetRow = Int(targetIndex / cols)
    if targetRow <= 0 then return -1
    bottomFirst = restoreKeyboardRowFirst(targetRow)
    bottomLast = restoreKeyboardRowLast(targetRow)
    if bottomFirst < 0 or bottomLast < 0 then return -1
    if bottomLast - bottomFirst + 1 >= cols then return -1
    sourceFirst = restoreKeyboardRowFirst(targetRow - 1)
    sourceLast = restoreKeyboardRowLast(targetRow - 1)
    if sourceFirst < 0 or sourceLast < 0 then return -1
    sourceIndex = sourceFirst + (targetIndex - bottomFirst)
    if sourceIndex > sourceLast then sourceIndex = sourceLast
    return sourceIndex
end function

function restoreKeyboardKeyRect(index as Integer, startX as Integer, startY as Integer, baseW as Integer, keyH as Integer, gap as Integer) as Object
    cols = 10
    row = Int(index / cols)
    y = startY + row * (keyH + gap)
    rowStart = row * cols
    rowEnd = rowStart + cols - 1
    if rowEnd > m.restoreKeys.count() - 1 then rowEnd = m.restoreKeys.count() - 1
    rowCount = rowEnd - rowStart + 1

    if rowCount >= cols then
        col = index MOD cols
        return { x: startX + col * (baseW + gap), y: y, w: baseW, h: keyH }
    end if

    totalW = 0
    for i = rowStart to rowEnd
        totalW += uiKeyboardKeyWidth(m.restoreKeys[i])
        if i < rowEnd then totalW += gap
    end for

    fullRowW = cols * baseW + (cols - 1) * gap
    x = startX + Int((fullRowW - totalW) / 2)
    for i = rowStart to index - 1
        x += uiKeyboardKeyWidth(m.restoreKeys[i]) + gap
    end for
    return { x: x, y: y, w: uiKeyboardKeyWidth(m.restoreKeys[index]), h: keyH }
end function

function storedRecoveryCode() as String
    section = CreateObject("roRegistrySection", backendApiAuthRegistrySection())
    if section <> invalid and section.Exists("recoveryCode") then
        code = section.Read("recoveryCode")
        if code <> invalid and code <> "" then return code
    end if
    return ""
end function

function cleanWelcomeRecoveryCode(value as Dynamic) as String
    text = UCase(welcomeCleanInput(value))
    out = ""
    for i = 1 to text.len()
        ch = Mid(text, i, 1)
        if Instr(1, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-", ch) > 0 then out += ch
    end for
    return out
end function

function welcomeCleanInput(value as Dynamic) as String
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

