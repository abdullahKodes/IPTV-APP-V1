function entitlementStatusLoad() as Object
    section = CreateObject("roRegistrySection", "iptvmax_entitlement")
    state = entitlementReadString(section, "state", "")
    if state = "" then return entitlementDefaultStatus()

    return {
        state: state,
        planId: entitlementReadString(section, "planId", ""),
        planName: entitlementReadString(section, "planName", "No subscription"),
        price: entitlementReadString(section, "price", ""),
        billingTerm: entitlementReadString(section, "billingTerm", ""),
        renewsAt: entitlementReadString(section, "renewsAt", ""),
        customerName: entitlementReadString(section, "customerName", "IPTV Viewer"),
        customerEmail: entitlementReadString(section, "customerEmail", "Roku account pending"),
        lastAction: entitlementReadString(section, "lastAction", "Ready"),
        message: entitlementReadString(section, "message", "Connect Roku Pay to validate this subscription."),
        mockMode: entitlementReadString(section, "mockMode", entitlementBillingMockValue())
    }
end function

function entitlementDefaultStatus() as Object
    return {
        state: "none",
        planId: "",
        planName: "No subscription",
        price: "",
        billingTerm: "",
        renewsAt: "Not active",
        customerName: "IPTV Viewer",
        customerEmail: "Roku account pending",
        lastAction: "Ready for Roku Pay",
        message: "Choose a plan to unlock playlist setup and premium playback.",
        mockMode: entitlementBillingMockValue()
    }
end function

function entitlementBillingConfig() as Object
    return {
        mode: entitlementBillingMode(),
        productId: "iptvmax_premium",
        monthlyCode: "iptvmax_monthly",
        annualCode: "iptvmax_yearly",
        trialCode: "iptvmax_monthly"
    }
end function

function entitlementBillingMode() as String
    section = CreateObject("roRegistrySection", "iptvmax_billing")
    return entitlementReadString(section, "mode", "mock")
end function

function entitlementBillingUseMock() as Boolean
    return entitlementBillingMode() <> "live"
end function

function entitlementBillingMockValue() as String
    if entitlementBillingUseMock() then return "1"
    return "0"
end function

function entitlementPlans() as Object
    config = entitlementBillingConfig()
    return [
        {
            id: "trial",
            storeCode: config.trialCode,
            label: "Free Trial",
            price: "$0.00",
            billingTerm: "7 days",
            badge: "Trial",
            title: "Start 7-Day Trial",
            subtitle: "Demo playlist access while Roku Pay is connected",
            description: "Best for testing the app on your TV before subscribing."
        },
        {
            id: "monthly",
            storeCode: config.monthlyCode,
            label: "Monthly",
            price: "$3.49",
            billingTerm: "per month",
            badge: "Popular",
            title: "Subscribe Monthly",
            subtitle: "Flexible IPTV access with Roku billing",
            description: "The clean first production plan for launch."
        },
        {
            id: "annual",
            storeCode: config.annualCode,
            label: "Annual",
            price: "$12.99",
            billingTerm: "per year",
            badge: "Save",
            title: "Subscribe Annual",
            subtitle: "Yearly access after catalog setup",
            description: "Prepared for later once monthly billing is stable."
        }
    ]
end function

function entitlementPlanById(planId as String) as Object
    for each plan in entitlementPlans()
        if plan.id = planId then return plan
    end for
    return entitlementPlans()[1]
end function

function entitlementPlanByStoreCode(code as String) as Object
    if code = invalid or code = "" then return entitlementPlanById("monthly")
    for each plan in entitlementPlans()
        if entitlementText(plan, "storeCode", "") = code then return plan
    end for
    return entitlementPlanById("monthly")
end function

function entitlementPlanStoreCode(planId as String) as String
    plan = entitlementPlanById(planId)
    return entitlementText(plan, "storeCode", "")
end function

sub entitlementActivateMockPlan(planId as String)
    plan = entitlementPlanById(planId)
    state = "active"
    if planId = "trial" then state = "trial"

    status = {
        state: state,
        planId: plan.id,
        planName: plan.label,
        price: plan.price,
        billingTerm: plan.billingTerm,
        renewsAt: entitlementRenewalLabel(plan.id),
        customerName: "Roku Viewer",
        customerEmail: "roku-account@example.com",
        lastAction: "Subscription activated",
        message: "Your subscription is active.",
        mockMode: "1"
    }
    entitlementStatusSave(status)
    entitlementCompleteOnboarding(plan.id)
    if planId = "trial" then playlistStoreSetActive(playlistStoreDemoId())
