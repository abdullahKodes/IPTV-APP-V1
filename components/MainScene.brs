sub init()
    m.colors = appColors()
    m.currentPage = invalid
    m.currentPageName = ""
    m.pendingPlayback = invalid
    m.pendingDetail = invalid
    m.pendingAddPlaylistReturnPage = ""
    m.pageStack = []
    m.pageHost = m.top.findNode("pageHost")
    m.parentalGateHost = m.top.findNode("parentalGateHost")
    m.parentalGateOpen = false
    m.parentalGateTarget = ""
    m.parentalGateCurrentName = ""
    m.parentalGatePinInput = ""
    m.parentalGatePinError = ""
    m.parentalGateKeyboardIndex = 0
    m.parentalGateKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "DONE"]
    m.parentalUnlockedToken = ""
    m.subscriptionGateDialog = invalid
    m.exitConfirmOpen = false
    m.exitConfirmFocusIndex = 0
    m.exitConfirmPreviousFocusIndex = -1
    m.top.backgroundColor = m.colors.bg
    m.top.setFocus(true)

    m.timer = CreateObject("roSGNode", "Timer")
    m.timer.repeat = true
    m.timer.duration = 10
    m.timer.observeField("fire", "onClockTick")
    m.timer.control = "start"

    showPage(initialPageForEntitlement())
end sub

sub onClockTick()
    if m.currentPage <> invalid then
        m.currentPage.callFunc("refreshClock")
    end if
end sub

sub showPage(componentName as String)
    componentName = gatedPageName(componentName)
    clearParentalUnlockForPage(componentName)
    if m.currentPage <> invalid and m.currentPage.hasField("pageActive") then m.currentPage.pageActive = false
    uiClear(m.pageHost)
    m.currentPageName = componentName
    m.currentPage = CreateObject("roSGNode", componentName)
    if m.currentPage.hasField("pageActive") then m.currentPage.pageActive = true
    m.currentPage.observeField("navigateTo", "onPageNavigation")
    if componentName = "PlayerPage" and m.pendingPlayback <> invalid then
        m.currentPage.playbackTitle = m.pendingPlayback.title
        m.currentPage.playbackSubtitle = m.pendingPlayback.subtitle
        m.currentPage.playbackFormat = m.pendingPlayback.streamFormat
        m.currentPage.playbackPosterUrl = m.pendingPlayback.posterUrl
        if m.currentPage.hasField("playbackMediaType") then m.currentPage.playbackMediaType = m.pendingPlayback.mediaType
        if m.currentPage.hasField("playbackPlaylistId") then m.currentPage.playbackPlaylistId = m.pendingPlayback.playlistId
        if m.currentPage.hasField("playbackMediaId") then m.currentPage.playbackMediaId = m.pendingPlayback.mediaId
        if m.currentPage.hasField("playbackEpisodeId") then m.currentPage.playbackEpisodeId = m.pendingPlayback.episodeId
        if m.currentPage.hasField("playbackSeasonIndex") then m.currentPage.playbackSeasonIndex = m.pendingPlayback.seasonIndex
        if m.currentPage.hasField("playbackSeasonNumber") then m.currentPage.playbackSeasonNumber = m.pendingPlayback.seasonNumber
        if m.currentPage.hasField("playbackEpisodeIndex") then m.currentPage.playbackEpisodeIndex = m.pendingPlayback.episodeIndex
        if m.currentPage.hasField("playbackSeasonCount") then m.currentPage.playbackSeasonCount = m.pendingPlayback.seasonCount
        if m.currentPage.hasField("playbackSeasonEpisodeCount") then m.currentPage.playbackSeasonEpisodeCount = m.pendingPlayback.seasonEpisodeCount
        if m.currentPage.hasField("playbackResumePosition") then m.currentPage.playbackResumePosition = m.pendingPlayback.resumePosition
        m.currentPage.returnPage = m.pendingPlayback.returnPage
        m.currentPage.playbackUrl = m.pendingPlayback.url
    else if (componentName = "MovieDetailPage" or componentName = "SeriesDetailPage") and m.pendingDetail <> invalid then
        m.currentPage.detailId = m.pendingDetail.id
        m.currentPage.detailTitle = m.pendingDetail.title
        m.currentPage.detailSubtitle = m.pendingDetail.subtitle
        m.currentPage.detailMeta = m.pendingDetail.meta
        m.currentPage.detailDescription = m.pendingDetail.description
        m.currentPage.detailPosterUrl = m.pendingDetail.posterUrl
        if m.currentPage.hasField("detailHeroUrl") then m.currentPage.detailHeroUrl = m.pendingDetail.heroUrl
        m.currentPage.detailBackdropUrl = m.pendingDetail.backdropUrl
        m.currentPage.detailPlaybackUrl = m.pendingDetail.playbackUrl
        m.currentPage.detailPlaybackFormat = m.pendingDetail.playbackFormat
        if m.currentPage.hasField("detailPlaylistId") then m.currentPage.detailPlaylistId = m.pendingDetail.playlistId
        if m.currentPage.hasField("detailMediaType") then m.currentPage.detailMediaType = m.pendingDetail.mediaType
        if m.currentPage.hasField("detailEpisodeNames") then m.currentPage.detailEpisodeNames = m.pendingDetail.episodeNames
        if m.currentPage.hasField("detailSeasonNames") then m.currentPage.detailSeasonNames = m.pendingDetail.seasonNames
        if m.currentPage.hasField("detailEpisodeDurations") then m.currentPage.detailEpisodeDurations = m.pendingDetail.episodeDurations
        if m.currentPage.hasField("detailActiveEpisodeTitle") then m.currentPage.detailActiveEpisodeTitle = m.pendingDetail.activeEpisodeTitle
        m.currentPage.detailReturnPage = m.pendingDetail.returnPage
        m.currentPage.callFunc("syncDetail")
    else if componentName = "AddPlaylistPage" and m.pendingAddPlaylistReturnPage <> "" then
        if m.currentPage.hasField("returnPage") then m.currentPage.returnPage = m.pendingAddPlaylistReturnPage
        m.pendingAddPlaylistReturnPage = ""
    end if
    m.pageHost.appendChild(m.currentPage)
    m.currentPage.setFocus(true)
end sub

sub restorePage(history as Object)
    if history = invalid or not history.doesExist("name") then return
    if not history.doesExist("page") or history.page = invalid then
        disposePageForRoute(m.currentPageName, m.currentPage)
        showPage(history.name)
        return
    end if
    clearParentalUnlockForPage(history.name)
    if m.currentPage <> invalid and m.currentPage.hasField("pageActive") then m.currentPage.pageActive = false
    uiClear(m.pageHost)
    m.currentPageName = history.name
    m.currentPage = history.page
    if m.currentPage.hasField("pageActive") then m.currentPage.pageActive = true
    if m.currentPage.hasField("navigateTo") then m.currentPage.navigateTo = ""
    m.pageHost.appendChild(m.currentPage)
    m.currentPage.setFocus(true)
    if history.name = "MovieDetailPage" or history.name = "SeriesDetailPage" then m.currentPage.callFunc("syncDetail")
    if history.name = "SeriesPage" then m.currentPage.callFunc("refreshProgress")
    if history.name = "FavoritesPage" then m.currentPage.callFunc("refreshFavorites")
end sub

sub onPageNavigation()
    target = m.currentPage.navigateTo
    if target <> invalid and target <> "" then
        currentName = m.currentPageName
        if m.currentPage.hasField("navigateTo") then m.currentPage.navigateTo = ""
        if subscriptionGateNeededForTarget(target) then
            openSubscriptionGate(target)
            return
        end if
        target = gatedPageName(target)
        if target = m.currentPageName then return
        if target = "AddPlaylistPage" then m.pendingAddPlaylistReturnPage = addPlaylistReturnPageForCurrent(currentName)
        if target = "PlayerPage" and m.currentPage.hasField("playbackUrl") then
            m.pendingPlayback = {
                title: m.currentPage.playbackTitle,
                subtitle: m.currentPage.playbackSubtitle,
                url: m.currentPage.playbackUrl,
                streamFormat: m.currentPage.playbackFormat,
                posterUrl: m.currentPage.playbackPosterUrl,
                mediaType: playbackPendingText(m.currentPage),
                playlistId: playbackPendingFieldText(m.currentPage, "playbackPlaylistId"),
                mediaId: playbackPendingFieldText(m.currentPage, "playbackMediaId"),
                episodeId: playbackPendingFieldText(m.currentPage, "playbackEpisodeId"),
                seasonIndex: playbackPendingFieldInt(m.currentPage, "playbackSeasonIndex"),
                seasonNumber: playbackPendingFieldInt(m.currentPage, "playbackSeasonNumber"),
                episodeIndex: playbackPendingFieldInt(m.currentPage, "playbackEpisodeIndex"),
                seasonCount: playbackPendingFieldInt(m.currentPage, "playbackSeasonCount"),
                seasonEpisodeCount: playbackPendingFieldInt(m.currentPage, "playbackSeasonEpisodeCount"),
                resumePosition: playbackPendingFieldInt(m.currentPage, "playbackResumePosition"),
                returnPage: m.currentPage.returnPage
            }
        else if (target = "MovieDetailPage" or target = "SeriesDetailPage") and m.currentPage.hasField("detailTitle") then
            m.pendingDetail = {
                id: m.currentPage.detailId,
                title: m.currentPage.detailTitle,
                subtitle: m.currentPage.detailSubtitle,
                meta: m.currentPage.detailMeta,
                description: m.currentPage.detailDescription,
                posterUrl: m.currentPage.detailPosterUrl,
                heroUrl: m.currentPage.detailHeroUrl,
                backdropUrl: m.currentPage.detailBackdropUrl,
                playbackUrl: m.currentPage.detailPlaybackUrl,
                playbackFormat: m.currentPage.detailPlaybackFormat,
                playlistId: detailPendingText(m.currentPage, "detailPlaylistId"),
                mediaType: detailPendingText(m.currentPage, "detailMediaType"),
                episodeNames: detailPendingText(m.currentPage, "detailEpisodeNames"),
                seasonNames: detailPendingText(m.currentPage, "detailSeasonNames"),
                episodeDurations: detailPendingText(m.currentPage, "detailEpisodeDurations"),
                activeEpisodeTitle: detailPendingText(m.currentPage, "detailActiveEpisodeTitle"),
                returnPage: m.currentPage.detailReturnPage
            }
        end if
        if parentalGateNeededForTarget(target, currentName) then
            openParentalGate(target, currentName)
            return
        end if
        completePageNavigation(target, currentName)
    end if