end sub

sub entitlementRestoreMock()
    status = {
        state: "active",
        planId: "monthly",
        planName: "Monthly",
        price: "$3.49",
        billingTerm: "per month",
        renewsAt: "Renews after Roku validation",
        customerName: "Roku Viewer",
        customerEmail: "roku-account@example.com",
        lastAction: "Subscription restored",
        message: "Your subscription is active.",
        mockMode: "1"
    }
    entitlementStatusSave(status)
    entitlementCompleteOnboarding("restore")
end sub

sub entitlementMarkAccountRestored()
    status = entitlementDefaultStatus()
    status.state = "account_restored"
    status.customerName = "Restored Account"
    status.customerEmail = "Subscription pending"
    status.lastAction = "Account restored"
    status.message = "Account restored. Restore Subscription to unlock playback and playlist changes."
    entitlementStatusSave(status)
    entitlementCompleteOnboarding("account_restore")
end sub

sub entitlementActivateRokuPurchase(purchase as Object, fallbackPlanId as String, action as String)
    planId = fallbackPlanId
    code = entitlementNodeText(purchase, "code", entitlementPlanStoreCode(fallbackPlanId))
    if code <> "" then planId = entitlementText(entitlementPlanByStoreCode(code), "id", fallbackPlanId)
    plan = entitlementPlanById(planId)

    purchaseStatus = LCase(entitlementNodeText(purchase, "status", "Valid"))
    inDunning = LCase(entitlementNodeText(purchase, "inDunning", "false"))
    state = "active"
    if planId = "trial" then state = "trial"
    if inDunning = "true" and purchaseStatus = "valid" then state = "grace"
    if inDunning = "true" and purchaseStatus <> "valid" then state = "on_hold"
    if purchaseStatus = "invalid" and inDunning <> "true" then state = "canceled"

    lastAction = "Roku Pay purchase validated"
    if action = "restore" then lastAction = "Roku Pay restore validated"

    status = {
        state: state,
        planId: plan.id,
        planName: plan.label,
        price: entitlementNodeText(purchase, "cost", plan.price),
        billingTerm: plan.billingTerm,
        renewsAt: entitlementRokuRenewalLabel(purchase, plan.id),
        customerName: "Roku Viewer",
        customerEmail: "Roku account",
        lastAction: lastAction,
        message: entitlementAccessMessageForState(state),
        mockMode: "0"
    }
    entitlementStatusSave(status)
    if entitlementCanEnterApp(status) then entitlementCompleteOnboarding(action)
end sub

sub entitlementSetMockState(state as String)
    status = entitlementStatusLoad()
    status.state = state
    if state = "grace" then
        status.planName = "Monthly"
        status.planId = "monthly"
        status.price = "$3.49"
        status.billingTerm = "per month"
        status.renewsAt = "Payment recovery grace period"
        status.lastAction = "Payment recovery state"
        status.message = "Playback can continue while Roku Pay asks the customer to update payment."
    else if state = "on_hold" then
        status.planName = "Monthly"
        status.planId = "monthly"
        status.price = "$3.49"
        status.billingTerm = "per month"
        status.renewsAt = "Payment update required"
        status.lastAction = "Payment update required"
        status.message = "Premium playback is blocked until Roku Pay recovery succeeds."
    else if state = "canceled" then
        status.planName = "Canceled"
        status.planId = ""
        status.price = ""
        status.billingTerm = ""
        status.renewsAt = "Expired"
        status.lastAction = "Subscription canceled"
        status.message = "Customer must choose a plan again to regain access."
    else if state = "none" then
        status = entitlementDefaultStatus()
    end if
    entitlementStatusSave(status)
end sub

sub entitlementClearLocalAccess()
    status = entitlementDefaultStatus()
    status.lastAction = "Signed out locally"
    status.message = "Choose a plan or restore your Roku purchase to unlock access."
    entitlementStatusSave(status)
end sub

sub entitlementStatusSave(status as Object)
    section = CreateObject("roRegistrySection", "iptvmax_entitlement")
    section.Write("state", entitlementText(status, "state", "none"))
    section.Write("planId", entitlementText(status, "planId", ""))
    section.Write("planName", entitlementText(status, "planName", "No subscription"))
    section.Write("price", entitlementText(status, "price", ""))
    section.Write("billingTerm", entitlementText(status, "billingTerm", ""))
    section.Write("renewsAt", entitlementText(status, "renewsAt", ""))
    section.Write("customerName", entitlementText(status, "customerName", "IPTV Viewer"))
    section.Write("customerEmail", entitlementText(status, "customerEmail", "Roku account pending"))
    section.Write("lastAction", entitlementText(status, "lastAction", "Ready"))
    section.Write("message", entitlementText(status, "message", ""))
    section.Write("mockMode", entitlementText(status, "mockMode", entitlementBillingMockValue()))
    section.Flush()
    entitlementWriteSettings(status)