end sub

sub completePageNavigation(target as String, currentName as String)
    if shouldResetPlaylistBrowseHistory(target, currentName) then m.pageStack = []

    if m.pageStack.count() > 0 then
        previous = m.pageStack[m.pageStack.count() - 1]
        if previous.name = target and shouldRestorePreviousForTarget(target, currentName) then
            restored = m.pageStack.pop()
            restorePage(restored)
            return
        end if
    end if

    if shouldPreservePageForTarget(target, currentName) then
        historyEntry = navigationHistoryEntry(currentName, m.currentPage, target)
        if historyEntry.page = invalid then disposePageForRoute(currentName, m.currentPage)
        m.pageStack.push(historyEntry)
        m.pageStack = navigationTrimHistory(m.pageStack, 8)
    else
        disposePageForRoute(currentName, m.currentPage)
        m.pageStack = []
    end if
    showPage(target)
end sub

sub disposePageForRoute(pageName as String, page as Dynamic)
    if page = invalid then return
    if pageName = "LiveTvPage" or pageName = "MoviesPage" or pageName = "SeriesPage" then page.callFunc("disposePage")
end sub

function initialPageForEntitlement() as String
    if onboardingShouldShow() then return "WelcomePage"
    if entitlementRequiresSubscriptionPage(entitlementStatusLoad()) then return "WelcomePage"
    return "HomePage"
end function

function gatedPageName(componentName as String) as String
    if componentName = invalid or componentName = "" then return "WelcomePage"
    if componentName = "WelcomePage" or componentName = "SubscriptionPage" then return componentName
    entitlement = entitlementStatusLoad()
    if not entitlementCanBrowseApp(entitlement) then return "WelcomePage"
    return componentName
end function

function routeRequiresSubscription(componentName as String) as Boolean
    return componentName = "AddPlaylistPage" or componentName = "PlayerPage"
end function

function subscriptionGateNeededForTarget(componentName as String) as Boolean
    if not routeRequiresSubscription(componentName) then return false
    entitlement = entitlementStatusLoad()
    if entitlementCanEnterApp(entitlement) then return false
    return entitlementCanBrowseApp(entitlement)
end function

sub openSubscriptionGate(target as String)
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Subscription Required"
    if target = "AddPlaylistPage" then
        dialog.message = "Your account is restored, but your subscription is not active yet. Restore Subscription before adding a new playlist."
    else
        dialog.message = "Your account is restored, but playback is locked until your subscription is restored through Roku Pay."
    end if
    dialog.buttons = ["Not Now", "Restore Subscription"]
    dialog.observeField("buttonSelected", "onSubscriptionGateButton")
    m.subscriptionGateDialog = dialog
    m.top.dialog = dialog
end sub

sub closeSubscriptionGate()
    m.top.dialog = invalid
    m.subscriptionGateDialog = invalid
end sub

sub onSubscriptionGateButton()
    if m.subscriptionGateDialog = invalid then return
    selected = m.subscriptionGateDialog.buttonSelected
    closeSubscriptionGate()
    if selected = 1 then completePageNavigation("ProfilePage", m.currentPageName)
end sub

sub openExitConfirm()
    m.exitConfirmOpen = true
    m.exitConfirmFocusIndex = 0
    m.exitConfirmPreviousFocusIndex = -1
    drawExitConfirm()
end sub

sub closeExitConfirm()
    m.exitConfirmOpen = false
    m.exitConfirmFocusIndex = 0
    m.exitConfirmPreviousFocusIndex = -1
    if m.parentalGateHost <> invalid then uiClear(m.parentalGateHost)
end sub

function handleExitConfirmKey(key as String) as Boolean
    if key = "back" then closeExitConfirm() : return true
    if key = "left" or key = "right" then
        m.exitConfirmPreviousFocusIndex = m.exitConfirmFocusIndex
        m.exitConfirmFocusIndex = 1 - m.exitConfirmFocusIndex
        drawExitConfirm()
        return true
    end if
    if key = "OK" then
        if m.exitConfirmFocusIndex = 0 then
            closeExitConfirm()
            m.top.appExit = true
        else
            closeExitConfirm()
        end if
        return true
    end if
    return true
end function

sub drawExitConfirm()
    if m.parentalGateHost = invalid then return
    uiClear(m.parentalGateHost)
    uiRect(m.parentalGateHost, 0, 0, 1280, 720, "0x000000FF", 0.64)

    x = 394
    y = 238
    w = 492
    h = 224
    uiPoster(m.parentalGateHost, "pkg:/images/ui/exit_confirm_panel_492x224.png", x, y, w, h, 0.98)
    uiRect(m.parentalGateHost, x + 74, y + 70, w - 148, 1, m.colors.whiteLine, 0.34)

    titleLabel = uiLabel(m.parentalGateHost, "Exit IPTV MAX?", x + 32, y + 22, w - 64, 40, 26, m.colors.text, "center")
    titleLabel.font.size = 26
    messageLabel = uiLabel(m.parentalGateHost, "Are you sure you want to exit the app?", x + 56, y + 82, w - 112, 40, 18, m.colors.textMuted, "center")
    messageLabel.font.size = 18

    drawExitConfirmButton(x + 126, y + 148, 108, "Yes", 0)
    drawExitConfirmButton(x + 258, y + 148, 108, "No", 1)