end sub

sub entitlementWriteSettings(status as Object)
    section = CreateObject("roRegistrySection", "iptvmax_settings")
    section.Write("signedIn", entitlementSignedInValue(entitlementText(status, "state", "none")))
    section.Write("subscription", entitlementProfileLabel(status))
    section.Write("userName", entitlementText(status, "customerName", "IPTV Viewer"))
    section.Write("userEmail", entitlementText(status, "customerEmail", "Roku account pending"))
    section.Write("lastSync", entitlementText(status, "lastAction", "Ready"))
    section.Flush()
end sub

sub entitlementCompleteOnboarding(path as String)
    section = CreateObject("roRegistrySection", "iptvmax_onboarding")
    section.Write("completed", "1")
    section.Write("path", path)
    section.Write("completedAt", entitlementNowSeconds())
    section.Flush()
end sub

function entitlementCanEnterApp(status as Object) as Boolean
    state = entitlementText(status, "state", "none")
    return state = "trial" or state = "active" or state = "grace"
end function

function entitlementCanBrowseApp(status as Object) as Boolean
    state = entitlementText(status, "state", "none")
    return state = "account_restored" or entitlementCanEnterApp(status)
end function

function entitlementRequiresSubscriptionPage(status as Object) as Boolean
    return not entitlementCanBrowseApp(status)
end function

function entitlementAccessMessageForState(state as String) as String
    if state = "account_restored" then return "Restore Subscription to unlock playback and playlist changes."
    if state = "trial" then return "Trial access is active."
    if state = "active" then return "Premium playback is active."
    if state = "grace" then return "Playback can continue during Roku Pay payment recovery."
    if state = "on_hold" then return "Premium playback is blocked until Roku Pay payment recovery succeeds."
    if state = "canceled" then return "Choose a plan again to regain access."
    return "Choose a plan to unlock playlist setup and premium playback."
end function

function entitlementProfileLabel(status as Object) as String
    state = entitlementText(status, "state", "none")
    if state = "account_restored" then return "Restored"
    if state = "trial" then return "Trial"
    if state = "active" then return "Premium"
    if state = "grace" then return "Grace"
    if state = "on_hold" then return "On Hold"
    if state = "canceled" then return "Canceled"
    return "Preview"
end function

function entitlementStatusTitle(status as Object) as String
    label = entitlementProfileLabel(status)
    if label = "Restored" then return "Account restored"
    if label = "Preview" then return "No subscription"
    if label = "Premium" then return "Premium active"
    if label = "Trial" then return "Trial active"
    return label
end function

function entitlementSignedInValue(state as String) as String
    if state = "account_restored" then return "1"
    if state = "trial" or state = "active" or state = "grace" then return "1"
    return "0"
end function

function entitlementRenewalLabel(planId as String) as String
    if planId = "trial" then return "Trial ends after Roku Pay setup"
    if planId = "annual" then return "Renews yearly after activation"
    return "Renews monthly after activation"
end function

function entitlementRokuRenewalLabel(purchase as Object, planId as String) as String
    renewal = entitlementNodeText(purchase, "renewalDate", "")
    if renewal <> "" then return "Renews " + renewal
    expiration = entitlementNodeText(purchase, "expirationDate", "")
    if expiration <> "" then return "Expires " + expiration
    return entitlementRenewalLabel(planId)
end function

function entitlementText(status as Object, key as String, fallback = "" as String) as String
    if status <> invalid and status.doesExist(key) and status[key] <> invalid then return status[key]
    return fallback
end function

function entitlementNodeText(node as Object, key as String, fallback = "" as String) as String
    if node <> invalid and node.hasField(key) and node[key] <> invalid then return node[key].toStr()
    return fallback
end function

function entitlementReadString(section as Object, key as String, fallback as String) as String
    if section <> invalid and section.Exists(key) then
        value = section.Read(key)
        if value <> invalid and value <> "" then return value
    end if
    return fallback
end function

function entitlementNowSeconds() as String
    now = CreateObject("roDateTime")
    return now.AsSeconds().toStr()
end function