end sub

sub drawExitConfirmButton(x as Integer, y as Integer, w as Integer, label as String, index as Integer)
    focused = index = m.exitConfirmFocusIndex
    buttonCanvas = CreateObject("roSGNode", "Group")
    buttonCanvas.id = "exitConfirmButton" + index.toStr()
    buttonCanvas.translation = [x, y]
    m.parentalGateHost.appendChild(buttonCanvas)

    textColor = m.colors.textMuted
    uiPoster(buttonCanvas, "pkg:/images/ui/feedback_category_108x34_base.png", 0, 0, w, 34, 0.94)
    if focused then
        textColor = m.colors.text
        focusOpacity = 0.82
        if m.exitConfirmPreviousFocusIndex <> index then focusOpacity = 0.0
        focusSurface = uiPoster(buttonCanvas, "pkg:/images/ui/feedback_category_108x34_focus.png", 0, 0, w, 34, focusOpacity)
        focusSurface.id = "exitConfirmFocus" + index.toStr()
        if m.exitConfirmPreviousFocusIndex <> index then animateExitConfirmButtonFocus(m.parentalGateHost, focusSurface, 0.82)
    end if
    uiScaledLabel(buttonCanvas, label, 8, 0, w - 16, 34, 12, textColor, "center", 0.70)
end sub

sub animateExitConfirmButtonFocus(parent as Object, focusSurface as Object, finalOpacity as Float)
    animation = CreateObject("roSGNode", "Animation")
    animation.duration = 0.14
    animation.easeFunction = "outQuad"

    opacityAnimation = animation.createChild("FloatFieldInterpolator")
    opacityAnimation.key = [0.0, 1.0]
    opacityAnimation.keyValue = [0.0, finalOpacity]
    opacityAnimation.fieldToInterp = focusSurface.id + ".opacity"

    parent.appendChild(animation)
    animation.control = "start"
end sub

function shouldRestorePreviousForTarget(target as String, currentName as String) as Boolean
    if currentName = "MovieDetailPage" or currentName = "SeriesDetailPage" or currentName = "PlayerPage" then return true
    if currentName = "AddPlaylistPage" or currentName = "ManagePlaylistsPage" then return true
    return false
end function

function shouldPreservePageForTarget(target as String, currentName as String) as Boolean
    if target = "MovieDetailPage" or target = "SeriesDetailPage" or target = "PlayerPage" then return true
    if currentName = "SubscriptionPage" and target = "WelcomePage" then return true
    if isHistoryPage(currentName) and isHistoryPage(target) then return true
    return false
end function

function isHistoryPage(pageName as String) as Boolean
    if pageName = "HomePage" then return true
    if pageName = "MyPlaylistsPage" then return true
    if pageName = "LiveTvPage" then return true
    if pageName = "SeriesPage" then return true
    if pageName = "MoviesPage" then return true
    if pageName = "FavoritesPage" then return true
    if pageName = "SettingsPage" then return true
    if pageName = "ProfilePage" then return true
    if pageName = "SubscriptionPage" then return true
    if pageName = "FeedbackPage" then return true
    return false
end function

function shouldResetPlaylistBrowseHistory(target as String, currentName as String) as Boolean
    if currentName <> "MyPlaylistsPage" then return false
    return isPlaylistBrowsePage(target)
end function

function isPlaylistBrowsePage(pageName as String) as Boolean
    if pageName = "LiveTvPage" then return true
    if pageName = "MoviesPage" then return true
    if pageName = "SeriesPage" then return true
    if pageName = "FavoritesPage" then return true
    return false
end function

function addPlaylistReturnPageForCurrent(currentName as String) as String
    if currentName <> invalid and currentName <> "" and currentName <> "AddPlaylistPage" then return currentName
    return "MyPlaylistsPage"
end function

sub clearParentalUnlockForPage(pageName as String)
    if pageName = "MovieDetailPage" or pageName = "SeriesDetailPage" or pageName = "PlayerPage" then return
    m.parentalUnlockedToken = ""
end sub

function parentalGateNeededForTarget(target as String, currentName as String) as Boolean
    if target <> "MovieDetailPage" and target <> "SeriesDetailPage" and target <> "PlayerPage" then return false
    if not parentalControlLockEnabled() then return false
    if not parentalControlPinIsSet() then return false
    gateToken = parentalGateTokenForTarget(target, currentName)
    if gateToken <> "" and gateToken = m.parentalUnlockedToken then return false

    if target = "MovieDetailPage" or target = "SeriesDetailPage" then
        return parentalControlIsRestrictedDetailPayload(m.pendingDetail)
    end if

    if currentName = "MovieDetailPage" or currentName = "SeriesDetailPage" then
        return parentalControlTextIsRestricted(currentDetailGateText())
    end if
    return parentalControlIsRestrictedPlaybackPayload(m.pendingPlayback)
end function

function parentalGateTokenForTarget(target as String, currentName as String) as String
    if target = "MovieDetailPage" or target = "SeriesDetailPage" then return parentalPayloadToken(m.pendingDetail)
    if target = "PlayerPage" and (currentName = "MovieDetailPage" or currentName = "SeriesDetailPage") then return currentDetailGateToken()
    if target = "PlayerPage" then return parentalPayloadToken(m.pendingPlayback)
    return ""
end function

function parentalPayloadToken(payload as Object) as String
    if payload = invalid then return ""
    id = parentalControlPayloadText(payload, "id")
    title = parentalControlPayloadText(payload, "title")
    mediaType = parentalControlPayloadText(payload, "mediaType")
    if id = "" then id = title
    if id = "" then return ""
    return LCase(mediaType + ":" + id)
end function

function currentDetailGateToken() as String
    if m.currentPage = invalid then return ""
    id = ""
    title = ""
    mediaType = ""
    if m.currentPage.hasField("detailId") then id = playbackPendingFieldText(m.currentPage, "detailId")
    if m.currentPage.hasField("detailTitle") then title = playbackPendingFieldText(m.currentPage, "detailTitle")
    if m.currentPage.hasField("detailMediaType") then mediaType = playbackPendingFieldText(m.currentPage, "detailMediaType")
    if id = "" then id = title
    if id = "" then return ""
    return LCase(mediaType + ":" + id)
end function

function currentDetailGateText() as String
    if m.currentPage = invalid then return ""
    text = ""
    if m.currentPage.hasField("detailTitle") then text += playbackPendingFieldText(m.currentPage, "detailTitle") + " "
    if m.currentPage.hasField("detailSubtitle") then text += playbackPendingFieldText(m.currentPage, "detailSubtitle") + " "
    if m.currentPage.hasField("detailMeta") then text += playbackPendingFieldText(m.currentPage, "detailMeta")
    return text
end function

sub openParentalGate(target as String, currentName as String)
    m.parentalGateOpen = true
    m.parentalGateTarget = target
    m.parentalGateCurrentName = currentName
    m.parentalGatePinInput = ""
    m.parentalGatePinError = ""
    m.parentalGateKeyboardIndex = 0
    drawParentalGate()
end sub

sub closeParentalGate()
    m.parentalGateOpen = false
    m.parentalGateTarget = ""
    m.parentalGateCurrentName = ""
    m.parentalGatePinInput = ""
    m.parentalGatePinError = ""
    if m.parentalGateHost <> invalid then uiClear(m.parentalGateHost)
end sub

function handleParentalGateKey(key as String) as Boolean
    if key = "back" then closeParentalGate() : return true
    nextIndex = uiKeyboardMoveIndex(m.parentalGateKeys, m.parentalGateKeyboardIndex, key, 3)
    if nextIndex <> m.parentalGateKeyboardIndex then m.parentalGateKeyboardIndex = nextIndex : drawParentalGate() : return true
    if key = "OK" then pressParentalGateKey() : return true
    return true
end function

sub pressParentalGateKey()
    selected = m.parentalGateKeys[m.parentalGateKeyboardIndex]
    m.parentalGatePinError = ""
    if selected = "DEL" then
        if m.parentalGatePinInput.len() > 0 then m.parentalGatePinInput = Left(m.parentalGatePinInput, m.parentalGatePinInput.len() - 1)
        drawParentalGate()
        return
    end if
    if selected = "DONE" then
        submitParentalGatePin()
        return
    end if
    if m.parentalGatePinInput.len() < 4 then m.parentalGatePinInput += selected
    drawParentalGate()
end sub

sub submitParentalGatePin()
    if not parentalControlPinValid(m.parentalGatePinInput) then
        m.parentalGatePinError = "Enter your 4-digit PIN."
        drawParentalGate()
        return
    end if
    if not parentalControlVerifyPin(m.parentalGatePinInput) then
        m.parentalGatePinInput = ""
        m.parentalGatePinError = "Incorrect PIN."
        drawParentalGate()
        return
    end if
    target = m.parentalGateTarget
    currentName = m.parentalGateCurrentName
    m.parentalUnlockedToken = parentalGateTokenForTarget(target, currentName)
    closeParentalGate()
    completePageNavigation(target, currentName)
end sub

sub drawParentalGate()
    if m.parentalGateHost = invalid then return
    uiClear(m.parentalGateHost)
    uiRect(m.parentalGateHost, 0, 0, 1280, 720, "0x000000FF", 0.62)
    x = 390
    y = 126
    w = 500
    h = 468
    uiPoster(m.parentalGateHost, "pkg:/images/ui/rr_500x468_panel_greenFocus.png", x, y, w, h, 0.98)
    titleLabel = uiLabel(m.parentalGateHost, "Parental Lock", x + 32, y + 20, w - 64, 42, 26, m.colors.textGreen, "center")
    titleLabel.font.size = 26
    subtitleLabel = uiLabel(m.parentalGateHost, "Locked category: " + parentalGateRestrictedCategoryLabel(), x + 42, y + 72, w - 84, 34, 18, m.colors.textMuted, "center")
    subtitleLabel.font.size = 18
    drawParentalGateDots(x + 142, y + 124)
    if m.parentalGatePinError <> "" then
        errorLabel = uiLabel(m.parentalGateHost, m.parentalGatePinError, x + 36, y + 182, w - 72, 34, 18, m.colors.red, "center")
        errorLabel.font.size = 18
    else
        continueLabel = uiLabel(m.parentalGateHost, "Enter PIN to continue", x + 36, y + 182, w - 72, 34, 18, m.colors.textDim, "center")
        continueLabel.font.size = 18
    end if
    drawParentalGateKeyboard(x + 133, y + 222)
end sub

sub drawParentalGateDots(x as Integer, y as Integer)
    for i = 0 to 3
        filled = i < m.parentalGatePinInput.len()
        dotX = x + i * 56
        drawParentalGatePinSlot(m.parentalGateHost, dotX, y, filled)
    end for
end sub

sub drawParentalGatePinSlot(parent as Object, x as Integer, y as Integer, filled as Boolean)
    slotUri = "pkg:/images/ui/rr_42x42_panel_purpleLine.png"
    if filled then slotUri = "pkg:/images/ui/rr_42x42_greenSoft_green.png"
    uiPoster(parent, slotUri, x, y, 42, 42, 0.94)
    if filled then
        uiPoster(parent, "pkg:/images/ui/rr_16x16_text_text.png", x + 13, y + 13, 16, 16, 0.94)
    else
        uiRect(parent, x + 12, y + 20, 18, 2, m.colors.textDim, 0.28)
    end if
end sub

sub drawParentalGateKeyboard(startX as Integer, startY as Integer)
    keyW = 70
    keyH = 36
    gap = 12
    for i = 0 to m.parentalGateKeys.count() - 1
        keyRect = parentalGateKeyRect(i, startX, startY, keyW, keyH, gap)
        keyLabel = m.parentalGateKeys[i]
        uiDrawPinKeyboardKey(m.parentalGateHost, keyLabel, uiKeyboardDisplayText(keyLabel, true), keyRect.x, keyRect.y, keyRect.w, keyRect.h, i = m.parentalGateKeyboardIndex, m.colors)
    end for
end sub

function parentalGateKeyRect(index as Integer, startX as Integer, startY as Integer, keyW as Integer, keyH as Integer, gap as Integer) as Object
    row = Int(index / 3)
    col = index MOD 3
    return { x: startX + col * (keyW + gap), y: startY + row * (keyH + gap), w: keyW, h: keyH }
end function

function parentalGateTargetLabel() as String
    if m.parentalGateTarget = "PlayerPage" then return "playback item"
    if m.parentalGateTarget = "SeriesDetailPage" then return "series"
    return "movie"
end function

function parentalGateRestrictedCategoryLabel() as String
    if m.parentalGateTarget = "PlayerPage" and m.pendingPlayback <> invalid and LCase(parentalControlPayloadText(m.pendingPlayback, "mediaType")) = "live" then
        return parentalControlRestrictedLiveCategory()
    end if
    return parentalControlRestrictedCategory()
end function

function playbackPendingText(page as Object) as String
    if page <> invalid and page.hasField("playbackMediaType") then return page.playbackMediaType
    return ""
end function

function playbackPendingFieldText(page as Object, key as String) as String
    if page <> invalid and page.hasField(key) and page[key] <> invalid then return page[key]
    return ""
end function

function playbackPendingFieldInt(page as Object, key as String) as Integer
    if page <> invalid and page.hasField(key) and page[key] <> invalid then return Int(page[key])
    return 0
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.exitConfirmOpen then return handleExitConfirmKey(key)
    if m.subscriptionGateDialog <> invalid then
        if key = "back" then closeSubscriptionGate() : return true
        return false
    end if
    if m.parentalGateOpen then return handleParentalGateKey(key)

    if key = "back" then
        if m.currentPage <> invalid and m.currentPage.callFunc("handleKey", key) then return true
        if m.pageStack.count() > 0 then
            restored = m.pageStack.pop()
            restorePage(restored)
            return true
        end if
        if m.currentPage <> invalid and m.currentPageName <> "HomePage" then
            homeTarget = gatedPageName("HomePage")
            if homeTarget = m.currentPageName then
                openExitConfirm()
                return true
            end if
            disposePageForRoute(m.currentPageName, m.currentPage)
            showPage(homeTarget)
            return true
        end if
        openExitConfirm()
        return true
    end if

    if m.currentPage <> invalid then
        return m.currentPage.callFunc("handleKey", key)
    end if

    return false
end function

function detailPendingText(page as Object, fieldName as String) as String
    if page = invalid then return ""
    if fieldName = "detailPlaylistId" and page.hasField(fieldName) then return page.detailPlaylistId
    if fieldName = "detailMediaType" and page.hasField(fieldName) then return page.detailMediaType
    if fieldName = "detailEpisodeNames" and page.hasField(fieldName) then return page.detailEpisodeNames
    if fieldName = "detailSeasonNames" and page.hasField(fieldName) then return page.detailSeasonNames
    if fieldName = "detailEpisodeDurations" and page.hasField(fieldName) then return page.detailEpisodeDurations
    if fieldName = "detailActiveEpisodeTitle" and page.hasField(fieldName) then return page.detailActiveEpisodeTitle
    return ""
end function
